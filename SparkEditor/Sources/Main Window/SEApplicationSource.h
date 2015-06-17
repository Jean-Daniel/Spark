/*
 *  SEApplicationSource.h
 *  Spark Editor
 *
 *  Created by Black Moon Team.
 *  Copyright (c) 2004 - 2007 Shadow Lab. All rights reserved.
 */

#import <WonderBox/WBTableDataSource.h>

@class WBTableView;
@class SELibraryWindow, SparkLibrary;
@interface SEApplicationSource : WBTableDataSource <NSOpenSavePanelDelegate> {
  IBOutlet WBTableView *uiTable;
  IBOutlet SELibraryWindow *ibWindow;
  @private
    BOOL se_locked;
  NSMutableSet *se_urls;
  SparkLibrary *se_library;
}

- (IBAction)newApplication:(id)sender;
- (IBAction)deleteSelection:(id)sender;

- (void)setLibrary:(SparkLibrary *)aLibrary;

@end
