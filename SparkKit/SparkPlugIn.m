//
//  PlugIns.m
//  Spark
//
//  Created by Fox on Fri Dec 12 2003.
//  Copyright (c) 2004 Shadow Lab. All rights reserved.
//

#import "SparkPrivate.h"
#import <SparkKit/SparkPlugIn.h>

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
    //[[NSScriptSuiteRegistry sharedScriptSuiteRegistry] loadSuitesFromBundle:bundle];
    sp_class = [bundle principalClass];
    [self setPath:[bundle bundlePath]];
    [self setBundleIdentifier:[bundle bundleIdentifier]];
  }
  return self;
}

+ (id)plugInWithBundle:(NSBundle *)bundle {
  return [[[self alloc] initWithBundle:bundle] autorelease]; 
}

- (void)dealloc {
  [sp_name release];
  [sp_path release];
  [sp_icon release];
  [sp_bundle release];
  [super dealloc];
}

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

- (Class)principalClass {
  return sp_class;
}

- (Class)actionClass {
  return [sp_class actionClass];
}

- (NSString *)description {
  return [NSString stringWithFormat:@"<%@ %p> {Name: %@,\nPlugInClass: %@}",
    [self className], self,
    [self name], NSStringFromClass([self principalClass])];
}

@end
