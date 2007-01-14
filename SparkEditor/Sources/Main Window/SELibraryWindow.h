/*
 *  SELibraryWindow.h
 *  Spark Editor
 *
 *  Created by Black Moon Team.
 *  Copyright (c) 2004 - 2006, Shadow Lab. All rights reserved.
 */

#import <Cocoa/Cocoa.h>

@class SparkLibrary, SEEntriesManager;
@class SEApplicationView, SETableView, SKTableView;
@class SELibrarySource, SEApplicationSource, SETriggersController;
@interface SELibraryWindow : NSWindowController {
  IBOutlet NSButton *ibDaemon;
  IBOutlet NSTextField *ibStatus;
  IBOutlet NSSegmentedControl *ibMenu;
  IBOutlet SEApplicationView *appField;  
  
  /* Application */
  IBOutlet NSDrawer *appDrawer;
  IBOutlet SKTableView *appTable;
  IBOutlet SEApplicationSource *appSource;
  
  /* Library */
  IBOutlet SETableView *libraryTable;
  IBOutlet SELibrarySource *listSource;
  
  /* Triggers */
  IBOutlet SETriggersController *triggers;  
}

- (SparkLibrary *)library;
- (SEEntriesManager *)manager;

@end

SK_PRIVATE
NSString * const SELibraryDidCreateEntryNotification;
