/*
 *  SparkScriptApplication.m
 *  SparkKit
 *
 *  Created by Black Moon Team.
 *  Copyright (c) 2004 - 2006 Shadow Lab. All rights reserved.
 *
 */

#import <SparkKit/SparkLibrary.h>

@implementation NSApplication (SparkScriptApplication)

// plugins

- (SparkLibrary *)library {
  return SparkSharedLibrary();
}

@end
