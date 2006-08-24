/*
 *  SETriggersController.h
 *  Spark Editor
 *
 *  Created by Black Moon Team.
 *  Copyright (c) 2004 - 2006 Shadow Lab. All rights reserved.
 */

#import <Cocoa/Cocoa.h>

@class SKTableView, SEEntryEditor;
@class SparkList, SparkApplication, SETriggerEntrySet;
@interface SETriggersController : NSObject {
  IBOutlet SKTableView *table;
  @private
    UInt32 se_filter;
  
  /* Selected list */
  SparkList *se_list; 
  /* Internal storage */
  NSMutableArray *se_entries;
}

- (void)loadTriggers; /* Reload data */

- (void)setList:(SparkList *)aList;

@end

