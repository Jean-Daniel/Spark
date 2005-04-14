//
//  SparkActionList.m
//  SparkKit
//
//  Created by Fox on 01/09/04.
//  Copyright 2004 Shadow Lab. All rights reserved.
//

#import "SparkActionList.h"

#import "SparkAction.h"
#import "SparkLibrary.h"
#import "SparkActionLibrary.h"

@interface SparkActionList (Private)
- (void)registerForNotification;
@end

@implementation SparkActionList

#pragma mark Protocols Implementation
- (id)copyWithZone:(NSZone *)zone {
  SparkActionList* copy = [super copyWithZone:zone];
  return copy;
}

- (void)encodeWithCoder:(NSCoder *)coder {
  [super encodeWithCoder:coder];
}

- (id)initWithCoder:(NSCoder *)coder {
  return [super initWithCoder:coder];
}

#pragma mark -
+ (NSString *)defaultIconName {
  return @"ActionList";
}

#pragma mark -
- (id)init {
  if (self = [super init]) {
  }
  return self;
}

- (id)initFromPropertyList:(id)plist {
  if (self = [super initFromPropertyList:plist]) {
  }
  return self;
}

- (void)dealloc {
  [[NSNotificationCenter defaultCenter] removeObserver:self];
  [super dealloc];
}

- (void)setLibrary:(SparkLibrary *)aLibrary {
  [super setLibrary:aLibrary];
  [self registerForNotification];
}

- (SparkObjectsLibrary *)contentsLibrary {
  return [[self library] actionLibrary];
}
- (Class)contentType {
  return [SparkAction class];
}

#pragma mark -
- (BOOL)isEditable {
  return YES;
}
- (BOOL)isCustomizable {
  return YES;
}

#pragma mark -
- (void)didAddAction:(NSNotification *)aNotification {
}

- (void)didRemoveAction:(NSNotification *)aNotification {
  [self removeObject:SparkNotificationObject(aNotification)];
}

- (void)didUpdateAction:(NSNotification *)aNotification {
  id object = SparkNotificationObject(aNotification);
  unsigned index = [self indexOfObject:object];
  if (index != NSNotFound) {
    [super replaceObjectAtIndex:index withObject:object];
  }
}

@end

@implementation SparkActionList (Private)

- (void)registerForNotification {
  [[NSNotificationCenter defaultCenter] removeObserver:self name:kSparkLibraryDidAddActionNotification object:nil];
  [[NSNotificationCenter defaultCenter] removeObserver:self name:kSparkLibraryDidRemoveActionNotification object:nil];
  [[NSNotificationCenter defaultCenter] removeObserver:self name:kSparkLibraryDidUpdateActionNotification object:nil];
  
  if ([self library]) {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didAddAction:)
                                                 name:kSparkLibraryDidAddActionNotification
                                               object:[self library]];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didRemoveAction:)
                                                 name:kSparkLibraryDidRemoveActionNotification
                                               object:[self library]];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didUpdateAction:)
                                                 name:kSparkLibraryDidUpdateActionNotification
                                               object:[self library]];
  }
}

@end