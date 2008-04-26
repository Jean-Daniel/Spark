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
HKKeyMapRef HKKLKeyMapCreateWithName(CFStringRef name);
HK_PRIVATE
HKKeyMapRef HKKLKeyMapCreateWithCurrentLayout(void);

#else

HK_INLINE
HKKeyMapRef HKKLKeyMapCreateWithName(CFStringRef name) { return NULL; }
HK_INLINE
HKKeyMapRef HKKLKeyMapCreateWithCurrentLayout(void) { return NULL; }

#endif
