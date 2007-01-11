/*
 *  SparkTrigger.h
 *  SparkKit
 *
 *  Created by Black Moon Team.
 *  Copyright (c) 2004 - 2006 Shadow Lab. All rights reserved.
 *
 */

#import <SparkKit/SparkObject.h>

@class SparkAction;
@interface SparkTrigger : SparkObject <NSCoding, NSCopying> {
  @private
  id sp_target;
  SEL sp_action;
  
  struct _sp_stFlags {
    unsigned int repeat:1;
    unsigned int overwrite:1;
    unsigned int reserved:30;
  } sp_stFlags;
}

+ (SparkAction *)currentAction;

- (id)target;
- (void)setTarget:(id)target;

- (SEL)action;
- (void)setAction:(SEL)action;

- (BOOL)hasManyAction;
- (void)setHasManyAction:(BOOL)flag;

- (IBAction)trigger:(id)sender;

  /* To override */
- (void)bypass;
- (BOOL)isRegistred;
- (BOOL)setRegistred:(BOOL)flag;
- (NSString *)triggerDescription;

/* Current event support */
- (BOOL)isARepeat;
- (NSTimeInterval)eventTime;

/* Optional */
- (void)willTriggerAction:(SparkAction *)anAction;
- (void)didTriggerAction:(SparkAction *)anAction;

/* Return YES only if the two trigger are equivalents */
- (BOOL)isEqualToTrigger:(SparkTrigger *)aTrigger;

/* Convenient setters */
- (void)setIsARepeat:(BOOL)flag;
@end
