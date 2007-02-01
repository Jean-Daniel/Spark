/*
 *  HKHotKeyManager.m
 *  HotKeyToolKit
 *
 *  Created by Shadow Team.
 *  Copyright (c) 2004 - 2007 Shadow Lab. All rights reserved.
 */

#import "HKKeyMap.h"

#import "HKHotKey.h"

#include <Carbon/Carbon.h>
#include <libkern/OSAtomic.h>

#import "HKHotKeyManager.h"
#import "HKHotKeyRegister.h"

static
const OSType kHKHotKeyEventSignature = 'HkTk';

static 
OSStatus _HandleHotKeyEvent(EventHandlerCallRef nextHandler,EventRef theEvent,void *userData);

static int32_t gHotKeyUID = 0;

/* Debugging purpose */
BOOL HKTraceHotKeyEvents = NO;

@interface HKHotKeyManager (Private)
- (OSStatus)handleCarbonEvent:(EventRef)theEvent;
@end

@implementation HKHotKeyManager

static EventHandlerUPP kHKHandlerUPP = NULL;
+ (void)initialize {
  if ([HKHotKeyManager class] == self) {
    kHKHandlerUPP = NewEventHandlerUPP(_HandleHotKeyEvent);
  }
}

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
    EventTypeSpec eventTypes[2];

    eventTypes[0].eventClass = kEventClassKeyboard;
    eventTypes[0].eventKind  = kEventHotKeyPressed;

    eventTypes[1].eventClass = kEventClassKeyboard;
    eventTypes[1].eventKind  = kEventHotKeyReleased;
    
    if (noErr != InstallApplicationEventHandler(kHKHandlerUPP, 2, eventTypes, self, &ref)) {
      [self release];
      self = nil;
    } else {
      hk_handler = ref;
      /* HKHotKey => EventHotKeyRef */
      hk_refs = NSCreateMapTable(NSNonRetainedObjectMapKeyCallBacks, NSNonOwnedPointerMapValueCallBacks, 0);
      /* UInt32 uid => HKHotKey */
      hk_keys = NSCreateMapTable(NSIntMapKeyCallBacks, NSNonRetainedObjectMapValueCallBacks, 0);
    }
  }
  return self;
}

- (void)dealloc {
  [self unregisterAll];
  if (hk_refs) NSFreeMapTable(hk_refs);
  if (hk_keys) NSFreeMapTable(hk_keys);
  if (hk_handler) RemoveEventHandler(hk_handler);
  [super dealloc];
}

- (BOOL)registerHotKey:(HKHotKey *)key {
  // Si la cle est valide est non enregistré
  if ([key isValid] && !NSMapGet(hk_refs, key)) {
    HKModifier mask = [key nativeModifier];
    HKKeycode keycode = [key keycode];
    UInt32 uid = OSAtomicIncrement32(&gHotKeyUID);
    if (HKTraceHotKeyEvents) {
      NSLog(@"Register HotKey %@", key);
    }
    EventHotKeyID hotKeyId = {kHKHotKeyEventSignature, uid};
    EventHotKeyRef ref = HKRegisterHotKey(keycode, mask, hotKeyId);
    if (ref) {
      NSMapInsert(hk_refs, key, ref);
      NSMapInsert(hk_keys, (void *)uid, key);
      return YES;
    }
  }
  return NO;
}

- (BOOL)unregisterHotKey:(HKHotKey *)key {
  if ([key isRegistred]) {
    EventHotKeyRef ref = NSMapGet(hk_refs, key);
    NSAssert(ref != nil, @"Unable to find Carbon HotKey Handler");
    
    BOOL result = (ref) ? HKUnregisterHotKey(ref) : NO;
    
    if (HKTraceHotKeyEvents) {
      NSLog(@"Unregister HotKey: %@", key);
    }
    
    NSMapRemove(hk_refs, key);

    /* Remove from keys record */
    HKHotKey *hkey = nil;
    unsigned long uid = 0;
    NSMapEnumerator refs = NSEnumerateMapTable(hk_keys);
    while (NSNextMapEnumeratorPair(&refs, (void **)&uid, (void **)&hkey)) {
      if (hkey == key) {
        NSMapRemove(hk_keys, (void *)uid);
        break;
      }
    }
    NSEndMapTableEnumeration(&refs);
    
    return result;
  }
  return NO;
}

- (void)unregisterAll {
  EventHotKeyRef ref = NULL;
  
  NSMapEnumerator refs = NSEnumerateMapTable(hk_refs);
  while (NSNextMapEnumeratorPair(&refs, NULL, (void **)&ref)) {
    if (ref)
      HKUnregisterHotKey(ref);
  }
  NSEndMapTableEnumeration(&refs);
  NSResetMapTable(hk_refs);
  NSResetMapTable(hk_keys);
}

- (OSStatus)handleCarbonEvent:(EventRef)theEvent {
  OSStatus err;
  HKHotKey* hotKey;
  EventHotKeyID hotKeyID;
  
  NSAssert(GetEventClass(theEvent) == kEventClassKeyboard, @"Unknown event class");
  
  err = GetEventParameter(theEvent,
                          kEventParamDirectObject, 
                          typeEventHotKeyID,
                          nil,
                          sizeof(EventHotKeyID),
                          nil,
                          &hotKeyID );
  if(noErr == err) {
    NSAssert(hotKeyID.id != 0, @"Invalid hot key id");
    NSAssert(hotKeyID.signature == kHKHotKeyEventSignature, @"Invalid hot key signature");
    
    if (HKTraceHotKeyEvents) {
      NSLog(@"HKManagerEvent {class:%@ kind:%i signature:%@ id:%p }",
            NSFileTypeForHFSTypeCode(GetEventClass(theEvent)),
            GetEventKind(theEvent),
            NSFileTypeForHFSTypeCode(hotKeyID.signature),
            hotKeyID.id);
    }
    
    hotKey = NSMapGet(hk_keys, (void *)hotKeyID.id);
    if (hotKey) {
      switch(GetEventKind(theEvent)) {
        case kEventHotKeyPressed:
          [self hotKeyPressed:hotKey];
          break;
        case kEventHotKeyReleased:
          [self hotKeyReleased:hotKey];
          break;
        default:
          DLog(@"Unknown event kind");
          break;
      }
    } else {
      DLog(@"Invalid hotkey id!");
    }
  }
  return err;
}

- (void)hotKeyPressed:(HKHotKey *)key {
  [key keyPressed];
}
- (void)hotKeyReleased:(HKHotKey *)key {
  [key keyReleased];
}

#pragma mark Filter Support
static HKHotKeyFilter _filter;

+ (void)setShortcutFilter:(HKHotKeyFilter)filter {
  _filter = filter;
}

#pragma mark -
+ (BOOL)isValidHotKeyCode:(HKKeycode)code withModifier:(HKModifier)modifier {
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
OSStatus _HandleHotKeyEvent(EventHandlerCallRef nextHandler,EventRef theEvent,void *userData) {
  return [(id)userData handleCarbonEvent:theEvent];
}
