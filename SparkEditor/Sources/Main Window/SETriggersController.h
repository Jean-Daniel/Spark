/*
 *  SETriggersController.h
 *  Spark Editor
 *
 *  Created by Black Moon Team.
 *  Copyright (c) 2004 - 2007 Shadow Lab. All rights reserved.
 */

#import <Cocoa/Cocoa.h>

@class SKTableView;
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
  /* Internal storage */
  NSMutableArray *se_entries;
  NSMutableArray *se_snapshot;
}

- (void)loadTriggers; /* Reload data */

- (NSView *)tableView;

- (void)setList:(SparkList *)aList;

@end

