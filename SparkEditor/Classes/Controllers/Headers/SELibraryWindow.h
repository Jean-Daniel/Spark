/*
 *  SELibraryWindow.h
 *  Spark Editor
 *
 *  Created by Black Moon Team.
 *  Copyright (c) 2004 - 2006 Shadow Lab. All rights reserved.
 */

#import <Cocoa/Cocoa.h>

@class SparkList;
@class SETableView, SKTableView, SKTableDataSource;
@class SEApplicationView, SESparkEntrySet, SEEntryEditor;
@class SELibrarySource, SEApplicationSource, SETriggersController;
@interface SELibraryWindow : NSWindowController {
  IBOutlet NSButton *ibDaemon;
  IBOutlet NSTextField *ibStatus;
  IBOutlet NSSearchField *search;
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

@end

SK_PRIVATE
NSString * const SELibraryDidCreateEntryNotification;
