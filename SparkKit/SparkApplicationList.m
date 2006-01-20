//
//  SparkApplicationList.m
//  SparkKit
//
//  Created by Grayfox on 16/09/04.
//  Copyright 2004 Shadow Lab. All rights reserved.
//

#import <SparkKit/SparkApplicationList.h>
#import <SparkKit/SparkLibrary.h>
#import <SparkKit/SparkApplicationLibrary.h>
#import <SparkKit/SparkApplication.h>

@interface SparkApplicationList (Private)
- (void)registerForNotification;
@end

@implementation SparkApplicationList

#pragma mark Protocols Implementation
- (id)copyWithZone:(NSZone *)zone {
  SparkApplicationList* copy = [super copyWithZone:zone];
  return copy;
}

- (void)encodeWithCoder:(NSCoder *)coder {
  [super encodeWithCoder:coder];
}

- (id)initWithCoder:(NSCoder *)coder {
  [self registerForNotification];
  return [super initWithCoder:coder];
}

#pragma mark -
+ (NSString *)defaultIconName {
  return @"ApplicationList";
}

#pragma mark -
- (id)init {
  if (self = [super init]) {
    [self registerForNotification];
  }
  return self;
}

- (id)initFromPropertyList:(id)plist {
  if (self = [super initFromPropertyList:plist]) {
    [self registerForNotification];
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
  return [[self library] applicationLibrary];
}
- (Class)contentType {
  return [SparkApplication class];
}

#pragma mark -
- (BOOL)isEditable {
  return YES;
}
- (BOOL)isCustomizable {
  return YES;
}

#pragma mark -
- (void)didAddApplication:(NSNotification *)aNotification {
}

- (void)didRemoveApplication:(NSNotification *)aNotification {
  [self removeObject:SparkNotificationObject(aNotification)];
}

- (void)didUpdateApplication:(NSNotification *)aNotification {
  id object = SparkNotificationObject(aNotification);
  unsigned index = [self indexOfObject:object];
  if (index != NSNotFound) {
    [super replaceObjectAtIndex:index withObject:object];
  }
}

@end

@implementation SparkApplicationList (Private)

- (void)registerForNotification {
  [[NSNotificationCenter defaultCenter] removeObserver:self name:kSparkLibraryDidAddApplicationNotification object:nil];
  [[NSNotificationCenter defaultCenter] removeObserver:self name:kSparkLibraryDidRemoveApplicationNotification object:nil];
  [[NSNotificationCenter defaultCenter] removeObserver:self name:kSparkLibraryDidUpdateApplicationNotification object:nil];
  
  if ([self library]) {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didAddApplication:)
                                                 name:kSparkLibraryDidAddApplicationNotification
                                               object:[self library]];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didRemoveApplication:)
                                                 name:kSparkLibraryDidRemoveApplicationNotification
                                               object:[self library]];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didUpdateApplication:)
                                                 name:kSparkLibraryDidUpdateApplicationNotification
                                               object:[self library]];
  }
}

@end
