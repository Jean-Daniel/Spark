/*
 *  SEEntryEditor.h
 *  Spark Editor
 *
 *  Created by Black Moon Team.
 *  Copyright (c) 2004 - 2007 Shadow Lab. All rights reserved.
 */

#import <ShadowKit/SKWindowController.h>

@class SparkEntry;
@class SETableView, SEApplicationView, SEHotKeyTrap;
@class SparkActionPlugIn, SparkApplication, SparkPlugIn;
@interface SEEntryEditor : SKWindowController {
  IBOutlet NSView *uiPlugin;
  IBOutlet SEHotKeyTrap *uiTrap;
  IBOutlet SETableView *uiTypeTable;
  IBOutlet SEApplicationView *uiApplication;
  
  IBOutlet NSButton *uiHelp;
  IBOutlet NSButton *uiConfirm;
  @private
    NSSize se_min;
  NSView *se_view; /* current view __weak */
  SparkEntry *se_entry; /* Edited entry */
  
  NSMutableArray *se_plugins; /* plugins list */
  SparkActionPlugIn *se_plugin; /* current action plugin __weak */
  SparkApplication *se_application; /* current application */

  NSMutableArray *se_views; /* binding cycle hack */
  NSMapTable *se_instances; /* plugin instances */
  NSMapTable *se_sizes; /* plugin min sizes */
  
  id se_delegate;
}

- (id)delegate;
- (void)setDelegate:(id)aDelegate;

- (SparkEntry *)entry;
- (void)setEntry:(SparkEntry *)anEntry;

- (SparkPlugIn *)actionType;
- (void)setActionType:(SparkPlugIn *)type;
- (void)setActionType:(SparkPlugIn *)aPlugin force:(BOOL)force;

- (SparkApplication *)application;
- (void)setApplication:(SparkApplication *)anApplication;

@end

@interface NSObject (SEEntryEditorDelegate)

- (BOOL)editor:(SEEntryEditor *)theEditor shouldCreateEntry:(SparkEntry *)entry;
- (BOOL)editor:(SEEntryEditor *)theEditor shouldReplaceEntry:(SparkEntry *)entry withEntry:(SparkEntry *)newEntry;

@end
