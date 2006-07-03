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
  //  HKEventTarget target = {signature:'hook'};
//  CGEventSourceRef source = CGEventSourceCreate(kCGEventSourceStatePrivate);
//  HKEventPostKeystrokeToTarget(kVirtualRightArrowKey, 0, target, kHKEventTargetSignature, source);
//  CFRelease(source);
//  HKEventPostKeystroke(23, kCGEventFlagMaskCommand, NULL);
  NSApplicationMain(argc, argv);
  return 0;
}
