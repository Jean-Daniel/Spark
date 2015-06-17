//
//  SparkEvent.h
//  SparkKit
//
//  Created by Jean-Daniel Dupas on 22/10/08.
//  Copyright 2008 Ninsight. All rights reserved.
//

#import <SparkKit/SparkKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, SparkEventType) {
  kSparkEventTypeEntry  = 0,
  kSparkEventTypeBypass = 1,
};

@class SparkEntry, SparkTrigger;

SPARK_OBJC_EXPORT
@interface SparkEvent : NSObject

+ (instancetype)eventWithEntry:(SparkEntry *)anEntry
                     eventTime:(NSTimeInterval)theEventTime isARepeat:(BOOL)isRepeat;
+ (instancetype)eventWithTrigger:(SparkTrigger *)aTrigger
                       eventTime:(NSTimeInterval)theEventTime isARepeat:(BOOL)isRepeat;

- (instancetype)initWithEntry:(SparkEntry *)anEntry
                    eventTime:(NSTimeInterval)theEventTime isARepeat:(BOOL)isRepeat;
- (instancetype)initWithTrigger:(SparkTrigger *)aTrigger
                      eventTime:(NSTimeInterval)theEventTime isARepeat:(BOOL)isRepeat;

@property(nonatomic, readonly) SparkEventType type;

@property(nonatomic, readonly, nullable) SparkEntry *entry;
@property(nonatomic, readonly, nullable) SparkTrigger *trigger;

@property(nonatomic, readonly) BOOL isARepeat;

@property(nonatomic, readonly) CFAbsoluteTime eventTime;

/* Current event */
+ (nullable SparkEvent *)currentEvent;
+ (void)setCurrentEvent:(nullable SparkEvent *)anEvent;

/* event dispatcher */
+ (void)sendEvent:(SparkEvent *)anEvent;

+ (void)setEventHandler:(nullable void(^)(SparkEvent *))handler;

@end

NS_ASSUME_NONNULL_END
