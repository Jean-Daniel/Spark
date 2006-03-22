/*
 *  HKAXUIExtensions.h
 *  HotKeyToolKit
 *
 *  Created by Fox on 16/08/04.
 *  Copyright 2004 Shadow Lab. All rights reserved.
 *
 */
/*!
    @header		HKAXUIExtensions
    @abstract   Extension using AX frameworks to send keyboard events to others applications.
*/

#import <Foundation/Foundation.h>
#import <HotKeyToolKit/HKHotKey.h>

enum {
  kHKActiveApplication = 0,
  kHKUnknowCreator	   = kUnknownType,
  kHKSystemWide		   = 'syst'
};

CGError HKSendHotKey(CGCharCode character, CGKeyCode keycode, unsigned int modifier);

/*!
	@function 	HKSendHotKeyToApplication
	@abstract   Send a keyboard shortcut event to a running application.
	@param      character If you don't know it or you want the keycode be resolve at run time, use <i>kHKNilUnichar</i>.
 	@param      keycode If you don't know it or you want the keycode be resolve at run time, use <i>kHKNilVirtualKeyCode</i>.
 	@param      modifier A combination of Cocoa Modifier constants (NSControlKeyMask, NSAlternateKeyMask, NSShiftKeyMask, NSCommandKeyMask).
 	@param      application The application signature (creator) or kHKActiveApplication to send event to front application ,
 				or kHKSystemWide to send System Wide events, or kHKUnknowCreator if you don't know it.
 	@param      bundleID The application bundle identifier or nil. If you pass kHKActiveApplication for application, this parameter isn't used.
	@result     An AXError code.
 */
extern AXError HKSendHotKeyToApplication(CGCharCode character, CGKeyCode keycode, unsigned int modifier, OSType application, CFStringRef bundleID);

/*!
	@function 	HKSendHotKeyToProcess
	@abstract   Send a keyboard shortcut event to a running process.
	@param      character If you don't know it or you want the keycode be resolve at run time, use <i>kHKNilUnichar</i>.
	@param      keycode If you don't know it or you want the keycode be resolve at run time, use <i>kHKNilVirtualKeyCode</i>.
	@param      modifier A combination of Cocoa Modifier constants (NSControlKeyMask, NSAlternateKeyMask, NSShiftKeyMask, NSCommandKeyMask).
	@param      psn The target process serial number or nil to send event to front process.
	@result     An AXError code.
 */
extern AXError HKSendHotKeyToProcess(CGCharCode character, CGKeyCode keycode, unsigned int modifier, ProcessSerialNumber *psn);
