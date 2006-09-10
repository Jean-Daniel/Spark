/*
 *  HKHotKey.h
 *  HotKeyToolKit
 *
 *  Created by Grayfox.
 *  Copyright 2004-2006 Shadow Lab. All rights reserved.
 */
/*!
@header HKHotKey
 */
#import <Foundation/Foundation.h>
#import <HotKeyToolKit/HKBase.h>

/*!
@function
 @abstract Returns the time interval between two repeat key down event.
 @result Returns the key repeat interval setted in "System Preferences".
 */
HK_EXPORT
NSTimeInterval HKGetSystemKeyRepeatInterval(void);

/*!
@function
 @abstract Returns the time interval between a key is pressed and system start to repeat key down event.
 @result Returns the initial key repeat interval setted in "System Preferences".
 */
HK_EXPORT 
NSTimeInterval HKGetSystemKeyRepeatThreshold(void);

/*!
@class HKHotKey
@abstract	This class represent a Global Hot Key (Shortcut) that can be registred to execute an action when called.
@discussion	It uses an UniChar and a virtual keycode to store the shortcut so if the keyboard layout change, the shortcut change too.
*/
@interface HKHotKey : NSObject <NSCopying, NSCoding> { 
  @private
  id hk_target;
  SEL hk_action;
  NSTimer *hk_repeatTimer;
  NSTimeInterval hk_repeatInterval;
  
  struct _hk_hkFlags {
    unsigned int lock:1;
    unsigned int invoked:1;
    unsigned int onrelease:1;
    unsigned int registred:1;
    unsigned int reserved:12;
  } hk_hkFlags;
  
  UInt32 hk_mask;
  UInt16 hk_keycode;
  UniChar hk_character;
}

#pragma mark -
#pragma mark Convenient constructors.
/*!
  @method
 @abstract Creates and returns an new Hot Key.
 @result A new HotKey.
 */
+ (id)hotkey;
/*!
  @method
 @abstract Creates and returns an new Hot Key with keycode set to <i>code</i> and modifier set to <i>modifier</i>.
 @param code A virtual keycode.
 @param modifier
 @result Returns a new HotKey with keystrock set to <i>keycode</i> and <i>modifier</i>.
 */
+ (id)hotkeyWithKeycode:(UInt32)code modifier:(UInt32)modifier;
/*!
  @method
 @abstract Creates and returns an new Hot Key with character set to <i>character</i> and modifier set to <i>modifier</i>.
 @param character An UniChar.
 @param modifier 
 @result Returns a new HotKey with keystrock set to <i>character</i> and <i>modifier</i>.
 */
+ (id)hotkeyWithUnichar:(UniChar)character modifier:(UInt32)modifier;

#pragma mark -
#pragma mark Initializers
/*!
  @method
 @abstract   Designated Initializer
 @result     A new HotKey.
 */
- (id)init;

/*!
  @method
 @abstract   Initializes a newly allocated hotkey.
 @param      code The virtual Keycode of the receiver.
 @param      modifier The modifier mask for the receiver.
 @result     Returns a HotKey with keystrock set to <i>keycode</i> and <i>modifier</i>.
 */
- (id)initWithKeycode:(UInt32)code modifier:(UInt32)modifier;
/*!
  @method
 @abstract   Initializes a newly allocated hotkey.
 @param      character (description)
 @param      modifier (description)
 @result     Returns a HotKey with keystrock set to <i>character</i> and <i>modifier</i>.
 */
- (id)initWithUnichar:(UniChar)character modifier:(UInt32)modifier;

#pragma mark -
#pragma mark Misc Properties
/*!
  @method
 @abstract   	Methode use to define if a key can be registred.
 @discussion 	A key is valid if charater is not nil.
 @result		Returns YES if it has a keycode and a character.
 */
- (BOOL)isValid;

/*!
  @method
 @abstract Returns an NSString representation of the shortcut using symbolic characters when possible.
 */
- (NSString*)shortcut;

#pragma mark -
#pragma mark iVar Accessors.
/*!
  @method
 @abstract   The modifier is an unsigned int as define in NSEvent.h
 @discussion This modifier is equivalent to KeyMask defined in NSEvent.h
 @result		Returns the modifier associated whit this Hot Key.
 */
- (UInt32)modifier;
/*!
  @method
 @abstract   Sets the HotKey modifier to <i>modifier</i>
 @param		modifier
 */
- (void)setModifier:(UInt32)modifier;

/*!
  @method
 @abstract   Returns the Virtual keycode assigned to this Hot Key for the current keyboard layout.
 */
- (UInt32)keycode;
/*!
  @method
 @abstract   Sets the HotKey keycode to the virtual key <i>keycode</i> and update character.
 @param		keycode A Virtual Keycode.
 */
- (void)setKeycode:(UInt32)keycode;

/*!
  @method
 @abstract   Character is an UniChar that represent the character associated whit this HotKey
 @discussion Character is an Unichar, but is not always printable. Some keyboard keys haven't a glyph
 representation. To obtain a printable representation use HKModifierStringForMask() with a nil modifier 
 */
- (UniChar)character;
/*!
  @method
 @abstract Sets the Hot Key character to <i>aCharacter</i> and update keycode.
 @discussion If your character could not be generatd by a single key event without modifier, 
 this method will try to find first keycode used to output character, and replace character by a output of this keycode. 
 @param aCharacter An Unicode character.
 */
- (void)setCharacter:(UniChar)aCharacter;

/*!
  @method
 @abstract   Returns the target object of the receiver.
 */
- (id)target;
/*!
  @method
 @abstract   Sets the receiver's target object to <i>anObject</i>.
 @param		anObject The receiver's target object
 */
- (void)setTarget:(id)anObject;

/*!
  @method
 @abstract   Returns the receiver’s action message selector.
 */
- (SEL)action;
/*!
  @method
 @abstract   Sets the selector used for the action message to aSelector.
 @param		aSelector the receiver action.
 */
- (void)setAction:(SEL)aSelector;

- (BOOL)invokeOnKeyUp;
- (void)setInvokeOnKeyUp:(BOOL)flag;

/*!
  @method
 @abstract   Returns the status of the Hot Key.
 @result		Returns YES if the receiver is currently register as a System Hot Key and respond to System Hot Key Events.
 */
- (BOOL)isRegistred;
/*!
  @method
 @abstract   Sets the stats of the receiver. If flag is YES, the receiver try to register himself as a Global Hot Key.
 @discussion This method call <i>isValid</i> before trying to register and return NO if receiver isn't valid.
 @param		flag
 @result		Returns YES if the stats is already flag or if it succesfully registers or unregisters.
 */
- (BOOL)setRegistred:(BOOL)flag;

/*!
  @method
 @abstract   Returns the time interval between two repeat key down event.
 @result     Returns a time interval in seconds or 0 if autorepeat isn't active for the receiver.
 */
- (NSTimeInterval)repeatInterval;
/*!
  @method
 @abstract   Sets the time interva between two autorepeat key down events.
 @param      interval the time interval in seconds, or 0 to desactivate autorepeat for the receiver.
 */
- (void)setRepeatInterval:(NSTimeInterval)interval;

/*!
  @method
 @abstract   Encode character, keycode and modifier as a single integer.
 @discussion This method can be usefull to serialize an hotkey or to save a keystae with one call.
 @result     A single integer representing receiver character, modifier and keycode.
 */
- (UInt64)rawkey;
/*!
  @method
 @abstract   Restore the receiver  character, keycode and modifier.
 @param      rawkey A rawkey.
 */
- (void)setRawkey:(UInt64)rawkey;

/*!
  @method
 @abstract   Make target perform action.
 */
- (void)invoke:(BOOL)repeat;

#pragma mark Callback Methods
- (void)keyPressed;
- (void)keyReleased;

- (void)willInvoke:(BOOL)repeat;
- (void)didInvoke:(BOOL)repeat;

@end

