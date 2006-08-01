/*
 *  SELibraryWindow.h
 *  Spark Editor
 *
 *  Created by Jean-Daniel Dupas on 05/07/06.
 *  Copyright 2006 Shadow Lab. All rights reserved.
 *
 */

#import <Cocoa/Cocoa.h>

SK_EXPORT
NSString * const SEApplicationDidChangeNotification;

@class SETriggersController, SEApplicationView, SparkList;
@class SKTableView, SKTableDataSource, SELibrarySource, SEApplicationSource;
@interface SELibraryWindow : NSWindowController {
  IBOutlet NSSearchField *search;
  IBOutlet SEApplicationView *appField;
  
  /* Application */
  IBOutlet SKTableView *appTable;
  IBOutlet SEApplicationSource *appSource;
  
  /* Library */
  IBOutlet SKTableView *libraryTable;
  IBOutlet SELibrarySource *listSource;
  
  /* Triggers */
  IBOutlet SETriggersController *triggers;
  @private
    SparkList *se_list;
}

@end
