//
//  SparkKeyLibrary.m
//  Spark
//
//  Created by Fox on Mon Feb 09 2004.
//  Copyright (c) 2004 Shadow Lab. All rights reserved.
//

#import "SparkKeyLibrary.h"

#import "ShadowMacros.h"

#import "SparkAction.h"
#import "SparkHotKey.h"
#import "SparkApplication.h"

#import "SparkLibrary.h"
#import "SparkActionLibrary.h"
#import "SparkApplicationLibrary.h"
#import "SparkLibraryObject.h"
#import "SparkApplicationList.h"

NSString* const kSparkLibraryDidAddKeyNotification = @"SparkLibraryDidAddKeyNotification";
NSString* const kSparkLibraryDidUpdateKeyNotification = @"SparkLibraryDidUpdateKeyNotification";
NSString* const kSparkLibraryDidRemoveKeyNotification = @"SparkLibraryDidRemoveKeyNotification";

#define kSparkKeyLibraryVersion_2_0		0x200
#define kSparkKeyLibraryCurrentVersion  kSparkKeyLibraryVersion_2_0

@implementation SparkKeyLibrary

- (unsigned int)libraryVersion {
  return kSparkKeyLibraryCurrentVersion;
}

- (BOOL)addObject:(id<SparkLibraryObject>)anObject {
  if ([super addObject:anObject]) {
    [self postNotification:kSparkLibraryDidAddKeyNotification withObject:anObject];
    return YES;
  }
  return NO;
}

- (BOOL)updateObject:(id<SparkLibraryObject>)object {
  if ([super updateObject:object]) {
    [self postNotification:kSparkLibraryDidUpdateKeyNotification withObject:object];
    return YES;
  }
  return NO;
}

- (void)removeObject:(id<SparkLibraryObject>)anObject {
  if ([self containsObject:anObject]) {
    [[anObject retain] autorelease]; // on la supprime du dictionnaire. il faut la retenir avant sinon elle est immediatement détruite.
    [super removeObject:anObject];
    [self postNotification:kSparkLibraryDidRemoveKeyNotification withObject:anObject];
  }
}

- (void)loadObject:(id)object {
  switch ([self version]) {
    case kSparkKeyLibraryCurrentVersion:
      [super loadObject:object];
      break;
    default:
      @try {
        object = [NSMutableDictionary dictionaryWithDictionary:object];
        [object removeObjectForKey:@"UID"];
        NSString *class = [object objectForKey:@"Class"];
        if ([class isEqualToString:@"AppHotKey"]) {
          class = @"ApplicationAction";
        } else if ([class isEqualToString:@"ITunesHotKey"]) {
          class= @"ITunesAction";
        } else if ([class isEqualToString:@"DocHotKey"]) {
          class= @"DocumentAction";
        } else if ([class isEqualToString:@"AppleScriptHotKey"]) {
          class= @"AppleScriptAction";
        } else if ([class isEqualToString:@"PowerHotKey"]) {
          class= @"PowerAction";
        }
        [object setObject:class forKey:@"Class"];
        id action = SparkDeserializeObject(object);
        if (nil == action) {
          [NSException raise:@"InvalidClassException" format:@"Class: %@ cannot be loaded", class];
        }
        [object setObject:@"SparkHotKey" forKey:@"Class"];
        id key = SparkDeserializeObject(object);
        [self addObject:key];
        [[[self library] actionLibrary] addObject:action];
        [key setDefaultAction:action];
      } @catch (id exception) {
        SKLogException(exception);
      }
  }
}

- (NSArray *)keysWithKeycode:(unsigned short)keycode modifier:(int)modifier {
  NSMutableArray *result = [NSMutableArray array];
  id keys = [self objectEnumerator];
  id key;
  while (key = [keys nextObject]) {
    if (([key keycode] == keycode) && [key modifier] == modifier)
      [result addObject:key];
  }
  return result;
}
- (SparkHotKey *)activeKeyWithKeycode:(unsigned short)keycode modifier:(int)modifier {
  id keys = [self objectEnumerator];
  id key;
  while (key = [keys nextObject]) {
    if (([key keycode] == keycode) && ([key modifier] == modifier) && [key isActive])
      return key;
  }
  return nil;
}

- (NSSet *)keysUsingAction:(SparkAction *)action {
  return [self keysUsingActions:[NSSet setWithObject:[action uid]]];
}

- (NSSet *)keysUsingActions:(NSSet *)actionsUids {
  NSMutableSet *result = [NSMutableSet set];
  id keys = [self objectEnumerator];
  id key;
  while (key = [keys nextObject]) {
    if ([[key actionsUids] intersectsSet:actionsUids]) {
      [result addObject:key];
    }
  }
  return result;
}

- (NSSet *)keysUsingApplication:(SparkApplication *)application {
  return [self keysUsingApplications:[NSSet setWithObject:[application uid]]];
}

- (NSSet *)keysUsingApplications:(NSSet *)applicationsUids {
  NSMutableSet *result = [NSMutableSet set];
  id keys = [self objectEnumerator];
  id key;
  while (key = [keys nextObject]) {
    if ([[key applicationsUids] intersectsSet:applicationsUids]) {
      [result addObject:key];
    }
  }
  return result;
}

- (NSSet *)keysUsingApplicationList:(SparkApplicationList *)list {
  return [self keysUsingApplicationLists:[NSSet setWithObject:[list uid]]];
}

- (NSSet *)keysUsingApplicationLists:(NSSet *)listsUids {
  NSMutableSet *result = [NSMutableSet set];
  id keys = [self objectEnumerator];
  id key;
  while (key = [keys nextObject]) {
    if ([[key listsUids] intersectsSet:listsUids]) {
      [result addObject:key];
    }
  }
  return result;
}

@end
