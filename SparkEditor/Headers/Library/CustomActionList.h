//
//  CustomActionList.h
//  Spark Editor
//
//  Created by Fox on 10/09/04.
//  Copyright 2004 Shadow Lab. All rights reserved.
//

#import <SparkKit/SparkKit.h>

@interface CustomActionList : SparkActionList {
  NSMutableArray *_plugins;
  NSMutableDictionary *_actions;
  
  NSMutableArray *_descriptors;
  
  id _table;
}

- (id)table;
- (void)setTable:(id)table;

- (void)reload;
- (void)loadActions;

- (NSArray *)selectedActions;
- (NSArray *)selectedPlugIns;
- (NSArray *)selectedObjectsAtLevel:(unsigned)level;

@end
