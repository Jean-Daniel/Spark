//
//  HKHotKeyTestCase.m
//  HotKeyToolKit
//
//  Created by Grayfox on 10/10/04.
//  Copyright (c) 2004 Shadow Lab. All rights reserved.
//

#import "HKHotKeyTestCase.h"
#import <HotKeyToolKit/HotKeyToolKit.h>

@implementation HKHotKeyTestCase

- (void)setUp {
  _hotkey = [[HKHotKey alloc] init];
}

- (void)tearDown {
  [_hotkey release];
}

- (void)testHotKeyIsValid {
  [_hotkey setCharacter:kHKNilUnichar];
  STAssertFalse([_hotkey isValid], @"Hotkey %@ shouldn't be valid", _hotkey);
  
  [_hotkey setKeycode:kHKNilVirtualKeyCode];
  STAssertFalse([_hotkey isValid], @"Hotkey %@ shouldn't be valid", _hotkey);
  
  [_hotkey setCharacter:'a'];
  STAssertTrue([_hotkey isValid], @"Hotkey %@ should be valid", _hotkey);
  
  [_hotkey setKeycode:0];
  STAssertTrue([_hotkey isValid], @"Hotkey %@ should be valid", _hotkey);
}

- (void)testKeycodeCharacterDepedencies {
  [_hotkey setCharacter:kHKNilUnichar];
  STAssertEquals([_hotkey keycode], kHKNilVirtualKeyCode, @"%@ keycode should be kHKNilVirtualKeyCode", _hotkey);
  
  [_hotkey setKeycode:kHKNilVirtualKeyCode];
  STAssertEquals([_hotkey character], kHKNilUnichar, @"%@ character should be kHKNilUnichar", _hotkey);
}

- (void)testHotKeyRetainCount {
  id key = [[HKHotKey alloc] initWithUnichar:'a' modifier:NSAlternateKeyMask];
  STAssertTrue([key setRegistred:YES], @"%a should be registred", key);
  STAssertEquals([key retainCount], (unsigned)1, @"Registring key shouldn't retain it");
  
  id key2 = [[HKHotKey alloc] initWithUnichar:'a' modifier:NSAlternateKeyMask];
  STAssertFalse([key2 setRegistred:YES], @"%a shouldn't be registred", key2);
  [key release];/* Testing if releasing a key unregister it */
  STAssertTrue([key2 setRegistred:YES], @"%a should be registred", key2);
  [key2 release];
}

- (void)testInvalidAccessException {
  id key = [[HKHotKey alloc] initWithUnichar:'a' modifier:NSAlternateKeyMask];
  STAssertTrue([key setRegistred:YES], @"%a should be registred", key);
  STAssertThrows([key setCharacter:'b'], @"Should throws exception when trying change and registred");
  STAssertThrows([key setKeycode:0], @"Should throws exception when trying change and registred");
  STAssertThrows([key setModifier:NSAlternateKeyMask], @"Should throws exception when trying change and registred");
  STAssertTrue([key setRegistred:NO], @"%a should be unregistred", key);
  [key release];
}

- (void)testEqualsKeyRegistring {
  id key1 = [[HKHotKey alloc] initWithUnichar:'a' modifier:NSAlternateKeyMask];
  id key2 = [[HKHotKey alloc] initWithUnichar:'a' modifier:NSAlternateKeyMask];
  STAssertTrue([key1 setRegistred:YES], @"%a should be registred", key1);
  STAssertFalse([key2 setRegistred:YES], @"%a shouldn't be registred", key2);
  
  [key2 setModifier:NSShiftKeyMask];
  STAssertTrue([key2 setRegistred:YES], @"%a should be registred", key2);
  STAssertTrue([key2 setRegistred:NO], @"%a should be unregistred", key2);
  
  [key1 release];
  [key2 release];
}

@end
