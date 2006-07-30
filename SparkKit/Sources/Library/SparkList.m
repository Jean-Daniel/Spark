/*
 *  SparkList.m
 *  SparkKit
 *
 *  Created by Grayfox on 30/07/06.
 *  Copyright 2006 Shadow Lab. All rights reserved.
 */

#import "SparkList.h"

static 
NSString * const kSparkObjectsKey = @"SparkObjects";

@implementation SparkList

- (id)initWithLibrary:(SparkObjectsLibrary *)aLibrary {
  if (self = [super init]) {
    [self setLibrary:aLibrary];
  }
  return self;
}

- (void)dealloc {
  [self setLibrary:nil];
  [sp_entries release];
  [super dealloc];
}

- (void)setLibrary:(SparkObjectsLibrary *)library {
  if (sp_lib != library) {
    /* unregister notifications */
    sp_lib = library;
    /* register notifications */
  }
}

- (BOOL)serialize:(NSMutableDictionary *)plist {
  [super serialize:plist];
}

- (id)initWithLibrary:(SparkObjectsLibrary *)library serializedValues:(NSDictionary *)plist  {
  if (self = [super initWithSerializedValues:plist]) {
    [self setLibrary:library];
    // Load plist
  }
  return self;
}

#pragma mark -



@end
