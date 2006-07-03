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
@typedef HKKeyMapRef
 @abstract An HKKeyMap reference. Represent a Keymap.
 */
typedef struct __HKKeyMap* HKKeyMapRef;

#pragma mark -
#pragma mark Creation/Destruction functions.
/*!
@function
	@abstract HKKeyMapCreate create and initializes the unichar to key code look up table using the currently active KCHR or uchr resource.
 To release memory allocated in currentKeyMap, use the <code>HKKeyMapRelease</code> function.
	@result Returns the keymap corresponding to the current keyboard.
 */
HKKeyMapRef HKKeyMapCreate(void *layout, Boolean reverse);

/*!	
@function
@abstract Release memory allocated by <i>HKKeyMapCreate</i>.
@param keymap The keyMap to release.
*/
void HKKeyMapRelease(HKKeyMapRef keymap);

#pragma mark -
#pragma mark Public Functions Declaration.
/*!
@function
	@abstract HKKeyMapValidate verifies that the unichar to key code
 lookup table is synchronized with the current KCHR or uchr resource.  If
 it is not synchronized, then the table is re-built.
 @param currentKeyMap the keymap you want to check.
 @param wasChanged En retour, true si la table a été modifiée.
 @result Returns noErr if no error.
 */
OSStatus HKKeyMapCheckCurrentMap(HKKeyMapRef currentKeyMap, Boolean *wasChanged);

/*!
@function
 @abstract Returns the name of <i>keymap</i>.
 @param keymap
 */
CFStringRef HKKeyMapGetName(HKKeyMapRef keymap);
/*!
@function
 @abstract Returns the localized name of <i>keymap</i>.
 @param keymap
 */
CFStringRef HKKeyMapGetLocalizedName(HKKeyMapRef keymap);

/*!
@function
	@abstract HKKeyMapUnicharToKeycodes looks up the unichar character in the key
 code look up table and returns the virtual key code for that
 letter.  If there is no virtual key code for that letter, then
 the value kHKInvalidVirtualKeyCode will be returned.
 @param currentKeyMap
 @param charCode The unichar you want to convert.
 @result Return the virtual keycode associated with this unichar character or kHKInvalidVirtualKeyCode.
 */
UInt32 HKKeyMapGetKeycodesForUnichar(HKKeyMapRef keyMap, UniChar character, UInt32 *keys, UInt32 *modifiers, UInt32 maxsize);

/*!
@function
 @abstract HKKeyMapKeycodeToUniChar convert the keycode into unichar character using the
 current keyboard keymap.
 @param virtualKeyCode The virtual keycode you want to convert.
 @result Returns kHKNilUnichar if no character was found.
 */
UniChar HKKeyMapGetUnicharForKeycode(HKKeyMapRef currentKeyMap, UInt32 virtualKeyCode);

/*!
@function
 @abstract Resolve a keycode/modifiers combinaison.
 @param virtualKeyCode The virtual keycode you want to convert.
 @result Returns kHKNilUnichar if no character was found.
 */
UniChar HKKeyMapGetUnicharForKeycodeAndModifier(HKKeyMapRef currentKeyMap, UInt32 virtualKeyCode, UInt32 modifiers);

