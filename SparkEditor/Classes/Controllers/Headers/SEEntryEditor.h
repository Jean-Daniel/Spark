/*
 *  SEEntryEditor.h
 *  Spark Editor
 *
 *  Created by Black Moon Team.
 *  Copyright (c) 2004 - 2006 Shadow Lab. All rights reserved.
 */

#import <ShadowKit/SKWindowController.h>

@class SparkActionPlugIn, SparkApplication, SparkPlugIn;
@class SETableView, SEApplicationView, SEHotKeyTrap;
@class SparkEntry;
@interface SEEntryEditor : SKWindowController {
  IBOutlet NSView *pluginView;
  IBOutlet SETableView *typeTable;
  IBOutlet SEHotKeyTrap *trap;
  IBOutlet NSButton *ibConfirm;
  IBOutlet SEApplicationView *appField;
  @private
    NSSize se_min;
  NSView *se_view; /* current view */
  SparkEntry *se_entry; /* Edited entry */
  
  NSMutableArray *se_plugins; /* plugins list */
  SparkActionPlugIn *se_plugin; /* current action plugin */
    
  NSMutableArray *se_views; /* binding cycle hack */
  NSMapTable *se_instances; /* plugin instances */
  
  id se_delegate;
}

- (id)delegate;
- (void)setDelegate:(id)aDelegate;

- (SparkEntry *)entry;
- (void)setEntry:(SparkEntry *)anEntry;

- (SparkPlugIn *)actionType;
- (void)setActionType:(SparkPlugIn *)type;

- (SparkApplication *)application;
- (void)setApplication:(SparkApplication *)anApplication;

@end

@interface NSObject (SEEntryEditorDelegate)

- (BOOL)editor:(SEEntryEditor *)theEditor shouldCreateEntry:(SparkEntry *)entry;
- (BOOL)editor:(SEEntryEditor *)theEditor shouldUpdateEntry:(SparkEntry *)entry;

@end
