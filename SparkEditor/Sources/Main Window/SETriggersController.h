/*
 *  SETriggersController.h
 *  Spark Editor
 *
 *  Created by Black Moon Team.
 *  Copyright (c) 2004 - 2007 Shadow Lab. All rights reserved.
 */

#import <Cocoa/Cocoa.h>

@class SKTableView, SparkApplication;
@class SparkList, SparkLibrary, SELibraryWindow;
@interface SETriggersController : NSObject {
  IBOutlet SKTableView *uiTable;
  IBOutlet NSSearchField *uiSearch;
  IBOutlet SELibraryWindow *ibWindow;
  @private
    UInt32 se_filter;
  
  /* Selected list */
  SparkList *se_list; 
  SparkLibrary *se_library;
  SparkApplication *se_application;
  /* Internal storage */
  NSMutableArray *se_entries;
  NSMutableArray *se_snapshot;
}

- (void)refresh; /* Reload data */

- (NSView *)tableView;

- (void)setList:(SparkList *)aList;

@end

