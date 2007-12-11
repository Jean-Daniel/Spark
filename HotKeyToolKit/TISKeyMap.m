/*
 *  TISKeyMap.m
 *  HotKeyToolKit
 *
 *  Created by Shadow Team.
 *  Copyright (c) 2004 - 2007 Shadow Lab. All rights reserved.
 */

#import "KeyMap.h"
#import "TISKeyMap.h"

HK_INLINE
CFStringRef __CopyCurrentKeyboardIdentifier(void) {
  CFStringRef uid = NULL;
  TISInputSourceRef input = TISCopyCurrentKeyboardLayoutInputSource();
  if (input) {
    uid = TISGetInputSourceProperty(input, kTISPropertyInputSourceID);
    if (uid) CFRetain(uid);
    CFRelease(input);
  }
  return uid;
}

static
HKKeyMapRef HKKeyMapCreateWithInputSource(TISInputSourceRef source, Boolean reverse) {
  HKKeyMapRef keymap = calloc(1, sizeof(struct __HKKeyMap));
  if (keymap) {
    keymap->reverse = reverse;
    keymap->tis.keyboard = (TISInputSourceRef)CFRetain(source);
    if (noErr != _HKKeyMapInit(keymap)) {
      HKKeyMapRelease(keymap);
      keymap = nil;
    }
  }
  return keymap;
}

OSStatus HKTISKeyMapInit(HKKeyMapRef keyMap) {
  OSStatus err = noErr;
  keyMap->tis.identifier = TISGetInputSourceProperty(keyMap->tis.keyboard, kTISPropertyInputSourceID);
  if (keyMap->tis.identifier) CFRetain(keyMap->tis.identifier);
  
  CFDataRef uchr = TISGetInputSourceProperty(keyMap->tis.keyboard, kTISPropertyUnicodeKeyLayoutData);
  if (uchr) {
    err = HKKeyMapContextWithUchrData((const UCKeyboardLayout *)CFDataGetBytePtr(uchr), keyMap->reverse, &keyMap->ctxt);
  } else {
    ECLog("Error while trying to get layout data");
    err = paramErr;
  }
  return err;
}

void HKTISKeyMapDispose(HKKeyMapRef keyMap) {
  if (keyMap->tis.keyboard) CFRelease(keyMap->tis.keyboard);
  if (keyMap->tis.identifier) CFRelease(keyMap->tis.identifier);
}

HKKeyMapRef HKTISKeyMapCreateWithName(CFStringRef name, Boolean reverse) {
  HKKeyMapRef keymap = NULL;
  CFStringRef str = CFLocaleCreateCanonicalLanguageIdentifierFromString(kCFAllocatorDefault, name);
  if (str) {
    TISInputSourceRef source = TISCopyInputSourceForLanguage(str);
    if (source) {
      keymap = HKKeyMapCreateWithInputSource(source, reverse);
      CFRelease(source);
    }
    CFRelease(str);
  }
  return keymap;
}

HKKeyMapRef HKTISKeyMapCreateWithCurrentLayout(Boolean reverse) {
  HKKeyMapRef keymap = NULL;
  TISInputSourceRef source = TISCopyCurrentKeyboardLayoutInputSource();
  if (source) {
    keymap = HKKeyMapCreateWithInputSource(source, reverse);
    CFRelease(source);
  }
  return keymap;
}

Boolean HKTISKeyMapIsCurrent(HKKeyMapRef keyMap) {
  Boolean current = true;
  CFStringRef identifier = __CopyCurrentKeyboardIdentifier();
  if (identifier) {
    current = CFEqual(identifier, keyMap->tis.identifier);
    CFRelease(identifier);
  }
  return current;
}

CFStringRef HKTISKeyMapGetName(HKKeyMapRef keymap) {
  return TISGetInputSourceProperty(keymap->tis.keyboard, kTISPropertyInputSourceLanguages);
}

CFStringRef HKTISKeyMapGetLocalizedName(HKKeyMapRef keymap) {
  return TISGetInputSourceProperty(keymap->tis.keyboard, kTISPropertyLocalizedName);
}

