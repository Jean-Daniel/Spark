/*
 *  HKEvent.m
 *  HotKeyToolKit
 *
 *  Created by Grayfox.
 *  Copyright 2004-2006 Shadow Lab. All rights reserved.
 */

#import "HKEvent.h"
#import "HKKeyMap.h"

static ProcessSerialNumber HKGetProcessWithSignature(OSType type);
static ProcessSerialNumber HKGetProcessWithBundleIdentifier(CFStringRef bundleId);

static 
void (*_HKEventPostKeyStroke)(CGKeyCode keycode, CGEventFlags modifier, CGEventSourceRef source, void *psn) = nil;

static
void __HKEventPostKeystroke(CGKeyCode keycode, CGEventFlags modifier, CGEventSourceRef source, void *psn);
__private_extern__
void __HKEventCompatPostKeystroke(CGKeyCode keycode, CGEventFlags modifier, CGEventSourceRef source, void *psn);

static Boolean HKEventCompat = NO;

static void __HKEventInitialize(void) __attribute__((constructor));
static void __HKEventInitialize() {
  if (CGEventCreateKeyboardEvent != NULL) {
    _HKEventPostKeyStroke = __HKEventPostKeystroke;
  } else {
    HKEventCompat = YES;
    _HKEventPostKeyStroke = __HKEventCompatPostKeystroke;
  }
}

#pragma mark -
static __inline__ 
void __HKEventPostKeyboardEvent(CGEventSourceRef source, CGKeyCode keycode, void *psn, Boolean down) {
  CGEventRef event = CGEventCreateKeyboardEvent(source, keycode, down);
  if (psn)
    CGEventPostToPSN(psn, event);
  else
    CGEventPost(kCGHIDEventTap, event);
  CFRelease(event);
}

static
void __HKEventPostKeystroke(CGKeyCode keycode, CGEventFlags modifier, CGEventSourceRef source, void *psn) {
  /* WARNING: look like CGEvent does not support null source */
  BOOL isource = NO;
  if (!source) {
    isource = YES;
    source = CGEventSourceCreate(kCGEventSourceStatePrivate);
  }
  
  /* Sending Modifier Keydown events */
  if (kCGEventFlagMaskAlphaShift & modifier) {
    __HKEventPostKeyboardEvent(source, kVirtualCapsLockKey, psn, YES);
  }
  if (kCGEventFlagMaskShift & modifier) {
    __HKEventPostKeyboardEvent(source, kVirtualShiftKey, psn, YES);
  }
  if (kCGEventFlagMaskControl & modifier) {
    __HKEventPostKeyboardEvent(source, kVirtualControlKey, psn, YES);
  }
  if (kCGEventFlagMaskAlternate & modifier) {
    __HKEventPostKeyboardEvent(source, kVirtualOptionKey, psn, YES);
  }
  if (kCGEventFlagMaskCommand & modifier) {
    __HKEventPostKeyboardEvent(source, kVirtualCommandKey, psn, YES);
  }
  
  /* Sending Character Key events */
  __HKEventPostKeyboardEvent(source, keycode , psn, YES);
  __HKEventPostKeyboardEvent(source, keycode, psn, NO);
  
  /* Sending Modifiers Key Up events */
  if (kCGEventFlagMaskCommand & modifier) {
    __HKEventPostKeyboardEvent(source, kVirtualCommandKey, psn, NO);
  }
  if (kCGEventFlagMaskAlternate & modifier) {
    __HKEventPostKeyboardEvent(source, kVirtualOptionKey, psn, NO);
  }
  if (kCGEventFlagMaskControl & modifier) {
    __HKEventPostKeyboardEvent(source, kVirtualControlKey, psn, NO);
  }
  if (kCGEventFlagMaskShift & modifier) {
    __HKEventPostKeyboardEvent(source, kVirtualShiftKey, psn, NO);
  }
  if (kCGEventFlagMaskAlphaShift & modifier) {
    __HKEventPostKeyboardEvent(source, kVirtualCapsLockKey, psn, NO);
  }
  
  if (isource) {
    CFRelease(source);
  }
}

static
Boolean __HKEventPostCharacterKeystrokes(UniChar character, CGEventSourceRef source, void *psn) {
  /* WARNING: look like CGEvent does not support null source */
  BOOL isource = NO; /* YES if internal source and should be released */ 
  if (!source && CGEventSourceCreate != NULL) {
    isource = YES;
    source = CGEventSourceCreate(kCGEventSourceStatePrivate);
  }
  
  UInt32 keys[8];
  UInt32 mods[8];
  unsigned i = 0;
  UInt32 count = HKMapGetKeycodesAndModifiersForUnichar(character, keys, mods, 8);
  for (i=0; i < count; i++) {
    _HKEventPostKeyStroke(keys[i], mods[i], source, psn);
  }
  
  if (isource) {
    CFRelease(source);
  }
  
  return count > 0;
}

#pragma mark API
void HKEventPostKeystroke(CGKeyCode keycode, CGEventFlags modifier, CGEventSourceRef source) {
  _HKEventPostKeyStroke(keycode, modifier, source, NULL);
}

Boolean HKEventPostCharacterKeystrokes(UniChar character, CGEventSourceRef source) {
  return __HKEventPostCharacterKeystrokes(character, source, NULL);
}

Boolean HKEventPostKeystrokeToTarget(CGKeyCode keycode, CGEventFlags modifier, HKEventTarget target, HKEventTargetType type, CGEventSourceRef source) {
  ProcessSerialNumber psn = {kNoProcess, kNoProcess};
  switch (type) {
    case kHKEventTargetSystem:
      _HKEventPostKeyStroke(keycode, modifier, source, NULL);
      return YES;
    case kHKEventTargetProcess:
      _HKEventPostKeyStroke(keycode, modifier, source, target.psn);
      return YES;
    case kHKEventTargetBundle:
      psn = HKGetProcessWithBundleIdentifier(target.bundle);
      break;
    case kHKEventTargetSignature:
      psn = HKGetProcessWithSignature(target.signature);
      break;
  }
  if (psn.lowLongOfPSN != kNoProcess) {
    _HKEventPostKeyStroke(keycode, modifier, source, &psn);
    return YES;
  }
  return NO;
}

Boolean HKEventPostCharacterKeystrokesToTarget(UniChar character, HKEventTarget target, HKEventTargetType type, CGEventSourceRef source) {
  ProcessSerialNumber psn = {kNoProcess, kNoProcess};
  switch (type) {
    case kHKEventTargetSystem:
      __HKEventPostCharacterKeystrokes(character, source, NULL);
      return YES;
    case kHKEventTargetProcess:
      __HKEventPostCharacterKeystrokes(character, source, target.psn);
      return YES;
    case kHKEventTargetBundle:
      psn = HKGetProcessWithBundleIdentifier(target.bundle);
      break;
    case kHKEventTargetSignature:
      psn = HKGetProcessWithSignature(target.signature);
      break;
  }
  if (psn.lowLongOfPSN != kNoProcess) {
    __HKEventPostCharacterKeystrokes(character, source, &psn);
    return YES;
  }
  return NO;
}

#pragma mark -
#pragma mark Statics Functions Definition
ProcessSerialNumber HKGetProcessWithSignature(OSType type) {
  ProcessSerialNumber serialNumber = {kNoProcess, kNoProcess};
  if (type) {
    ProcessInfoRec info;
    while (procNotFound != GetNextProcess(&serialNumber))  {
      info.processInfoLength = sizeof(info);
      info.processName = NULL;
      info.processAppSpec = NULL;
      if (noErr == GetProcessInformation (&serialNumber, &info) && info.processSignature == type) {
        break;
      }
    }
  }
  return serialNumber; 
}

ProcessSerialNumber HKGetProcessWithBundleIdentifier(CFStringRef bundleId) {
  ProcessSerialNumber serialNumber = {kNoProcess, kNoProcess};
  CFPropertyListRef procValue;
  CFDictionaryRef info;
  
  if (!bundleId) {
    return serialNumber;
  }
  while (procNotFound != GetNextProcess(&serialNumber))  {
    info = ProcessInformationCopyDictionary(&serialNumber, kProcessDictionaryIncludeAllInformationMask);
    procValue = CFDictionaryGetValue (info, kCFBundleIdentifierKey);
    
    if (procValue && (CFEqual(procValue , bundleId)) ) {
      CFRelease(info);
      info = NULL;
      break;
    }
    if (info) {
      CFRelease(info);
      info = NULL;
    }
  }
  return serialNumber; 
}

#pragma mark -
@implementation HKHotKey (HKEventExtension)

- (BOOL)sendKeystroke {
  if ([self isValid]) {
    BOOL ok = NO;
    HKEventTarget target;
    ProcessSerialNumber psn;
    HKEventTargetType type = kHKEventTargetSystem;
    if (HKEventCompat) {
      ok = [self isRegistred];
      if (ok) [self setRegistred:NO];
    } else {
      if ([self isRegistred]) {
        GetFrontProcess(&psn);
        target.psn = &psn;
        type = kHKEventTargetProcess;
      }
    }
    HKEventPostKeystrokeToTarget([self keycode], 
                                 HKUtilsConvertModifier([self modifier], kHKModifierFormatCocoa, kHKModifierFormatNative),
                                 target, type, NULL);
    if (HKEventCompat) {
      if (ok) [self setRegistred:YES];
    }
  } else {
    return NO;
  }
  return YES;
}

- (BOOL)sendKeystrokeToApplication:(OSType)signature bundle:(NSString *)bundleId {
  BOOL result = NO;
  if ([self isValid]) {
    BOOL ok = NO;
    if (HKEventCompat) {
      ok = [self isRegistred];
      if (ok) [self setRegistred:NO];
    }
    /* Find target and target type */
    HKEventTarget target;
    HKEventTargetType type = kHKEventTargetSystem;
    
    if (signature && signature != kUnknownType) {
      target.signature = signature;
      type = kHKEventTargetSignature;
    } else if (bundleId) {
      target.bundle = (CFStringRef)bundleId;
      type = kHKEventTargetBundle;
    }
    
    result = HKEventPostKeystrokeToTarget([self keycode], HKUtilsConvertModifier([self modifier], kHKModifierFormatCocoa, kHKModifierFormatNative), target, type, NULL);
    if (HKEventCompat) {
      if (ok) [self setRegistred:YES];
    }
  }
  return result;
}

@end

