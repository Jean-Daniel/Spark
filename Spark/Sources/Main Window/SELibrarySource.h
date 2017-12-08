/*
 *  SELibrarySource.h
 *  Spark Editor
 *
 *  Created by Black Moon Team.
 *  Copyright (c) 2004 - 2007 Shadow Lab. All rights reserved.
 */

#import <WonderBox/WonderBox.h>

@class SparkAction;
@class SparkLibrary, SparkPlugIn;
@class SEEntryList, WBTableView, SELibraryWindow;

@interface SELibrarySource : WBTableDataSource {
  IBOutlet WBTableView *uiTable;
  IBOutlet SELibraryWindow *ibWindow;
}

- (IBAction)newGroup:(id)sender;

- (void)setLibrary:(SparkLibrary *)aLibrary;

- (SparkPlugIn *)plugInForList:(SEEntryList *)aList;

- (IBAction)selectLibrary:(id)sender;
- (IBAction)selectApplicationList:(id)sender;

- (void)selectListForAction:(SparkAction *)anAction;

@end
