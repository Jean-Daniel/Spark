/*
 *  SELibraryWindow.h
 *  Spark Editor
 *
 *  Created by Black Moon Team.
 *  Copyright (c) 2004 - 2007 Shadow Lab. All rights reserved.
 */

#import <Cocoa/Cocoa.h>

#import <SparkKit/SparkAppleScriptSuite.h>

@class SEEntryList;
@class SEApplicationView, SETableView;
@class SparkEntry, SparkLibrary, SparkApplication;
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
  IBOutlet SETriggersController *triggers;  
  
  @private
    SparkLibrary *se_library;
}

- (SparkLibrary *)library;
- (NSUndoManager *)undoManager;
- (SparkApplication *)application;

- (void)setLibrary:(SparkLibrary *)aLibrary;

- (SEEntryList *)selectedList;
- (void)revealEntry:(SparkEntry *)entry;
- (void)revealEntries:(NSArray *)entries;

- (void)setDaemonStatus:(SparkDaemonStatus)status;

@end

SK_PRIVATE
NSString * const SELibraryDidCreateEntryNotification;
