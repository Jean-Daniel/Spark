//
//  SparkActionLibrary.m
//  SparkKit
//
//  Created by Fox on 01/09/04.
//  Copyright 2004 Shadow Lab. All rights reserved.
//

#import <SparkKit/SparkActionLibrary.h>

#import <SparkKit/SparkActionLoader.h>
#import <SparkKit/Spark_Private.h>
#import <SparkKit/SparkKeyList.h>
#import <SparkKit/SparkLibrary.h>
#import <SparkKit/SparkKeyLibrary.h>
#import <SparkKit/SparkLibraryObject.h>

NSString* const kSparkLibraryDidAddActionNotification = @"SparkLibraryDidAddActionNotification";
NSString* const kSparkLibraryDidUpdateActionNotification = @"SparkLibraryDidUpdateActionNotification";
NSString* const kSparkLibraryDidRemoveActionNotification = @"SparkLibraryDidRemoveActionNotification";

#define kSparkActionLibraryVersion_1_0		0x100
#define kSparkActionLibraryCurrentVersion 	kSparkActionLibraryVersion_1_0

inline SparkAction* SparkIgnoreAction() {
  return [SparkActionLibrary ignoreAction];
}

@implementation SparkActionLibrary

+ (void)initialize {
  static BOOL tooLate = NO;
  if (!tooLate) {
    [SparkActionLoader sharedLoader]; /* On vérifie que les plugins sont bien chargés */
    tooLate = YES;
  }
}

+ (SparkAction *)ignoreAction {
  static id ignoreAction = nil;
  if (!ignoreAction) {
    ignoreAction = [[_SparkIgnoreAction alloc] init];
    [ignoreAction setUid:SKUInt(0)];
  }
  return ignoreAction;
}

#pragma mark -
- (unsigned int)libraryVersion {
  return kSparkActionLibraryCurrentVersion;
}

- (void)loadObjects:(NSArray *)objectsArray {
  [super loadObjects:objectsArray];
  [self addObject:SparkIgnoreAction()];
}

- (BOOL)addObject:(id<SparkLibraryObject>)anObject {
  if ([super addObject:anObject]) {
    [self postNotification:kSparkLibraryDidAddActionNotification withObject:anObject];
    return YES;
  }
  return NO;  
}

- (BOOL)updateObject:(id<SparkLibraryObject>)object {
  if ([super updateObject:object]) {
    [self postNotification:kSparkLibraryDidUpdateActionNotification withObject:object];
    return YES;
  }
  return NO;
}

- (void)removeObject:(id<SparkLibraryObject>)anObject {
  if ([self containsObject:anObject]) {
    [[anObject retain] autorelease]; // on la supprime du dictionnaire. il faut la retenir avant sinon elle est immediatement détruite.
    [super removeObject:anObject];
    [self postNotification:kSparkLibraryDidRemoveActionNotification withObject:anObject];
  }
}

- (NSArray *)customActions {
  NSMutableArray *actions = [NSMutableArray array];
  id items = [self objectEnumerator];
  id item;
  while (item = [items nextObject]) {
    if ([item isCustom]) {
      [actions addObject:item];
    }
  }
  return actions;
}

@end
