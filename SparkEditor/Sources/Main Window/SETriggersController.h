/*
 *  SETriggersController.h
 *  Spark Editor
 *
 *  Created by Black Moon Team.
 *  Copyright (c) 2004 - 2006, Shadow Lab. All rights reserved.
 */

#import <Cocoa/Cocoa.h>

@class SKTableView, SEEntryEditor;
@class SparkList, SparkApplication, SESparkEntrySet;
@interface SETriggersController : NSObject {
  IBOutlet SKTableView *table;
  IBOutlet NSSearchField *ibSearch;
  @private
    UInt32 se_filter;
  
  /* Selected list */
  SparkList *se_list; 
  /* Internal storage */
  NSMutableArray *se_entries;
  NSMutableArray *se_snapshot;
}

- (void)loadTriggers; /* Reload data */

- (void)setList:(SparkList *)aList;

@end

