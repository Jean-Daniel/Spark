/*
 *  SELibrarySource.h
 *  Spark Editor
 *
 *  Created by Jean-Daniel Dupas on 31/07/06.
 *  Copyright 2006 Adamentium. All rights reserved.
 *
 */

#import <Foundation/Foundation.h>

@class SparkList, SETableView;
@interface SELibrarySource : NSObject {
  IBOutlet SETableView *table;
  @private
  id se_delegate;
  NSMutableArray *se_content;
}

- (void)rearrangeObjects;

- (id)delegate;
- (void)setDelegate:(id)aDelegate;

@end

@interface NSObject (SELibrarySourceDelegate)

- (void)source:(SELibrarySource *)aSource didChangeSelection:(SparkList *)list;
- (void)source:(SELibrarySource *)aSource didAddList:(SparkList *)aList atIndex:(unsigned)anIndex;

@end
