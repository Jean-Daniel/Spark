/*
 *  SparkEntry.h
 *  SparkKit
 *
 *  Created by Black Moon Team.
 *  Copyright (c) 2004 - 2006 Shadow Lab. All rights reserved.
 */

#import <Cocoa/Cocoa.h>

@class SparkAction, SparkTrigger, SparkApplication;

@interface SparkEntry : NSObject <NSCopying> {
  @private
  SparkAction *sp_action;
  SparkTrigger *sp_trigger;
  SparkApplication *sp_application;
  
  struct _sp_seFlags {
    unsigned int enabled:1;
    unsigned int reserved:31;
  } sp_seFlags;
}

+ (id)entryWithAction:(SparkAction *)anAction trigger:(SparkTrigger *)aTrigger application:(SparkApplication *)anApplication;

- (id)initWithAction:(SparkAction *)anAction trigger:(SparkTrigger *)aTrigger application:(SparkApplication *)anApplication;

- (SparkAction *)action;
- (void)setAction:(SparkAction *)action;

- (id)trigger;
- (void)setTrigger:(SparkTrigger *)trigger;

- (SparkApplication *)application;
- (void)setApplication:(SparkApplication *)anApplication;

- (NSImage *)icon;
- (void)setIcon:(NSImage *)anIcon;

- (NSString *)name;
- (void)setName:(NSString *)aName;

- (NSString *)categorie;
- (NSString *)actionDescription;
- (NSString *)triggerDescription;

@end
