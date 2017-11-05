/*
 *  SEEntryEditor.h
 *  Spark Editor
 *
 *  Created by Black Moon Team.
 *  Copyright (c) 2004 - 2007 Shadow Lab. All rights reserved.
 */

#import <WonderBox/WBWindowController.h>

@class SparkEntry, SparkAction, SparkTrigger;
@class WBTableView, SEApplicationView;
@class SparkApplication, SparkPlugIn;

@protocol SEEntryEditorDelegate;

@interface SEEntryEditor : WBWindowController {
  IBOutlet NSView *uiPlugin;
	IBOutlet WBTableView *uiTypeTable;
  IBOutlet SEApplicationView *uiApplication;
  
  IBOutlet NSButton *uiHelp;
  IBOutlet NSButton *uiConfirm;
}

@property(nonatomic, assign) id<SEEntryEditorDelegate> delegate;

/* Edited entry */
@property(nonatomic, retain) SparkEntry *entry;

@property(nonatomic, retain) SparkPlugIn *actionType;

- (void)setActionType:(SparkPlugIn *)aPlugin force:(BOOL)force;

/* current application */
@property(nonatomic, retain) SparkApplication *application;

- (IBAction)ok:(id)sender;
- (IBAction)cancel:(id)sender;
- (IBAction)openHelp:(id)sender;

@end

@protocol SEEntryEditorDelegate <NSObject>
@optional
- (BOOL)editor:(SEEntryEditor *)theEditor shouldCreateEntryWithAction:(SparkAction *)anAction
			 trigger:(SparkTrigger *)aTrigger
	 application:(SparkApplication *)anApplication;

- (BOOL)editor:(SEEntryEditor *)theEditor shouldUpdateEntry:(SparkEntry *)entry 
		setAction:(SparkAction *)anAction
			 trigger:(SparkTrigger *)aTrigger
	 application:(SparkApplication *)anApplication;

@end
