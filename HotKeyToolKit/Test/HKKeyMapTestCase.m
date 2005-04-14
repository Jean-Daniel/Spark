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

+ (void)initialize {
  HKUseFullKeyMap = YES;
}

- (void)setUp {
  STAssertNotNil(HKCurrentKeyMapName(), @"Error while loading keymap"); /* Load the key Map */
}

- (void)tearDown {

}

- (void)testReverseMapping {
  unichar character = 'a';
  CGKeyCode keycode = HKKeycodeForUnichar(character);
  unichar reverseChar = HKUnicharForKeycode(keycode);
  STAssertEquals(character, reverseChar, @"%i != %i", character, reverseChar);
  
  CGKeyCode keycode2 = HKKeycodeForUnichar('A');
  STAssertEquals(keycode, keycode2, @"Check if full mapping is enable", keycode, keycode2);
  
  unsigned int codes = HKKeycodeAndModifierForUnichar('A');
  STAssertEquals(codes & 0xffff0000, (unsigned)NSShiftKeyMask, @"Invalid Mask for reverse mapping");
}

@end
