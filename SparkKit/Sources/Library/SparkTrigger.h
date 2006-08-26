/*
 *  SparkTrigger.h
 *  SparkKit
 *
 *  Created by Black Moon Team.
 *  Copyright (c) 2004 - 2006 Shadow Lab. All rights reserved.
 *
 */

#import <SparkKit/SparkObject.h>

@interface SparkTrigger : SparkObject <NSCoding, NSCopying> {
  @private
  id sp_target;
  SEL sp_action;
  
  struct _sp_stFlags {
    unsigned int enabled:1;
    unsigned int overwrite:1;
    unsigned int reserved:30;
  } sp_stFlags;
}

- (id)target;
- (void)setTarget:(id)target;

- (SEL)action;
- (void)setAction:(SEL)action;

- (BOOL)isEnabled;
- (void)setEnabled:(BOOL)flag;

- (IBAction)trigger:(id)sender;
/* To override */
- (BOOL)setRegistred:(BOOL)flag;
- (NSString *)triggerDescription;

/* Return YES only if the two trigger are equivalents */
- (BOOL)isEqualToTrigger:(SparkTrigger *)aTrigger;

@end
