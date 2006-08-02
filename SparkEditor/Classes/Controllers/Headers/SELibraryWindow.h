/*
 *  SELibraryWindow.h
 *  Spark Editor
 *
 *  Created by Jean-Daniel Dupas on 05/07/06.
 *  Copyright 2006 Shadow Lab. All rights reserved.
 *
 */

#import <Cocoa/Cocoa.h>

@class SETriggersController, SEApplicationView, SETriggerEntrySet, SparkList;
@class SKTableView, SKTableDataSource, SELibrarySource, SEApplicationSource;
@interface SELibraryWindow : NSWindowController {
  IBOutlet NSSearchField *search;
  IBOutlet SEApplicationView *appField;
  
  /* Application */
  IBOutlet NSDrawer *appDrawer;
  IBOutlet SKTableView *appTable;
  IBOutlet SEApplicationSource *appSource;
  
  /* Library */
  IBOutlet SKTableView *libraryTable;
  IBOutlet SELibrarySource *listSource;
  
  /* Triggers */
  IBOutlet SETriggersController *triggers;
  @private
  SETriggerEntrySet *se_defaults; /* system triger cache */
  SETriggerEntrySet *se_triggers; /* shared triggers */
}

@end
