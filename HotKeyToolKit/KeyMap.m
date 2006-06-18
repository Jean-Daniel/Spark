/*
 *  KeyMap.c
 *  Short-Cut
 *
 *  Created by Fox on Tue Dec 09 2003.
 *  Copyright (c) 2004 Shadow Lab. All rights reserved.
 *
 */

#import "KeyMap.h"
#import "HKKeyMap.h"
#import "HKKeyboardUtils.h"

#pragma mark Structure Definition
struct __HKKeyMap {
  UInt32 kchrID;
  CFStringRef keyMapName;
  UInt16 keyCount;
  UInt16 mapCount;
  UniChar *keyMap;
  UInt16 *modifiers;
};

#pragma mark -
#pragma mark Statics Functions Declaration
static OSStatus HKKeyMapInit(HKKeyMapRef currentKeyMap);
static void HKKeyMapDispose(HKKeyMapRef keyMap);

static inline UInt32 CurrentKCHRId(void) {
  KeyboardLayoutRef ref;
  UInt32 uid = 0;
  KLGetCurrentKeyboardLayout(&ref);
  KLGetKeyboardLayoutProperty(ref, kKLIdentifier, (const void **)&uid);
  return uid;
}

#pragma mark -
#pragma mark Creation/Destruction functions.
HKKeyMapRef HKKeyMapCreate() {
  HKKeyMapRef keymap = NSZoneCalloc(nil, 1, sizeof(struct __HKKeyMap));
  if (nil != keymap) {
    if (noErr != HKKeyMapInit(keymap)) {
      HKKeyMapRelease(keymap);
      keymap = nil;
    }
  }
  return keymap;
}

void HKKeyMapRelease(HKKeyMapRef keymap) {
  HKKeyMapDispose(keymap);
  NSZoneFree(nil, keymap);
}

#pragma mark -
#pragma mark Public Functions Definition.

OSStatus HKKeyMapValidate(HKKeyMapRef currentKeyMap, Boolean *wasChanged) {
  UInt32 theID = CurrentKCHRId();
  if (theID != currentKeyMap->kchrID) {
    if (wasChanged)
      *wasChanged = YES;
    HKKeyMapDispose(currentKeyMap);
    return HKKeyMapInit(currentKeyMap);
  }
  else {
    if (wasChanged)
      *wasChanged = NO;
    return noErr;
  }
}

UInt32 HKKeyMapUnicharToKeycodes(HKKeyMapRef keyMap, UniChar charCode) {
  unsigned int i = 0;
  HKKeyMapValidate(keyMap, nil);
  UniChar *character = keyMap->keyMap;
  UInt32 length = keyMap->mapCount * keyMap->keyCount;
  while (i < length) {
    if (charCode == *character) {
      UInt32 modifier = keyMap->modifiers[i/keyMap->keyCount];
      return (i % keyMap->keyCount) | HKCarbonToCocoaModifier(modifier);
    }
    character++;
    i++;
  }
  return kHKNilVirtualKeyCode;
}

UniChar HKKeyMapKeycodeToUniChar(HKKeyMapRef keyMap, UInt16 virtualKeyCode) {
  HKKeyMapValidate(keyMap, nil);
  if (virtualKeyCode < keyMap->keyCount) {
    return keyMap->keyMap[virtualKeyCode];
  }
  return kHKNilUnichar;
}

CFStringRef HKKeyMapGetName(HKKeyMapRef keymap) {
  return (keymap != nil) ? keymap->keyMapName : nil;
}

#pragma mark -
#pragma mark Statics Functions Definition.

OSStatus HKKeyMapInit(HKKeyMapRef keyMap) {
  /* find the current layout resource ID */
  KeyboardLayoutRef ref;
  KLGetCurrentKeyboardLayout(&ref);
  KLGetKeyboardLayoutProperty(ref, kKLIdentifier, (const void **)&(keyMap->kchrID));
  KLGetKeyboardLayoutProperty(ref, kKLLocalizedName, (const void **)&(keyMap->keyMapName));
  
  return HKCurrentKeyMap(&(keyMap->keyMap), &(keyMap->keyCount), &(keyMap->mapCount), &(keyMap->modifiers));
}

void HKKeyMapDispose(HKKeyMapRef keyMap) {
  keyMap->kchrID = 0;
  keyMap->keyMapName = nil;
  keyMap->keyCount = 0;
  keyMap->mapCount = 0;
  if (keyMap->keyMap) {
    NSZoneFree(nil, keyMap->keyMap);
    keyMap->keyMap = nil;
  }
  if (keyMap->modifiers) {
    NSZoneFree(nil, keyMap->modifiers);
    keyMap->modifiers = nil;
  }
}
