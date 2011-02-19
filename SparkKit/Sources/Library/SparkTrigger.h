/*
 *  SparkTrigger.h
 *  SparkKit
 *
 *  Created by Black Moon Team.
 *  Copyright (c) 2004 - 2007 Shadow Lab. All rights reserved.
 */

#import <SparkKit/SparkObject.h>

SPARK_OBJC_EXPORT
@interface SparkTrigger : SparkObject <NSCoding, NSCopying> {
  @private
  struct _sp_stFlags {
    unsigned int overwrite:1;
    unsigned int reserved:15;
  } sp_stFlags;
}

- (BOOL)hasManyAction;
- (void)setHasSpecificAction:(BOOL)flag;

  /* To overwrite */
- (void)bypass;
- (BOOL)isRegistred;
- (BOOL)setRegistred:(BOOL)flag;
- (NSString *)triggerDescription;

/* Return YES only if the two trigger are equivalents */
- (BOOL)isEqualToTrigger:(SparkTrigger *)aTrigger;

@end

@class SparkEvent, SparkEntry;
@interface SparkTrigger (SparkEvent)

- (SparkEntry *)resolveEntry;

- (void)sendEvent:(SparkEvent *)anEvent;
- (void)sendEventWithTime:(NSTimeInterval)eventTime isARepeat:(BOOL)repeat;
- (void)sendEventWithEntry:(SparkEntry *)anEntry time:(NSTimeInterval)eventTime isARepeat:(BOOL)repeat;

@end
