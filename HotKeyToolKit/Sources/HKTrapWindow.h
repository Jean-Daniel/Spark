/*
 *  HKTrapWindow.h
 *  HotKeyToolKit
 *
 *  Created by Jean-Daniel Dupas.
 *  Copyright © 2004 - 2011 Shadow Lab. All rights reserved.
 */
/*!
 @header HKTrapWindow
 */

#import <HotKeyToolKit/HKBase.h>

// MARK: Constants Declaration
/*!
 @const 		kHKTrapWindowKeyCaughtNotification
 @abstract   Notification sended when a NSEvent is catch.
 @discussion Notification userInfo contains a NSDictionary with 3 keys:<br />
 - kHKEventKeyCodeKey: A NSNumber<br />
 - kHKEventModifierKey: A NSNumber<br />
 - kHKEventCharacterKey: A NSNumber<br />
 */
HK_EXPORT
NSString * const kHKTrapWindowDidCatchKeyNotification;

HK_EXPORT
NSString * const kHKEventKeyCodeKey;
HK_EXPORT
NSString * const kHKEventModifierKey;
HK_EXPORT
NSString * const kHKEventCharacterKey;

// MARK: -
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
@class HKHotKey;
@protocol HKTrapWindowDelegate;
HK_OBJC_EXPORT
@interface HKTrapWindow : NSWindow {
@private
  struct _hk_twFlags {
    unsigned int trap:1;
    unsigned int resend:1;
    unsigned int skipverify:1;
    unsigned int :5;
  } hk_twFlags;
  NSTextField *hk_trapField;
}

- (BOOL)isTrapping;
- (void)setTrapping:(BOOL)flag;

- (BOOL)verifyHotKey;
- (void)setVerifyHotKey:(BOOL)flag;

- (NSTextField *)trapField;
- (void)setTrapField:(NSTextField *)newTrapField;

/* simulate event (usefull when want to catch an already registred hotkey) */
- (void)handleHotKey:(HKHotKey *)aKey;

@property(assign) id<HKTrapWindowDelegate> delegate;

@end

// MARK: -
/*!
 @category	NSObject(TrapWindowDelegate)
 @abstract	Delegate Methods for HKTrapWindow
 */
@protocol HKTrapWindowDelegate <NSWindowDelegate>

/*!
 @method     trapWindow:needPerformKeyEquivalent:
 @abstract   This method permit to block some key equivalent and to handle others (like ESC key equivalent).
 @param      window The Trap Window.
 @param      theEvent
 @result     If returns YES, key equivalents are handle as in normal Windows. If returns NO they are not processed.
 */
- (BOOL)trapWindow:(HKTrapWindow *)window needPerformKeyEquivalent:(NSEvent *)theEvent;

/*!
 @method     trapWindow:needProceedKeyEvent:
 @discussion You can use this method to avoid catching event like <code>return</code> or <code>escape</code>.
 Return YES to proceed the event and don't catch it.
 @param      window The Trap Window.
 @param      theEvent The event to proceed.
 @result     if returns YES, the event is proceed and not catch.
 */
- (BOOL)trapWindow:(HKTrapWindow *)window needProceedKeyEvent:(NSEvent *)theEvent;

/* hotkey filter */
- (BOOL)trapWindow:(HKTrapWindow *)window isValidHotKey:(HKKeycode)keycode modifier:(HKModifier)modifier;

/*!
 @method     trapWindowDidCatchHotKey:
 @abstract   Notification sended when the trap catch an Event.
 @discussion userInfo contains a NSDictionary with 3 keys:<br />
 - kHKEventKeyCodeKey: A NSNumber<br />
 - kHKEventModifierKey: A NSNumber<br />
 - kHKEventCharacterKey: A NSNumber<br />
 @param      aNotification The Notification object is the window itself.
 */
- (void)trapWindowDidCatchHotKey:(NSNotification *)aNotification;

@end
