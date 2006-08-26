/*
 *  SELibrarySource.h
 *  Spark Editor
 *
 *  Created by Black Moon Team.
 *  Copyright (c) 2004 - 2006 Shadow Lab. All rights reserved.
 */

#import <Foundation/Foundation.h>

@class SETableView, SESparkEntrySet;
@class SparkList, SparkApplication, SparkPlugIn;
@interface SELibrarySource : NSObject {
  IBOutlet SETableView *table;
  @private
  id se_delegate;
  NSMapTable *se_plugins;
  SparkList *se_overwrite;
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
