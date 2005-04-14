//
//  MyHotKeySet.m
//  MySparkHotKey
//
//  Created by JD on Sat Mar 20 2004.
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//

#import "MyHotKeySet.h"
#import "MyHotKey.h"

@implementation MyHotKeySet

- (void)setHotKey:(id)key {
  [super setHotKey:key]; // => set name, icon and hotkey. Must be called.
  [self setBeepCount:[key beepCount]];
}

- (NSAlert *)controllerShouldConfigKey {
  // Here we check if user has correctly set MyHotKey parameters. Icon can be nil and name is checked later, so you can set it on -configHotKey.
  if (beepCount < 1 || beepCount > 9) {
    return [NSAlert alertWithMessageText:@"Beep Count is not valid"
                           defaultButton:@"OK"
                         alternateButton:nil
                             otherButton:nil
               informativeTextWithFormat:@"Beep Count must be more than 0 and less than 10."];
  }
  return nil;
}

- (void)configHotKey {
  // super configHotKey set hotKey Name with [self name] and hotKey icon with [self icon]
  // If you want to use custom name and custom icon, you can avoid call it.
  [super configHotKey];
  MyHotKey *hotKey = [self hotKey];
  // no need to check beepCount value here. -configHotKey is called only if -controllerShouldConfigKey: return nil.
  [hotKey setBeepCount:beepCount];
}

- (int)beepCount {
  return beepCount;
}
- (void)setBeepCount:(int)newBeepCount {
  beepCount = newBeepCount;
}

@end
