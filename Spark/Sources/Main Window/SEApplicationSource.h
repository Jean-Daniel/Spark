/*
 *  SEApplicationSource.h
 *  Spark Editor
 *
 *  Created by Black Moon Team.
 *  Copyright (c) 2004 - 2007 Shadow Lab. All rights reserved.
 */

#import <WonderBox/WonderBox.h>

@class WBTableView;
@class SELibraryWindow, SparkLibrary;

@interface SEApplicationSource : WBTableDataSource <NSOpenSavePanelDelegate> {
  IBOutlet WBTableView *uiTable;
  IBOutlet SELibraryWindow *ibWindow;
}

- (IBAction)newApplication:(id)sender;
- (IBAction)deleteSelection:(id)sender;

- (void)setLibrary:(SparkLibrary *)aLibrary;

@end
