/*
 *  HKEventCompat.m
 *  HotKeyToolKit
 *
 *  Created by Grayfox.
 *  Copyright 2004-2006 Shadow Lab. All rights reserved.
 */

#include "HKEvent.h"
#include "HKKeyMap.h"

#include <unistd.h>

static __inline__ 
void __HKEventPostKeyboardEvent(CGEventSourceRef source, CGKeyCode keycode, AXUIElementRef app, Boolean down) {
  if (app)
    AXUIElementPostKeyboardEvent(app, 0, keycode, down);
  else
    CGPostKeyboardEvent(0, keycode, down);
  /* Avoid to fast typing */
  usleep(HKEventSleepInterval);
}

SK_PRIVATE
void __HKEventCompatPostKeystroke(CGKeyCode keycode, CGEventFlags modifier, void *source, ProcessSerialNumber *psn);

void __HKEventCompatPostKeystroke(CGKeyCode keycode, CGEventFlags modifier, void *source, ProcessSerialNumber *psn) {
  AXUIElementRef app = nil;
  
  if (psn && (psn->lowLongOfPSN != kNoProcess || psn->highLongOfPSN != kNoProcess)) {
    pid_t pid;
    GetProcessPID(psn, &pid);
    app = (pid != 0) ? AXUIElementCreateApplication(pid) : nil;
  }
  
  CGInhibitLocalEvents(YES);
  CGEnableEventStateCombining(NO);
  CGSetLocalEventsFilterDuringSuppressionState (kCGEventFilterMaskPermitAllEvents, kCGEventSuppressionStateSuppressionInterval);
  
  /* Sending Modifier Keydown events */
  if (kCGEventFlagMaskAlphaShift & modifier) {
    __HKEventPostKeyboardEvent(source, kVirtualCapsLockKey, app, YES);
  }
  if (kCGEventFlagMaskShift & modifier) {
    __HKEventPostKeyboardEvent(source, kVirtualShiftKey, app, YES);
  }
  if (kCGEventFlagMaskControl & modifier) {
    __HKEventPostKeyboardEvent(source, kVirtualControlKey, app, YES);
  }
  if (kCGEventFlagMaskAlternate & modifier) {
    __HKEventPostKeyboardEvent(source, kVirtualOptionKey, app, YES);
  }
  if (kCGEventFlagMaskCommand & modifier) {
    __HKEventPostKeyboardEvent(source, kVirtualCommandKey, app, YES);
  }
  
  /* Sending Character Key events */
  __HKEventPostKeyboardEvent(source, keycode , app, YES);
  __HKEventPostKeyboardEvent(source, keycode, app, NO);
  
  /* Sending Modifiers Key Up events */
  if (kCGEventFlagMaskCommand & modifier) {
    __HKEventPostKeyboardEvent(source, kVirtualCommandKey, app, NO);
  }
  if (kCGEventFlagMaskAlternate & modifier) {
    __HKEventPostKeyboardEvent(source, kVirtualOptionKey, app, NO);
  }
  if (kCGEventFlagMaskControl & modifier) {
    __HKEventPostKeyboardEvent(source, kVirtualControlKey, app, NO);
  }
  if (kCGEventFlagMaskShift & modifier) {
    __HKEventPostKeyboardEvent(source, kVirtualShiftKey, app, NO);
  }
  if (kCGEventFlagMaskAlphaShift & modifier) {
    __HKEventPostKeyboardEvent(source, kVirtualCapsLockKey, app, NO);
  }
  
  CGEnableEventStateCombining(YES); 
  CGInhibitLocalEvents(NO);
  
  if (app) {
    CFRelease(app);
  }
}
