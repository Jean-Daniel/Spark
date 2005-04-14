//
//  KeyLibraryList.m
//  Spark
//
//  Created by Fox on Sat Jan 10 2004.
//  Copyright (c) 2004 Shadow Lab. All rights reserved.
//

#import "KeyLibraryList.h"

@implementation KeyLibraryList

- (id)copyWithZone:(NSZone *)zone {
  KeyLibraryList *copy = [super copyWithZone:zone];
  return copy;
}

- (id)init {
  if (self = [super init]) {
    [self setName:NSLocalizedStringFromTable(@"KEY_LIBRARY", @"Libraries", @"Key Library List Display Name")];
    [self setIcon:[NSImage imageNamed:@"LibraryIcon"]];
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

- (void)didAddHotKey:(NSNotification *)aNotification {
  [self addObject:SparkNotificationObject(aNotification)];
}
@end
