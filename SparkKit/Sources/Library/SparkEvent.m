//
//  SparkEvent.m
//  SparkKit
//
//  Created by Jean-Daniel Dupas on 22/10/08.
//  Copyright 2008 Ninsight. All rights reserved.
//

#import <SparkKit/SparkEvent.h>

@implementation SparkEvent

static NSString * const SparkCurrentEventKey = @"SparkCurrentEventKey";
+ (SparkEvent *)currentEvent {
  NSMutableDictionary *dict = [[NSThread currentThread] threadDictionary];
  return [dict objectForKey:SparkCurrentEventKey];
}
+ (void)setCurrentEvent:(SparkEvent *)anEvent {
  NSMutableDictionary *dict = [[NSThread currentThread] threadDictionary];
  if (anEvent) [dict setObject:anEvent forKey:SparkCurrentEventKey];
  else [dict removeObjectForKey:SparkCurrentEventKey];
}

+ (id)eventWithEntry:(SparkEntry *)anEntry 
           eventTime:(NSTimeInterval)theEventTime isARepeat:(BOOL)isRepeat {
  return [[[self alloc] initWithEntry:anEntry eventTime:theEventTime isARepeat:isRepeat] autorelease];
}
+ (id)eventWithTrigger:(SparkTrigger *)aTrigger 
           eventTime:(NSTimeInterval)theEventTime isARepeat:(BOOL)isRepeat {
  return [[[self alloc] initWithTrigger:aTrigger eventTime:theEventTime isARepeat:isRepeat] autorelease];
}

- (id)initWithData:(id)anObject 
            eventTime:(NSTimeInterval)theEventTime isARepeat:(BOOL)isRepeat {
  if (self = [super init]) {
    sp_time = theEventTime;
    sp_data = [anObject retain];
    sp_evFlags.repeat = isRepeat;
  }
  return self;  
}

- (id)initWithEntry:(SparkEntry *)anEntry 
          eventTime:(NSTimeInterval)theEventTime isARepeat:(BOOL)isRepeat {
  if (self = [self initWithData:anEntry eventTime:theEventTime isARepeat:isRepeat]) {
    sp_evFlags.type = kSparkEventTypeEntry;
  }
  return self;
}
- (id)initWithTrigger:(SparkTrigger *)aTrigger 
          eventTime:(NSTimeInterval)theEventTime isARepeat:(BOOL)isRepeat {
  if (self = [self initWithData:aTrigger eventTime:theEventTime isARepeat:isRepeat]) {
    sp_evFlags.type = kSparkEventTypeBypass;
  }
  return self;
}

- (void)dealloc {
  [sp_data release];
  [super dealloc];
}

- (NSString *)description {
  return [NSString stringWithFormat:@"<%@ %p> { type: %lu, time: %f, repeat: %@}",
          [self class], self,
          (long)[self type], sp_time, [self isARepeat] ? @"YES" : @"NO"];
}

#pragma mark -
- (NSUInteger)type {
  return sp_evFlags.type;
}
- (SparkEntry *)entry {
  return sp_evFlags.type == kSparkEventTypeEntry ? sp_data : nil;
}
- (SparkTrigger *)trigger {
  return sp_evFlags.type == kSparkEventTypeEntry ? [[self entry] trigger] : sp_data;
}

- (BOOL)isARepeat {
  return sp_evFlags.repeat;
}
- (NSTimeInterval)eventTime {
  return sp_time;
}

#pragma mark -
static id sHandler = nil;
static SEL sHandlerAction = NULL;

+ (void)sendEvent:(SparkEvent *)anEvent {
  @try {
    [sHandler performSelector:sHandlerAction withObject:anEvent];
  } @catch (id exception) {
    SPXLogException(exception);
  }
}
+ (void)setEventHandler:(id)handler andSelector:(SEL)aSelector {
  sHandler = handler;
  sHandlerAction = aSelector;
}

@end
