/*
 *  SETriggersController.h
 *  Spark Editor
 *
 *  Created by Black Moon Team.
 *  Copyright (c) 2004 - 2007 Shadow Lab. All rights reserved.
 */

#import WBHEADER(WBTableDataSource.h)

@class WBTableView, SparkApplication;
@class SparkLibrary, SELibraryWindow, SEEntryList;
@interface SETriggersController : WBTableDataSource {
  IBOutlet WBTableView *uiTable;
  IBOutlet NSSearchField *uiSearch;
  IBOutlet SELibraryWindow *ibWindow;
}

- (NSView *)tableView;

@end

@class SparkTrigger;
WB_PRIVATE
NSUInteger SETriggerSortValue(SparkTrigger *);
