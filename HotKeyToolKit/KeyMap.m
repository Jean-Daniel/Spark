/*
 *  KeyMap.m
 *  HotKeyToolKit
 *
 *  Created by Shadow Team.
 *  Copyright (c) 2004 - 2007 Shadow Lab. All rights reserved.
 */

#include <Carbon/Carbon.h>

#import "KeyMap.h"
#import "KLKeyMap.h"
#import "TISKeyMap.h"
#import <HotKeyToolKit/HKKeyMap.h>

#pragma mark -
OSStatus _HKKeyMapInit(HKKeyMapRef keyMap) {
  OSStatus err;
  if (HKTISAvailable()) {
    err = HKTISKeyMapInit(keyMap);
  } else {
	  err = HKKLKeyMapInit(keyMap);   
  }
  return err;
}

static
void _HKKeyMapDispose(HKKeyMapRef keyMap) {
  if (HKTISAvailable()) {
    HKTISKeyMapDispose(keyMap);
  } else {
    HKKLKeyMapDispose(keyMap);
  }
  if (keyMap->ctxt.dealloc) {
    keyMap->ctxt.dealloc(&keyMap->ctxt);
    bzero(&keyMap->ctxt, sizeof(keyMap->ctxt));
  }
}

#pragma mark -
#pragma mark Creation/Destruction functions.
HKKeyMapRef HKKeyMapCreateWithName(CFStringRef name, Boolean reverse) {
  if (HKTISAvailable()) {
    return HKTISKeyMapCreateWithName(name, reverse);
  } else {
    return HKKLKeyMapCreateWithName(name, reverse);
  }
}

HKKeyMapRef HKKeyMapCreateWithCurrentLayout(Boolean reverse) {
  if (HKTISAvailable()) {
    return HKTISKeyMapCreateWithCurrentLayout(reverse);
  } else {
    return HKKLKeyMapCreateWithCurrentLayout(reverse);
  }
}

void HKKeyMapRelease(HKKeyMapRef keymap) {
  _HKKeyMapDispose(keymap);
  free(keymap);
}

#pragma mark -
#pragma mark Public Functions Definition.
OSStatus HKKeyMapCheckCurrentMap(HKKeyMapRef keyMap, Boolean *wasChanged) {
  Boolean changed = false;
  if (HKTISAvailable()) {
    changed = !HKTISKeyMapIsCurrent(keyMap);
  } else {
    changed = !HKKLKeyMapIsCurrent(keyMap);
  }
  if (changed) {
    if (wasChanged)
    *wasChanged = YES;
    _HKKeyMapDispose(keyMap);
    return _HKKeyMapInit(keyMap);
  } else {
    if (wasChanged)
    *wasChanged = NO;
    return noErr;
  }
}

NSUInteger HKKeyMapGetKeycodesForUnichar(HKKeyMapRef keyMap, UniChar character, HKKeycode *keys, HKModifier *modifiers, NSUInteger maxsize) {
  NSUInteger count = 0;
  if (keyMap->reverse && keyMap->ctxt.reverseMap) {
    count = keyMap->ctxt.reverseMap(keyMap->ctxt.data, character, keys, modifiers, maxsize);
  }
  return count;
}

UniChar HKKeyMapGetUnicharForKeycode(HKKeyMapRef keyMap, HKKeycode virtualKeyCode) {
  UniChar result = kHKNilUnichar;
  if (keyMap->ctxt.baseMap) {
    result = keyMap->ctxt.baseMap(keyMap->ctxt.data, virtualKeyCode);
  }
  return result;
}

UniChar HKKeyMapGetUnicharForKeycodeAndModifier(HKKeyMapRef keyMap, HKKeycode virtualKeyCode, HKModifier modifiers) {
  UniChar result = kHKNilUnichar;
  if (keyMap->ctxt.fullMap) {
    result = keyMap->ctxt.fullMap(keyMap->ctxt.data, virtualKeyCode, modifiers);
  }
  return result;
}

CFStringRef HKKeyMapGetName(HKKeyMapRef keymap) {
  CFStringRef str = NULL;
  if (HKTISAvailable()) {
    str = HKTISKeyMapGetName(keymap);
  } else {
    str = HKKLKeyMapGetName(keymap);
  }
  return str;
}

CFStringRef HKKeyMapGetLocalizedName(HKKeyMapRef keymap) {
  CFStringRef str = NULL;
  if (HKTISAvailable()) {
    str = HKTISKeyMapGetLocalizedName(keymap);
  } else {
    str = HKKLKeyMapGetLocalizedName(keymap);
  }
  return str;
}

