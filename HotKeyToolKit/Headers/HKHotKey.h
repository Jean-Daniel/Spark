//
//  HKHotKey.h
//  Spark
//
//  Created by Fox on Mon Jan 05 2004.
//  Copyright (c) 2004 Shadow Lab. All rights reserved.
//
/*!
    @header HKHotKey
*/

#import <Foundation/Foundation.h>

/*!
	@function 	HKGetSystemKeyRepeatInterval
 	@abstract   Returns the time interval between two repeat key down event.
 	@result     Returns the key repeat interval setted in "System Preferences".
*/
extern NSTimeInterval HKGetSystemKeyRepeatInterval();

/*!
    @function 	HKGetSystemInitialKeyRepeatInterval
    @abstract   Returns the time interval between a key is pressed and system start to repeat key down event.
    @result     Returns the initial key repeat interval setted in "System Preferences".
*/
extern NSTimeInterval HKGetSystemInitialKeyRepeatInterval();

/*!
	@class HKHotKey
	@abstract	This class represent a Global Hot Key (Shortcut) that can be registred to execute an action when called.
	@discussion	It uses an unichar and a virtual keycode to store the shortcut so if the keyboard layout change, the shortcut change too.
*/
@interface HKHotKey : NSObject <NSCopying, NSCoding> { 
@private
  id hk_target;
  SEL hk_action;
  BOOL hk_isRegistred;
  NSTimer *hk_repeatTimer;
  NSTimeInterval hk_keyRepeat;
  
  unsigned int hk_mask;
  unichar hk_character;
  unsigned short hk_keycode;
}

#pragma mark -
#pragma mark Convenient constructors.
/*!
	@method hotkey
	@abstract Creates and returns an new Hot Key.
	@result A new HotKey.
*/
+ (id)hotkey;
/*!
	@method hotkeyWithKeycode:modifier:
	@abstract Creates and returns an new Hot Key with keycode set to <i>code</i> and modifier set to <i>modifier</i>.
	@param code A virtual keycode.
	@param modifier
 	@result Returns a new HotKey with keystrock set to <i>keycode</i> and <i>modifier</i>.
*/
+ (id)hotkeyWithKeycode:(int)code modifier:(int)modifier;
/*!
	@method hotkeyWithUnichar:modifier:
	@abstract Creates and returns an new Hot Key with character set to <i>character</i> and modifier set to <i>modifier</i>.
  	@param character An unichar.
  	@param modifier 
 	@result Returns a new HotKey with keystrock set to <i>character</i> and <i>modifier</i>.
*/
+ (id)hotkeyWithUnichar:(unichar)character modifier:(int)modifier;

#pragma mark -
#pragma mark Initializers
/*!
    @method     init
    @abstract   Designated Initializer
    @result     A new HotKey.
*/
- (id)init;

/*!
    @method     initWithKeycode:modifier:
    @abstract   Initializes a newly allocated hotkey.
    @param      code The virtual Keycode of the receiver.
    @param      modifier The modifier mask for the receiver.
    @result     Returns a HotKey with keystrock set to <i>keycode</i> and <i>modifier</i>.
*/
- (id)initWithKeycode:(int)code modifier:(int)modifier;
/*!
    @method     initWithUnichar:modifier:
    @abstract   Initializes a newly allocated hotkey.
    @param      character (description)
    @param      modifier (description)
    @result     Returns a HotKey with keystrock set to <i>character</i> and <i>modifier</i>.
*/
- (id)initWithUnichar:(unichar)character modifier:(int)modifier;

#pragma mark -
#pragma mark Misc Properties
/*!
   @method     	isValid
   @abstract   	Methode use to define if a key can be registred.
   @discussion 	A key is valid if charater is not nil.
   @result		Returns YES if it has a keycode and a character.
*/
- (BOOL)isValid;

/*!
	@method     shortCut
    @abstract   Returns a UTF-8 String representation of the shortcut using symbolic characters when possible.
 */
- (NSString*)shortCut;

#pragma mark -
#pragma mark iVar Accessors.
/*!
    @method     modifier
    @abstract   The modifier is an unsigned int as define in NSEvent.h
    @discussion This modifier is equivalent to KeyMask defined in NSEvent.h
  	@result		Returns the modifier associated whit this Hot Key.
*/
- (unsigned int)modifier;
/*!
    @method     setModifier:
    @abstract   Sets the HotKey modifier to <i>modifier</i>
 	@param		modifier
*/
- (void)setModifier:(unsigned int)modifier;

  /*!
	@method     keycode
	@abstract   Returns the Virtual keycode assigned to this Hot Key for the current keyboard layout.
   */
- (unsigned short)keycode;
  /*!
	@method     setKeycode:
	@abstract   Sets the HotKey keycode to the virtual key <i>keycode</i> and update character.
	@param		keycode A Virtual Keycode.
   */
- (void)setKeycode:(unsigned short)keycode;

/*!
    @method     character
    @abstract   Character is an unichar that represent the character associated whit this HotKey
    @discussion Character is an Unichar, but is not always printable. Some keyboard keys haven't a glyph
 				representation. To obtain a printable representation use HKModifierStringForMask() with a nil modifier 
*/
- (unichar)character;
/*!
    @method     setCharacter:
    @abstract   Sets the Hot Key character to <i>aCharacter</i> and update keycode.
    @discussion As all Unichar have not a Keycode, if you call this methode directly, you must be sure that the Key 
 				exist. You can pass Unicode constants defines in KeyMap.h
 	@param		aCharacter An Unicode character.
*/
- (void)setCharacter:(unichar)aCharacter;

/*!
    @method     setKeycode:andCharacter:
    @abstract   Sets keycode and character for this HotKey.
    @param      aKeycode A Virtual Keycode.
    @param      aCharacter An Unicode character.
*/
- (void)setKeycode:(unsigned short)aKeycode andCharacter:(unichar)aCharacter;

/*!
    @method     target
    @abstract   Returns the target object of the receiver.
*/
- (id)target;
/*!
    @method     setTarget:
    @abstract   Sets the receiver's target object to <i>anObject</i>.
 	@param		anObject The receiver's target object
*/
- (void)setTarget:(id)anObject;

/*!
    @method     action
    @abstract   Returns the receiver’s action message selector.
*/
- (SEL)action;
/*!
    @method     setAction:
    @abstract   Sets the selector used for the action message to aSelector.
  	@param		aSelector the receiver action.
*/
- (void)setAction:(SEL)aSelector;

/*!
    @method     isRegistred
    @abstract   Returns the status of the Hot Key.
  	@result		Returns YES if the receiver is currently register as a System Hot Key and respond to System Hot Key Events.
*/
- (BOOL)isRegistred;
/*!
    @method     setRegistred:
    @abstract   Sets the stats of the receiver. If flag is YES, the receiver try to register himself as a Global Hot Key.
    @discussion This method call <i>isValid</i> before trying to register and return NO if receiver isn't valid.
 	@param		flag
  	@result		Returns YES if the stats is already flag or if it succesfully registers or unregisters.
*/
- (BOOL)setRegistred:(BOOL)flag;

/*!
    @method     keyRepeat
    @abstract   Returns the time interval between two repeat key down event.
	@result     Returns a time interval in seconds or 0 if autorepeat isn't active for the receiver.
*/
- (NSTimeInterval)keyRepeat;
/*!
    @method     setKeyRepeat:
    @abstract   Sets the time interva between two autorepeat key down events.
    @param      interval the time interval in seconds, or 0 to desactivate autorepeat for the receiver.
*/
- (void)setKeyRepeat:(NSTimeInterval)interval;

/*!
    @method     rawkey
    @abstract   Encode character, keycode and modifier as a single integer.
    @discussion This method can be usefull to serialize an hotkey or to save a keystae with one call.
    @result     A single integer representing receiver character, modifier and keycode.
*/
- (unsigned)rawkey;
/*!
    @method     setRawkey:
    @abstract   Restore the receiver  character, keycode and modifier.
    @param      rawkey A rawkey.
*/
- (void)setRawkey:(unsigned)rawkey;

/*!
    @method     invoke
    @abstract   Make target perform action.
*/
- (void)invoke;

#pragma mark Callback Methods
- (void)keyPressed;
- (void)keyReleased;

@end

