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
  STAssertNotNil(HKMapGetCurrentMapName(), @"Error while loading keymap"); /* Load the key Map */
}

- (void)tearDown {

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

@end
