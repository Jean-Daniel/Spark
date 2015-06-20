/*
 *  SELibraryWindow.h
 *  Spark Editor
 *
 *  Created by Black Moon Team.
 *  Copyright (c) 2004 - 2007 Shadow Lab. All rights reserved.
 */

#import <SparkKit/SparkAppleScriptSuite.h>

@class SEApplicationView, SETableView;
@class SEEntryList, SparkEntry, SparkLibrary, SparkApplication;
@class SEApplicationSource, SELibrarySource, SETriggersController;
@interface SELibraryWindow : NSWindowController {
  IBOutlet NSSegmentedControl *uiMenu;
  IBOutlet SEApplicationView *appField;  
  
  /* Status image */
  IBOutlet NSButton *uiStartStop;
  IBOutlet NSImageView *uiDisabled;
  
  /* Application */
  IBOutlet NSDrawer *appDrawer;
  
  /* Library */
  IBOutlet SETableView *libraryTable;
  IBOutlet SELibrarySource *ibGroups;
  IBOutlet SEApplicationSource *ibApplications;
  
  /* Triggers */
  IBOutlet SETriggersController *ibTriggers;
}

@property(nonatomic, readonly) NSUndoManager *undoManager;
@property(nonatomic, readonly) SparkApplication *application;

@property(nonatomic, retain) SparkLibrary *library;

@property(nonatomic, readonly) SEEntryList *selectedList;
- (void)revealEntry:(SparkEntry *)entry;
- (void)revealEntries:(NSArray *)entries;

- (void)setDaemonStatus:(SparkDaemonStatus)status;

@property(nonatomic, readonly) SETriggersController *triggers;

- (IBAction)revealInApplication:(id)sender;

@end

SPARK_PRIVATE
NSString * const SELibraryDidCreateEntryNotification;
