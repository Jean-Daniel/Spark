/*
 *  KLKeyMap.h
 *  HotKeyToolKit
 *
 *  Created by Shadow Team.
 *  Copyright (c) 2004 - 2007 Shadow Lab. All rights reserved.
 */

#include <Carbon/Carbon.h>
#import <HotKeyToolKit/HKBase.h>

#if MAC_OS_X_VERSION_MIN_REQUIRED < MAC_OS_X_VERSION_10_5
HK_PRIVATE
OSStatus HKKLKeyMapInit(HKKeyMapRef keyMap);
HK_PRIVATE
void HKKLKeyMapDispose(HKKeyMapRef keyMap);

HK_PRIVATE
HKKeyMapRef HKKLKeyMapCreateWithName(CFStringRef name, Boolean reverse);
HK_PRIVATE
HKKeyMapRef HKKLKeyMapCreateWithCurrentLayout(Boolean reverse);

HK_PRIVATE
Boolean HKKLKeyMapIsCurrent(HKKeyMapRef keyMap);
HK_PRIVATE
CFStringRef HKKLKeyMapGetName(HKKeyMapRef keymap);
HK_PRIVATE
CFStringRef HKKLKeyMapGetLocalizedName(HKKeyMapRef keymap);

#else
HK_INLINE
OSStatus HKKLKeyMapInit(HKKeyMapRef keyMap) { return paramErr; }
HK_INLINE
void HKKLKeyMapDispose(HKKeyMapRef keyMap) {}

HK_INLINE
HKKeyMapRef HKKLKeyMapCreateWithName(CFStringRef name, Boolean reverse) { return NULL; }
HK_INLINE
HKKeyMapRef HKKLKeyMapCreateWithCurrentLayout(Boolean reverse) { return NULL; }

HK_INLINE
Boolean HKKLKeyMapIsCurrent(HKKeyMapRef keyMap) { return true; }
HK_INLINE
CFStringRef HKKLKeyMapGetName(HKKeyMapRef keymap) { return NULL; }
HK_INLINE
CFStringRef HKKLKeyMapGetLocalizedName(HKKeyMapRef keymap) { return NULL; }

#endif
