//
//  ApplicationLibraryList.m
//  Spark Editor
//
//  Created by Grayfox on 16/09/04.
//  Copyright 2004 Shadow Lab. All rights reserved.
//

#import "ApplicationLibraryList.h"

@implementation ApplicationLibraryList

- (id)init {
  if (self = [super init]) {
    [self setName:NSLocalizedStringFromTable(@"APP_LIBRARY", @"Libraries", @"Applications List Display Name")];
    [self setIcon:[NSImage imageNamed:@"ApplicationListIcon"]];
    [self addObjects:[[self contentsLibrary] objects]];
  }
  return self;
}

- (BOOL)isEditable {
  return NO;
}

- (BOOL)isCustomizable {
  return NO;
}

- (void)didAddApplication:(NSNotification *)aNotification {
  [self addObject:SparkNotificationObject(aNotification)];
}
@end
