/*
 *  SELibrarySource.h
 *  Spark Editor
 *
 *  Created by Black Moon Team.
 *  Copyright (c) 2004 - 2007 Shadow Lab. All rights reserved.
 */

#import <ShadowKit/SKTableDataSource.h>

@class SparkLibrary, SparkPlugIn;
@class SETableView, SELibraryWindow;
@class SEEntryList, SESmartEntryList;
@interface SELibrarySource : SKTableDataSource {
  IBOutlet SETableView *uiTable;
  IBOutlet SELibraryWindow *ibWindow;
  @private
  NSMapTable *se_plugins;
  SESmartEntryList *se_overwrite;
  
  SparkLibrary *se_library;
}

- (IBAction)newGroup:(id)sender;

- (void)setLibrary:(SparkLibrary *)aLibrary;

- (SparkPlugIn *)pluginForList:(SEEntryList *)aList;

- (IBAction)selectLibrary:(id)sender;
- (IBAction)selectApplicationList:(id)sender;

@end
