/*
 *  KLKeyMap.m
 *  HotKeyToolKit
 *
 *  Created by Shadow Team.
 *  Copyright (c) 2004 - 2008 Shadow Lab. All rights reserved.
 */

#import "KeyMap.h"
#import "KLKeyMap.h"
#import "TISKeyMap.h"

#if MAC_OS_X_VERSION_MIN_REQUIRED < MAC_OS_X_VERSION_10_5

static
OSStatus HKKLKeyMapInit(HKKeyMapRef keyMap);
static
void HKKLKeyMapDispose(HKKeyMapRef keyMap);

static
Boolean HKKLKeyMapIsCurrent(HKKeyMapRef keyMap);
static
CFStringRef HKKLKeyMapGetName(HKKeyMapRef keymap);
static
CFStringRef HKKLKeyMapGetLocalizedName(HKKeyMapRef keymap);

const HKLayoutContext kKLContext = {
init:HKKLKeyMapInit,
dispose:HKKLKeyMapDispose,
isCurrent:HKKLKeyMapIsCurrent,
getName:HKKLKeyMapGetName,
getLocalizedName:HKKLKeyMapGetLocalizedName,
};

HK_INLINE
KeyboardLayoutIdentifier __CurrentKCHRId(void) {
  KeyboardLayoutRef ref;
  KLGetCurrentKeyboardLayout(&ref);
  KeyboardLayoutIdentifier uid = 0;
  KLGetKeyboardLayoutProperty(ref, kKLIdentifier, (void *)&uid);
  return uid;
}

static
HKKeyMapRef HKKeyMapCreateWithKeyboardLayout(KeyboardLayoutRef layout) {
  HKKeyMapRef keymap = calloc( 1, sizeof(struct __HKKeyMap));
  if (keymap) {
    keymap->lctxt = kKLContext;
    keymap->storage.kl.keyboard = layout;
  }
  return keymap;
}

OSStatus HKKLKeyMapInit(HKKeyMapRef keyMap) {
  /* find the current layout resource ID */
  KeyboardLayoutKind kind = 0;
  KeyboardLayoutPropertyTag tag = 0;
  KLGetKeyboardLayoutProperty(keyMap->storage.kl.keyboard, kKLIdentifier, (void *)&(keyMap->storage.kl.identifier));
  
  OSStatus err = KLGetKeyboardLayoutProperty(keyMap->storage.kl.keyboard, kKLKind, (void *)&kind);
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
    err = KLGetKeyboardLayoutProperty(keyMap->storage.kl.keyboard, tag, (void *)&data);
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
  keyMap->storage.kl.keyboard = NULL;
}

HKKeyMapRef HKKLKeyMapCreateWithName(CFStringRef name) {
  KeyboardLayoutRef ref;
  if (noErr == KLGetKeyboardLayoutWithName(name, &ref)) {
    return HKKeyMapCreateWithKeyboardLayout(ref);
  }
  return NULL;
}

HKKeyMapRef HKKLKeyMapCreateWithCurrentLayout(void) {
  KeyboardLayoutRef ref;
  if (noErr == KLGetCurrentKeyboardLayout(&ref)) { 
    return HKKeyMapCreateWithKeyboardLayout(ref);
  }
  return NULL;
}

Boolean HKKLKeyMapIsCurrent(HKKeyMapRef keyMap) {
  return __CurrentKCHRId() == keyMap->storage.kl.identifier;
}

CFStringRef HKKLKeyMapGetName(HKKeyMapRef keymap) {
  CFStringRef str = NULL;
  KLGetKeyboardLayoutProperty(keymap->storage.kl.keyboard, kKLName, (void *)&str);
  return str;
}

CFStringRef HKKLKeyMapGetLocalizedName(HKKeyMapRef keymap) {
  CFStringRef str = NULL;
  KLGetKeyboardLayoutProperty(keymap->storage.kl.keyboard, kKLLocalizedName, (void *)&str);
  return str;  
}

#endif /* Leopard */
