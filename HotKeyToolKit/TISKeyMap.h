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

typedef struct HKLayoutContext {
  OSStatus (*init)(HKKeyMapRef keyMap);
  void (*dispose)(HKKeyMapRef keyMap);
  Boolean (*isCurrent)(HKKeyMapRef keyMap);
  CFStringRef (*getName)(HKKeyMapRef keymap);
  CFStringRef (*getLocalizedName)(HKKeyMapRef keymap);
} HKLayoutContext;

struct __HKKeyMap {
  Boolean reverse;
  CFStringRef constructor;
  union {
#if MAC_OS_X_VERSION_MIN_REQUIRED < MAC_OS_X_VERSION_10_5
    struct {
      KeyboardLayoutRef keyboard;
      KeyboardLayoutIdentifier identifier;
    } kl;
#endif
    struct {
      TISInputSourceRef keyboard;
      CFStringRef identifier;
    } tis;
  };
  HKKeyMapContext ctxt;
  HKLayoutContext lctxt;
};

HK_INLINE
Boolean HKTISAvailable() {
#if MAC_OS_X_VERSION_MIN_REQUIRED >= MAC_OS_X_VERSION_10_5
  return true;
#else
  return TISInputSourceGetTypeID != NULL;
#endif
}

HK_PRIVATE
HKKeyMapRef HKTISKeyMapCreateWithCurrentLayout(void);

HK_PRIVATE
HKKeyMapRef HKTISKeyMapCreateWithName(CFStringRef name);

