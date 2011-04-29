/*
 *  HKHotKeyTestCase.m
 *  HotKeyToolKit
 *
 *  Created by Jean-Daniel Dupas.
 *  Copyright © 2004 - 2011 Shadow Lab. All rights reserved.
 */

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
  GHAssertFalse([_hotkey isValid], @"Hotkey %@ shouldn't be valid", _hotkey);
  
  [_hotkey setKeycode:kHKInvalidVirtualKeyCode];
  GHAssertFalse([_hotkey isValid], @"Hotkey %@ shouldn't be valid", _hotkey);
  
  [_hotkey setCharacter:'a'];
  GHAssertTrue([_hotkey isValid], @"Hotkey %@ should be valid", _hotkey);
  
  [_hotkey setKeycode:0];
  GHAssertTrue([_hotkey isValid], @"Hotkey %@ should be valid", _hotkey);
}

- (void)testKeycodeCharacterDepedencies {
  [_hotkey setCharacter:kHKNilUnichar];
  GHAssertTrue([_hotkey keycode] == kHKInvalidVirtualKeyCode, @"%@ keycode should be kHKInvalidVirtualKeyCode", _hotkey);
  
  [_hotkey setKeycode:kHKInvalidVirtualKeyCode];
  GHAssertTrue([_hotkey character] == kHKNilUnichar, @"%@ character should be kHKNilUnichar", _hotkey);
}

- (void)testHotKeyRetainCount {
  id key = [[HKHotKey alloc] initWithUnichar:'y' modifier:NSAlternateKeyMask];
  GHAssertTrue([key setRegistred:YES], @"%@ should be registred", key);
  /* this test can be innacurate as autorelease will bump the retain count */ 
  GHAssertTrue([key retainCount] == (unsigned)1, @"Registring key shouldn't retain it");
  
  id key2 = [[HKHotKey alloc] initWithUnichar:'y' modifier:NSAlternateKeyMask];
  GHAssertFalse([key2 setRegistred:YES], @"%@ shouldn't be registred", key2);
  [key release];/* Testing if releasing a key unregister it */
  GHAssertTrue([key2 setRegistred:YES], @"%@ should registre", key2);
  // Cleanup
  GHAssertTrue([key2 setRegistred:NO], @"%@ should be registred", key2);
  [key2 release];
}

- (void)testInvalidAccessException {
  id key = [[HKHotKey alloc] initWithUnichar:'a' modifier:NSAlternateKeyMask];
  GHAssertTrue([key setRegistred:YES], @"%@ should be registred", key);
  GHAssertThrows([key setCharacter:'b'], @"Should throws exception when trying change and registred");
  GHAssertThrows([key setKeycode:0], @"Should throws exception when trying change and registred");
  GHAssertThrows([key setModifier:NSAlternateKeyMask], @"Should throws exception when trying change and registred");
  GHAssertTrue([key setRegistred:NO], @"%@ should be unregistred", key);
  [key release];
}

- (void)testEqualsKeyRegistring {
  id key1 = [[HKHotKey alloc] initWithUnichar:'a' modifier:NSAlternateKeyMask];
  id key2 = [[HKHotKey alloc] initWithUnichar:'a' modifier:NSAlternateKeyMask];
  GHAssertTrue([key1 setRegistred:YES], @"%@ should be registred", key1);
  GHAssertFalse([key2 setRegistred:YES], @"%@ shouldn't be registred", key2);
  
  [key2 setModifier:NSShiftKeyMask];
  GHAssertTrue([key2 setRegistred:YES], @"%@ should be registred", key2);
  GHAssertTrue([key2 setRegistred:NO], @"%@ should be unregistred", key2);
  GHAssertTrue([key1 setRegistred:NO], @"%@ should be unregistred", key1);
  
  [key1 release];
  [key2 release];
}

- (void)testReapeatInterval {
  NSTimeInterval inter = HKGetSystemKeyRepeatInterval();
  GHAssertTrue(inter > 0, @"Cannot retreive repeat interval");
  inter = HKGetSystemInitialKeyRepeatInterval();
  GHAssertTrue(inter > 0, @"Cannot retreive initial repeat interval");
}

@end
