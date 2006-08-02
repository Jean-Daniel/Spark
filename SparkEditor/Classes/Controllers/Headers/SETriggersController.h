/*
 *  SETriggersController.h
 *  Spark Editor
 *
 *  Created by Jean-Daniel Dupas on 07/07/06.
 *  Copyright 2006 Shadow Lab. All rights reserved.
 *
 */

#import <Cocoa/Cocoa.h>

@class SKTableView;
@class SparkList, SparkApplication, SETriggerEntrySet;
@interface SETriggersController : NSObject {
  IBOutlet SKTableView *table;
  
  @private
    SparkList *se_list; /* Selected list */
  /* Internal storage */
  NSMutableArray *se_entries;
  SETriggerEntrySet *se_triggers;
}

- (void)setList:(SparkList *)aList;

@end

