/*
 *  SELibraryWindow.h
 *  Spark Editor
 *
 *  Created by Black Moon Team.
 *  Copyright (c) 2004 - 2007 Shadow Lab. All rights reserved.
 */

#import <Cocoa/Cocoa.h>

@class SEEntryList;
@class SEApplicationView, SETableView;
@class SELibrarySource, SETriggersController;
@class SparkEntry, SparkLibrary, SparkApplication;
@interface SELibraryWindow : NSWindowController {
  IBOutlet NSButton *ibDaemon;
  IBOutlet NSTextField *ibStatus;
  IBOutlet NSSegmentedControl *ibMenu;
  IBOutlet SEApplicationView *appField;  
  
  /* Application */
  IBOutlet NSDrawer *appDrawer;
  
  /* Library */
  IBOutlet SETableView *libraryTable;
  IBOutlet SELibrarySource *listSource;
  
  /* Triggers */
  IBOutlet SETriggersController *triggers;  
}

- (SparkLibrary *)library;
- (NSUndoManager *)undoManager;
- (SparkApplication *)application;

- (SEEntryList *)selectedList;
- (void)revealEntry:(SparkEntry *)entry;
- (void)revealEntries:(NSArray *)entries;

@end

SK_PRIVATE
NSString * const SELibraryDidCreateEntryNotification;
