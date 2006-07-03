//
//  HotKeyManager.m
//  Short-Cut
//
//  Created by Fox on Sat Nov 29 2003.
//  Copyright (c) 2004 Shadow Lab. All rights reserved.
//

#import "HKKeyMap.h"

#import "HKHotKey.h"

#include <Carbon/Carbon.h>

#import "HKHotKeyManager.h"
#import "HKHotKeyRegister.h"

static const OSType kHKHotKeyEventSignature = 'HkTk';

static OSStatus HandleHotKeyEvent(EventHandlerCallRef nextHandler,EventRef theEvent,void *userData);

BOOL HKTraceHotKeyEvents = NO;

@interface HKHotKeyManager (Private)
- (void)_hotKeyReleased:(HKHotKey *)key;
- (void)_hotKeyPressed:(HKHotKey *)key;
- (OSStatus)handleCarbonEvent:(EventRef)theEvent;
@end

@implementation HKHotKeyManager

+ (HKHotKeyManager *)sharedManager {
  static id sharedManager = nil;
  @synchronized (self) {
    if (!sharedManager) {
      sharedManager = [[self alloc] init];
    }
  }
  return sharedManager;
}

- (id)init {
  if (self = [super init]) {
    EventHandlerRef ref;
    EventHandlerUPP upp;
    EventTypeSpec eventTypes[2];

    eventTypes[0].eventClass = kEventClassKeyboard;
    eventTypes[0].eventKind  = kEventHotKeyPressed;

    eventTypes[1].eventClass = kEventClassKeyboard;
    eventTypes[1].eventKind  = kEventHotKeyReleased;

    upp = NewEventHandlerUPP(HandleHotKeyEvent);
    
    if (noErr != InstallApplicationEventHandler(upp, 2, eventTypes, self, &ref)) {
      [self release];
      self = nil;
    }
    else {
      handlerRef = ref;
      handlerUPP = upp;
      keys = [[NSMutableDictionary alloc] init];
    }
  }
  return self;
}

- (void)dealloc {
  [self unregisterAll];
  [keys release];
  if (handlerRef) {
    RemoveEventHandler(handlerRef);
  }
  if (handlerUPP) {
    DisposeEventHandlerUPP(handlerUPP);
  }
  [super dealloc];
}

- (BOOL)registerHotKey:(HKHotKey *)key {
  // Si la cle est valide est non enregistré
  if ([key isValid] && ![keys objectForKey:key]) {
    UInt32 mask = [key modifier];
    UInt16 keycode = [key keycode];
    DLog(@"%@ Code: %i, mask: %x, character: %C",NSStringFromSelector(_cmd), keycode, mask, [key character]);
    EventHotKeyID hotKeyId = {kHKHotKeyEventSignature, (unsigned)key};
    EventHotKeyRef ref = HKRegisterHotKey(keycode, mask, hotKeyId);
    if (ref) {
      [keys setObject:[NSValue valueWithPointer:ref] forKey:[NSValue valueWithPointer:key]];
      return YES;
    }
  }
  return NO;
}

- (BOOL)unregisterHotKey:(HKHotKey *)key {
  if ([key isRegistred]) {
    EventHotKeyRef ref = [[keys objectForKey:[NSValue valueWithPointer:key]] pointerValue];
    NSAssert(ref != nil, @"Unable to find Carbon HotKey Handler");
    
    BOOL result = (ref) ? HKUnregisterHotKey(ref) : NO;
    
    [keys removeObjectForKey:key];
    return result;
  }
  return NO;
}

- (void)unregisterAll {
  EventHotKeyRef ref;
  NSEnumerator *refs = [keys objectEnumerator];
  while (ref = [[refs nextObject] pointerValue]) {
    HKUnregisterHotKey(ref);
  }
  [keys removeAllObjects];
}

- (OSStatus)handleCarbonEvent:(EventRef)theEvent {
  OSStatus err;
  EventHotKeyID hotKeyID;
  HKHotKey* hotKey;
  
  NSAssert(GetEventClass(theEvent) == kEventClassKeyboard, @"Unknown event class");
  
  err = GetEventParameter(theEvent,
                          kEventParamDirectObject, 
                          typeEventHotKeyID,
                          nil,
                          sizeof(EventHotKeyID),
                          nil,
                          &hotKeyID );
  if(noErr == err) {
    NSAssert(hotKeyID.signature == kHKHotKeyEventSignature, @"Invalid hot key signature");
    NSAssert(hotKeyID.id != nil, @"Invalid hot key id");
    
    if (HKTraceHotKeyEvents) {
      NSLog(@"HKManagerEvent {class:%@ kind:%i signature:%@ id:%p }",
            NSFileTypeForHFSTypeCode(GetEventClass(theEvent)),
            GetEventKind(theEvent),
            NSFileTypeForHFSTypeCode(hotKeyID.signature),
            hotKeyID.id);
    }
    
    hotKey = (HKHotKey*)hotKeyID.id;
    
    switch(GetEventKind(theEvent)) {
      case kEventHotKeyPressed:
        [self _hotKeyPressed:hotKey];
        break;
      case kEventHotKeyReleased:
        [self _hotKeyReleased:hotKey];
        break;
      default:
        NSAssert(NO, @"Unknown event kind");
        break;
    }
  }
  return err;
}

- (void)_hotKeyPressed:(HKHotKey *)key {
  [key keyPressed];
}
- (void)_hotKeyReleased:(HKHotKey *)key {
  [key keyReleased];
}

#pragma mark Filter Support
static HKHotKeyFilter _filter;

+ (void)setShortcutFilter:(HKHotKeyFilter)filter {
  _filter = filter;
}

#pragma mark -
+ (BOOL)isValidHotKeyCode:(UInt16)code withModifier:(UInt32)modifier {
  BOOL isValid = YES;
  // Si un filtre est utilisé, on l'utilise.
  if (_filter != nil) {
    isValid = (*_filter)(code, modifier);
  }
  if (isValid) {
    // Si le filtre est OK, on demande au system ce qu'il en pense.
    EventHotKeyID hotKeyId = {'Test', 0};
    @synchronized (self) {
      EventHotKeyRef key = HKRegisterHotKey(code, modifier, hotKeyId);
      if (key) {
        // Si le système est OK, la clée est valide
        HKUnregisterHotKey(key);
      }
      else {
        // Sinon elle est invalide.
        isValid = NO;
      }
    }
  }
  return isValid;
}

@end

#pragma mark -
#pragma mark Carbon Event Handler
OSStatus HandleHotKeyEvent(EventHandlerCallRef nextHandler,EventRef theEvent,void *userData) {
  return [(id)userData handleCarbonEvent:theEvent];
}
