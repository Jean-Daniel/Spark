/*
 *  KeyMap.m
 *  HotKeyToolKit
 *
 *  Created by Jean-Daniel Dupas.
 *  Copyright © 2004 - 2011 Shadow Lab. All rights reserved.
 */

#include <Carbon/Carbon.h>

#import "KeyMap.h"
#import "KLKeyMap.h"
#import "TISKeyMap.h"
#import <HotKeyToolKit/HKKeyMap.h>

#pragma mark -

static
void _HKKeyMapDispose(HKKeyMapRef keymap) {
  if (keymap->ctxt.dealloc) {
    keymap->ctxt.dealloc(&keymap->ctxt);
    bzero(&keymap->ctxt, sizeof(keymap->ctxt));
  }
  if (keymap->constructor) CFRelease(keymap->constructor);
  keymap->lctxt.dispose(keymap);
}

#pragma mark -
#pragma mark Creation/Destruction functions.
static OSStatus _HKKeyMapInit(HKKeyMapRef keymap, CFStringRef name, Boolean reverse) {
  keymap->reverse = reverse;
  keymap->constructor = name ? CFRetain(name) : NULL;
  return keymap->lctxt.init(keymap);
}

HKKeyMapRef HKKeyMapCreateWithName(CFStringRef name, Boolean reverse) {
  check(name);
  HKKeyMapRef keymap = NULL;
  if (HKTISAvailable()) {
    keymap = HKTISKeyMapCreateWithName(name);
  } else {
    keymap = HKKLKeyMapCreateWithName(name);
  }
  if (keymap && noErr != _HKKeyMapInit(keymap, name, reverse)) {
    HKKeyMapRelease(keymap);
    keymap = nil;
  }
  return keymap;
}

HKKeyMapRef HKKeyMapCreateWithCurrentLayout(Boolean reverse) {
  HKKeyMapRef keymap = NULL;
  if (HKTISAvailable()) {
    keymap = HKTISKeyMapCreateWithCurrentLayout();
  } else {
    keymap = HKKLKeyMapCreateWithCurrentLayout();
  }
  if (keymap && noErr != _HKKeyMapInit(keymap, NULL, reverse)) {
    HKKeyMapRelease(keymap);
    keymap = nil;
  }
  return keymap;
}

void HKKeyMapRelease(HKKeyMapRef keymap) {
  check(keymap);
  _HKKeyMapDispose(keymap);
  free(keymap);
}

#pragma mark -
#pragma mark Public Functions Definition.
// FIXME: Broken method
OSStatus HKKeyMapCheckCurrentMap(HKKeyMapRef keyMap, Boolean *wasChanged) {
  check(keyMap);
  if (wasChanged) *wasChanged = false;

//  Boolean changed = false;
//  switch (keyMap->kind) {
//    case kHKKeyMapKindKL:
//      changed = !HKKLKeyMapIsCurrent(keyMap);
//      break;
//    case kHKKeyMapKindTIS:
//      changed = !HKTISKeyMapIsCurrent(keyMap);
//      break;
//  }
//
//  if (changed) {
//    if (wasChanged)
//      *wasChanged = YES;
//    _HKKeyMapDispose(keyMap);
//    return keyMap->lctxt.init(keyMap);
//  } else {
//    if (wasChanged)
//      *wasChanged = NO;
//    return noErr;
//  }
  return noErr;
}

NSUInteger HKKeyMapGetKeycodesForUnichar(HKKeyMapRef keyMap, UniChar character, HKKeycode *keys, HKModifier *modifiers, NSUInteger maxsize) {
  assert(keyMap);
  NSUInteger count = 0;
  if (keyMap && keyMap->reverse && keyMap->ctxt.reverseMap) {
    count = keyMap->ctxt.reverseMap(keyMap->ctxt.data, character, keys, modifiers, maxsize);
  }
  return count;
}

UniChar HKKeyMapGetUnicharForKeycode(HKKeyMapRef keyMap, HKKeycode virtualKeyCode) {
  assert(keyMap);
  UniChar result = kHKNilUnichar;
  if (keyMap && keyMap->ctxt.baseMap)
    result = keyMap->ctxt.baseMap(keyMap->ctxt.data, virtualKeyCode);
  return result;
}

UniChar HKKeyMapGetUnicharForKeycodeAndModifier(HKKeyMapRef keyMap, HKKeycode virtualKeyCode, HKModifier modifiers) {
  assert(keyMap);
  UniChar result = kHKNilUnichar;
  if (keyMap && keyMap->ctxt.fullMap)
    result = keyMap->ctxt.fullMap(keyMap->ctxt.data, virtualKeyCode, modifiers);
  return result;
}

CFStringRef HKKeyMapGetName(HKKeyMapRef keyMap) {
  assert(keyMap);
  return keyMap ? keyMap->lctxt.getName(keyMap) : NULL;
}

CFStringRef HKKeyMapGetLocalizedName(HKKeyMapRef keyMap) {
  assert(keyMap);
  return keyMap ? keyMap->lctxt.getLocalizedName(keyMap) : NULL;
}

