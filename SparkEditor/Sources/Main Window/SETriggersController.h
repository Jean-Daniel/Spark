/*
 *  SETriggersController.h
 *  Spark Editor
 *
 *  Created by Black Moon Team.
 *  Copyright (c) 2004 - 2007 Shadow Lab. All rights reserved.
 */

#import <ShadowKit/SKTableDataSource.h>

@class SKTableView, SparkApplication;
@class SEEntryList, SparkLibrary, SELibraryWindow;
@interface SETriggersController : SKTableDataSource {
  IBOutlet SKTableView *uiTable;
  IBOutlet NSSearchField *uiSearch;
  IBOutlet SELibraryWindow *ibWindow;
  @private
    UInt32 se_filter;
}

- (NSView *)tableView;

@end

