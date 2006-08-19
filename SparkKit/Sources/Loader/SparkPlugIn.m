/*
 *  SparkPlugIn.m
 *  SparkKit
 *
 *  Created by Black Moon Team.
 *  Copyright (c) 2004 - 2006 Shadow Lab. All rights reserved.
 *
 */

#import "SparkPrivate.h"

#import <SparkKit/SparkPlugIn.h>

#import <ShadowKit/SKImageUtils.h>
#import <ShadowKit/SKCGFunctions.h>

@implementation SparkPlugIn

+ (void)initialize {
  if ([SparkPlugIn class] == self) {
    [self exposeBinding:@"path"];
    [self exposeBinding:@"name"];
    [self exposeBinding:@"icon"];
  }
}

- (id)initWithBundle:(NSBundle *)bundle {
  if (self = [super init]) {
    sp_class = [bundle principalClass];
    [self setPath:[bundle bundlePath]];
    [self setBundleIdentifier:[bundle bundleIdentifier]];
    /* Extend applescript support */
    [[NSScriptSuiteRegistry sharedScriptSuiteRegistry] loadSuitesFromBundle:bundle];
  }
  return self;
}

+ (id)plugInWithBundle:(NSBundle *)bundle {
  return [[[self alloc] initWithBundle:bundle] autorelease]; 
}

- (void)dealloc {
  [sp_nib release];
  [sp_name release];
  [sp_path release];
  [sp_icon release];
  [sp_bundle release];
  [super dealloc];
}

- (unsigned)hash {
  return [sp_bundle hash];
}

- (BOOL)isEqual:(id)object {
  if (!object || ![object isKindOfClass:[SparkPlugIn class]])
    return NO;
  
  return [sp_bundle isEqual:[object bundleIdentifier]];
}

- (NSString *)description {
  return [NSString stringWithFormat:@"<%@ %p> {Name: %@, Class: %@}",
    [self class], self,
    [self name], sp_class];
}

#pragma mark -
- (NSString *)name {
  if (sp_name == nil) {
    [self setName:[sp_class plugInName]];
  }
  return sp_name;
}
- (void)setName:(NSString *)newName {
  SKSetterRetain(sp_name, newName);
}

- (NSString *)path {
  return sp_path;
}

- (void)setPath:(NSString *)newPath {
  SKSetterRetain(sp_path, newPath);
}

- (NSImage *)icon {
  if (sp_icon == nil) {
    [self setIcon:[sp_class plugInIcon]];
  }
  return sp_icon;
}
- (void)setIcon:(NSImage *)icon {
  SKSetterRetain(sp_icon, icon);
}

- (NSString *)bundleIdentifier {
  return sp_bundle;
}
- (void)setBundleIdentifier:(NSString *)identifier {
  SKSetterRetain(sp_bundle, identifier);
}

- (id)instantiatePlugin {
  if (!sp_nib) {
    NSString *path = [sp_class nibPath];
    if (path) {
      NSURL *url = [NSURL fileURLWithPath:path];
      sp_nib = [[NSNib alloc] initWithContentsOfURL:url];
    } else {
      DLog(@"Invalid plugin nib path");
    }
  }
  SparkPlugIn *plugin = [[sp_class alloc] init];
  [sp_nib instantiateNibWithOwner:plugin topLevelObjects:nil];
  return [plugin autorelease];
}

- (Class)actionClass {
  return [sp_class actionClass];
}

@end

@implementation SparkPlugIn (SparkBuiltInPlugIn)

- (id)initWithClass:(Class)cls {
  if (self = [self init]) {
    sp_class = cls;
  }
  return self;
}


@end

