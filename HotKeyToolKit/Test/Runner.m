/*
 *  Runner.m
 *  HotKeyToolKit
 *
 *  Created by Grayfox on 01/07/06.
 *  Copyright 2006 Shadow Lab. All rights reserved.
 */

#import <HotKeyToolKit/HotKeyToolKit.h>
#include <unistd.h>
@interface KeyDelegate : NSObject {
}
@end

@implementation KeyDelegate

- (void)awakeFromNib {
  HKHotKey *key = [[HKHotKey alloc] initWithKeycode:23 modifier:NSCommandKeyMask];
  [key setRegistred:YES];
  [key setTarget:self];
  [key setAction:@selector(coucou:)];
}

- (IBAction)coucou:(id)sender {
  ShadowTrace();
//  [sender setRegistred:NO];
//  usleep(75000);
  [sender sendKeystroke];
  
//  [sender setRegistred:YES];
}

@end

int main(int argc, const char **argv) {
  HKKeycode keycode = HKMapGetKeycodeAndModifierForUnichar('n', NULL, NULL);
  UniChar character = 0x00D1; /* 'Ñ' */
  HKKeycode keycodes[8];
  HKModifier modifiers[8];
  NSUInteger count = HKMapGetKeycodesAndModifiersForUnichar(character, keycodes, modifiers, 8);
//  STAssertTrue(count == 2, @"Invalid keys count (%d) for reverse mapping", count);
//  
//  STAssertTrue(keycodes[0] == keycode, @"Invalid modifier for tilde");
//  STAssertTrue(modifiers[0] == kCGEventFlagMaskAlternate, @"Invalid modifier for tilde");
//  
//  STAssertTrue(keycodes[1] == keycode, @"Invalid modifier for tilde");
//  STAssertTrue(modifiers[1] == kCGEventFlagMaskShift, @"Invalid modifier for tilde");
  NSApplicationMain(argc, argv);
  return 0;
}
