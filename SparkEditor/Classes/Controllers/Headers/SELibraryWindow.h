/*
 *  SELibraryWindow.h
 *  Spark Editor
 *
 *  Created by Jean-Daniel Dupas on 05/07/06.
 *  Copyright 2006 Adamentium. All rights reserved.
 *
 */

#import <Cocoa/Cocoa.h>

@class SKTableView, SKTableDataSource;
@class SETriggersController;
@interface SELibraryWindow : NSWindowController {
  IBOutlet NSSearchField *search;
  IBOutlet SKTableView *appTable;
  IBOutlet SKTableDataSource *appSource;
  IBOutlet SETriggersController *triggers;
}

@end
