/*
 *  UCKeyboardUtils.h
 *  HotKeyToolKit
 *
 *  Created by Fox on Wed Mar 10 2004.
 *  Copyright (c) 2004 Shadow Lab. All rights reserved.
 *
 */
/*!
    @header		HKKeyboardUtils
    @abstract   Abstract layer to access KeyMap on KCHR Keyboard or uchr Keyboard.
*/
#include <CoreServices/CoreServices.h>

/*!
    @function 	HKCurrentKeyMap
    @abstract   Create the KeyMap for the current Keyboard layout.
    @param      keyMap On return, a Unichar array allocated into the default NSZone. You are responsible to free it.
    @param      keyCount On return, the size of a keyMap.
    @param      mapCount On return, the number of keyMap.
 	@param		modifiers On return, contains an <i>mapCount</i> length array of modifiers.
    @result     Return an Error code.
*/
OSStatus HKCurrentKeyMap(UniChar *keyMap[], UInt16 *keyCount, UInt16 *mapCount, UInt16 *modifiers[]);