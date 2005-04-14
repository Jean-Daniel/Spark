//
//  SparkActionList.m
//  Spark Editor
//
//  Created by Fox on 01/09/04.
//  Copyright 2004 Shadow Lab. All rights reserved.
//

#import "ActionLibraryList.h"

@implementation ActionLibraryList

- (id)init {
  if (self = [super init]) {
    [self setName:NSLocalizedStringFromTable(@"ACTIONS_LIBRARY", @"Libraries", @"Actions List Display Name")];
    [self setIcon:[NSImage imageNamed:@"ActionListIcon"]];
    [self addObjects:[(id)[self contentsLibrary] customActions]];
  }
  return self;
}

- (BOOL)isEditable {
  return NO;
}

- (BOOL)isCustomizable {
  return NO;
}

- (void)didAddAction:(NSNotification *)aNotification {
  id action = SparkNotificationObject(aNotification);
  if ([action isCustom])
    [self addObject:action];
}

@end
