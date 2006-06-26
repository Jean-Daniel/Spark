//
//  SparkApplicationLibrary.m
//  SparkKit
//
//  Created by Grayfox on 16/09/04.
//  Copyright 2004 Shadow Lab. All rights reserved.
//

#import <ShadowKit/SKFunctions.h>
#import <ShadowKit/SKExtensions.h>

#import <SparkKit/SparkApplicationLibrary.h>
#import <SparkKit/SparkApplication.h>
#import <SparkKit/SparkLibrary.h>

#define kSparkApplicationLibraryVersion_1_0		0x100
#define kSparkApplicationLibraryCurrentVersion	kSparkApplicationLibraryVersion_1_0

NSString* const kSparkLibraryDidAddApplicationNotification = @"SparkLibraryDidAddApplicationNotification";
NSString* const kSparkLibraryDidUpdateApplicationNotification = @"SparkLibraryDidUpdateApplicationNotification";
NSString* const kSparkLibraryDidRemoveApplicationNotification = @"SparkLibraryDidRemoveApplicationNotification";

inline SparkApplication* SparkSystemApplication() {
  return [SparkApplicationLibrary systemApplication];
}

@implementation SparkApplicationLibrary

+ (SparkApplication *)systemApplication {
  static id system = nil;
  if (!system) {
    system = [[_SparkSystemApplication alloc] init];
    [system setUid:SKUInt(0)];
  }
  return system;
}

#pragma mark -
- (unsigned int)libraryVersion {
  return kSparkApplicationLibraryCurrentVersion;
}

#define FINDER_PATH		@"/System/Library/CoreServices/Finder.app"
- (void)loadObjects:(NSArray *)objectsArray {
  [super loadObjects:objectsArray];
  [self addObject:SparkSystemApplication()];
  if ([self applicationWithIdentifier:@"MACS"] == nil) {
    id finder = [[SparkApplication alloc] initWithPath:FINDER_PATH];
    if (finder) {
      [self addObject:finder];
      [finder release];
    }
  }
}

- (BOOL)addObject:(id)anObject {
  if ([super addObject:anObject]) {
    [self postNotification:kSparkLibraryDidAddApplicationNotification withObject:anObject];
    return YES;
  }
  return NO;
}

- (BOOL)updateObject:(id<SparkLibraryObject>)object {
  if ([super updateObject:object]) {
    [self postNotification:kSparkLibraryDidUpdateApplicationNotification withObject:object];
    return YES;
  }
  return NO;
}

- (void)removeObject:(id)anObject {
  if ([self containsObject:anObject]) {
    [[anObject retain] autorelease]; // on la supprime du dictionnaire. il faut la retenir avant sinon elle est immediatement détruite.
    [super removeObject:anObject];
    [self postNotification:kSparkLibraryDidRemoveApplicationNotification withObject:anObject];
  }
}

- (SparkApplication *)applicationForProcess:(ProcessSerialNumber *)psn {
  CFDictionaryRef dico = ProcessInformationCopyDictionary(psn, kProcessDictionaryIncludeAllInformationMask);
  id result = nil;
  if (dico) {
    id creator = (id)CFDictionaryGetValue(dico, CFSTR("FileCreator"));
    id bundle = (id)CFDictionaryGetValue(dico, kCFBundleIdentifierKey);
    id objects = [self objectEnumerator];
    SparkApplication *object;
    while (object = [objects nextObject]) {
      if ([[object identifier] isEqualToString:creator] || [[object identifier] isEqualToString:bundle]) {
        result = object;
        break;
      }
    }
    CFRelease(dico);
  }
  return result;
}

- (SparkApplication *)applicationWithIdentifier:(NSString *)identifier {
  id objects = [self objectEnumerator];
  SparkApplication *object;
  while (object = [objects nextObject]) {
    if ([[object identifier] isEqualToString:identifier]) {
      return object;
    }
  }
  return nil;
}

@end
