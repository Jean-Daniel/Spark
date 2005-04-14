//
//  ActionPlugInList.m
//  Spark
//
//  Created by Fox on Fri Jan 09 2004.
//  Copyright (c) 2004 Shadow Lab. All rights reserved.
//

#import "ActionPlugInList.h"

@implementation ActionPlugInList

#pragma mark Protocols Implementation
- (id)copyWithZone:(NSZone *)zone {
  ActionPlugInList *copy = [super copyWithZone:zone]; 
  copy->_plugIn = [_plugIn retain];
  return copy;
}

#pragma mark -
#pragma mark Statics Methods
+ (NSString *)defaultIconName {
  return @"PlugInListIcon";
}

#pragma mark -
#pragma mark Constructors
+ (id)listWithPlugIn:(SparkPlugIn *)plugIn {
  return [[[self alloc] initWithPlugIn:plugIn] autorelease];
}

- (id)initWithPlugIn:(SparkPlugIn *)plugIn {
  if (self = [super initWithName:[plugIn name]]) {
    [self setIcon:[plugIn icon]];
    [self setPlugIn:plugIn];
  }
  return self;
}

- (void)dealloc {
  [_plugIn release];
  [super dealloc];
}

#pragma mark -
#pragma mark Inherited Methods
- (BOOL)isEditable {
  return NO;
}
- (BOOL)isCustomizable {
  return NO;
}

- (void)didAddAction:(NSNotification *)aNotification {
  id action = SparkNotificationObject(aNotification);
  if ([action isCustom] && ([_plugIn actionClass] == [action class])) {
    [self addObject:action];
  } 
}

#pragma mark -
#pragma mark Specifics Methods
- (SparkPlugIn *)plugIn {
  return _plugIn;
}
- (void)setPlugIn:(SparkPlugIn *)plugIn {
  if (_plugIn != plugIn) {
    [_plugIn release];
    _plugIn = [plugIn retain];
    [self reload];
  }
}

- (void)reload {
  id actions = [SparkDefaultActionLibrary() objectEnumerator];
  id action;
  while (action = [actions nextObject]) {
    if ([action isCustom] && ([_plugIn actionClass] == [action class])) {
      [self addObject:action];
    }
  }
}

@end
