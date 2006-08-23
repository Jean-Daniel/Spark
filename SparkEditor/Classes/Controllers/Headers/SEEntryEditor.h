/*
 *  SEEntryEditor.h
 *  Spark Editor
 *
 *  Created by Grayfox on 09/07/06.
 *  Copyright 2006 Shadow Lab. All rights reserved.
 */

#import <ShadowKit/SKWindowController.h>

@class SparkActionPlugIn, SparkApplication, SparkPlugIn;
@class SETriggerEntry, SETableView;
@class SEApplicationView, SEHotKeyTrap;
@interface SEEntryEditor : SKWindowController {
  IBOutlet NSView *pluginView;
  IBOutlet SETableView *typeTable;
  IBOutlet SEHotKeyTrap *trap;
  IBOutlet NSButton *ibConfirm;
  IBOutlet SEApplicationView *appField;
  @private
    NSSize se_min;
  NSView *se_view; /* current view */
  SETriggerEntry *se_entry; /* Edited entry */
  
  NSMutableArray *se_plugins; /* plugins list */
  SparkActionPlugIn *se_plugin; /* current action plugin */
    
  NSMutableArray *se_views; /* binding cycle hack */
  NSMapTable *se_instances; /* plugin instances */
  
  id se_delegate;
}

- (id)delegate;
- (void)setDelegate:(id)aDelegate;

- (SETriggerEntry *)entry;
- (void)setEntry:(SETriggerEntry *)anEntry;

- (SparkPlugIn *)actionType;
- (void)setActionType:(SparkPlugIn *)type;

- (SparkApplication *)application;
- (void)setApplication:(SparkApplication *)anApplication;

@end

@interface NSObject (SEEntryEditorDelegate)

- (BOOL)editor:(SEEntryEditor *)theEditor shouldCreateEntry:(SETriggerEntry *)entry;
- (BOOL)editor:(SEEntryEditor *)theEditor shouldUpdateEntry:(SETriggerEntry *)entry;

@end
