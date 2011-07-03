/*
 *  HKHotKeyManager.m
 *  HotKeyToolKit
 *
 *  Created by Jean-Daniel Dupas.
 *  Copyright © 2004 - 2011 Shadow Lab. All rights reserved.
 */

#import "HKKeyMap.h"

#import "HKHotKey.h"
#import "HKHotKeyManager.h"

#include <Carbon/Carbon.h>

static
const OSType kHKHotKeyEventSignature = 'HkTk';

static
OSStatus _HandleHotKeyEvent(EventHandlerCallRef nextHandler, EventRef theEvent, void *userData);

static
OSStatus HKRegisterHotKey(HKKeycode keycode, HKModifier modifier, EventHotKeyID hotKeyId, EventHotKeyRef *outRef) {
  /* Convert from cocoa to carbon */
  UInt32 mask = (UInt32)HKUtilsConvertModifier(modifier, kHKModifierFormatNative, kHKModifierFormatCarbon);
  return RegisterEventHotKey(keycode, mask,hotKeyId, GetApplicationEventTarget(), 0, outRef);
}

static
OSStatus HKUnregisterHotKey(EventHotKeyRef ref) {
  return UnregisterEventHotKey(ref);
}

static NSUInteger gHotKeyUID = 0;

/* Debugging purpose */
BOOL HKTraceHotKeyEvents = NO;

@interface HKHotKeyManager ()
- (OSStatus)handleCarbonEvent:(EventRef)theEvent;
@end

@implementation HKHotKeyManager

static HKHotKeyManager *sManager = nil;
+ (void)initialize {
  if ([HKHotKeyManager class] == self) {
    sManager = [[self alloc] init];
  }
}

+ (HKHotKeyManager *)sharedManager { return sManager; }

- (id)init {
  if (self = [super init]) {
    EventHandlerRef ref;
    EventTypeSpec eventTypes[] = {
      { .eventClass = kEventClassKeyboard, .eventKind  = kEventHotKeyPressed },
      { .eventClass = kEventClassKeyboard, .eventKind  = kEventHotKeyReleased },
    };

    OSStatus err = InstallApplicationEventHandler(_HandleHotKeyEvent, GetEventTypeCount(eventTypes), eventTypes, (__bridge void *)self, &ref);
    if (noErr != err) {
      WBLogError(@"Event handler creation failed: %s", GetMacOSStatusCommentString(err));
      wb_release(self);
      self = nil;
    } else {
      hk_handler = ref;
      /* UInt32 uid => HKHotKey */
      hk_keys = NSCreateMapTable(NSIntegerMapKeyCallBacks, NSNonRetainedObjectMapValueCallBacks, 0);
      /* HKHotKey => EventHotKeyRef */
      hk_refs = NSCreateMapTable(NSNonRetainedObjectMapKeyCallBacks, NSNonOwnedPointerMapValueCallBacks, 0);
    }
  }
  return self;
}

- (void)dealloc {
  [self unregisterAll];
  if (hk_refs) NSFreeMapTable(hk_refs);
  if (hk_keys) NSFreeMapTable(hk_keys);
  if (hk_handler) RemoveEventHandler(hk_handler);
  wb_dealloc();
}

//MARK: -
- (BOOL)registerHotKey:(HKHotKey *)key {
  // Si la cle est valide est non enregistré
  if ([key isValid] && !NSMapGet(hk_refs, (__bridge void *)key)) {
    HKModifier mask = [key nativeModifier];
    HKKeycode keycode = [key keycode];
    NSUInteger uid = ++gHotKeyUID;

    if (HKTraceHotKeyEvents)
      NSLog(@"Register HotKey %@", key);

    EventHotKeyRef ref = NULL;
    EventHotKeyID hotKeyId = { kHKHotKeyEventSignature, (UInt32)uid };
    if (noErr == HKRegisterHotKey(keycode, mask, hotKeyId, &ref)) {
      NSMapInsert(hk_refs, (__bridge void *)key, ref);
      NSMapInsert(hk_keys, (void *)uid, (__bridge void *)key);
      return YES;
    }
  }
  return NO;
}

- (BOOL)unregisterHotKey:(HKHotKey *)key {
  if (NSMapGet(hk_refs, (__bridge void *)key) /* [key isRegistred] */) {
    EventHotKeyRef ref = NSMapGet(hk_refs, (__bridge void *)key);
    NSAssert(ref != nil, @"Unable to find Carbon HotKey Handler");
    if (!ref) return NO;

    OSStatus err = HKUnregisterHotKey(ref);
    if (noErr == err) {
      if (HKTraceHotKeyEvents)
        NSLog(@"Unregister HotKey: %@", key);

      NSMapRemove(hk_refs, (__bridge void *)key);

      /* Remove from keys record */
      intptr_t uid = 0;
      void *hkeyptr = nil;
      NSMapEnumerator refs = NSEnumerateMapTable(hk_keys);
      while (NSNextMapEnumeratorPair(&refs, (void **)&uid, &hkeyptr)) {
        HKHotKey *hkey = (__bridge HKHotKey *)hkeyptr;
        if (hkey == key) {
          NSMapRemove(hk_keys, (void *)uid);
          break;
        }
      }
      NSEndMapTableEnumeration(&refs);
    }
    return noErr == err;
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
  NSAssert(GetEventClass(theEvent) == kEventClassKeyboard, @"Unknown event class");

  EventHotKeyID hotKeyID;
  OSStatus err = GetEventParameter(theEvent,
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
      NSLog(@"HKManagerEvent {class:%@ kind:%lu signature:%@ id:0x%lx }",
            NSFileTypeForHFSTypeCode(GetEventClass(theEvent)),
            (long)GetEventKind(theEvent),
            NSFileTypeForHFSTypeCode(hotKeyID.signature),
            (long)hotKeyID.id);
    }
    HKHotKey *hotKey = (__bridge HKHotKey *)NSMapGet(hk_keys, (void *)(intptr_t)hotKeyID.id);
    if (hotKey) {
      hk_event = theEvent;
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
      hk_event = NULL;
    } else {
      DLog(@"Invalid hotkey id!");
    }
  }
  return err;
}

- (NSTimeInterval)currentEventTime {
  return hk_event ? GetEventTime((EventRef)hk_event) : 0;
}
- (void)hotKeyPressed:(HKHotKey *)key {
  [key keyPressed];
}
- (void)hotKeyReleased:(HKHotKey *)key {
  [key keyReleased];
}

@end

//MARK: -
BOOL HKHotKeyCheckKeyCodeAndModifier(HKKeycode code, HKModifier modifier) {
  BOOL isValid = NO;
  EventHotKeyRef key;
  EventHotKeyID hotKeyId = { 'Test', 0 };
  if (noErr == HKRegisterHotKey(code, modifier, hotKeyId, &key)) {
    verify_noerr(HKUnregisterHotKey(key));
    isValid = YES;
  }
  return isValid;
}

//MARK: Carbon Event Handler
OSStatus _HandleHotKeyEvent(EventHandlerCallRef nextHandler, EventRef theEvent, void *userData) {
  return [(__bridge HKHotKeyManager *)userData handleCarbonEvent:theEvent];
}
