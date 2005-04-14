//
//  KeyCodeFunctions.h
//  Short-Cut
//
//  Created by Fox on Tue Dec 09 2003.
//  Copyright (c) 2004 Shadow Lab. All rights reserved.
//
/*!
    @header KeyMap
*/

#pragma mark Type definition.
/*!
    @typedef 	HKKeyMapRef
    @abstract   An HKKeyMap reference. Represent a Keymap.
*/
typedef struct __HKKeyMap* HKKeyMapRef;

#pragma mark -
#pragma mark Creation/Destruction functions.
/*!
	@function 	HKKeyMapCreate
	@abstract   HKKeyMapCreate create and initializes the unichar to key code look up table using the currently active KCHR or uchr resource.
				To release memory allocated in currentKeyMap, use the <code>HKKeyMapRelease</code> function.
	@result     Returns the keymap corresponding to the current keyboard.
 */
HKKeyMapRef HKKeyMapCreate();

/*!	
	@function 	HKKeyMapRelease
	@abstract   Release memory allocated by <i>HKKeyMapCreate</i>.
	@param      keymap The keyMap to release.
 */
void HKKeyMapRelease(HKKeyMapRef keymap);

#pragma mark -
#pragma mark Public Functions Declaration.
/*!
    @function 	HKKeyMapValidate
	@abstract   HKKeyMapValidate verifies that the unichar to key code
				lookup table is synchronized with the current KCHR or uchr resource.  If
                it is not synchronized, then the table is re-built.
    @param      currentKeyMap the keymap you want to check.
 	@param		wasChanged En retour, true si la table a été modifiée.
    @result     Returns noErr if no error.
*/
OSStatus HKKeyMapValidate(HKKeyMapRef currentKeyMap,Boolean *wasChanged);

/*!
    @function 	HKKeyMapGetName
    @abstract   Return the name of <i>keymap</i>.
    @param      keymap
*/
CFStringRef HKKeyMapGetName(HKKeyMapRef keymap);

/*!
    @function 	HKKeyMapUnicharToKeycodes
	@abstract   HKKeyMapUnicharToKeycodes looks up the unichar character in the key
				code look up table and returns the virtual key code for that
				letter.  If there is no virtual key code for that letter, then
				the value kHKNilVirtualKeyCode will be returned.
    @param      currentKeyMap
 	@param		charCode The unichar you want to convert.
    @result     Return the virtual keycode associated with this unichar character or kHKNilVirtualKeyCode.
*/
UInt32 HKKeyMapUnicharToKeycodes(HKKeyMapRef currentKeyMap, UniChar charCode);

/*!
    @function 	HKKeyMapKeycodeToUniChar
    @abstract   HKKeyMapKeycodeToUniChar convert the keycode into unichar character using the
 				current keyboard keymap.
    @param      virtualKeyCode The virtual keycode you want to convert.
    @result     Returns kHKNilUnichar if no character was found.
*/
UniChar HKKeyMapKeycodeToUniChar(HKKeyMapRef currentKeyMap, UInt16 virtualKeyCode);
