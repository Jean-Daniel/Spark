//
//  HKKeyMapTestCase.m
//  HotKeyToolKit
//
//  Created by Grayfox on 11/10/04.
//  Copyright (c) 2004 Shadow Lab. All rights reserved.
//

#import "HKKeyMapTestCase.h"
#import <HotKeyToolKit/HotKeyToolKit.h>

@implementation HKKeyMapTestCase

- (void)setUp {
  /* Load the key Map */
  STAssertNotNil(HKMapGetCurrentMapName(), @"Error while loading keymap");
}

- (void)tearDown {

}

- (void)testDeadKeyRepresentation {
  UInt32 keycode = 33; // ^ key on french keyboard
  UniChar chr = HKMapGetUnicharForKeycode(keycode);
  STAssertTrue('^' == chr, @"HKMapGetUnicharForKeycode return '%C' (0x%x) instead of '^'", chr, chr);
  
  keycode = 42; // ` key on french keyboard
  chr = HKMapGetUnicharForKeycode(keycode);
  STAssertTrue('`' == chr, @"HKMapGetUnicharForKeycode return '%C' (0x%x) instead of '`'", chr, chr);
  
  keycode = kHKVirtualSpaceKey; 
  chr = HKMapGetUnicharForKeycode(keycode);
  STAssertTrue(' ' == chr, @"HKMapGetUnicharForKeycode return '%C' (0x%x) instead of ' '", chr, chr);
}

- (void)testReverseMapping {
  UniChar character = 's';
  HKKeycode keycode = HKMapGetKeycodeAndModifierForUnichar(character, NULL);
  STAssertTrue(keycode != kHKInvalidVirtualKeyCode, @"Reverse mapping does not work");
  
  UniChar reverseChar = HKMapGetUnicharForKeycode(keycode);
  STAssertTrue(reverseChar != kHKNilUnichar, @"Reverse mapping does not work");
  STAssertTrue(reverseChar == character, @"Reverse mapping does not work");
  
  HKKeycode keycode2 = HKMapGetKeycodeAndModifierForUnichar('S', NULL);
  STAssertTrue(keycode == keycode2, @"'s'(%d) and 'S'(%d) should have same keycode", keycode, keycode2);
  
  HKModifier modifier;
  HKKeycode scode = HKMapGetKeycodeAndModifierForUnichar('S', &modifier);
  STAssertTrue(scode == keycode, @"Invalid keycode for reverse mapping");
  STAssertTrue(modifier == NSShiftKeyMask, @"Invalid modifier for reverse mapping");

  keycode = HKMapGetKeycodeAndModifierForUnichar('^', NULL);
  STAssertTrue(keycode != kHKInvalidVirtualKeyCode, @"'^'unichar to deadkey does not return a valid keycode");
  
  keycode = HKMapGetKeycodeAndModifierForUnichar(' ', NULL);
  STAssertTrue(kHKVirtualSpaceKey == keycode, @"'space' mapping does not works");

  /* no break space */
  keycode = HKMapGetKeycodeAndModifierForUnichar(0xa0, NULL);
  STAssertTrue(kHKVirtualSpaceKey == keycode, @"'no break space' mapping does not works");
}

- (void)testAdvancedReverseMapping {
  HKKeycode keycode = HKMapGetKeycodeAndModifierForUnichar('n', NULL);
  UniChar character = 0x00D1; /* 'Ñ' */
  HKKeycode keycodes[8];
  HKModifier modifiers[8];
  NSUInteger count = HKMapGetKeycodesAndModifiersForUnichar(character, keycodes, modifiers, 8);
  STAssertTrue(count == 2, @"Invalid keys count (%d) for reverse mapping", count);
  
  STAssertTrue(keycodes[0] == keycode, @"Invalid modifier for tilde");
  STAssertTrue(modifiers[0] == kCGEventFlagMaskAlternate, @"Invalid modifier for tilde");
  
  STAssertTrue(keycodes[1] == keycode, @"Invalid modifier for tilde");
  STAssertTrue(modifiers[1] == kCGEventFlagMaskShift, @"Invalid modifier for tilde");
}

@end
