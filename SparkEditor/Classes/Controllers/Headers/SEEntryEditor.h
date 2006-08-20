/*
 *  SEEntryEditor.h
 *  Spark Editor
 *
 *  Created by Grayfox on 09/07/06.
 *  Copyright 2006 Shadow Lab. All rights reserved.
 */

#import <ShadowKit/SKWindowController.h>

@class SparkApplication, SparkPlugIn;
@class SETriggerEntry, SETableView;
@class SEApplicationView, SEHotKeyTrap;
@interface SEEntryEditor : SKWindowController {
  IBOutlet NSView *pluginView;
  IBOutlet SETableView *typeTable;
  IBOutlet SEHotKeyTrap *trap;
  IBOutlet SEApplicationView *appField;
  @private
    NSSize se_min;
  NSView *se_view; /* current view */
  SETriggerEntry *se_entry; /* Edited entry */
  NSMutableArray *se_plugins; /* plugins list */
  
  NSMutableArray *se_views; /* binding cycle hack */
  NSMapTable *se_instances; /* plugin instances */
}

- (void)setEntry:(SETriggerEntry *)anEntry;

- (void)setActionType:(SparkPlugIn *)type;
- (void)setApplication:(SparkApplication *)anApplication;

@end
