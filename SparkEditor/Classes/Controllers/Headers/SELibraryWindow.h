/*
 *  SELibraryWindow.h
 *  Spark Editor
 *
 *  Created by Jean-Daniel Dupas on 05/07/06.
 *  Copyright 2006 Shadow Lab. All rights reserved.
 *
 */

#import <Cocoa/Cocoa.h>

@class SparkList;
@class SETableView, SKTableView, SKTableDataSource;
@class SEApplicationView, SETriggerEntrySet, SEEntryEditor;
@class SELibrarySource, SEApplicationSource, SETriggersController;
@interface SELibraryWindow : NSWindowController {
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
  @private
    SEEntryEditor *se_editor;
  SETriggerEntrySet *se_defaults; /* system triger cache */
  SETriggerEntrySet *se_triggers; /* shared triggers */
}

@end
