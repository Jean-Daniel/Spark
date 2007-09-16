/*
 *  KLKeyMap.m
 *  HotKeyToolKit
 *
 *  Created by Shadow Team.
 *  Copyright (c) 2004 - 2007 Shadow Lab. All rights reserved.
 */

#import "KeyMap.h"
#import "KLKeyMap.h"
#import "TISKeyMap.h"

#if MAC_OS_X_VERSION_MIN_REQUIRED < MAC_OS_X_VERSION_10_5

HK_INLINE
KeyboardLayoutIdentifier __CurrentKCHRId(void) {
  KeyboardLayoutRef ref;
  KLGetCurrentKeyboardLayout(&ref);
  KeyboardLayoutIdentifier uid = 0;
  KLGetKeyboardLayoutProperty(ref, kKLIdentifier, (void *)&uid);
  return uid;
}

static
HKKeyMapRef HKKeyMapCreateWithKeyboardLayout(KeyboardLayoutRef layout, Boolean reverse) {
  HKKeyMapRef keymap = calloc( 1, sizeof(struct __HKKeyMap));
  if (keymap) {
    keymap->reverse = reverse;
    keymap->kl.keyboard = layout;
    if (noErr != _HKKeyMapInit(keymap)) {
      HKKeyMapRelease(keymap);
      keymap = nil;
    }
  }
  return keymap;
}

OSStatus HKKLKeyMapInit(HKKeyMapRef keyMap) {
  /* find the current layout resource ID */
  KeyboardLayoutKind kind = 0;
  KeyboardLayoutPropertyTag tag = 0;
  KLGetKeyboardLayoutProperty(keyMap->kl.keyboard, kKLIdentifier, (void *)&(keyMap->kl.identifier));
  
  OSStatus err = KLGetKeyboardLayoutProperty(keyMap->kl.keyboard, kKLKind, (void *)&kind);
  if (noErr == err) {
    switch (kind) {
    case kKLuchrKind:
    case kKLKCHRuchrKind:
      // Load uchr data
      tag = kKLuchrData;
      break;
    case kKLKCHRKind:
      // load kchr data
      tag = kKLKCHRData;
      break;
    }
  }
  const void *data = NULL;
  if (noErr == err) {
    err = KLGetKeyboardLayoutProperty(keyMap->kl.keyboard, tag, (void *)&data);
  }
  if (noErr == err) {
    switch (kind) {
    case kKLuchrKind:
    case kKLKCHRuchrKind:
      // Load uchr data
      err = HKKeyMapContextWithUchrData(data, keyMap->reverse, &keyMap->ctxt);
      break;
    case kKLKCHRKind:
      // load kchr data
      err = HKKeyMapContextWithKCHRData(data, keyMap->reverse, &keyMap->ctxt);
      break;
    }
  }
  return err;
}

void HKKLKeyMapDispose(HKKeyMapRef keyMap) {
  keyMap->kl.keyboard = NULL;
}

HKKeyMapRef HKKLKeyMapCreateWithName(CFStringRef name, Boolean reverse) {
  KeyboardLayoutRef ref;
  if (noErr == KLGetKeyboardLayoutWithName(name, &ref)) {
    return HKKeyMapCreateWithKeyboardLayout(ref, reverse);
  }
  return NULL;
}

HKKeyMapRef HKKLKeyMapCreateWithCurrentLayout(Boolean reverse) {
  KeyboardLayoutRef ref;
  if (noErr == KLGetCurrentKeyboardLayout(&ref)) { 
    return HKKeyMapCreateWithKeyboardLayout(ref, reverse);
  }
  return NULL;
}

Boolean HKKLKeyMapIsCurrent(HKKeyMapRef keyMap) {
  return __CurrentKCHRId() == keyMap->kl.identifier;
}

CFStringRef HKKLKeyMapGetName(HKKeyMapRef keymap) {
  CFStringRef str = NULL;
  KLGetKeyboardLayoutProperty(keymap->kl.keyboard, kKLName, (void *)&str);
  return str;
}

CFStringRef HKKLKeyMapGetLocalizedName(HKKeyMapRef keymap) {
  CFStringRef str = NULL;
  KLGetKeyboardLayoutProperty(keymap->kl.keyboard, kKLLocalizedName, (void *)&str);
  return str;  
}

#endif /* Leopard */
