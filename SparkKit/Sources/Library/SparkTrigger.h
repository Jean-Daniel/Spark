/*
 *  SparkTrigger.h
 *  SparkKit
 *
 *  Created by Black Moon Team.
 *  Copyright (c) 2004 - 2007 Shadow Lab. All rights reserved.
 */

#import <SparkKit/SparkObject.h>

SPARK_OBJC_EXPORT
@interface SparkTrigger : SparkObject <NSCoding, NSCopying>

- (BOOL)hasManyAction;
- (void)setHasSpecificAction:(BOOL)flag;

  /* To overwrite */
- (void)bypass;

- (BOOL)isRegistred;
- (BOOL)setRegistred:(BOOL)flag;

@property(nonatomic, readonly) NSString *triggerDescription;

/* Return YES only if the two trigger are equivalents */
- (BOOL)isEqualToTrigger:(SparkTrigger *)aTrigger;

@end

@class SparkEvent, SparkEntry;
@interface SparkTrigger (SparkEvent)

- (SparkEntry *)resolveEntry;

- (void)sendEvent:(SparkEvent *)anEvent;
- (void)sendEventWithTime:(CFAbsoluteTime)eventTime isARepeat:(BOOL)repeat;
- (void)sendEventWithEntry:(SparkEntry *)anEntry time:(CFAbsoluteTime)eventTime isARepeat:(BOOL)repeat;

@end
