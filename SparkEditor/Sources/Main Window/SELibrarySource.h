/*
 *  SELibrarySource.h
 *  Spark Editor
 *
 *  Created by Black Moon Team.
 *  Copyright (c) 2004 - 2007 Shadow Lab. All rights reserved.
 */

#import <ShadowKit/SKTableDataSource.h>

@class SparkLibrary;
@class SEEntryList, SparkPlugIn;
@class SETableView, SELibraryWindow;
@interface SELibrarySource : SKTableDataSource {
  IBOutlet SETableView *uiTable;
  IBOutlet SELibraryWindow *ibWindow;
  @private
  id se_delegate;
  NSMapTable *se_plugins;
  SEEntryList *se_overwrite;
  
  SparkLibrary *se_library;
  
  NSMutableArray *se_pendings;
}

- (IBAction)newList:(id)sender;

- (void)reloadPluginLists;

- (id)delegate;
- (void)setDelegate:(id)aDelegate;

- (SparkPlugIn *)pluginForList:(SEEntryList *)aList;

@end

@interface NSObject (SELibrarySourceDelegate)

- (void)source:(SELibrarySource *)aSource didChangeSelection:(SEEntryList *)list;

@end
