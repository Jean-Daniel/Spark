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
}

- (void)testReverseMapping {
  UniChar character = 's';
  UInt32 keycode = HKMapGetKeycodeAndModifierForUnichar(character, NULL, NULL);
  STAssertTrue(keycode != kHKInvalidVirtualKeyCode, @"Reverse mapping does not work");
  
  UniChar reverseChar = HKMapGetUnicharForKeycode(keycode);
  STAssertTrue(reverseChar != kHKNilUnichar, @"Reverse mapping does not work");
  STAssertEquals(reverseChar, character, @"Reverse mapping does not work");
  
  UInt32 keycode2 = HKMapGetKeycodeAndModifierForUnichar('S', NULL, NULL);
  STAssertEquals(keycode, keycode2, @"'s' and 'S' should have same keycode");
  
  UInt32 modifier, count;
  UInt32 scode = HKMapGetKeycodeAndModifierForUnichar('S', &modifier, &count);
  STAssertTrue(count == 1, @"Invalid keys count for reverse mapping");
  STAssertTrue(scode == keycode, @"Invalid keycode for reverse mapping");
  STAssertTrue(modifier == NSShiftKeyMask, @"Invalid modifier for reverse mapping");
}

- (void)testAdvancedReverseMapping {
  UInt32 keycode = HKMapGetKeycodeAndModifierForUnichar('n', NULL, NULL);
  UniChar character = 0x00D1; /* 'Ñ' */
  UInt32 keycodes[8], modifiers[8];
  UInt32 count = HKMapGetKeycodesAndModifiersForUnichar(character, keycodes, modifiers, 8);
  STAssertTrue(count == 2, @"Invalid keys count for reverse mapping");
  
  STAssertTrue(keycodes[0] == keycode, @"Invalid modifier for tilde");
  STAssertTrue(modifiers[0] == kCGEventFlagMaskAlternate, @"Invalid modifier for tilde");
  
  STAssertTrue(keycodes[1] == keycode, @"Invalid modifier for tilde");
  STAssertTrue(modifiers[1] == kCGEventFlagMaskShift, @"Invalid modifier for tilde");
}

@end
