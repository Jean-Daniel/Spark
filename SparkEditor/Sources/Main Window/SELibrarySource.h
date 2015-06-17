/*
 *  SELibrarySource.h
 *  Spark Editor
 *
 *  Created by Black Moon Team.
 *  Copyright (c) 2004 - 2007 Shadow Lab. All rights reserved.
 */

#import <WonderBox/WBTableDataSource.h>

@class SparkAction;
@class SparkLibrary, SparkPlugIn;
@class SEEntryList, SETableView, SELibraryWindow;
@interface SELibrarySource : WBTableDataSource {
  IBOutlet SETableView *uiTable;
  IBOutlet SELibraryWindow *ibWindow;
@private
  NSMapTable *se_plugins;
  SEEntryList *se_overwrite;

  SparkLibrary *se_library;
}

- (IBAction)newGroup:(id)sender;

- (void)setLibrary:(SparkLibrary *)aLibrary;

- (SparkPlugIn *)plugInForList:(SEEntryList *)aList;

- (IBAction)selectLibrary:(id)sender;
- (IBAction)selectApplicationList:(id)sender;

- (void)selectListForAction:(SparkAction *)anAction;

@end
