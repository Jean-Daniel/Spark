/*
 *  SparkTrigger.m
 *  SparkKit
 *
 *  Created by Black Moon Team.
 *  Copyright (c) 2004 - 2007 Shadow Lab. All rights reserved.
 */

#import "SparkPrivate.h"
#import <SparkKit/SparkTrigger.h>

#import <SparkKit/SparkEvent.h>
#import <SparkKit/SparkEntry.h>
#import <SparkKit/SparkAction.h>
#import <SparkKit/SparkLibrary.h>
#import <SparkKit/SparkEntryManager.h>

@implementation SparkTrigger {
@private
  struct _sp_stFlags {
    unsigned int overwrite:1;
    unsigned int reserved:15;
  } sp_stFlags;
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

- (NSComparisonResult)compare:(SparkTrigger *)aTrigger {
  return [[self triggerDescription] caseInsensitiveCompare:[aTrigger triggerDescription]];
}

#pragma mark Implementation
- (BOOL)hasManyAction {
  return sp_stFlags.overwrite;
}
- (void)setHasSpecificAction:(BOOL)flag {
  SPXFlagSet(sp_stFlags.overwrite, flag);
}

- (NSString *)triggerDescription {
  return @"<trigger>";
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

@end

#pragma mark -
@implementation SparkTrigger (SparkEvent)

- (SparkEntry *)resolveEntry {
  SparkApplication *front = nil;
  
  SparkLibrary *library = [self library];
  SparkEntryManager *manager = [[self library] entryManager];
  /* If action depends front application */
  if ([self hasManyAction])
    front = [library frontmostApplication];
  
  if (!front) front = [library systemApplication];
  return [manager resolveEntryForTrigger:self application:front];
}

- (void)sendEvent:(SparkEvent *)anEvent {
  [SparkEvent sendEvent:anEvent];
}

- (void)sendEventWithTime:(NSTimeInterval)eventTime isARepeat:(BOOL)repeat {
  [self sendEventWithEntry:[self resolveEntry] time:eventTime isARepeat:repeat];
}

- (void)sendEventWithEntry:(SparkEntry *)anEntry time:(NSTimeInterval)eventTime isARepeat:(BOOL)repeat {
  SparkEvent *evnt;
  if (anEntry) {
    // create and dispatch spark event
    evnt = [SparkEvent eventWithEntry:anEntry eventTime:eventTime isARepeat:repeat];
  } else {
    evnt = [SparkEvent eventWithTrigger:self eventTime:eventTime isARepeat:repeat];
  }
  [self sendEvent:evnt];
}

@end
