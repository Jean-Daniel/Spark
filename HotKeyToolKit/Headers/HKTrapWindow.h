//
//  TrapField.h
//  Short-Cut
//
//  Created by Fox on Thu Nov 27 2003.
//  Copyright (c) 2004 Shadow Lab. All rights reserved.
//
/*!
    @header HKTrapWindow
*/

#import <Cocoa/Cocoa.h>

#pragma mark Constants Declaration
/*!
    @const 		kHKTrapWindowKeyCatchNotification
    @abstract   Notification sended when a NSEvent is catch.
	@discussion Notification userInfo contains a NSDictionary with 3 keys:<br />
	 			- kHKEventKeyCodeKey: A NSNumber<br />
				- kHKEventModifierKey: A NSNumber<br />
				- kHKEventCharacterKey: A NSNumber<br />
*/
extern NSString * const kHKTrapWindowKeyCatchedNotification;

extern NSString * const kHKEventKeyCodeKey;
extern NSString * const kHKEventModifierKey;
extern NSString * const kHKEventCharacterKey;

#pragma mark -
/*!
@class HKTrapWindow
@abstract   This Window can be use to record a Hot Key Event.
@discussion The Window catch all Events and when the 
			NSTextField trapField is selected, it block KeyEvents and send a -setHotKey:mask: message
			to the delegate.
			To use it, create an NSWindow in Interface Builder. Change the window class to HKTrapWindow
			and link trapField to a NSTextField owned by this window. Each time the Window receive an event, 
			it set the value of this textField to the shortCut String Description.
*/
@interface HKTrapWindow : NSWindow {
  IBOutlet NSTextField *trapField;
@private
  struct _hk_twFlags {
    unsigned int trap:1;
    unsigned int block:1;
    unsigned int verify:1;
    unsigned int :5;
  } hk_twFlags;
}

- (BOOL)isTrapping;
- (void)setTrapping:(BOOL)flag;

- (BOOL)verifyHotKey;
- (void)setVerifyHotKey:(BOOL)flag;

- (NSTextField *)trapField;
- (void)setTrapField:(NSTextField *)newTrapField;

@end

#pragma mark -
/*!
    @category	NSObject(TrapWindowDelegate)
    @abstract	Delegate Methods for HKTrapWindow
*/
@interface NSObject (TrapWindowDelegate)

/*!
    @method     trapWindow:needPerformKeyEquivalent:
    @abstract   This method permit to block some key equivalent and to handle others (like ESC key equivalent).
    @param      window The Trap Window.
    @param      theEvent 
    @result     If return YES, key equivalents are handle as in normal Windows. If return NO they are not processed.
*/
- (BOOL)trapWindow:(HKTrapWindow *)window needPerformKeyEquivalent:(NSEvent *)theEvent;

/*!
    @method     trapWindow:needProceedKeyEvent:
    @discussion You can use this method to avoid catching event like <code>return</code> or <code>escape</code>.
 				Return YES to proceed the event and don't catch it.
    @param      window The Trap Window.
    @param      theEvent The event to proceed.
    @result     if return YES, the event is proceed and not catch.
*/
- (BOOL)trapWindow:(HKTrapWindow *)window needProceedKeyEvent:(NSEvent *)theEvent;

/*!
    @method     trapWindowCatchHotKey:
    @abstract   Notification sended when the trap catch an Event.
	@discussion userInfo contains a NSDictionary with 3 keys:<br />
 				- kHKEventKeyCodeKey: A NSNumber<br />
 				- kHKEventModifierKey: A NSNumber<br />
 				- kHKEventCharacterKey: A NSNumber<br />
    @param      aNotification The Notification object is the window itself.
*/
- (void)trapWindowCatchHotKey:(NSNotification *)aNotification;

@end