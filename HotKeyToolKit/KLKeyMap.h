/*
 *  KLKeyMap.h
 *  HotKeyToolKit
 *
 *  Created by Shadow Team.
 *  Copyright (c) 2004 - 2007 Shadow Lab. All rights reserved.
 */

#include <Carbon/Carbon.h>

#if MAC_OS_X_VERSION_MIN_REQUIRED < MAC_OS_X_VERSION_10_5

SK_PRIVATE
OSStatus HKKLKeyMapInit(HKKeyMapRef keyMap);
SK_PRIVATE
void HKKLKeyMapDispose(HKKeyMapRef keyMap);

SK_PRIVATE
HKKeyMapRef HKKLKeyMapCreateWithName(CFStringRef name, Boolean reverse);

SK_PRIVATE
HKKeyMapRef HKKLKeyMapCreateWithCurrentLayout(Boolean reverse);


SK_PRIVATE
Boolean HKKLKeyMapIsCurrent(HKKeyMapRef keyMap);

SK_PRIVATE
CFStringRef HKKLKeyMapGetName(HKKeyMapRef keymap);

SK_PRIVATE
CFStringRef HKKLKeyMapGetLocalizedName(HKKeyMapRef keymap);

#else
SK_INLINE
OSStatus HKKLKeyMapInit(HKKeyMapRef keyMap) { return paramErr; }
SK_INLINE
void HKKLKeyMapDispose(HKKeyMapRef keyMap) {}

SK_INLINE
HKKeyMapRef HKKLKeyMapCreateWithName(CFStringRef name, Boolean reverse) { return NULL; }
SK_INLINE
HKKeyMapRef HKKLKeyMapCreateWithCurrentLayout(Boolean reverse) { return NULL; }

SK_INLINE
Boolean HKKLKeyMapIsCurrent(HKKeyMapRef keyMap) { return true; }
SK_INLINE
CFStringRef HKKLKeyMapGetName(HKKeyMapRef keymap) { return NULL; }
SK_INLINE
CFStringRef HKKLKeyMapGetLocalizedName(HKKeyMapRef keymap) { return NULL; }

#endif
