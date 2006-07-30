/*
 *  SETriggersController.h
 *  Spark Editor
 *
 *  Created by Jean-Daniel Dupas on 07/07/06.
 *  Copyright 2006 Shadow Lab. All rights reserved.
 *
 */

#import <Cocoa/Cocoa.h>

@class SKOutlineView;
@class SparkApplication, SETriggerEntrySet;
@interface SETriggersController : NSObject {
  IBOutlet SKOutlineView *outline;
  @private
    NSMutableArray *se_plugins;
  SparkApplication *se_app;
  /* Internal storage */
  NSMapTable *se_entries;
  SETriggerEntrySet *se_defaults;
  SETriggerEntrySet *se_triggers;
}

- (SparkApplication *)application;
- (void)setApplication:(SparkApplication *)application;

@end

