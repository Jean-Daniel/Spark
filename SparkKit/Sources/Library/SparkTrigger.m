/*
 *  SparkTrigger.m
 *  SparkKit
 *
 *  Created by Black Moon Team.
 *  Copyright (c) 2004 - 2006 Shadow Lab. All rights reserved.
 *
 */

#import <SparkKit/SparkTrigger.h>

@implementation SparkTrigger

#pragma mark Copying
- (id)copyWithZone:(NSZone *)aZone {
  SparkTrigger *copy = [super copyWithZone:aZone];
  return copy;
}

#pragma mark Coding
- (void)encodeWithCoder:(NSCoder *)aCoder {
  [super encodeWithCoder:aCoder];
  [aCoder encodeInt:sp_stFlags.enabled forKey:@"STEnabled"];
}
- (id)initWithCoder:(NSCoder *)aDecoder {
  if (self = [super initWithCoder:aDecoder]) {
    SKSetFlag(sp_stFlags.enabled, [aDecoder decodeIntForKey:@"STEnabled"]);
  }
  return self;
}

- (BOOL)serialize:(NSMutableDictionary *)plist {
  [super serialize:plist];
  [plist setObject:SKBool(sp_stFlags.enabled) forKey:@"STEnabled"];
  return YES;
}

- (id)initWithSerializedValues:(NSDictionary *)plist {
  if (self = [super initWithSerializedValues:plist]) {
    sp_stFlags.enabled = [[plist objectForKey:@"STEnabled"] boolValue] ? 1 : 0;
  }
  return self;
}

#pragma mark Implementation
- (id)target {
  return sp_target;
}
- (void)setTarget:(id)target {
  sp_target = target;
}

- (SEL)action {
  return sp_action;
}
- (void)setAction:(SEL)action {
  sp_action = action;
}

- (BOOL)isEnabled {
  return sp_stFlags.enabled;
}
- (void)setEnabled:(BOOL)flag {
  SKSetFlag(sp_stFlags.enabled, flag);
}

- (NSString *)triggerDescription {
  return @"<trigger>";
}

- (IBAction)trigger:(id)sender {
  if ([sp_target respondsToSelector:sp_action]) {
    [sp_target performSelector:sp_action withObject:self];
  } else {
    NSBeep();
  }
}

- (BOOL)isEqualToTrigger:(SparkTrigger *)aTrigger {
  return [self isEqual:aTrigger];
}

- (BOOL)setRegistred:(BOOL)flag {
  return NO;
}

@end
