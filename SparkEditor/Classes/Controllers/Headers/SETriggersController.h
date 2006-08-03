/*
 *  SETriggersController.h
 *  Spark Editor
 *
 *  Created by Jean-Daniel Dupas on 07/07/06.
 *  Copyright 2006 Shadow Lab. All rights reserved.
 *
 */

#import <Cocoa/Cocoa.h>

@class SKTableView, SEEntryEditor;
@class SparkList, SparkApplication, SETriggerEntrySet;
@interface SETriggersController : NSObject {
  IBOutlet SKTableView *table;
  
  @private
    UInt32 se_filter;
    SparkList *se_list; /* Selected list */
    SEEntryEditor *se_editor;
    
  /* Internal storage */
  NSMutableArray *se_entries;
  SETriggerEntrySet *se_triggers;
  
  /* Internal Cache */
  SparkApplication *se_application;
  SETriggerEntrySet *se_defaults;
}

- (void)loadTriggers; /* Reload data */

- (void)setList:(SparkList *)aList;
- (void)setTriggers:(SETriggerEntrySet *)triggers application:(SparkApplication *)anApplication;

@end

