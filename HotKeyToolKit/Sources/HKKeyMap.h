/*
 *  HKKeyMap.h
 *  HotKeyToolKit
 *
 *  Created by Jean-Daniel Dupas.
 *  Copyright © 2004 - 2011 Shadow Lab. All rights reserved.
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
 @abstract Virtual KeyCode for Special keys.
 @constant	kHKVirtualCapsLockKey		CapsLock keycode.
 @constant	kHKVirtualShiftKey		Shift keycode.
 @constant	kHKVirtualControlKey      Control keycode.
 @constant	kHKVirtualOptionKey		Option keycode.
 @constant	kHKVirtualCommandKey 		Command keycode.
 @constant	kHKVirtualF1Key			F1 keycode.
 @constant	kHKVirtualF2Key			F2 keycode.
 @constant	kHKVirtualF3Key			F3 keycode.
 @constant	kHKVirtualF4Key			F4 keycode.
 @constant	kHKVirtualF5Key			F5 keycode.
 @constant	kHKVirtualF6Key			F6 keycode.
 @constant	kHKVirtualF7Key			F7 keycode.
 @constant	kHKVirtualF8Key			F8 keycode.
 @constant	kHKVirtualF9Key			F9 keycode.
 @constant	kHKVirtualF10Key			F10 keycode.
 @constant	kHKVirtualF11Key			F11 keycode.
 @constant	kHKVirtualF12Key			F12 keycode.
 @constant	kHKVirtualF13Key			F13 keycode.
 @constant	kHKVirtualF14Key			F14 keycode.
 @constant	kHKVirtualF15Key			F15 keycode.
 @constant	kHKVirtualF16Key			F16 keycode.
 @constant	kHKVirtualHelpKey			Help keycode.
 @constant	kHKVirtualDeleteKey		Delete keycode.
 @constant	kHKVirtualTabKey			Tabulation keycode.
 @constant	kHKVirtualEnterKey		Enter keycode.
 @constant	kHKVirtualReturnKey		Return keycode.
 @constant	kHKVirtualEscapeKey		Escape keycode.
 @constant	kHKVirtualForwardDeleteKey	Forward Delete keycode.
 @constant	kHKVirtualHomeKey			Home keycode.
 @constant	kHKVirtualEndKey			End keycode.
 @constant	kHKVirtualPageUpKey		Page Up keycode.
 @constant	kHKVirtualPageDownKey		Page Down keycode.
 @constant	kHKVirtualLeftArrowKey	Left Arrow keycode.
 @constant	kHKVirtualRightArrowKey	Right Arrow keycode.
 @constant	kHKVirtualUpArrowKey		Up Arrow keycode.
 @constant	kHKVirtualDownArrowKey	Down Arrow keycode.
 @constant	kHKVirtualClearLineKey	Clear Line keycode.
 @constant	kHKVirtualSpaceKey		Space keycode.
 */
enum {
  /* modifier keys */
  kHKVirtualCommandKey       = 0x037,
  kHKVirtualShiftKey         = 0x038,
  kHKVirtualCapsLockKey      = 0x039,
  kHKVirtualOptionKey        = 0x03A,
  kHKVirtualControlKey       = 0x03B,
  /* functions keys */
  kHKVirtualF1Key            = 0x07A,
  kHKVirtualF2Key            = 0x078,
  kHKVirtualF3Key            = 0x063,
  kHKVirtualF4Key            = 0x076,
  /* functions keys */
  kHKVirtualF5Key            = 0x060,
  kHKVirtualF6Key            = 0x061,
  kHKVirtualF7Key            = 0x062,
  kHKVirtualF8Key            = 0x064,
  /* functions keys */
  kHKVirtualF9Key            = 0x065,
  kHKVirtualF10Key           = 0x06D,
  kHKVirtualF11Key           = 0x067,
  kHKVirtualF12Key           = 0x06F,
  /* functions keys */
  kHKVirtualF13Key           = 0x069,
  kHKVirtualF14Key           = 0x06b,
  kHKVirtualF15Key           = 0x071,
  kHKVirtualF16Key           = 0x06a,
  /* aluminium keyboards */
  kHKVirtualF17Key           = 0x040,
  kHKVirtualF18Key           = 0x04f,
  kHKVirtualF19Key           = 0x050,
  /* editing utility keys */
  kHKVirtualHelpKey          = 0x072,
  kHKVirtualDeleteKey        = 0x033,
  kHKVirtualTabKey           = 0x030,
  kHKVirtualEnterKey         = 0x04C,
  kHKVirtualReturnKey        = 0x024,
  kHKVirtualEscapeKey        = 0x035,
  kHKVirtualForwardDeleteKey = 0x075,
  /* navigation keys */
  kHKVirtualHomeKey          = 0x073,
  kHKVirtualEndKey           = 0x077,
  kHKVirtualPageUpKey        = 0x074,
  kHKVirtualPageDownKey      = 0x079,
  kHKVirtualLeftArrowKey     = 0x07B,
  kHKVirtualRightArrowKey    = 0x07C,
  kHKVirtualUpArrowKey       = 0x07E,
  kHKVirtualDownArrowKey     = 0x07D,
  /* others keys */
  kHKVirtualClearLineKey     = 0x047,
  kHKVirtualSpaceKey         = 0x031,

  /* Invalid */
  kHKInvalidVirtualKeyCode = 0xffff,
};

/*!
 @enum Special characters used into event representation.
 @abstract Unichars used to represent key whitout character.
 @constant		kHKF1Unicode 			Arbitrary Private Unicode character.
 @constant		kHKF2Unicode 			Arbitrary Private Unicode character.
 @constant		kHKF3Unicode 			Arbitrary Private Unicode character.
 @constant		kHKF4Unicode 			Arbitrary Private Unicode character.
 @constant		kHKF5Unicode 			Arbitrary Private Unicode character.
 @constant		kHKF6Unicode	 		Arbitrary Private Unicode character.
 @constant		kHKF7Unicode 			Arbitrary Private Unicode character.
 @constant		kHKF8Unicode 			Arbitrary Private Unicode character.
 @constant		kHKF9Unicode 			Arbitrary Private Unicode character.
 @constant		kHKF10Unicode 		Arbitrary Private Unicode character.
 @constant		kHKF11Unicode 		Arbitrary Private Unicode character.
 @constant		kHKF12Unicode 		Arbitrary Private Unicode character.
 @constant		kHKF13Unicode 		Arbitrary Private Unicode character.
 @constant		kHKF14Unicode 		Arbitrary Private Unicode character.
 @constant		kHKF15Unicode 		Arbitrary Private Unicode character.
 @constant		kHKF16Unicode 		Arbitrary Private Unicode character.
 @constant		kHKF17Unicode 		Arbitrary Private Unicode character.
 @constant		kHKF18Unicode 		Arbitrary Private Unicode character.
 @constant		kHKF19Unicode 		Arbitrary Private Unicode character.

 @constant		kHKHelpUnicode 		      Arbitrary Private Unicode character.
 @constant		kHKClearLineUnicode     Clear Line Unicode character.
 @constant		kHKForwardDeleteUnicode Forward Delete Unicode character.

 @constant		kHKHomeUnicode          Home Unicode character.
 @constant		kHKEndUnicode           End Unicode character
 @constant		kHKPageUpUnicode        Page Up Unicode character.
 @constant		kHKPageDownUnicode      Page Down Unicode character.
 @constant		kHKUpArrowUnicode       Up Arrow Unicode character.
 @constant		kHKDownArrowUnicode     Down Arrow Unicode character.
 @constant		kHKLeftArrowUnicode     Left Arrow Unicode character.
 @constant		kHKRightArrowUnicode    Right Arrow Unicode character.

 @constant		kHKEnterUnicode   Enter Unicode character.
 @constant		kHKTabUnicode     Tabulation Unicode character.
 @constant		kHKReturnUnicode  Return Unicode character.
 @constant		kHKEscapeUnicode  Escape Unicode character.
 @constant		kHKDeleteUnicode  Delete Unicode character.
 @constant		kHKNoBreakSpaceUnicode  Arbitrary Private Unicode character.
 */
enum {
  /* functions keys */
  kHKF1Unicode            = NSF1FunctionKey,
  kHKF2Unicode            = NSF2FunctionKey,
  kHKF3Unicode            = NSF3FunctionKey,
  kHKF4Unicode            = NSF4FunctionKey,
  /* functions Unicodes */
  kHKF5Unicode            = NSF5FunctionKey,
  kHKF6Unicode            = NSF6FunctionKey,
  kHKF7Unicode            = NSF7FunctionKey,
  kHKF8Unicode            = NSF8FunctionKey,
  /* functions Unicodes */
  kHKF9Unicode            = NSF9FunctionKey,
  kHKF10Unicode           = NSF10FunctionKey,
  kHKF11Unicode           = NSF11FunctionKey,
  kHKF12Unicode           = NSF12FunctionKey,
  /* functions Unicodes */
  kHKF13Unicode           = NSF13FunctionKey,
  kHKF14Unicode           = NSF14FunctionKey,
  kHKF15Unicode           = NSF15FunctionKey,
  kHKF16Unicode           = NSF16FunctionKey,
  /* aluminium keyboard */
  kHKF17Unicode           = NSF17FunctionKey,
  kHKF18Unicode           = NSF18FunctionKey,
  kHKF19Unicode           = NSF19FunctionKey,
  /* editing utility keys */
  kHKHelpUnicode          = NSHelpFunctionKey,
  kHKClearLineUnicode     = NSClearLineFunctionKey,
  kHKForwardDeleteUnicode = NSDeleteFunctionKey,
  /* navigation keys */
  kHKHomeUnicode          = NSHomeFunctionKey,
  kHKEndUnicode           = NSEndFunctionKey,
  kHKPageUpUnicode        = NSPageUpFunctionKey,
  kHKPageDownUnicode      = NSPageDownFunctionKey,
  kHKUpArrowUnicode       = NSUpArrowFunctionKey,
  kHKDownArrowUnicode     = NSDownArrowFunctionKey,
  kHKLeftArrowUnicode     = NSLeftArrowFunctionKey,
  kHKRightArrowUnicode    = NSRightArrowFunctionKey,
  /* others Unicodes */
  kHKEnterUnicode         = 0x0003, /* 3 */
  kHKTabUnicode           = 0x0009, /* 9 */
  kHKReturnUnicode        = 0x000d, /* 13 */
  kHKEscapeUnicode        = 0x001b, /* 27 */
  kHKDeleteUnicode        = 0x007f, /* 127 */
  kHKNoBreakSpaceUnicode  = 0x00a0  /* 160 */
};

#pragma mark -
#pragma mark Public Functions Declaration

/*!
 @function
 @abstract   Advanced reverse mapping function.
 @param      character
 @param      modifier On return, first keystroke modifier. Pass <code>NULL</code> if you do not want it.
 @result     Returns virtual keycode of the keystroke needed to generate <code>character</code>,
 or kHKInvalidVirtualKeyCode if need more than one keystroke to generate the character, except if character is a deadkey output (eg: ^, ¨, …).
 */
HK_EXPORT
HKKeycode HKMapGetKeycodeAndModifierForUnichar(UniChar character, HKModifier *modifier);

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

HK_EXPORT
UniChar HKMapGetUnicharForKeycodeAndModifier(HKKeycode keycode, HKModifier aModifier);

/*!
 @function
 @abstract   Returns the name of the current keyMap.
 */
HK_EXPORT
NSString *HKMapGetCurrentMapName(void);

/*!
 @function
 @abstract   Returns a String representation of the Shortcut, or nil if character is 0.
 @param      character
 @param      modifier If <i>modifier</i> is nil, return a representation of the key Unichar.
 */
HK_EXPORT
NSString *HKMapGetStringRepresentationForCharacterAndModifier(UniChar character, HKModifier modifier);

HK_EXPORT
NSString *HKMapGetSpeakableStringRepresentationForCharacterAndModifier(UniChar character, HKModifier modifier);

HK_EXPORT
bool HKMapIsFunctionKey(HKKeycode code);
HK_EXPORT
bool HKMapIsFunctionKeyForCharacter(UniChar chr);

enum {
  kHKModifierFormatNative, /* kCGEventFlagsMask */
  kHKModifierFormatCarbon, /* Carbon Event modifiers */
  kHKModifierFormatCocoa, /* NSEvent modifiers */
};
typedef NSInteger HKModifierFormat;

/*!
 @function
 @abstract   Convert modifiers from one domain to another domain. All HKKeyMap function use native domain modifiers.
 @param      mask A Cocoa modifier mask.
 @result     Return a carbon modifier.
 */
HK_EXPORT
NSUInteger HKUtilsConvertModifier(NSUInteger modifier, HKModifierFormat input, HKModifierFormat output);
