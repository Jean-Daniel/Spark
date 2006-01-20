//
//  SparkKeyList.m
//  Spark
//
//  Created by Fox on Thu Jan 08 2004.
//  Copyright (c) 2004 Shadow Lab. All rights reserved.
//

#import <SparkKit/SparkKeyList.h>

#import <SparkKit/SparkHotKey.h>
#import <SparkKit/SparkLibrary.h>
#import <SparkKit/SparkKeyLibrary.h>

@interface SparkKeyList (Private)
- (void)registerForNotification;
@end

@implementation SparkKeyList

#pragma mark Protocols Implementation
- (id)copyWithZone:(NSZone *)zone {
  SparkKeyList* copy = [super copyWithZone:zone];
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
  return @"KeyList";
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
  return [[self library] keyLibrary];
}

- (Class)contentType {
  return [SparkHotKey class];
}

#pragma mark -
- (BOOL)isEditable {
  return YES;
}
- (BOOL)isCustomizable {
  return YES;
}

#pragma mark -
- (void)didAddHotKey:(NSNotification *)notification {
}
- (void)didRemoveHotKey:(NSNotification *)aNotification {
  [self removeObject:SparkNotificationObject(aNotification)];
}

- (void)_didUpdateKey:(NSNotification *)aNotification {
  id object = SparkNotificationObject(aNotification);
  unsigned index = [self indexOfObject:object];
  if (index != NSNotFound) {
    [super replaceObjectAtIndex:index withObject:object];
  }
}

@end

@implementation SparkKeyList (Private)

- (void)registerForNotification {
  [[NSNotificationCenter defaultCenter] removeObserver:self name:kSparkLibraryDidAddKeyNotification object:nil];
  [[NSNotificationCenter defaultCenter] removeObserver:self name:kSparkLibraryDidRemoveKeyNotification object:nil];
  [[NSNotificationCenter defaultCenter] removeObserver:self name:kSparkLibraryDidUpdateKeyNotification object:nil];
  
  if (nil != [self library]) {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didAddHotKey:)
                                                 name:kSparkLibraryDidAddKeyNotification
                                               object:[self library]];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didRemoveHotKey:)
                                                 name:kSparkLibraryDidRemoveKeyNotification
                                               object:[self library]];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(_didUpdateKey:)
                                                 name:kSparkLibraryDidUpdateKeyNotification
                                               object:[self library]];
  }
}

@end