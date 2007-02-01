/*
 *  HKTrapWindow.m
 *  HotKeyToolKit
 *
 *  Created by Shadow Team.
 *  Copyright (c) 2004 - 2007 Shadow Lab. All rights reserved.
 */

#import "HKKeyMap.h"
#import "HKTrapWindow.h"
#import "HKHotKeyManager.h"

#pragma mark Constants Definition
NSString * const kHKEventKeyCodeKey = @"EventKeycode";
NSString * const kHKEventModifierKey = @"EventModifier";
NSString * const kHKEventCharacterKey = @"EventCharacter";
NSString * const kHKTrapWindowKeyCatchedNotification = @"kHKTrapWindowKeyCatched";

#pragma mark -
@implementation HKTrapWindow

- (void)dealloc {
  [self setDelegate:nil];
  [super dealloc];
}

- (void)setDelegate:(id)delegate {
  id previous = [self delegate];
  if (previous) {
    SKDelegateUnregisterNotification(previous, @selector(trapWindowCatchHotKey:), kHKTrapWindowKeyCatchedNotification);
  }
  [super setDelegate:delegate];
  if (delegate) {
    SKDelegateRegisterNotification(delegate, @selector(trapWindowCatchHotKey:), kHKTrapWindowKeyCatchedNotification);
  }
}
#pragma mark -
#pragma mark Trap accessor
- (BOOL)isTrapping {
  return hk_twFlags.trap;
}

- (void)setTrapping:(BOOL)flag {
  if (!hk_trapField) {
    SKSetFlag(hk_twFlags.trap, flag);
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
  SKSetFlag(hk_twFlags.skipverify, !flag);
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
  if (hk_twFlags.trap &&  !hk_twFlags.block) {
    BOOL perform = NO;
    if (SKDelegateHandle([self delegate], trapWindow:needPerformKeyEquivalent:))  {
      perform = [[self delegate] trapWindow:self needPerformKeyEquivalent:theEvent];
    }
    /* If should not perform */
    if (!perform) {
      hk_twFlags.block = 1;
      [self sendEvent:theEvent];
      hk_twFlags.block = 0;
      return YES;
    }
  }
  return [super performKeyEquivalent:theEvent];
}

- (void)sendEvent:(NSEvent *)theEvent {
  if ([theEvent type] == NSKeyDown && hk_twFlags.trap) {
    BOOL needProcess;
    if (SKDelegateHandle([self delegate], trapWindow:needProceedKeyEvent:))  {
      needProcess = [[self delegate] trapWindow:self needProceedKeyEvent:theEvent];
    } else {
      needProcess = NO;
    }
    if (needProcess) {
      [super sendEvent:theEvent];
    } else {
      HKKeycode code = [theEvent keyCode];
      HKModifier mask = [theEvent modifierFlags] & NSDeviceIndependentModifierFlagsMask; //0x00ff0000;
      unichar character = 0;
//#if defined(DEBUG)
//      NSLog(@"Code: %u, modifier: %x", code, mask);
//      if (mask & NSNumericPadKeyMask)
//        NSLog(@"NumericPad");
//#endif
      if (mask & NSAlphaShiftKeyMask) {
        mask &= ~NSAlphaShiftKeyMask;
        // DLog(@"Remove caps lock modifier");
      }
      /* If verify and verification return NO */
      if ([self verifyHotKey] && ![HKHotKeyManager isValidHotKeyCode:code withModifier:HKUtilsConvertModifier(mask, kHKModifierFormatCocoa, kHKModifierFormatNative)]) {
        mask = 0;
        character = kHKNilUnichar;
        code = kHKInvalidVirtualKeyCode;
        NSBeep();
        DLog(@"Invalid Key");
      } else {
        character = HKMapGetUnicharForKeycode(code);
        if (kHKNilUnichar == character) {
          code = kHKInvalidVirtualKeyCode;
          mask = 0;
          NSBeep();
        }
      }
      NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:
        SKUInt(code), kHKEventKeyCodeKey,
        SKUInt(mask), kHKEventModifierKey,
        SKUInt(character), kHKEventCharacterKey,
        nil];
      [[NSNotificationCenter defaultCenter] postNotificationName:kHKTrapWindowKeyCatchedNotification
                                                          object:self
                                                        userInfo:userInfo];
    } /* needProcess */
  } else { /* Not a KeyDown Event or not trapping */
    [super sendEvent:theEvent];
  }
}

@end
