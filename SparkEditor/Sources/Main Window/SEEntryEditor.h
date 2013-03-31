/*
 *  SEEntryEditor.h
 *  Spark Editor
 *
 *  Created by Black Moon Team.
 *  Copyright (c) 2004 - 2007 Shadow Lab. All rights reserved.
 */

#import <WonderBox/WBWindowController.h>

@class SparkEntry, SparkAction, SparkTrigger;
@class SETableView, SEApplicationView, SEHotKeyTrap;
@class SparkActionPlugIn, SparkApplication, SparkPlugIn;
@interface SEEntryEditor : WBWindowController {
  IBOutlet NSView *uiPlugin;
	IBOutlet SETableView *uiTypeTable;
  IBOutlet SEApplicationView *uiApplication;
  
  IBOutlet NSButton *uiHelp;
  IBOutlet NSButton *uiConfirm;
@private
	NSSize se_min;
  NSView *se_view; /* current view __weak */
  SparkEntry *se_entry; /* Edited entry */
	SEHotKeyTrap *se_trap; /* trap field */
	
  NSMutableArray *se_plugins; /* plugins list */
  SparkActionPlugIn *se_plugin; /* current action plugin __weak */
  SparkApplication *se_application; /* current application */
	
	id se_delegate;
	
	NSMapTable *se_sizes; /* plugin min sizes */
	NSMapTable *se_instances; /* plugin instances */
  NSMutableArray *se_views; /* binding cycle hack */
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

- (IBAction)ok:(id)sender;
- (IBAction)cancel:(id)sender;
- (IBAction)openHelp:(id)sender;

@end

@interface NSObject (SEEntryEditorDelegate)

- (BOOL)editor:(SEEntryEditor *)theEditor shouldCreateEntryWithAction:(SparkAction *)anAction
			 trigger:(SparkTrigger *)aTrigger
	 application:(SparkApplication *)anApplication;

- (BOOL)editor:(SEEntryEditor *)theEditor shouldUpdateEntry:(SparkEntry *)entry 
		setAction:(SparkAction *)anAction
			 trigger:(SparkTrigger *)aTrigger
	 application:(SparkApplication *)anApplication;

@end
