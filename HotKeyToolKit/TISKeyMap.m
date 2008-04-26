/*
 *  TISKeyMap.m
 *  HotKeyToolKit
 *
 *  Created by Shadow Team.
 *  Copyright (c) 2004 - 2007 Shadow Lab. All rights reserved.
 */

#import "KeyMap.h"
#import "TISKeyMap.h"

static
OSStatus HKTISKeyMapInit(HKKeyMapRef keyMap);
static
void HKTISKeyMapDispose(HKKeyMapRef keyMap);

static
Boolean HKTISKeyMapIsCurrent(HKKeyMapRef keyMap);
static
CFStringRef HKTISKeyMapGetName(HKKeyMapRef keymap);
static
CFStringRef HKTISKeyMapGetLocalizedName(HKKeyMapRef keymap);

const HKLayoutContext kTISContext = {
init:HKTISKeyMapInit,
dispose:HKTISKeyMapDispose,
isCurrent:HKTISKeyMapIsCurrent,
getName:HKTISKeyMapGetName,
getLocalizedName:HKTISKeyMapGetLocalizedName,
};

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
HKKeyMapRef HKKeyMapCreateWithInputSource(TISInputSourceRef source) {
  HKKeyMapRef keymap = calloc(1, sizeof(struct __HKKeyMap));
  if (keymap) {
    keymap->lctxt = kTISContext;
    keymap->tis.keyboard = (TISInputSourceRef)CFRetain(source);
  }
  return keymap;
}

OSStatus HKTISKeyMapInit(HKKeyMapRef keyMap) {
  OSStatus err = noErr;
  CFDataRef uchr = TISGetInputSourceProperty(keyMap->tis.keyboard, kTISPropertyUnicodeKeyLayoutData);
  if (uchr) {
    err = HKKeyMapContextWithUchrData((const UCKeyboardLayout *)CFDataGetBytePtr(uchr), keyMap->reverse, &keyMap->ctxt);
  } else {
#if MAC_OS_X_VERSION_MIN_REQUIRED < MAC_OS_X_VERSION_10_5
    /* maybe this is kchr data only ... */
    KeyboardLayoutRef ref;
    if (keyMap->constructor) err = KLGetKeyboardLayoutWithName(keyMap->constructor, &ref);
    else err = KLGetCurrentKeyboardLayout(&ref);
    if (noErr == err) {
      const void *data = NULL;
      err = KLGetKeyboardLayoutProperty(ref, kKLKCHRData, (void *)&data);
      if (noErr == err) 
        err = HKKeyMapContextWithKCHRData(data, keyMap->reverse, &keyMap->ctxt);
    }
    if (noErr != err) { WCLog("Error while trying to get layout data"); }
#else
    WCLog("No UCHR data found and 64 bits does not support KCHR.");
    err = paramErr;
#endif
  }
  if (noErr == err) {
    keyMap->tis.identifier = TISGetInputSourceProperty(keyMap->tis.keyboard, kTISPropertyInputSourceID);
    if (keyMap->tis.identifier) CFRetain(keyMap->tis.identifier);
  }
  return err;
}

void HKTISKeyMapDispose(HKKeyMapRef keyMap) {
  if (keyMap->tis.keyboard) CFRelease(keyMap->tis.keyboard);
  if (keyMap->tis.identifier) CFRelease(keyMap->tis.identifier);
}

HKKeyMapRef HKTISKeyMapCreateWithName(CFStringRef name) {
  HKKeyMapRef keymap = NULL;
  CFStringRef str = CFLocaleCreateCanonicalLanguageIdentifierFromString(kCFAllocatorDefault, name);
  if (str) {
    TISInputSourceRef source = TISCopyInputSourceForLanguage(str);
    if (source) {
      keymap = HKKeyMapCreateWithInputSource(source);
      CFRelease(source);
    }
    CFRelease(str);
  }
  return keymap;
}

HKKeyMapRef HKTISKeyMapCreateWithCurrentLayout() {
  HKKeyMapRef keymap = NULL;
  TISInputSourceRef source = TISCopyCurrentKeyboardLayoutInputSource();
  if (source) {
    keymap = HKKeyMapCreateWithInputSource(source);
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

