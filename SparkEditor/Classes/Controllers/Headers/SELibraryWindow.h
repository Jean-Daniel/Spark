/*
 *  SELibraryWindow.h
 *  Spark Editor
 *
 *  Created by Jean-Daniel Dupas on 05/07/06.
 *  Copyright 2006 Shadow Lab. All rights reserved.
 *
 */

#import <Cocoa/Cocoa.h>

@class SETriggersController, SEApplicationView;
@class SKTableView, SKTableDataSource, SELibrarySource, SEApplicationSource;
@interface SELibraryWindow : NSWindowController {
  IBOutlet NSSearchField *search;
  IBOutlet SKTableView *appTable;
  IBOutlet SEApplicationSource *appSource;
  
  IBOutlet SELibrarySource *listSource;
  
  IBOutlet SKTableView *libraryTable;
  IBOutlet SETriggersController *triggers;
  
  IBOutlet SEApplicationView *appField;
}

@end
