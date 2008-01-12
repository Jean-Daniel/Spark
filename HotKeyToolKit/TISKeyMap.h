/*
 *  TISKeyMap.h
 *  HotKeyToolKit
 *
 *  Created by Shadow Team.
 *  Copyright (c) 2004 - 2007 Shadow Lab. All rights reserved.
 */
/*!
 @header KeyMap
 */

#import "HKKeyboardUtils.h"

#include <Carbon/Carbon.h>

struct __HKKeyMap {
  Boolean reverse;
  union {
    struct {
      KeyboardLayoutRef keyboard;
      KeyboardLayoutIdentifier identifier;
    } kl;
#if MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_5
    struct {
      TISInputSourceRef keyboard;
      CFStringRef identifier;
    } tis;
#endif
  };
  HKKeyMapContext ctxt;
};

#if MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_5

HK_INLINE
Boolean HKTISAvailable() {
#if MAC_OS_X_VERSION_MIN_REQUIRED >= MAC_OS_X_VERSION_10_5
  return true;
#else
  return TISInputSourceGetTypeID != NULL;
#endif
}

HK_PRIVATE
OSStatus HKTISKeyMapInit(HKKeyMapRef keyMap);
HK_PRIVATE
void HKTISKeyMapDispose(HKKeyMapRef keyMap);

HK_PRIVATE
HKKeyMapRef HKTISKeyMapCreateWithName(CFStringRef name, Boolean reverse);

HK_PRIVATE
HKKeyMapRef HKTISKeyMapCreateWithCurrentLayout(Boolean reverse);


HK_PRIVATE
Boolean HKTISKeyMapIsCurrent(HKKeyMapRef keyMap);

HK_PRIVATE
CFStringRef HKTISKeyMapGetName(HKKeyMapRef keymap);

HK_PRIVATE
CFStringRef HKTISKeyMapGetLocalizedName(HKKeyMapRef keymap);

#else

HK_INLINE
Boolean HKTISAvailable() { return false; }

HK_INLINE
OSStatus HKTISKeyMapInit(HKKeyMapRef keyMap) { return paramErr; }
HK_INLINE
void HKTISKeyMapDispose(HKKeyMapRef keyMap) {}

HK_INLINE
HKKeyMapRef HKTISKeyMapCreateWithName(CFStringRef name, Boolean reverse) { return NULL; }

HK_INLINE
HKKeyMapRef HKTISKeyMapCreateWithCurrentLayout(Boolean reverse) { return NULL; }


HK_INLINE
Boolean HKTISKeyMapIsCurrent(HKKeyMapRef keyMap) { return true; }

HK_INLINE
CFStringRef HKTISKeyMapGetName(HKKeyMapRef keymap) { return NULL; }

HK_INLINE
CFStringRef HKTISKeyMapGetLocalizedName(HKKeyMapRef keymap) { return NULL; }
#endif
