//
//  SKHotKeyRegister.h
//  Spark
//
//  Created by Fox on Sun Dec 14 2003.
//  Copyright (c) 2004 Shadow Lab. All rights reserved.
//
/*!
    @header HKHotKeyRegister
*/

/*!
    @function   HKRegisterHotKey
    @abstract   Register a Global EventHotKey.
    @param      keycode The HotKey keycode
    @param      modifier The HotKey modifier.
    @param      hotKeyId An uniq HotKeyID passed as parameter in callback function.
    @result     Returns a EventHotKeyRef that you must keep to unregister the HotKey.
*/
EventHotKeyRef HKRegisterHotKey(UInt16 keycode, UInt32 modifier, EventHotKeyID hotKeyId);
/*!
    @function   UnregisterHotKey
    @abstract   Unregister an Global EventHotKey.
    @param      ref The event HotKey Reference obtains during registration.
    @result     Return YES if the key is succesfully unregistred.
*/
BOOL HKUnregisterHotKey(EventHotKeyRef ref);
