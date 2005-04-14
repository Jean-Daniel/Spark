//
//  TrapField.m
//  Short-Cut
//
//  Created by Fox on Thu Nov 27 2003.
//  Copyright (c) 2004 Shadow Lab. All rights reserved.
//

#import "HKTrapWindow.h"
#import "HKKeyMap.h"
#import "HKHotKeyManager.h"

#pragma mark Constants Definition
NSString * const kHKEventKeyCodeKey = @"Keycode";
NSString * const kHKEventModifierKey = @"Modifier";
NSString * const kHKEventCharacterKey = @"Character";
NSString * const kHKTrapWindowKeyCatchedNotification = @"kHKTrapWindowKeyCatched";

#pragma mark -
@implementation HKTrapWindow

- (void)dealloc {
  [self setDelegate:nil];
  [super dealloc];
}

- (void)removeDelegate {
  [[NSNotificationCenter defaultCenter] removeObserver:[self delegate] name:nil object:self];
}

- (void)setDelegate:(id)delegate {
  if ([self delegate]) {
    [self removeDelegate];
  }
  if (delegate && [delegate respondsToSelector:@selector(trapWindowCatchHotKey:)]) {
    [[NSNotificationCenter defaultCenter] addObserver:delegate selector:@selector(trapWindowCatchHotKey:) name:kHKTrapWindowKeyCatchedNotification object:self];
  }
  [super setDelegate:delegate];
}
#pragma mark -
#pragma mark Trap accessor
- (BOOL)isTrapping {
  return _needTrap;
}

- (void)setTrapping:(BOOL)flag {
  if (nil == trapField) {
    _needTrap = flag;
  } else {
    if (flag)
      [self makeFirstResponder:trapField];
    else
      [self makeFirstResponder:self];
  }
}

#pragma mark -
#pragma mark Trap Observer.
- (NSTextField *)trapField {
  return trapField;
}
- (void)setTrapField:(NSTextField *)newTrapField {
  trapField = newTrapField;
}

- (void)endEditingFor:(id)anObject {
  [super endEditingFor:anObject];
  if (nil != trapField)
    _needTrap = (anObject == trapField);
}

#pragma mark -
#pragma mark Event Trap.
- (BOOL)performKeyEquivalent:(NSEvent *)theEvent {
  BOOL perform;
  if ([self delegate] && [[self delegate] respondsToSelector:@selector(trapWindow:needPerformKeyEquivalent:)])  {
    perform = [[self delegate] trapWindow:self needPerformKeyEquivalent:theEvent];
  } else {
    perform = NO;
  }
  if (_needTrap && !_block && !perform) {
    _block = YES;
    [self sendEvent:theEvent];
    _block = NO;
    return YES;
  }
  return [super performKeyEquivalent:theEvent];
}

- (void)sendEvent:(NSEvent *)theEvent {
  if ([theEvent type] == NSKeyDown && _needTrap) {
    BOOL needProcess;
    if ([self delegate] && [[self delegate] respondsToSelector:@selector(trapWindow:needProceedKeyEvent:)])  {
      needProcess = [[self delegate] trapWindow:self needProceedKeyEvent:theEvent];
    } else {
      needProcess = NO;
    }
    if (!needProcess) {
      int code = [theEvent keyCode];
      int mask = [theEvent modifierFlags] & 0x00ff0000;
      unichar character = 0;
#if defined(DEBUG)
      NSLog(@"Code: %i, modifier: %i", code, mask);
      if (mask & NSNumericPadKeyMask)
        NSLog(@"NumericPad");
#endif
      if ([HKHotKeyManager isValidHotKeyCode:code withModifier:mask]) {
        character = HKUnicharForKeycode(code);
        if (kHKNilUnichar == character) {
          code = kHKNilVirtualKeyCode;
          mask = 0;
          NSBeep();
        }
      }
      else {
        mask = 0;
        character = kHKNilUnichar;
        code = kHKNilVirtualKeyCode;
        NSBeep();
#if defined(DEBUG)
        NSLog(@"Invalid Key");
#endif
      }
      id userInfo = [NSDictionary dictionaryWithObjectsAndKeys:
        [NSNumber numberWithUnsignedShort:code], kHKEventKeyCodeKey,
        [NSNumber numberWithUnsignedInt:mask], kHKEventModifierKey,
        [NSNumber numberWithUnsignedShort:character], kHKEventCharacterKey,
        nil];
      [[NSNotificationCenter defaultCenter] postNotificationName:kHKTrapWindowKeyCatchedNotification
                                                          object:self
                                                        userInfo:userInfo];
    } else { /* needProcess */
      [super sendEvent:theEvent];
    }
  } else { /* Not a KeyDown Event or not trapping */
    [super sendEvent:theEvent];
  }
}

@end
