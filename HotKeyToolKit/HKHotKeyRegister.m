/*
 *  HKHotKeyRegister.m
 *  HotKeyToolKit
 *
 *  Created by Shadow Team.
 *  Copyright (c) 2004 - 2007 Shadow Lab. All rights reserved.
 */

#import "HKHotKeyRegister.h"
#import "HKKeyMap.h"

EventHotKeyRef HKRegisterHotKey(HKKeycode keycode, HKModifier modifier, EventHotKeyID hotKeyId) {
  EventHotKeyRef outRef;
  /* Convert from cocoa to carbon */
  UInt32 mask = (UInt32)HKUtilsConvertModifier(modifier, kHKModifierFormatNative, kHKModifierFormatCarbon);
  OSStatus err = RegisterEventHotKey(keycode,
                                     mask,
                                     hotKeyId,
                                     GetApplicationEventTarget(),
                                     0,
                                     &outRef);
#if defined(DEBUG)
  switch (err) {
    case noErr:
      //NSLog(@"HotKey Registred");
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
      //NSLog(@"HotKey Unregistred");
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
