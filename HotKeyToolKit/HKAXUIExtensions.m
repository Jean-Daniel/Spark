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

#pragma mark Statics Functions Declaration
static ProcessSerialNumber HKGetProcessWithSignature(OSType type);
static ProcessSerialNumber HKGetProcessWithBundleIdentifier(CFStringRef bundleId);
static ProcessSerialNumber HKGetProcessWithProperty(CFStringRef property, CFPropertyListRef value);

#pragma mark -
#pragma mark Publics Functions Definitions
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
  
  if (kHKNilVirtualKeyCode == keycode) keycode = HKKeycodeForUnichar(character);
  if (kHKNilVirtualKeyCode == keycode) return kAXErrorIllegalArgument;

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
  if ([self isValid])
    return HKSendHotKeyToApplication([self character], [self keycode], [self modifier], sign, (CFStringRef)bundleId);
  else return kAXErrorIllegalArgument;
}

@end

#pragma mark -
#pragma mark Statics Functions Definition
ProcessSerialNumber HKGetProcessWithSignature(OSType type) {
  ProcessSerialNumber psn = {kNoProcess, kNoProcess};
  CFStringRef sign = CFStringCreateWithBytes(kCFAllocatorDefault, (char *)&type, sizeof(OSType), kCFStringEncodingMacRoman, NO);
  if (nil != sign) {
    psn = HKGetProcessWithProperty(CFSTR("FileCreator"), sign);
    CFRelease(sign);
  }
  return psn;
}

ProcessSerialNumber HKGetProcessWithBundleIdentifier(CFStringRef bundleId) {
  return HKGetProcessWithProperty(kCFBundleIdentifierKey, bundleId);
}

ProcessSerialNumber HKGetProcessWithProperty(CFStringRef property, CFPropertyListRef value) {
  ProcessSerialNumber serialNumber = {kNoProcess, kNoProcess};
  CFPropertyListRef procValue;
  CFDictionaryRef info;
  
  if (!value) {
    return serialNumber;
  }
  while (procNotFound != GetNextProcess(&serialNumber))  {
    info = ProcessInformationCopyDictionary(&serialNumber, kProcessDictionaryIncludeAllInformationMask);
    if (info) {
      procValue = CFDictionaryGetValue(info, property);
      
      if (procValue && (CFEqual(procValue, value)) ) {
        CFRelease(info);
        info = NULL;
        break;
      }
      CFRelease(info);
      info = NULL;
    }
  }
  return serialNumber; 
}
