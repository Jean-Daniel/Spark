/*
 *  SELibrarySource.h
 *  Spark Editor
 *
 *  Created by Black Moon Team.
 *  Copyright (c) 2004 - 2006, Shadow Lab. All rights reserved.
 */

#import <Foundation/Foundation.h>

@class SparkLibrary;
@class SparkList, SparkPlugIn;
@class SETableView, SELibraryWindow;
@interface SELibrarySource : NSObject {
  IBOutlet SETableView *uiTable;
  IBOutlet SELibraryWindow *ibWindow;
  @private
  id se_delegate;
  NSMapTable *se_plugins;
  SparkList *se_overwrite;
  SparkLibrary *se_library;
  NSMutableArray *se_content;
}

- (IBAction)newList:(id)sender;

- (void)rearrangeObjects;

- (id)delegate;
- (void)setDelegate:(id)aDelegate;

- (id)objectAtIndex:(unsigned)idx;
- (SparkPlugIn *)pluginForList:(SparkList *)aList;

@end

@interface NSObject (SELibrarySourceDelegate)

- (void)source:(SELibrarySource *)aSource didChangeSelection:(SparkList *)list;

@end
