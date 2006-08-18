/*
 *  SEEntryEditor.h
 *  Spark Editor
 *
 *  Created by Grayfox on 09/07/06.
 *  Copyright 2006 Shadow Lab. All rights reserved.
 */

#import <ShadowKit/SKWindowController.h>

@class SparkApplication, SparkPlugIn;
@class SETriggerEntry, SETableView, SEApplicationView;
@interface SEEntryEditor : SKWindowController {
  IBOutlet NSView *pluginView;
  IBOutlet SETableView *typeTable;
  IBOutlet SEApplicationView *appField;
  @private
    NSSize se_min;
  NSView *se_view;
  NSMutableArray *se_views;
  NSMutableArray *se_actions;
  NSMutableArray *se_plugins;
  NSMutableArray *se_instances;
}

- (void)setActionType:(SparkPlugIn *)type;

- (void)setEntry:(SETriggerEntry *)anEntry;
- (void)setApplication:(SparkApplication *)anApplication;

@end
