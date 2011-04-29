/*
 *  HKKeyMapTestCase.m
 *  HotKeyToolKit
 *
 *  Created by Jean-Daniel Dupas.
 *  Copyright © 2004 - 2011 Shadow Lab. All rights reserved.
 */

#import "HKKeyMapTestCase.h"
#import <HotKeyToolKit/HotKeyToolKit.h>

@implementation HKKeyMapTestCase

- (void)setUp {
  /* Load the key Map */
  GHAssertNotNil(HKMapGetCurrentMapName(), @"Error while loading keymap");
}

- (void)tearDown {

}

- (void)testDeadKeyRepresentation {
  UInt32 keycode = 33; // ^ key on french keyboard
  UniChar chr = HKMapGetUnicharForKeycode(keycode);
  GHAssertTrue('^' == chr, @"HKMapGetUnicharForKeycode return '%C' (0x%x) instead of '^'", chr, chr);
  
  keycode = 42; // ` key on french keyboard
  chr = HKMapGetUnicharForKeycode(keycode);
  GHAssertTrue('`' == chr, @"HKMapGetUnicharForKeycode return '%C' (0x%x) instead of '`'", chr, chr);
  
  keycode = kHKVirtualSpaceKey; 
  chr = HKMapGetUnicharForKeycode(keycode);
  GHAssertTrue(' ' == chr, @"HKMapGetUnicharForKeycode return '%C' (0x%x) instead of ' '", chr, chr);
}

- (void)testMapping {
  UniChar uchr = HKMapGetUnicharForKeycode(0);
  GHAssertTrue(uchr == 'q', @"mapping does not work");
  
  uchr = HKMapGetUnicharForKeycodeAndModifier(0, kCGEventFlagMaskShift);
  GHAssertTrue(uchr == 'Q', @"mapping does not work");
}

- (void)testReverseMapping {
  UniChar character = 's';
  HKKeycode keycode = HKMapGetKeycodeAndModifierForUnichar(character, NULL);
  GHAssertTrue(keycode != kHKInvalidVirtualKeyCode, @"Reverse mapping does not work");
  
  UniChar reverseChar = HKMapGetUnicharForKeycode(keycode);
  GHAssertTrue(reverseChar != kHKNilUnichar, @"Reverse mapping does not work");
  GHAssertTrue(reverseChar == character, @"Reverse mapping does not work");
  
  HKKeycode keycode2 = HKMapGetKeycodeAndModifierForUnichar('S', NULL);
  GHAssertTrue(keycode == keycode2, @"'s'(%d) and 'S'(%d) should have same keycode", keycode, keycode2);
  
  HKModifier modifier;
  HKKeycode scode = HKMapGetKeycodeAndModifierForUnichar('S', &modifier);
  GHAssertTrue(scode == keycode, @"Invalid keycode for reverse mapping");
  GHAssertTrue(modifier == NSShiftKeyMask, @"Invalid modifier for reverse mapping");

  keycode = HKMapGetKeycodeAndModifierForUnichar('^', NULL);
  GHAssertTrue(keycode != kHKInvalidVirtualKeyCode, @"'^'unichar to deadkey does not return a valid keycode");
  
  keycode = HKMapGetKeycodeAndModifierForUnichar(' ', NULL);
  GHAssertTrue(kHKVirtualSpaceKey == keycode, @"'space' mapping does not works");

  /* no break space */
  keycode = HKMapGetKeycodeAndModifierForUnichar(0xa0, NULL);
  GHAssertTrue(kHKVirtualSpaceKey == keycode, @"'no break space' mapping does not works");
}

- (void)testAdvancedReverseMapping {
  HKKeycode keycode = HKMapGetKeycodeAndModifierForUnichar('n', NULL);
  UniChar character = 0x00D1; /* 'Ñ' */
  HKKeycode keycodes[8];
  HKModifier modifiers[8];
  NSUInteger count = HKMapGetKeycodesAndModifiersForUnichar(character, keycodes, modifiers, 8);
  GHAssertTrue(count == 2, @"Invalid keys count (%d) for reverse mapping", count);
  
  GHAssertTrue(keycodes[0] == keycode, @"Invalid modifier for tilde");
  GHAssertTrue(modifiers[0] == kCGEventFlagMaskAlternate, @"Invalid modifier for tilde");
  
  GHAssertTrue(keycodes[1] == keycode, @"Invalid modifier for tilde");
  GHAssertTrue(modifiers[1] == kCGEventFlagMaskShift, @"Invalid modifier for tilde");
}

@end
