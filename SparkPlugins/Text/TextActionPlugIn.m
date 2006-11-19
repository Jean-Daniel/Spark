/*
 *  TextActionPlugIn.m
 *  Spark Plugins
 *
 *  Created by Black Moon Team.
 *  Copyright (c) 2004 - 2006, Shadow Lab. All rights reserved.
 */

#import "TextActionPlugIn.h"

@implementation TextActionPlugIn


- (void)loadSparkAction:(SparkAction *)anAction toEdit:(BOOL)isEditing {
  
}

- (NSAlert *)sparkEditorShouldConfigureAction {
  return nil;
}

- (void)configureAction {
  NSString *str = [ibText string];
  [[self sparkAction] setString:str];
}

@end
