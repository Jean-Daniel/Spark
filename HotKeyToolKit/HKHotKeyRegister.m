//
//  SKHotKeyRegister.m
//  Spark
//
//  Created by Fox on Sun Dec 14 2003.
//  Copyright (c) 2004 Shadow Lab. All rights reserved.
//

#include <Carbon/Carbon.h>
#import "HKHotKeyRegister.h"
#import "HKKeyMap.h"

UInt32 HKCocoaToCarbonModifier(UInt32 mask) {
  UInt32 carbonMask = 0;
  if (NSControlKeyMask & mask) {
    carbonMask |= controlKey; // Ctrl
  }
  if (NSAlternateKeyMask & mask) {
    carbonMask |= optionKey; // Opt
  }
  if (NSShiftKeyMask & mask) {
    carbonMask |= shiftKey; // Shift
  }
  if (NSCommandKeyMask & mask) {
    carbonMask |= cmdKey; //Cmd
  }
/*
  if (NSNumericPadKeyMask & mask) {
    carbonMask |= kEventKeyModifierNumLockMask; //numpad
  }
  if (NSFunctionKeyMask & mask) {
    carbonMask |= kEventKeyModifierFnBit;
  }
 */
  return carbonMask;
}

UInt32 HKCarbonToCocoaModifier(UInt32 mask) {
  UInt32 cocoaMask = 0;
  if ((controlKey | rightControlKey) & mask) {
    cocoaMask |= NSControlKeyMask; // Ctrl
  }
  if ((optionKey | rightOptionKey) & mask) {
    cocoaMask |= NSAlternateKeyMask; // Opt
  }
  if ((shiftKey | rightShiftKey) & mask) {
    cocoaMask |= NSShiftKeyMask; // Shift
  }
  if (cmdKey & mask) {
    cocoaMask |= NSCommandKeyMask; //Cmd
  }
  if (alphaLock & mask) {
    cocoaMask |= NSAlphaShiftKeyMask; //Caps lock
  }
/*
  if (kEventKeyModifierNumLockMask & mask) {
    cocoaMask |= NSNumericPadKeyMask; //numpad
  }
  if (kEventKeyModifierFnBit & mask) {
    cocoaMask |= NSFunctionKeyMask;
  }
 */
  return cocoaMask;
}

EventHotKeyRef HKRegisterHotKey(UInt16 keycode, UInt32 modifier, EventHotKeyID hotKeyId) {
  EventHotKeyRef outRef;
  UInt32 mask = HKCocoaToCarbonModifier(modifier);
  OSStatus err = RegisterEventHotKey (keycode,
                                      mask,
                                      hotKeyId,
                                      GetApplicationEventTarget(),
                                      0,
                                      &outRef);
#if defined(DEBUG)
  switch (err) {
    case noErr:
      NSLog(@"HotKey Registred");
      break;
    case eventHotKeyExistsErr:
      NSLog(@"HotKey Exists");
      break;
    case eventHotKeyInvalidErr:
      NSLog(@"Invalid Hot Key");
      break;
    default:
      NSLog(@"Undefined error RegisterEventHotKey: %i", err);
  }
#else
#pragma unused(err)
#endif
  return outRef;
}

BOOL HKUnregisterHotKey(EventHotKeyRef ref) {
  NSCParameterAssert(nil != ref);
  OSStatus err = UnregisterEventHotKey(ref);
#if defined(DEBUG)
  switch (err) {
    case noErr:
      NSLog(@"HotKey Unregistred");
      break;
    case eventHotKeyInvalidErr:
      NSLog(@"Invalid Hot Key");
      break;
    default:
      NSLog(@"Error %i during UnregisterEventHotKey", err);
  }
#endif
  return err == noErr;
}
