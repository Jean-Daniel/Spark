/*
 *  TextAction.m
 *  Spark Plugins
 *
 *  Created by Black Moon Team.
 *  Copyright (c) 2004 - 2007, Shadow Lab. All rights reserved.
 */

#import "TextAction.h"

#import <HotKeyToolKit/HotKeyToolKit.h>

@implementation TextAction

- (id)copyWithZone:(NSZone *)aZone {
  TextAction *copy = [super copyWithZone:aZone];
  copy->ta_str = [ta_str copy];
  return copy;
}

- (BOOL)serialize:(NSMutableDictionary *)plist {
  if ([super serialize:plist]) {
    if (ta_str)
      [plist setObject:ta_str forKey:@"text"];
    return YES;
  }
  return NO;
}

- (id)initWithSerializedValues:(NSDictionary *)plist {
  if (self = [super initWithSerializedValues:plist]) {
    [self setString:[plist objectForKey:@"text"]];
  }
  return self;
}

- (void)dealloc {
  [ta_str release];
  [super dealloc];
}

#pragma mark -
- (SparkAlert *)performAction {
  if (ta_str) {
    CGEventSourceRef src = HKEventCreatePrivateSource();
    for (NSUInteger idx = 0; idx < [ta_str length]; idx++) {
      HKEventPostCharacterKeystrokes([ta_str characterAtIndex:idx], src);
    }
    if (src)
      CFRelease(src);
  }
  return nil;
}

- (BOOL)shouldSaveIcon {
  return NO;
}

#pragma mark -
- (NSString *)string {
  return ta_str;
}

- (void)setString:(NSString *)aString {
  SKSetterRetain(ta_str, aString);
}

@end
