/*
 *  HKAXUIExtensions.c
 *  HotKeyToolKit
 *
 *  Created by Fox on 16/08/04.
 *  Copyright 2004 Shadow Lab. All rights reserved.
 *
 */

#import "HKAXUIExtensions.h"
#import "HKAXUIHotKey.h"
#import "HKKeyMap.h"

#pragma mark -
#pragma mark Publics Functions Definitions
CGError HKSendHotKey(CGCharCode character, CGKeyCode keycode, unsigned int modifier) {
  CGError err = kCGErrorSuccess;
  
  /* Checking arguments values */
  if (kHKNilUnichar == character) character = HKUnicharForKeycode(keycode);
  if (kHKNilUnichar == character) return kCGErrorIllegalArgument;
  
  if (kHKInvalidVirtualKeyCode == keycode) keycode = HKKeycodeForUnichar(character);
  if (kHKInvalidVirtualKeyCode == keycode) return kCGErrorIllegalArgument;
  
  CGInhibitLocalEvents(YES);
  CGEnableEventStateCombining(NO);
  CGSetLocalEventsFilterDuringSuppressionState (kCGEventFilterMaskPermitAllEvents, kCGEventSuppressionStateSuppressionInterval);
  
  /* Sending Modifier Keydown events */
  if (NSControlKeyMask & modifier) {
    err = CGPostKeyboardEvent(0, (CGKeyCode)kVirtualControlKey, YES);
  }
  if (NSAlternateKeyMask & modifier) {
    err = CGPostKeyboardEvent(0, (CGKeyCode)kVirtualOptionKey, YES);
  }
  if (NSShiftKeyMask & modifier) {
    err = CGPostKeyboardEvent(0, (CGKeyCode)kVirtualShiftKey, YES);
  }
  if (NSCommandKeyMask & modifier) {
    err = CGPostKeyboardEvent(0, (CGKeyCode)kVirtualCommandKey, YES);
  }
  
  /* Sending Character Key events */
  /* If key already down in carbon app, event not sended */
  err = CGPostKeyboardEvent((CGCharCode)character, keycode , YES);
  err = CGPostKeyboardEvent((CGCharCode)character, keycode, NO);
  
  /* Sending Modifiers Key Up events */
  if (NSCommandKeyMask & modifier) {
    err = CGPostKeyboardEvent((CGCharCode)0, (CGKeyCode)kVirtualCommandKey, NO);
  }
  if (NSShiftKeyMask & modifier) {
    err = CGPostKeyboardEvent((CGCharCode)0, (CGKeyCode)kVirtualShiftKey, NO);
  }
  if (NSAlternateKeyMask & modifier) {
    err = CGPostKeyboardEvent((CGCharCode)0, (CGKeyCode)kVirtualOptionKey, NO);
  }
  if (NSControlKeyMask & modifier) {
    err = CGPostKeyboardEvent((CGCharCode)0, (CGKeyCode)kVirtualControlKey, NO);
  }
  
  CGEnableEventStateCombining(YES); 
  CGInhibitLocalEvents(NO);
  return err;
}

AXError HKSendHotKeyToApplication(CGCharCode character, CGKeyCode keycode, unsigned int modifier, OSType signature, CFStringRef bundleID) {
  
  if (kHKUnknowCreator == signature && nil == bundleID) {
    return kAXErrorIllegalArgument;
  }
  
  ProcessSerialNumber psn = {kNoProcess, kNoProcess};
  switch (signature) {
    case kHKSystemWide:
      return HKSendHotKeyToProcess(character, keycode, modifier, nil);
    case kHKActiveApplication:
      GetFrontProcess(&psn);
      break;
    case kHKUnknowCreator:
      psn = HKGetProcessWithBundleIdentifier(bundleID);
      break;
    default:
      psn = HKGetProcessWithSignature(signature);
  }
  return HKSendHotKeyToProcess(character, keycode, modifier, &psn);
}


AXError HKSendHotKeyToProcess(CGCharCode character, CGKeyCode keycode, unsigned int modifier, ProcessSerialNumber *psn) {
  AXUIElementRef app = nil;
  AXError err = kAXErrorSuccess;
  
  /* Checking arguments values */
  if (kHKNilUnichar == character) character = HKUnicharForKeycode(keycode);
  if (kHKNilUnichar == character) return kAXErrorIllegalArgument;
  
  if (kHKInvalidVirtualKeyCode == keycode) keycode = HKKeycodeForUnichar(character);
  if (kHKInvalidVirtualKeyCode == keycode) return kAXErrorIllegalArgument;

  /* Creating AXUIElement with process */
  if (psn == nil) {
    app = AXUIElementCreateSystemWide();
  } else if (psn->lowLongOfPSN != kNoProcess || psn->highLongOfPSN != kNoProcess) {
    pid_t pid;
    GetProcessPID(psn, &pid);
    app = (pid != 0) ? AXUIElementCreateApplication(pid) : nil;
  } else {
    return kAXErrorIllegalArgument;
  }
  
  if (nil == app) {
    return kAXErrorInvalidUIElement;
  }
  CGInhibitLocalEvents(YES);
  CGEnableEventStateCombining(NO);
  CGSetLocalEventsFilterDuringSuppressionState (kCGEventFilterMaskPermitAllEvents, kCGEventSuppressionStateSuppressionInterval);
  
  /* Sending Modifier Keydown events */
  if (NSControlKeyMask & modifier) {
    err = AXUIElementPostKeyboardEvent(app, 0, (CGKeyCode)kVirtualControlKey, YES);
  }
  if (NSAlternateKeyMask & modifier) {
    err = AXUIElementPostKeyboardEvent(app, 0, (CGKeyCode)kVirtualOptionKey, YES);
  }
  if (NSShiftKeyMask & modifier) {
    err = AXUIElementPostKeyboardEvent(app, 0, (CGKeyCode)kVirtualShiftKey, YES);
  }
  if (NSCommandKeyMask & modifier) {
    err = AXUIElementPostKeyboardEvent(app, 0, (CGKeyCode)kVirtualCommandKey, YES);
  }
  
  /* Sending Character Key events */
  /* If key already down in carbon app, event not sended */
  err = AXUIElementPostKeyboardEvent(app, (CGCharCode)character, keycode , YES);
  err = AXUIElementPostKeyboardEvent(app, (CGCharCode)character, keycode, NO);

  /* Sending Modifiers Key Up events */
  if (NSCommandKeyMask & modifier) {
    err = AXUIElementPostKeyboardEvent(app, (CGCharCode)0, (CGKeyCode)kVirtualCommandKey, NO);
  }
  if (NSShiftKeyMask & modifier) {
    err = AXUIElementPostKeyboardEvent(app, (CGCharCode)0, (CGKeyCode)kVirtualShiftKey, NO);
  }
  if (NSAlternateKeyMask & modifier) {
    err = AXUIElementPostKeyboardEvent(app, (CGCharCode)0, (CGKeyCode)kVirtualOptionKey, NO);
  }
  if (NSControlKeyMask & modifier) {
    err = AXUIElementPostKeyboardEvent(app, (CGCharCode)0, (CGKeyCode)kVirtualControlKey, NO);
  }
  
  CGEnableEventStateCombining(YES); 
  CGInhibitLocalEvents(NO);
  return err;
}

#pragma mark -
@implementation HKHotKey (AXUIExtension)

- (AXError)sendHotKeyToApplicationWithSignature:(OSType)sign bundleId:(NSString *)bundleId {
  AXError err = kAXErrorSuccess;
  if ([self isValid]) {
    BOOL ok = [self isRegistred];
    if (ok) [self setRegistred:NO];
    err = HKSendHotKeyToApplication([self character], [self keycode], [self modifier], sign, (CFStringRef)bundleId);
    if (ok) [self setRegistred:YES];
  } else {
    err = kAXErrorIllegalArgument;
  }
  return err;
}

- (CGError)sendHotKey {
  CGError err = kCGErrorSuccess;
  if ([self isValid]) {
    BOOL ok = [self isRegistred];
    if (ok) [self setRegistred:NO];
    err = HKSendHotKey([self character], [self keycode], [self modifier]);
    if (ok) [self setRegistred:YES];
  }
  return err;
}

@end

