/*
 *  HKHotKeyManager.m
 *  HotKeyToolKit
 *
 *  Created by Shadow Team.
 *  Copyright (c) 2004 - 2007 Shadow Lab. All rights reserved.
 */

#import "HKKeyMap.h"

#import "HKHotKey.h"
#import "HKHotKeyManager.h"
#import "HKHotKeyRegister.h"

static
const OSType kHKHotKeyEventSignature = 'HkTk';

static 
OSStatus _HandleHotKeyEvent(EventHandlerCallRef nextHandler, EventRef theEvent, void *userData);

static 
NSUInteger gHotKeyUID = 0;

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
  static HKHotKeyManager *shared = nil;
  if (!shared) {
    @synchronized (self) {
      if (!shared) {
        shared = [[self alloc] init];
      }
    }
  }
  return shared;
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
      hk_keys = NSCreateMapTable(NSIntegerMapKeyCallBacks, NSNonRetainedObjectMapValueCallBacks, 0);
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

#pragma mark -
- (BOOL)registerHotKey:(HKHotKey *)key {
  // Si la cle est valide est non enregistré
  if ([key isValid] && !NSMapGet(hk_refs, key)) {
    HKModifier mask = [key nativeModifier];
    HKKeycode keycode = [key keycode];
    NSUInteger uid = ++gHotKeyUID;
    if (HKTraceHotKeyEvents) {
      NSLog(@"Register HotKey %@", key);
    }
    EventHotKeyID hotKeyId = { kHKHotKeyEventSignature, (UInt32)uid };
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
  if (NSMapGet(hk_refs, key) /* [key isRegistred] */) {
    EventHotKeyRef ref = NSMapGet(hk_refs, key);
    NSAssert(ref != nil, @"Unable to find Carbon HotKey Handler");
    
    BOOL result = (ref) ? HKUnregisterHotKey(ref) : NO;
    
    if (HKTraceHotKeyEvents) {
      NSLog(@"Unregister HotKey: %@", key);
    }
    
    NSMapRemove(hk_refs, key);

    /* Remove from keys record */
    intptr_t uid = 0;
    HKHotKey *hkey = nil;
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
                          NULL,
                          sizeof(EventHotKeyID),
                          NULL,
                          &hotKeyID);
  if(noErr == err) {
    NSAssert(hotKeyID.id != 0, @"Invalid hot key id");
    NSAssert(hotKeyID.signature == kHKHotKeyEventSignature, @"Invalid hot key signature");
    
    if (HKTraceHotKeyEvents) {
      NSLog(@"HKManagerEvent {class:%@ kind:%u signature:%@ id:%p }",
            NSFileTypeForHFSTypeCode(GetEventClass(theEvent)),
            GetEventKind(theEvent),
            NSFileTypeForHFSTypeCode(hotKeyID.signature),
            hotKeyID.id);
    }
    hotKey = NSMapGet(hk_keys, (void *)(intptr_t)hotKeyID.id);
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

#pragma mark -
+ (BOOL)isValidHotKeyCode:(HKKeycode)code withModifier:(HKModifier)modifier {
  BOOL isValid = NO;
  EventHotKeyID hotKeyId = { 'Test', 0 };
  EventHotKeyRef key = HKRegisterHotKey(code, modifier, hotKeyId);
  if (key) {
    isValid = YES;
    HKUnregisterHotKey(key);
  }
  return isValid;
}

@end

#pragma mark -
#pragma mark Carbon Event Handler
OSStatus _HandleHotKeyEvent(EventHandlerCallRef nextHandler, EventRef theEvent, void *userData) {
  return [(HKHotKeyManager *)userData handleCarbonEvent:theEvent];
}
