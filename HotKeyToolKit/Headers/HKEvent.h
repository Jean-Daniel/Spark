/*
 *  HKEvent.h
 *  HotKeyToolKit
 *
 *  Created by Shadow Team.
 *  Copyright (c) 2004 - 2007 Shadow Lab. All rights reserved.
 */

#import <ApplicationServices/ApplicationServices.h>
#import <HotKeyToolKit/HKBase.h>
#import <HotKeyToolKit/HKHotKey.h>

/* Sleeping interval between 2 key events (microseconds). Defaults: 5 ms */
HK_EXPORT
UInt32 HKEventSleepInterval;

HK_EXPORT
void HKEventPostKeystroke(CGKeyCode keycode, CGEventFlags modifier, CGEventSourceRef source);

HK_EXPORT
Boolean HKEventPostCharacterKeystrokes(UniChar character, CGEventSourceRef source);

typedef union {
  OSType signature;
  CFStringRef bundle;
  ProcessSerialNumber *psn;
} HKEventTarget;

typedef enum {
  kHKEventTargetSystem = 0,
  kHKEventTargetBundle,
  kHKEventTargetProcess,
  kHKEventTargetSignature,
} HKEventTargetType;

/*!
@function
 @abstract   Send a keyboard shortcut event to a running process.
 @param      character If you don't know it or you want the keycode be resolved at run time, use <i>kHKNilUnichar</i>.
 @param      keycode If you don't know it or you want the keycode be resolved at run time, use <i>kHKInvalidVirtualKeyCode</i>.
 @param      modifier A combination of Quartz Modifier constants.
 @param      psn The target process serial number or nil to send event to front process.
 @result     Returns true of successfully sent.
 */
HK_EXPORT
Boolean HKEventPostKeystrokeToTarget(CGKeyCode keycode, CGEventFlags modifier, HKEventTarget target, HKEventTargetType type, CGEventSourceRef source);

HK_EXPORT
Boolean HKEventPostCharacterKeystrokesToTarget(UniChar character, HKEventTarget target, HKEventTargetType type, CGEventSourceRef source);

@interface HKHotKey (HKEventExtension)

- (BOOL)sendKeystroke;

  /*!
  @method
   @abstract Perform the receiver HotKey on the application specified by <i>signature</i> or <i>bundleId</i>.
   @discussion If you want to send event system wide, pass '????' or 0 as signature and nil and bundle identifier, or use -sendKeystroke method.
   @param signature The target application process signature (creator).
   @param bundleId The Bundle identifier of the target process.
   @result YES.
   */
- (BOOL)sendKeystrokeToApplication:(OSType)signature bundle:(NSString *)bundleId;

@end
