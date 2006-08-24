/*
 *  SEBuiltInPlugin.m
 *  Spark Editor
 *
 *  Created by Black Moon Team.
 *  Copyright (c) 2004 - 2006 Shadow Lab. All rights reserved.
 */

#import "SEBuiltInPlugin.h"
#import "SETriggerEntry.h"

@implementation SEIgnorePlugin

- (int)type {
  return kSEEntryTypeIgnore;
}

+ (Class)actionClass {
  return Nil;
}

+ (NSString *)plugInName {
  return @"Ignore Spark";
}

+ (NSImage *)plugInIcon {
  return [NSImage imageNamed:@"IgnoreAction"];
}

+ (NSString *)helpFile {
  return nil;
}

+ (NSString *)nibPath {
  return [[NSBundle mainBundle] pathForResource:@"SEIgnorePlugin" ofType:@"nib"];
}

@end

@implementation SEInheritsPlugin

- (int)type {
  return kSEEntryTypeGlobal;
}

+ (Class)actionClass {
  return Nil;
}

+ (NSString *)plugInName {
  return @"Globals Setting";
}

+ (NSImage *)plugInIcon {
  return [NSImage imageNamed:@"applelogo"];
}

+ (NSString *)helpFile {
  return nil;
}

+ (NSString *)nibPath {
  return [[NSBundle mainBundle] pathForResource:@"SEInheritsPlugin" ofType:@"nib"];
}

@end
