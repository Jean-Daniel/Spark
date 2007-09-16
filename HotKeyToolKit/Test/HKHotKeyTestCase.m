//
//  HKHotKeyTestCase.m
//  HotKeyToolKit
//
//  Created by Grayfox on 10/10/04.
//  Copyright (c) 2004 Shadow Lab. All rights reserved.
//

#import "HKHotKeyTestCase.h"
#import <HotKeyToolKit/HotKeyToolKit.h>

@implementation HKHotKeyTests

- (void)setUp {
  _hotkey = [[HKHotKey alloc] init];
}

- (void)tearDown {
  [_hotkey release];
}

- (void)testHotKeyIsValid {
  [_hotkey setCharacter:kHKNilUnichar];
  STAssertFalse([_hotkey isValid], @"Hotkey %@ shouldn't be valid", _hotkey);
  
  [_hotkey setKeycode:kHKInvalidVirtualKeyCode];
  STAssertFalse([_hotkey isValid], @"Hotkey %@ shouldn't be valid", _hotkey);
  
  [_hotkey setCharacter:'a'];
  STAssertTrue([_hotkey isValid], @"Hotkey %@ should be valid", _hotkey);
  
  [_hotkey setKeycode:0];
  STAssertTrue([_hotkey isValid], @"Hotkey %@ should be valid", _hotkey);
}

- (void)testKeycodeCharacterDepedencies {
  [_hotkey setCharacter:kHKNilUnichar];
  STAssertTrue([_hotkey keycode] == kHKInvalidVirtualKeyCode, @"%@ keycode should be kHKInvalidVirtualKeyCode", _hotkey);
  
  [_hotkey setKeycode:kHKInvalidVirtualKeyCode];
  STAssertTrue([_hotkey character] == kHKNilUnichar, @"%@ character should be kHKNilUnichar", _hotkey);
}

- (void)testHotKeyRetainCount {
  id key = [[HKHotKey alloc] initWithUnichar:'y' modifier:NSAlternateKeyMask];
  STAssertTrue([key setRegistred:YES], @"%@ should be registred", key);
  /* this test can be innacurate as autorelease will bump the retain count */ 
  STAssertTrue([key retainCount] == (unsigned)1, @"Registring key shouldn't retain it");
  
  id key2 = [[HKHotKey alloc] initWithUnichar:'y' modifier:NSAlternateKeyMask];
  STAssertFalse([key2 setRegistred:YES], @"%@ shouldn't be registred", key2);
  [key release];/* Testing if releasing a key unregister it */
  STAssertTrue([key2 setRegistred:YES], @"%@ should be registred", key2);
  [key2 release];
}

- (void)testInvalidAccessException {
  id key = [[HKHotKey alloc] initWithUnichar:'a' modifier:NSAlternateKeyMask];
  STAssertTrue([key setRegistred:YES], @"%@ should be registred", key);
  STAssertThrows([key setCharacter:'b'], @"Should throws exception when trying change and registred");
  STAssertThrows([key setKeycode:0], @"Should throws exception when trying change and registred");
  STAssertThrows([key setModifier:NSAlternateKeyMask], @"Should throws exception when trying change and registred");
  STAssertTrue([key setRegistred:NO], @"%@ should be unregistred", key);
  [key release];
}

- (void)testEqualsKeyRegistring {
  id key1 = [[HKHotKey alloc] initWithUnichar:'a' modifier:NSAlternateKeyMask];
  id key2 = [[HKHotKey alloc] initWithUnichar:'a' modifier:NSAlternateKeyMask];
  STAssertTrue([key1 setRegistred:YES], @"%@ should be registred", key1);
  STAssertFalse([key2 setRegistred:YES], @"%@ shouldn't be registred", key2);
  
  [key2 setModifier:NSShiftKeyMask];
  STAssertTrue([key2 setRegistred:YES], @"%@ should be registred", key2);
  STAssertTrue([key2 setRegistred:NO], @"%@ should be unregistred", key2);
  STAssertTrue([key1 setRegistred:NO], @"%@ should be unregistred", key1);
  
  [key1 release];
  [key2 release];
}

- (void)testReapeatInterval {
  NSTimeInterval inter = HKGetSystemKeyRepeatInterval();
  STAssertTrue(inter > 0, @"Cannot retreive repeat interval");
  inter = HKGetSystemInitialKeyRepeatInterval();
  STAssertTrue(inter > 0, @"Cannot retreive initial repeat interval");
}

@end
