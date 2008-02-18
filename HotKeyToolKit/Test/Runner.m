/*
 *  Runner.m
 *  HotKeyToolKit
 *
 *  Created by Grayfox on 01/07/06.
 *  Copyright 2006 Shadow Lab. All rights reserved.
 */

#import "KeyMap.h"
#import <HotKeyToolKit/HotKeyToolKit.h>
#import <SenTestingKit/SenTestingKit.h>
#include <IOKit/hidsystem/event_status_driver.h>

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
  WBTrace();
//  [sender setRegistred:NO];
//  usleep(75000);
//  [sender sendKeystroke];
  
//  [sender setRegistred:YES];
}

@end

NSTimeInterval _HKGetSystemKeyRepeatInterval() {
  double value = 0;
  NXEventHandle handle = NXOpenEventStatus();
  if (handle) {
    value = NXKeyRepeatInterval(handle);
    NXCloseEventStatus(handle);
  }
  return value;
}

NSTimeInterval _HKGetSystemKeyRepeatThreshold() {
  double value = 0;
  NXEventHandle handle = NXOpenEventStatus();
  if (handle) {
    value = NXKeyRepeatThreshold(handle);
    NXCloseEventStatus(handle);
  }
  return value;
}

int main(int argc, const char **argv) {
  _HKGetSystemKeyRepeatInterval();
  HKGetSystemKeyRepeatInterval();
  //SenSelfTestMain();
//  id tests = [[NSClassFromString(@"HKHotKeyTests") alloc] init];
//  [tests performSelector:@selector(testEqualsKeyRegistring)];
//  [tests release];
  
//  NSApplicationMain(argc, argv);
  return 0;
}
