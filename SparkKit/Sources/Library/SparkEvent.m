//
//  SparkEvent.m
//  SparkKit
//
//  Created by Jean-Daniel Dupas on 22/10/08.
//  Copyright 2008 Ninsight. All rights reserved.
//

#import <SparkKit/SparkEvent.h>
#import <SparkKit/SparkEntry.h>

@implementation SparkEvent {
  id sp_data;

  struct _sp_evFlags {
    unsigned int type:2;
    unsigned int repeat:1;
    unsigned int reserved:5;
  } sp_evFlags;
  NSTimeInterval sp_time;
}

static NSString * const SparkCurrentEventKey = @"SparkCurrentEventKey";

+ (SparkEvent *)currentEvent {
  NSMutableDictionary *dict = [[NSThread currentThread] threadDictionary];
  return [dict objectForKey:SparkCurrentEventKey];
}

+ (void)setCurrentEvent:(SparkEvent *)anEvent {
  NSMutableDictionary *dict = [[NSThread currentThread] threadDictionary];
  if (anEvent)
    [dict setObject:anEvent forKey:SparkCurrentEventKey];
  else
    [dict removeObjectForKey:SparkCurrentEventKey];
}

+ (instancetype)eventWithEntry:(SparkEntry *)anEntry
                     eventTime:(NSTimeInterval)theEventTime isARepeat:(BOOL)isRepeat {
  return [[self alloc] initWithEntry:anEntry eventTime:theEventTime isARepeat:isRepeat];
}

+ (instancetype)eventWithTrigger:(SparkTrigger *)aTrigger
                       eventTime:(NSTimeInterval)theEventTime isARepeat:(BOOL)isRepeat {
  return [[self alloc] initWithTrigger:aTrigger eventTime:theEventTime isARepeat:isRepeat];
}

- (instancetype)initWithData:(id)anObject
                   eventTime:(NSTimeInterval)theEventTime isARepeat:(BOOL)isRepeat {
  if (self = [super init]) {
    sp_time = theEventTime;
    sp_data = anObject;
    sp_evFlags.repeat = isRepeat;
  }
  return self;  
}

- (instancetype)initWithEntry:(SparkEntry *)anEntry
                    eventTime:(NSTimeInterval)theEventTime isARepeat:(BOOL)isRepeat {
  if (self = [self initWithData:anEntry eventTime:theEventTime isARepeat:isRepeat]) {
    sp_evFlags.type = kSparkEventTypeEntry;
  }
  return self;
}
- (instancetype)initWithTrigger:(SparkTrigger *)aTrigger
                      eventTime:(NSTimeInterval)theEventTime isARepeat:(BOOL)isRepeat {
  if (self = [self initWithData:aTrigger eventTime:theEventTime isARepeat:isRepeat]) {
    sp_evFlags.type = kSparkEventTypeBypass;
  }
  return self;
}

- (NSString *)description {
  return [NSString stringWithFormat:@"<%@ %p> { type: %lu, time: %f, repeat: %@}",
          [self class], self,
          (long)self.type, sp_time, self.isARepeat ? @"YES" : @"NO"];
}

#pragma mark -
- (SparkEventType)type {
  return sp_evFlags.type;
}
- (SparkEntry *)entry {
  return sp_evFlags.type == kSparkEventTypeEntry ? sp_data : nil;
}
- (SparkTrigger *)trigger {
  return sp_evFlags.type == kSparkEventTypeEntry ? self.entry.trigger : sp_data;
}

- (BOOL)isARepeat {
  return sp_evFlags.repeat;
}
- (NSTimeInterval)eventTime {
  return sp_time;
}

#pragma mark -
static void(^sHandler)(id);

+ (void)sendEvent:(SparkEvent *)anEvent {
  @try {
    sHandler(anEvent);
  } @catch (id exception) {
    SPXLogException(exception);
  }
}
+ (void)setEventHandler:(nullable void(^)(SparkEvent *))handler {
  sHandler = handler;
}

@end
