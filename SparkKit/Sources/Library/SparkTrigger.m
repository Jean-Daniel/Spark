/*
 *  SparkTrigger.m
 *  SparkKit
 *
 *  Created by Black Moon Team.
 *  Copyright (c) 2004 - 2006 Shadow Lab. All rights reserved.
 *
 */

#import "SparkPrivate.h"
#import <SparkKit/SparkTrigger.h>

@implementation SparkTrigger

static SparkAction *sp_spAction = nil;
+ (SparkAction *)currentAction {
  return sp_spAction;
}

#pragma mark Copying
- (id)copyWithZone:(NSZone *)aZone {
  SparkTrigger *copy = [super copyWithZone:aZone];
  return copy;
}

#pragma mark Coding
- (void)encodeWithCoder:(NSCoder *)aCoder {
  [super encodeWithCoder:aCoder];
}
- (id)initWithCoder:(NSCoder *)aDecoder {
  if (self = [super initWithCoder:aDecoder]) {

  }
  return self;
}

- (BOOL)serialize:(NSMutableDictionary *)plist {
  [super serialize:plist];
  return YES;
}

- (id)initWithSerializedValues:(NSDictionary *)plist {
  if (self = [super initWithSerializedValues:plist]) {

  }
  return self;
}

- (void)dealloc {
  [super dealloc];
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

- (BOOL)hasManyAction {
  return sp_stFlags.overwrite;
}
- (void)setHasManyAction:(BOOL)flag {
  SKSetFlag(sp_stFlags.overwrite, flag);
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

- (void)bypass {
}
- (BOOL)isRegistred {
  return NO;
}
- (BOOL)setRegistred:(BOOL)flag {
  return NO;
}

- (BOOL)isARepeat {
  return sp_stFlags.repeat;
}
- (NSTimeInterval)eventTime {
  return [[NSApp currentEvent] timestamp];
}

- (void)setIsARepeat:(BOOL)flag {
  SKSetFlag(sp_stFlags.repeat, flag);
}

- (void)willTriggerAction:(SparkAction *)anAction {
  [SparkAction setCurrentTrigger:self];
  SKSetterRetain(sp_spAction, anAction);
}

- (void)didTriggerAction:(SparkAction *)anAction {
  [SparkAction setCurrentTrigger:nil];
}

@end
