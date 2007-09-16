/*
 *  HKEvent.m
 *  HotKeyToolKit
 *
 *  Created by Shadow Team.
 *  Copyright (c) 2004 - 2007 Shadow Lab. All rights reserved.
 */

#import "HKEvent.h"
#import "HKKeyMap.h"

#include <unistd.h>

static ProcessSerialNumber _HKGetProcessWithSignature(OSType type);
static ProcessSerialNumber _HKGetProcessWithBundleIdentifier(CFStringRef bundleId);

#pragma mark -
useconds_t HKEventSleepInterval = 5000;

HK_INLINE
void __HKEventPostKeyboardEvent(CGEventSourceRef source, HKKeycode keycode, void *psn, Boolean down) {
  CGEventRef event = CGEventCreateKeyboardEvent(source, keycode, down);
  if (psn)
    CGEventPostToPSN(psn, event);
  else
    CGEventPost(kCGHIDEventTap, event);
  CFRelease(event);
  if (HKEventSleepInterval > 0) {
    /* Avoid to fast typing (5 ms by default) */
    usleep(HKEventSleepInterval);
  }
}

static
void _HKEventPostKeyStroke(HKKeycode keycode, HKModifier modifier, CGEventSourceRef source, void *psn) {
  /* WARNING: look like CGEvent does not support null source (bug) */
  BOOL isource = NO;
  if (!source) {
    isource = YES;
    source = HKEventCreatePrivateSource();
  }
  
  /* Sending Modifier Keydown events */
  if (kCGEventFlagMaskAlphaShift & modifier) {
    /* Lock Caps Lock */
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
    /* Unlock Caps Lock */
    __HKEventPostKeyboardEvent(source, kVirtualCapsLockKey, psn, NO);
  }
  
  if (isource && source) {
    CFRelease(source);
  }
}

static
Boolean _HKEventPostCharacterKeystrokes(UniChar character, CGEventSourceRef source, void *psn) {
  /* WARNING: look like CGEvent does not support null source (bug) */
  BOOL isource = NO; /* YES if internal source and should be released */ 
  if (!source) {
    isource = YES;
    source = HKEventCreatePrivateSource();
  }
  
  HKKeycode keys[8];
  HKModifier mods[8];
  NSUInteger count = HKMapGetKeycodesAndModifiersForUnichar(character, keys, mods, 8);
  for (NSUInteger idx = 0; idx < count; idx++) {
    _HKEventPostKeyStroke(keys[idx], mods[idx], source, psn);
  }
  
  if (isource && source) {
    CFRelease(source);
  }
  
  return count > 0;
}

#pragma mark API
CGEventSourceRef HKEventCreatePrivateSource() {
  return CGEventSourceCreate(kCGEventSourceStatePrivate);
}

void HKEventPostKeystroke(HKKeycode keycode, HKModifier modifier, CGEventSourceRef source) {
  _HKEventPostKeyStroke(keycode, modifier, source, NULL);
}

Boolean HKEventPostCharacterKeystrokes(UniChar character, CGEventSourceRef source) {
  return _HKEventPostCharacterKeystrokes(character, source, NULL);
}

HK_INLINE
ProcessSerialNumber __HKEventGetPSNForTarget(HKEventTarget target, HKEventTargetType type) {
  ProcessSerialNumber psn = { kNoProcess, kNoProcess };
  switch (type) {
    case kHKEventTargetSystem:
      psn.lowLongOfPSN = kSystemProcess;
      break;
    case kHKEventTargetProcess:
      psn = *target.psn;
      if (kCurrentProcess == psn.lowLongOfPSN) GetCurrentProcess(&psn);
      break;
    case kHKEventTargetBundle:
      psn = _HKGetProcessWithBundleIdentifier(target.bundle);
      break;
    case kHKEventTargetSignature:
      psn = _HKGetProcessWithSignature(target.signature);
      break;
  }
  return psn;
}

Boolean HKEventPostKeystrokeToTarget(HKKeycode keycode, HKModifier modifier, HKEventTarget target, HKEventTargetType type, CGEventSourceRef source) {
  ProcessSerialNumber psn = __HKEventGetPSNForTarget(target, type);
  if (psn.lowLongOfPSN != kNoProcess) {
    _HKEventPostKeyStroke(keycode, modifier, source, kSystemProcess == psn.lowLongOfPSN ? NULL : &psn);
    return YES;
  }
  return NO;
}

Boolean HKEventPostCharacterKeystrokesToTarget(UniChar character, HKEventTarget target, HKEventTargetType type, CGEventSourceRef source) {
  ProcessSerialNumber psn = __HKEventGetPSNForTarget(target, type);
  if (psn.lowLongOfPSN != kNoProcess) {
    _HKEventPostCharacterKeystrokes(character, source, kSystemProcess == psn.lowLongOfPSN ? NULL : &psn);
    return YES;
  }
  return NO;
}

#pragma mark -
#pragma mark Statics Functions Definition
ProcessSerialNumber _HKGetProcessWithSignature(OSType type) {
  ProcessSerialNumber serialNumber = {kNoProcess, kNoProcess};
  if (type) {
    ProcessInfoRec info;
    while (procNotFound != GetNextProcess(&serialNumber))  {
      info.processInfoLength = (UInt32)sizeof(info);
      info.processName = NULL;
#if __LP64__
      info.processAppRef = NULL;
#else
      info.processAppSpec = NULL;
#endif
      if (noErr == GetProcessInformation(&serialNumber, &info) && info.processSignature == type) {
        break;
      }
    }
  }
  return serialNumber; 
}

ProcessSerialNumber _HKGetProcessWithBundleIdentifier(CFStringRef bundleId) {
  ProcessSerialNumber serialNumber = { kNoProcess, kNoProcess };
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
    HKEventTarget target;
    ProcessSerialNumber psn;
    HKEventTargetType type = kHKEventTargetSystem;
    if ([self isRegistred]) {
      GetFrontProcess(&psn);
      target.psn = &psn;
      type = kHKEventTargetProcess;
    }
    HKEventPostKeystrokeToTarget([self keycode], [self nativeModifier], target, type, NULL);
  } else {
    return NO;
  }
  return YES;
}

- (BOOL)sendKeystrokeToApplication:(OSType)signature bundle:(NSString *)bundleId {
  BOOL result = NO;
  if ([self isValid]) {
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
    
    result = HKEventPostKeystrokeToTarget([self keycode], [self nativeModifier], target, type, NULL);
  }
  return result;
}

@end
