/*
 *  HKTrapWindow.m
 *  HotKeyToolKit
 *
 *  Created by Shadow Team.
 *  Copyright (c) 2004 - 2008 Shadow Lab. All rights reserved.
 */

#import "HKKeyMap.h"
#import "HKHotKey.h"
#import "HKTrapWindow.h"
#import "HKHotKeyManager.h"

#pragma mark Constants Definition
NSString * const kHKEventKeyCodeKey = @"EventKeycode";
NSString * const kHKEventModifierKey = @"EventModifier";
NSString * const kHKEventCharacterKey = @"EventCharacter";
NSString * const kHKTrapWindowDidCatchKeyNotification = @"kHKTrapWindowKeyCaught";

#pragma mark -
@implementation HKTrapWindow

- (void)dealloc {
  [self setDelegate:nil];
  [super dealloc];
}

- (id<HKTrapWindowDelegate>)delegate {
  return (id<HKTrapWindowDelegate>)[super delegate];
}
- (void)setDelegate:(id<HKTrapWindowDelegate>)delegate {
  id previous = [super delegate];
  if (previous) {
    WBDelegateUnregisterNotification(previous, @selector(trapWindowDidCatchHotKey:), kHKTrapWindowDidCatchKeyNotification);
  }
  [super setDelegate:delegate];
  if (delegate) {
    WBDelegateRegisterNotification(delegate, @selector(trapWindowDidCatchHotKey:), kHKTrapWindowDidCatchKeyNotification);
  }
}
#pragma mark -
#pragma mark Trap accessor
- (BOOL)isTrapping {
  return hk_twFlags.trap;
}

- (void)setTrapping:(BOOL)flag {
  if (!hk_trapField) {
    WBFlagSet(hk_twFlags.trap, flag);
  } else {
    if (flag)
      [self makeFirstResponder:hk_trapField];
    else
      [self makeFirstResponder:self];
  }
}

- (BOOL)verifyHotKey {
  return !hk_twFlags.skipverify;
}
- (void)setVerifyHotKey:(BOOL)flag {
  WBFlagSet(hk_twFlags.skipverify, !flag);
}

#pragma mark -
#pragma mark Trap Observer.
- (NSTextField *)trapField {
  return hk_trapField;
}
- (void)setTrapField:(NSTextField *)newTrapField {
  hk_trapField = newTrapField;
}

- (void)endEditingFor:(id)anObject {
  [super endEditingFor:anObject];
  if (hk_trapField)
    hk_twFlags.trap = (anObject == hk_trapField) ? 1 : 0;
}

#pragma mark -
#pragma mark Event Trap.
- (BOOL)performKeyEquivalent:(NSEvent *)theEvent {
  if (hk_twFlags.trap && !hk_twFlags.resend) {
    BOOL perform = NO;
    if (WBDelegateHandle([self delegate], trapWindow:needPerformKeyEquivalent:))  {
      perform = [[self delegate] trapWindow:self needPerformKeyEquivalent:theEvent];
    }
    /* If should not perform */
    if (!perform) {
      hk_twFlags.resend = 1;
      [self sendEvent:theEvent];
      hk_twFlags.resend = 0;
      return YES;
    }
  }
  return [super performKeyEquivalent:theEvent];
}

- (void)handleHotKey:(HKHotKey *)aKey {
  if (hk_twFlags.trap) {
    bool valid = true;
    if ([[self delegate] respondsToSelector:@selector(trapWindow:isValidHotKey:modifier:)])
      valid = [[self delegate] trapWindow:self isValidHotKey:[aKey keycode] modifier:[aKey nativeModifier]];
    
    if (valid) {
      NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:
                                WBUInteger([aKey keycode]), kHKEventKeyCodeKey,
                                WBUInteger([aKey modifier]), kHKEventModifierKey,
                                WBUInteger([aKey character]), kHKEventCharacterKey,
                                nil];
      [[NSNotificationCenter defaultCenter] postNotificationName:kHKTrapWindowDidCatchKeyNotification
                                                          object:self
                                                        userInfo:userInfo];
    }
  }
}

- (void)sendEvent:(NSEvent *)theEvent {
  if ([theEvent type] == NSKeyDown && hk_twFlags.trap) {
    BOOL needProcess = NO;
    if (!hk_twFlags.resend && WBDelegateHandle([self delegate], trapWindow:needProceedKeyEvent:))  {
      needProcess = [[self delegate] trapWindow:self needProceedKeyEvent:theEvent];
    }
    if (needProcess) {
      [super sendEvent:theEvent];
    } else {
      HKKeycode code = [theEvent keyCode];
      NSUInteger mask = [theEvent modifierFlags] & NSDeviceIndependentModifierFlagsMask; //0x00ff0000;
      unichar character = 0;
//      DLog(@"Code: %u, modifier: %x", code, mask);
//      if (mask & NSNumericPadKeyMask) {
//        DLog(@"NumericPad");
//      }
      if (mask & NSAlphaShiftKeyMask) {
        // ignore caps lock modifier
        mask &= ~NSAlphaShiftKeyMask;
      }
      /* If verify keycode and modifier */
      bool valid = true;
      HKModifier modifier = (HKModifier)HKUtilsConvertModifier(mask, kHKModifierFormatCocoa, kHKModifierFormatNative);
      if ([self verifyHotKey]) {
        /* ask delegate if he want to filter the keycode and modifier */
        if ([[self delegate] respondsToSelector:@selector(trapWindow:isValidHotKey:modifier:)])
          valid = [[self delegate] trapWindow:self isValidHotKey:code modifier:modifier];
        /* ask hotkey manager */
        if (valid)
          valid = [HKHotKeyManager isValidHotKeyCode:code withModifier:modifier];
      }
      if (valid) {
        character = HKMapGetUnicharForKeycode(code);
        if (kHKNilUnichar == character) {
          code = kHKInvalidVirtualKeyCode;
          modifier = 0;
          NSBeep();
        }
      } else {
        NSBeep();
        modifier = 0;
        character = kHKNilUnichar;
        code = kHKInvalidVirtualKeyCode;
      }
      if (code != kHKInvalidVirtualKeyCode) {
        NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:
                                  WBUInteger(code), kHKEventKeyCodeKey,
                                  WBUInteger(modifier), kHKEventModifierKey,
                                  WBUInteger(character), kHKEventCharacterKey,
                                  nil];
        [[NSNotificationCenter defaultCenter] postNotificationName:kHKTrapWindowDidCatchKeyNotification
                                                            object:self
                                                          userInfo:userInfo];
      }
    } /* needProcess */
  } else { /* Not a KeyDown Event or not trapping */
    [super sendEvent:theEvent];
  }
}

@end
