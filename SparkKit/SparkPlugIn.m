//
//  PlugIns.m
//  Spark
//
//  Created by Fox on Fri Dec 12 2003.
//  Copyright (c) 2004 Shadow Lab. All rights reserved.
//

#import "SparkPlugIn.h"
#import "Spark_Private.h"

@implementation SparkPlugIn

+ (void)initialize {
  static BOOL tooLate;
  if (NO == tooLate) {
    [self exposeBinding:@"path"];
    [self exposeBinding:@"name"];
    [self exposeBinding:@"icon"];
    tooLate = YES;
  }
}

- (id)initWithBundle:(NSBundle *)bundle {
  if (self = [super init]) {
    //[[NSScriptSuiteRegistry sharedScriptSuiteRegistry] loadSuitesFromBundle:bundle];
    _plugInClass = [bundle principalClass];
    [self setPath:[bundle bundlePath]];
    [self setBundleIdentifier:[bundle bundleIdentifier]];
  }
  return self;
}

- (id)initWithName:(NSString *)name icon:(NSImage *)icon class:(Class)class {
  if (self = [super init]) {
    _name = [name retain];
    _icon = [icon retain];
    [self setPath:[[NSBundle bundleForClass:class] bundlePath]];
    _plugInClass = class;
  }
  return self;
}

+ (id)plugInWithBundle:(NSBundle *)bundle {
  return [[[self alloc] initWithBundle:bundle] autorelease]; 
}

+ (id)plugInWithName:(NSString *)name icon:(NSImage *)icon class:(Class)class {
  return [[[self alloc] initWithName:name icon:icon class:class] autorelease];
}

- (void)dealloc {
  [_name release];
  [_path release];
  [_icon release];
  [_bundleId release];
  [super dealloc];
}

- (NSString *)name {
  if (_name == nil) {
    [self setName:[_plugInClass plugInName]];
  }
  return _name;
}
- (void)setName:(NSString *)newName {
  if (_name != newName) {
    [_name release];
    _name = [newName retain];
  }
}

- (NSString *)path {
  return _path;
}

- (void)setPath:(NSString *)newPath {
  if (_path != newPath) {
    [_path release];
    _path = [newPath retain];
  }
}

- (NSImage *)icon {
  if (_icon == nil) {
    [self setIcon:[_plugInClass plugInIcon]];
  }
  return _icon;
}
- (void)setIcon:(NSImage *)icon {
  if (_icon != icon) {
    [_icon release];
    _icon = [icon retain];
  }
}

- (NSString *)bundleIdentifier {
  return _bundleId;
}

- (void)setBundleIdentifier:(NSString *)anIdentifier {
  if (_bundleId != anIdentifier) {
    [_bundleId release];
    _bundleId = [anIdentifier copy];
  }
}

- (Class)principalClass {
  return _plugInClass;
}

- (Class)actionClass {
  return [_plugInClass actionClass];
}

- (NSString *)description {
  return [NSString stringWithFormat:@"<%@ %p> {Name: %@,\nPlugInClass: %@}",
    [self className], self,
    [self name], NSStringFromClass([self principalClass])];
}

@end