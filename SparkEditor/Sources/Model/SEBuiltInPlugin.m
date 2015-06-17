/*
 *  SEBuiltInPlugin.m
 *  Spark Editor
 *
 *  Created by Black Moon Team.
 *  Copyright (c) 2004 - 2007 Shadow Lab. All rights reserved.
 */

#import "SEBuiltInPlugIn.h"

@implementation SEInheritsPlugIn

+ (Class)actionClass {
  return Nil;
}

+ (NSString *)plugInName {
  return NSLocalizedString(@"Globals Setting", @"Inherits 'Built-in Plugin' title");
}

+ (NSImage *)plugInIcon {
  return [NSImage imageNamed:@"applelogo"];
}

+ (NSString *)helpFile {
  return nil;
}

+ (NSString *)nibName {
  return @"SEInheritsPlugin";
}

@end
