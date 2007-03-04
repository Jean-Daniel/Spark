/*
 *  TextActionPlugIn.m
 *  Spark Plugins
 *
 *  Created by Black Moon Team.
 *  Copyright (c) 2004 - 2007, Shadow Lab. All rights reserved.
 */

#import "TextActionPlugIn.h"

@implementation TextActionPlugIn

- (void)loadSparkAction:(TextAction *)anAction toEdit:(BOOL)isEditing {
  [ibText setString:[anAction string] ? :  @""];
}

- (NSAlert *)sparkEditorShouldConfigureAction {
  return nil;
}

- (void)configureAction {
  NSString *str = [ibText string];
  [[self sparkAction] setString:str];
}

@end
