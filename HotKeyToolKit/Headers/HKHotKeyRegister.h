/*
 *  HKHotKeyRegister.h
 *  HotKeyToolKit
 *
 *  Created by Shadow Team.
 *  Copyright (c) 2004 - 2007 Shadow Lab. All rights reserved.
 */
/*!
    @header HKHotKeyRegister
*/
#import <HotKeyToolKit/HKBase.h>

#include <Carbon/Carbon.h>
#if __LP64__
extern EventTargetRef GetApplicationEventTarget(void);
#endif

/*!
    @function   HKRegisterHotKey
    @abstract   Register a Global EventHotKey.
    @param      keycode The HotKey keycode
    @param      modifier The HotKey modifier.
    @param      hotKeyId An uniq HotKeyID passed as parameter in callback function.
    @result     Returns a EventHotKeyRef that you must keep to unregister the HotKey.
*/
HK_PRIVATE
EventHotKeyRef HKRegisterHotKey(HKKeycode keycode, HKModifier modifier, EventHotKeyID hotKeyId);
/*!
    @function   UnregisterHotKey
    @abstract   Unregister an Global EventHotKey.
    @param      ref The event HotKey Reference obtains during registration.
    @result     Return YES if the key is succesfully unregistred.
*/
HK_PRIVATE
BOOL HKUnregisterHotKey(EventHotKeyRef ref);
