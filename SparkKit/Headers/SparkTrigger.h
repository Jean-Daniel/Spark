/*
 *  SparkTrigger.h
 *  SparkKit
 *
 *  Created by Grayfox on 04/07/06.
 *  Copyright 2006 Shadow Lab. All rights reserved.
 */

#import <SparkKit/SparkLibraryObject.h>

@interface SparkTrigger : SparkLibraryObject <NSCoding, NSCopying> {
  @private
  id sp_target;
  SEL sp_action;
  
  struct _sp_stFlags {
    unsigned int enabled:1;
    unsigned int reserved:31;
  } sp_stFlags;
}

- (id)target;
- (void)setTarget:(id)target;

- (SEL)action;
- (void)setAction:(SEL)action;

- (IBAction)trigger:(id)sender;
- (BOOL)setRegistred:(BOOL)flag;

@end
