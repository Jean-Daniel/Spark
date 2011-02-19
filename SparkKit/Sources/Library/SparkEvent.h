//
//  SparkEvent.h
//  SparkKit
//
//  Created by Jean-Daniel Dupas on 22/10/08.
//  Copyright 2008 Ninsight. All rights reserved.
//

#import <SparkKit/SparkKit.h>

enum {
  kSparkEventTypeEntry  = 0,
  kSparkEventTypeBypass = 1,
};

@class SparkEntry, SparkTrigger;
SPARK_OBJC_EXPORT
@interface SparkEvent : NSObject {
  id sp_data;
  
  struct _sp_evFlags {
    unsigned int type:2;
    unsigned int repeat:1;
    unsigned int reserved:5;
  } sp_evFlags;
  NSTimeInterval sp_time;
}

+ (id)eventWithEntry:(SparkEntry *)anEntry 
           eventTime:(NSTimeInterval)theEventTime isARepeat:(BOOL)isRepeat;
+ (id)eventWithTrigger:(SparkTrigger *)aTrigger 
             eventTime:(NSTimeInterval)theEventTime isARepeat:(BOOL)isRepeat;

- (id)initWithEntry:(SparkEntry *)anEntry 
          eventTime:(NSTimeInterval)theEventTime isARepeat:(BOOL)isRepeat;
- (id)initWithTrigger:(SparkTrigger *)aTrigger 
            eventTime:(NSTimeInterval)theEventTime isARepeat:(BOOL)isRepeat;

- (NSUInteger)type;

- (SparkEntry *)entry;
- (SparkTrigger *)trigger;

- (BOOL)isARepeat;
- (NSTimeInterval)eventTime;

/* Current event */
+ (SparkEvent *)currentEvent;
+ (void)setCurrentEvent:(SparkEvent *)anEvent;

/* event dispatcher */
+ (void)sendEvent:(SparkEvent *)anEvent;
+ (void)setEventHandler:(id)handler andSelector:(SEL)aSelector;

@end

