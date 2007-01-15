/*
 *  SELibraryWindow.h
 *  Spark Editor
 *
 *  Created by Black Moon Team.
 *  Copyright (c) 2004 - 2006, Shadow Lab. All rights reserved.
 */

#import <Cocoa/Cocoa.h>

@class SparkLibrary;
@class SEApplicationView, SETableView;
@class SELibrarySource, SETriggersController;
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

@end

SK_PRIVATE
NSString * const SELibraryDidCreateEntryNotification;
