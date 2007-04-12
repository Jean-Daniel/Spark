/*
 *  HKKeyMap.h
 *  HotKeyToolKit
 *
 *  Created by Shadow Team.
 *  Copyright (c) 2004 - 2007 Shadow Lab. All rights reserved.
 */
/*!
	@header HKKeyMap
	@abstract A set of converter to map between Keyboard Hardware keycode and represented character.
*/

#import <HotKeyToolKit/HKBase.h>

#pragma mark Constants definition
HK_EXPORT
const UniChar kHKNilUnichar;

/*!
    @enum 		Virtual Keycodes
    @abstract   Virtual KeyCode for Special keys.
    @constant	kVirtualCapsLockKey		CapsLock keycode.
    @constant	kVirtualShiftKey		Shift keycode.
    @constant	kVirtualControlKey      Control keycode.
    @constant	kVirtualOptionKey		Option keycode.
    @constant	kVirtualCommandKey 		Command keycode.
    @constant	kVirtualF1Key			F1 keycode.
    @constant	kVirtualF2Key			F2 keycode.
    @constant	kVirtualF3Key			F3 keycode.
    @constant	kVirtualF4Key			F4 keycode.
    @constant	kVirtualF5Key			F5 keycode.
    @constant	kVirtualF6Key			F6 keycode.
    @constant	kVirtualF7Key			F7 keycode.
    @constant	kVirtualF8Key			F8 keycode.
    @constant	kVirtualF9Key			F9 keycode.
    @constant	kVirtualF10Key			F10 keycode.
    @constant	kVirtualF11Key			F11 keycode.
    @constant	kVirtualF12Key			F12 keycode.
    @constant	kVirtualF13Key			F13 keycode.
    @constant	kVirtualF14Key			F14 keycode.
    @constant	kVirtualF15Key			F15 keycode.
    @constant	kVirtualF16Key			F16 keycode.
    @constant	kVirtualHelpKey			Help keycode.
    @constant	kVirtualDeleteKey		Delete keycode.
    @constant	kVirtualTabKey			Tabulation keycode.
    @constant	kVirtualEnterKey		Enter keycode.
    @constant	kVirtualReturnKey		Return keycode.
    @constant	kVirtualEscapeKey		Escape keycode.
    @constant	kVirtualForwardDeleteKey	Forward Delete keycode.
    @constant	kVirtualHomeKey			Home keycode.
    @constant	kVirtualEndKey			End keycode.
    @constant	kVirtualPageUpKey		Page Up keycode.
    @constant	kVirtualPageDownKey		Page Down keycode.
    @constant	kVirtualLeftArrowKey	Left Arrow keycode.
    @constant	kVirtualRightArrowKey	Right Arrow keycode.
    @constant	kVirtualUpArrowKey		Up Arrow keycode.
    @constant	kVirtualDownArrowKey	Down Arrow keycode.
    @constant	kVirtualClearLineKey	Clear Line keycode.
    @constant	kVirtualSpaceKey		Space keycode.
*/
enum {
  /* modifier keys */
  kVirtualCommandKey       = 0x037,
  kVirtualShiftKey         = 0x038,
  kVirtualCapsLockKey      = 0x039,
  kVirtualOptionKey        = 0x03A,
  kVirtualControlKey       = 0x03B,
  /* functions keys */
  kVirtualF1Key            = 0x07A,
  kVirtualF2Key            = 0x078,
  kVirtualF3Key            = 0x063,
  kVirtualF4Key            = 0x076,
  /* functions keys */
  kVirtualF5Key            = 0x060,
  kVirtualF6Key            = 0x061,
  kVirtualF7Key            = 0x062,
  kVirtualF8Key            = 0x064,
  /* functions keys */
  kVirtualF9Key            = 0x065,
  kVirtualF10Key           = 0x06D,
  kVirtualF11Key           = 0x067,
  kVirtualF12Key           = 0x06F,
  /* functions keys */
  kVirtualF13Key           = 0x069,
  kVirtualF14Key           = 0x06b,
  kVirtualF15Key           = 0x071,
  kVirtualF16Key           = 0x06a,
  /* editing utility keys */
  kVirtualHelpKey          = 0x072,
  kVirtualDeleteKey        = 0x033,
  kVirtualTabKey           = 0x030,
  kVirtualEnterKey         = 0x04C,
  kVirtualReturnKey        = 0x024,
  kVirtualEscapeKey        = 0x035,
  kVirtualForwardDeleteKey = 0x075,
  /* navigation keys */
  kVirtualHomeKey          = 0x073,
  kVirtualEndKey           = 0x077,
  kVirtualPageUpKey        = 0x074,
  kVirtualPageDownKey      = 0x079,
  kVirtualLeftArrowKey     = 0x07B,
  kVirtualRightArrowKey    = 0x07C,
  kVirtualUpArrowKey       = 0x07E,
  kVirtualDownArrowKey     = 0x07D,
  /* others keys */
  kVirtualClearLineKey     = 0x047,
  kVirtualSpaceKey         = 0x031,
  
  /* Invalid */
  kHKInvalidVirtualKeyCode = 0xffff,
};

/*!
    @enum 			Special characters used into event representation.
    @abstract		Unichars used to represent key whitout character.
    @constant		kF1Unicode 			Arbitrary Private Unicode character.
    @constant		kF2Unicode 			Arbitrary Private Unicode character.
    @constant		kF3Unicode 			Arbitrary Private Unicode character.
    @constant		kF4Unicode 			Arbitrary Private Unicode character.
    @constant		kF5Unicode 			Arbitrary Private Unicode character.
    @constant		kF6Unicode	 		Arbitrary Private Unicode character.
    @constant		kF7Unicode 			Arbitrary Private Unicode character.
    @constant		kF8Unicode 			Arbitrary Private Unicode character.
    @constant		kF9Unicode 			Arbitrary Private Unicode character.
    @constant		kF10Unicode 		Arbitrary Private Unicode character.
    @constant		kF11Unicode 		Arbitrary Private Unicode character.
    @constant		kF12Unicode 		Arbitrary Private Unicode character.
    @constant		kF13Unicode 		Arbitrary Private Unicode character.
    @constant		kF14Unicode 		Arbitrary Private Unicode character.
    @constant		kF15Unicode 		Arbitrary Private Unicode character.
    @constant		kF16Unicode 		Arbitrary Private Unicode character.
    @constant		kHelpUnicode 		Arbitrary Private Unicode character.
    @constant		kDeleteUnicode 		Delete Unicode character.
    @constant		kTabUnicode 		Tabulation Unicode character.
    @constant		kEnterUnicode 		Enter Unicode character.
    @constant		kReturnUnicode 		Return Unicode character.
    @constant		kEscapeUnicode 		Escape Unicode character.
    @constant		kForwardDeleteUnicode Forward Delete Unicode character.
    @constant		kHomeUnicode 		Home Unicode character.
    @constant		kEndUnicode 		End Unicode character
    @constant		kPageUpUnicode 		Page Up Unicode character.
    @constant		kPageDownUnicode    Page Down Unicode character.
    @constant		kLeftArrowUnicode 	Left Arrow Unicode character.
    @constant		kUpArrowUnicode 	Up Arrow Unicode character.
    @constant		kRightArrowUnicode 	Right Arrow Unicode character.
    @constant		kDownArrowUnicode 	Down Arrow Unicode character.
    @constant		kClearLineUnicode 	Clear Line Unicode character.
    @constant		kSpaceUnicode 		Arbitrary Private Unicode character.
*/
enum {
  /* functions keys */
  kF1Unicode            = NSF1FunctionKey,
  kF2Unicode            = NSF2FunctionKey,
  kF3Unicode            = NSF3FunctionKey,
  kF4Unicode            = NSF4FunctionKey,
  /* functions Unicodes */
  kF5Unicode            = NSF5FunctionKey,
  kF6Unicode            = NSF6FunctionKey,
  kF7Unicode            = NSF7FunctionKey,
  kF8Unicode            = NSF8FunctionKey,
  /* functions Unicodes */
  kF9Unicode            = NSF9FunctionKey,
  kF10Unicode           = NSF10FunctionKey,
  kF11Unicode           = NSF11FunctionKey,
  kF12Unicode           = NSF12FunctionKey,
  /* functions Unicodes */
  kF13Unicode           = NSF13FunctionKey,
  kF14Unicode           = NSF14FunctionKey,
  kF15Unicode           = NSF15FunctionKey,
  kF16Unicode           = NSF16FunctionKey,
  /* editing utility keys */
  kHelpUnicode          = NSHelpFunctionKey,
  kClearLineUnicode     = NSClearLineFunctionKey,
  kForwardDeleteUnicode = NSDeleteFunctionKey,
  /* navigation keys */
  kHomeUnicode          = NSHomeFunctionKey,
  kEndUnicode           = NSEndFunctionKey,
  kPageUpUnicode        = NSPageUpFunctionKey,
  kPageDownUnicode      = NSPageDownFunctionKey,
  kUpArrowUnicode       = NSUpArrowFunctionKey,
  kDownArrowUnicode     = NSDownArrowFunctionKey,
  kLeftArrowUnicode     = NSLeftArrowFunctionKey,
  kRightArrowUnicode    = NSRightArrowFunctionKey,
  /* others Unicodes */
  kEnterUnicode         = 0x0003, /* 3 */
  kTabUnicode           = 0x0009, /* 9 */
  kReturnUnicode        = 0x000d, /* 13 */
  kEscapeUnicode        = 0x001b, /* 27 */
  kDeleteUnicode        = 0x007f, /* 127 */
  kSpaceUnicode         = 0x00a0  /* 160 */
};

#pragma mark -
#pragma mark Public Functions Declaration

/*!
@function 
 @abstract   Advanced reverse mapping function.
 @param      character
 @param      modifier On return, first keystroke modifier. Pass <code>NULL</code> if you do not want it.
 @param      count On return, count of keystokes needed to generate this character. Pass <code>NULL</code> if you do not want it.
 @result     Returns virtual keycode of the first keystroke needed to generate <code>character</code>.
 */
HK_EXPORT
HKKeycode HKMapGetKeycodeAndModifierForUnichar(UniChar character, HKModifier *modifier, NSUInteger *count);

/*!
@function 
 @abstract   Advanced reverse mapping function.
 @param      character
 @param      keys On return, an array of virtual keycode.
 @param      modifiers  On return, an array of modifiers.
 @param      maxcount Size of keys and modifiers array.
 @result     Returns Count of keystroke needed to generate character. Can be more than maxcount.
 */
HK_EXPORT 
NSUInteger HKMapGetKeycodesAndModifiersForUnichar(UniChar character, HKKeycode *keys, HKModifier *modifiers, NSUInteger maxcount);

/*!
	@function
	@abstract   Mapping function.
	@discussion If the unichar is not a simple printable char, return one of the Unicode Constant.
	@param      keycode A virtual keycode.
	@result     an Unichar corresponding to keycode passed.
 */
HK_EXPORT
UniChar HKMapGetUnicharForKeycode(HKKeycode keycode);

/*!
    @function
    @abstract   Returns the name of the current keyMap.
*/
HK_EXPORT
NSString* HKMapGetCurrentMapName(void);

/*!
    @function
    @abstract   Returns a String representation of the Shortcut, or nil if character is 0.
    @param      character 
    @param      modifier If <i>modifier</i> is nil, return a representation of the key Unichar.
*/
HK_EXPORT 
NSString* HKMapGetStringRepresentationForCharacterAndModifier(UniChar character, HKModifier modifier);

HK_EXPORT 
NSString* HKMapGetSpeakableStringRepresentationForCharacterAndModifier(UniChar character, HKModifier modifier);

typedef enum {
  kHKModifierFormatNative, /* kCGEventFlagsMask */
  kHKModifierFormatCarbon, /* Carbon Event modifiers */
  kHKModifierFormatCocoa, /* NSEvent modifiers */
} HKModifierFormat;

/*!
	@function
	@abstract   Convert modifiers from one domain to another domain. All HKKeyMap function use native domain modifiers.
	@param      mask A Cocoa modifier mask.
	@result     Return a carbon modifier.
 */
HK_EXPORT
NSUInteger HKUtilsConvertModifier(NSUInteger modifier, HKModifierFormat input, HKModifierFormat output);
