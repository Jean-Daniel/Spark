/*
 *  SETriggersController.h
 *  Spark Editor
 *
 *  Created by Black Moon Team.
 *  Copyright (c) 2004 - 2007 Shadow Lab. All rights reserved.
 */

#import <WonderBox/WBTableDataSource.h>

@class WBTableView;
@class SELibraryWindow;

@interface SETriggersController : WBTableDataSource {
  IBOutlet WBTableView *uiTable;
  IBOutlet NSSearchField *uiSearch;
  IBOutlet SELibraryWindow *ibWindow;
}

@property(nonatomic, readonly) NSView *tableView;

@end

@class SparkTrigger;
WB_PRIVATE
NSUInteger SETriggerSortValue(SparkTrigger *);
