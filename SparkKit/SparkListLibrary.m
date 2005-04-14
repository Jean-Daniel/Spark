//
//  SparkListLibrary.m
//  Spark
//
//  Created by Fox on Mon Feb 09 2004.
//  Copyright (c) 2004 Shadow Lab. All rights reserved.
//

#import "SparkListLibrary.h"

#import "SparkObjectList.h"
#import "SparkKeyLibrary.h"
#import "SparkLibraryObject.h"

NSString* const kSparkLibraryDidAddListNotification = @"SparkLibraryDidAddListNotification";
NSString* const kSparkLibraryDidRemoveListNotification = @"SparkLibraryDidRemoveListNotification";

#define kSparkListLibraryVersion_2_0		0x200
#define kSparkListLibraryCurrentVersion 	kSparkListLibraryVersion_2_0

@implementation SparkListLibrary

- (unsigned int)libraryVersion {
  return kSparkListLibraryCurrentVersion;
}

- (BOOL)addObject:(id)anObject {
  if (![self containsObject:anObject]) {
    if ([super addObject:anObject]) {
      [self postNotification:kSparkLibraryDidAddListNotification withObject:anObject];
      return YES;
    }
  }
  else {
    SparkObjectList *existingList = [self objectWithId:[anObject uid]];
    [existingList addObjects:[anObject objects]];
  }
  return NO;
}

- (void)removeObject:(SparkLibraryObject *)anObject {
  if ([self containsObject:anObject]) {
    [[anObject retain] autorelease]; // on la supprime du dictionnaire. il faut la retenir avant sinon elle est immediatement détruite.
    [super removeObject:anObject];
    [self postNotification:kSparkLibraryDidRemoveListNotification withObject:anObject];
  }
}

- (void)loadObject:(NSMutableDictionary *)object {
  switch ([self version]) {
    case kSparkListLibraryCurrentVersion:
      [super loadObject:object];
      break;
    default:
      [object removeObjectForKey:@"UID"];
      [super loadObject:object];
  }
}

#pragma mark -
- (NSArray *)listsWithContentType:(Class)contentType {
  NSMutableArray *lists = [NSMutableArray arrayWithCapacity:[self count]];
  id objects = [self objectEnumerator];
  id object;
  while (object = [objects nextObject]) {
    if ([[object contentType] isSubclassOfClass:contentType]) {
      [lists addObject:object];
    }
  }
  return lists;
}

- (NSArray *)listsWithName:(NSString *)name contentType:(Class)contentType {
  NSMutableArray *lists = [NSMutableArray arrayWithCapacity:[self count]];
  id objects = [self objectEnumerator];
  id object;
  while (object = [objects nextObject]) {
    if ([[object name] isEqualToString:name] && [[object contentType] isSubclassOfClass:contentType]) {
      [lists addObject:object];
    }
  }
  return lists;
}

@end
