/*
 *  SparkTrigger.m
 *  SparkKit
 *
 *  Created by Black Moon Team.
 *  Copyright (c) 2004 - 2007 Shadow Lab. All rights reserved.
 */

#import "SparkPrivate.h"
#import <SparkKit/SparkTrigger.h>

#import <SparkKit/SparkEntry.h>
#import <SparkKit/SparkAction.h>
#import <SparkKit/SparkLibrary.h>
#import <SparkKit/SparkEntryManager.h>

@implementation SparkTrigger

static NSString * const SparkCurrentActionKey = @"SparkCurrentAction";
+ (SparkAction *)currentAction {
  NSMutableDictionary *dict = [[NSThread currentThread] threadDictionary];
  return [dict objectForKey:SparkCurrentActionKey];
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

- (NSComparisonResult)compare:(SparkTrigger *)aTrigger {
  return [[self triggerDescription] caseInsensitiveCompare:[aTrigger triggerDescription]];
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
- (void)setHasSpecificAction:(BOOL)flag {
  WBFlagSet(sp_stFlags.overwrite, flag);
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
//  if (XOR(flag, [self isRegistred])) {
//    /* Update attached actions */
//    SparkEntryManager *manager = [[self library] entryManager];
//    NSArray *entries = [manager entriesForTrigger:[self uid]];
//    NSUInteger idx = [entries count];
//    while (idx-- > 0) {
//      SparkEntry *entry = [entries objectAtIndex:idx];
//      if ([entry isActive] && XOR(flag, [[entry action] isRegistred])) {
//        [[entry action] setRegistred:flag];
//      } else if (!flag && [[entry action] isRegistred]) {
//        [[entry action] setRegistred:NO];
//      }
//    }
//  }
  return NO;
}

- (BOOL)isARepeat {
  return sp_stFlags.repeat;
}
- (NSTimeInterval)eventTime {
  return [[NSApp currentEvent] timestamp];
}

- (void)setIsARepeat:(BOOL)flag {
  WBFlagSet(sp_stFlags.repeat, flag);
}

- (void)willTriggerAction:(SparkAction *)anAction {
  [SparkAction setCurrentTrigger:self];
  [[[NSThread currentThread] threadDictionary] setValue:anAction forKey:SparkCurrentActionKey];
}

- (void)didTriggerAction:(SparkAction *)anAction {
  [[[NSThread currentThread] threadDictionary] removeObjectForKey:SparkCurrentActionKey];
  [SparkAction setCurrentTrigger:nil];
}

@end
