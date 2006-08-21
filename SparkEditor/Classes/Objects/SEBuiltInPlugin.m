/*
 *  SEBuiltInPlugin.m
 *  Spark Editor
 *
 *  Created by Grayfox on 19/08/06.
 *  Copyright 2006 Shadow Lab. All rights reserved.
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
  return kSEEntryTypeInherit;
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
