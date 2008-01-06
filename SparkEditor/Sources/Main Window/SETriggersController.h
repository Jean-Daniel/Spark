/*
 *  SETriggersController.h
 *  Spark Editor
 *
 *  Created by Black Moon Team.
 *  Copyright (c) 2004 - 2007 Shadow Lab. All rights reserved.
 */

#import <ShadowKit/SKTableDataSource.h>

@class SKTableView, SparkApplication;
@class SparkLibrary, SELibraryWindow, SEEntryList;
@interface SETriggersController : SKTableDataSource {
  IBOutlet SKTableView *uiTable;
  IBOutlet NSSearchField *uiSearch;
  IBOutlet SELibraryWindow *ibWindow;
}

- (NSView *)tableView;

@end

