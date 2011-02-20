/*
 *  TISKeyMap.m
 *  HotKeyToolKit
 *
 *  Created by Jean-Daniel Dupas.
 *  Copyright © 2004 - 2011 Shadow Lab. All rights reserved.
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
  .init = HKTISKeyMapInit,
  .dispose = HKTISKeyMapDispose,
  .isCurrent = HKTISKeyMapIsCurrent,
  .getName = HKTISKeyMapGetName,
  .getLocalizedName = HKTISKeyMapGetLocalizedName,
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
    keymap->storage.tis.keyboard = (TISInputSourceRef)CFRetain(source);
  }
  return keymap;
}

OSStatus HKTISKeyMapInit(HKKeyMapRef keyMap) {
  OSStatus err = noErr;
  CFDataRef uchr = TISGetInputSourceProperty(keyMap->storage.tis.keyboard, kTISPropertyUnicodeKeyLayoutData);
  if (uchr) {
    err = HKKeyMapContextWithUchrData((const UCKeyboardLayout *)CFDataGetBytePtr(uchr), keyMap->reverse, &keyMap->ctxt);
  } else {
#if !__LP64__
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
    if (noErr != err) { WBCLogWarning("Error while trying to get layout data"); }
#else
    WBCLogWarning("No UCHR data found and 64 bits does not support KCHR.");
    err = paramErr;
#endif
  }
  if (noErr == err) {
    keyMap->storage.tis.identifier = TISGetInputSourceProperty(keyMap->storage.tis.keyboard, kTISPropertyInputSourceID);
    if (keyMap->storage.tis.identifier) CFRetain(keyMap->storage.tis.identifier);
  }
  return err;
}

void HKTISKeyMapDispose(HKKeyMapRef keyMap) {
  if (keyMap->storage.tis.keyboard) CFRelease(keyMap->storage.tis.keyboard);
  if (keyMap->storage.tis.identifier) CFRelease(keyMap->storage.tis.identifier);
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

HKKeyMapRef HKTISKeyMapCreateWithCurrentLayout(void) {
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
    current = CFEqual(identifier, keyMap->storage.tis.identifier);
    CFRelease(identifier);
  }
  return current;
}

CFStringRef HKTISKeyMapGetName(HKKeyMapRef keymap) {
  return TISGetInputSourceProperty(keymap->storage.tis.keyboard, kTISPropertyInputSourceLanguages);
}

CFStringRef HKTISKeyMapGetLocalizedName(HKKeyMapRef keymap) {
  return TISGetInputSourceProperty(keymap->storage.tis.keyboard, kTISPropertyLocalizedName);
}

