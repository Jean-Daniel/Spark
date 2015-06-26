/*
 *  SparkIconManager.m
 *  SparkKit
 *
 *  Created by Black Moon Team.
 *  Copyright (c) 2004 - 2007 Shadow Lab. All rights reserved.
 */

#import "SparkIconManagerPrivate.h"

#import "SparkLibraryPrivate.h"

#import <SparkKit/SparkList.h>
#import <SparkKit/SparkAction.h>
#import <SparkKit/SparkTrigger.h>
#import <SparkKit/SparkApplication.h>

#import <SparkKit/SparkObject.h>
#import <SparkKit/SparkLibrary.h>
#import <SparkKit/SparkObjectSet.h>

#import <WonderBox/WBFSFunctions.h>
#import <WonderBox/WBImageFunctions.h>

enum {
  kSparkInvalidType = 0xff
};

WB_INLINE
uint8_t __SparkIconTypeForObject(SparkObject *object) {
  Class cls = [object class];
  if ([cls isSubclassOfClass:[SparkList class]])
    return kSparkListSet;
  if ([cls isSubclassOfClass:[SparkAction class]])
    return kSparkActionSet;
  if ([cls isSubclassOfClass:[SparkTrigger class]])
    return kSparkTriggerSet;
  if ([cls isSubclassOfClass:[SparkApplication class]])
    return kSparkApplicationSet;
  return kSparkInvalidType;
}

//SparkObjectSet *_SparkObjectSetForType(SparkLibrary *library, UInt8 type) {
//  switch (type) {
//    case 0:
//      return [library listSet];
//    case 1:
//      return [library actionSet];
//    case 2:
//      return [library triggerSet];
//    case 3:
//      return [library applicationSet];
//  }
//  return nil;
//}

#pragma mark -
@implementation SparkIconManager {
@private
  SparkLibrary *_library;
  NSMutableDictionary *sp_cache[kSparkSetCount];
}

- (id)initWithLibrary:(SparkLibrary *)aLibrary URL:(NSURL *)anURL {
  NSParameterAssert(aLibrary != nil);
  if (self = [super init]) {
    _URL = anURL;

    if (![_URL checkResourceIsReachableAndReturnError:NULL]) {
      if (![[NSFileManager defaultManager] createDirectoryAtURL:_URL withIntermediateDirectories:YES attributes:nil error:NULL])
        return nil;
    }

    for (NSUInteger idx = 0; idx < kSparkSetCount; idx++) {
      NSURL *dir = [_URL URLByAppendingPathComponent:[NSString stringWithFormat:@"%lu", (unsigned long)idx]];
      if (![dir checkResourceIsReachableAndReturnError:NULL])
        if (![[NSFileManager defaultManager] createDirectoryAtURL:_URL withIntermediateDirectories:NO attributes:nil error:NULL])
          return nil;
    }

    for (NSUInteger idx = 0; idx < kSparkSetCount; idx++)
      sp_cache[idx] = [[NSMutableDictionary alloc] init];
    
    _library = aLibrary;
    /* Listen notifications */
    [_library.notificationCenter addObserver:self
                                    selector:@selector(didAddObject:)
                                        name:SparkObjectSetDidAddObjectNotification
                                      object:nil];
    //    [_library.notificationCenter addObserver:self
    //                                        selector:@selector(didUpdateObject:)
    //                                            name:SparkObjectSetDidUpdateObjectNotification
    //                                          object:nil];
    [_library.notificationCenter addObserver:self
                                    selector:@selector(willRemoveObject:)
                                        name:SparkObjectSetWillRemoveObjectNotification
                                      object:nil];
  }
  return self;
}

- (void)dealloc {
  [_library.notificationCenter removeObserver:self];
  for (NSUInteger idx = 0; idx < kSparkSetCount; idx++)
    sp_cache[idx] = nil;
}

#pragma mark -
- (void)setURL:(NSURL *)anURL {
  if (_URL)
    SPXThrowException(NSInvalidArgumentException, @"%@ does not support rename", [self class]);

  if (anURL) {
    if (![anURL checkResourceIsReachableAndReturnError:NULL]) {
      if (![[NSFileManager defaultManager] createDirectoryAtURL:anURL withIntermediateDirectories:YES attributes:nil error:NULL])
        return;
    }

    for (NSUInteger idx = 0; idx < kSparkSetCount; idx++) {
      NSURL *dir = [anURL URLByAppendingPathComponent:[NSString stringWithFormat:@"%lu", (unsigned long)idx]];
      if (![dir checkResourceIsReachableAndReturnError:NULL])
        if (![[NSFileManager defaultManager] createDirectoryAtURL:anURL withIntermediateDirectories:NO attributes:nil error:NULL])
          return;
    }

    for (NSUInteger idx = 0; idx < kSparkSetCount; idx++)
      sp_cache[idx] = [[NSMutableDictionary alloc] init];

    _URL = anURL;
  }
}

- (_SparkIconEntry *)entryForObjectType:(uint8_t)type uid:(SparkUID)anUID {
  _SparkIconEntry *entry = nil;
  if (type != kSparkInvalidType) {
    entry = [sp_cache[type] objectForKey:@(anUID)];
    if (!entry) {
      entry = [[_SparkIconEntry alloc] initWithObjectType:type uid:anUID];
      [sp_cache[type] setObject:entry forKey:@(anUID)];
    }
  }
  return entry;
}

- (_SparkIconEntry *)entryForObject:(SparkObject *)anObject {
	return [self entryForObjectType:__SparkIconTypeForObject(anObject) uid:[anObject uid]];
}

- (NSImage *)iconForObject:(SparkObject *)anObject {
  _SparkIconEntry *entry = [self entryForObject:anObject];
  if (entry && ![entry loaded] && _URL) {
    NSURL *url = [_URL URLByAppendingPathComponent:entry.path];
    if ([url checkResourceIsReachableAndReturnError:NULL]) {
      NSImage *icon = [[NSImage alloc] initByReferencingURL:url];
      /* Set icon from disk */
      //SPXDebug(@"Load icon (%@): %@", [anObject name], icon);
      [entry setCachedIcon:icon];
    } else {
      /* No icon on disk */
      [entry setCachedIcon:nil];
      SPXDebug(@"Icon not found in cache for object: %@", anObject);
    }
  }
  return entry.icon;
}

- (void)setIcon:(NSImage *)icon forObject:(SparkObject *)anObject {
  _SparkIconEntry *entry = [self entryForObject:anObject];
  if (entry) {
    /* Adjust resolution */
    if (icon)
      WBImageSetRepresentationsSize(icon, NSMakeSize(16, 16));
    [entry setIcon:icon];
  }
}

- (void)synchronize:(NSMutableDictionary *)entries {
  if (_URL) {
    @autoreleasepool {
      [entries enumerateKeysAndObjectsUsingBlock:^(id key, _SparkIconEntry *entry, BOOL *stop) {
        if ([entry hasChanged]) {
          NSURL *url = [self->_URL URLByAppendingPathComponent:entry.path];
          if (!entry.icon) {
            SPXDebug(@"delete icon: %@", url);
            [[NSFileManager defaultManager] removeItemAtURL:url error:NULL];
          } else {
            NSData *data = [entry.icon TIFFRepresentationUsingCompression:NSTIFFCompressionLZW factor:1];
            if (data) {
              SPXDebug(@"save icon: %@", url);
              [data writeToURL:url atomically:NO];
            }
          }
          [entry applyChange];
        }
      }];
    }
  }
}

- (BOOL)synchronize {
  if (_URL) {
    for (NSUInteger idx = 0; idx < kSparkSetCount; idx++)
      [self synchronize:sp_cache[idx]];
  } else {
    SPXDebug(@"WARNING: sync icon cache with undefined path");
  }
  return YES;
}

- (void)enumerateEntries:(uint8_t)type usingBlock:(void (^)(SparkUID uid, _SparkIconEntry *entry, BOOL *stop))block {
  if (type < 0 || type >= kSparkSetCount) return;
  [sp_cache[type] enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
    block([key unsignedIntValue], obj, stop);
  }];
}

#pragma mark Notifications
- (void)didAddObject:(NSNotification *)aNotification {
  SparkObject *object = SparkNotificationObject(aNotification);
  if ([object shouldSaveIcon] && [object hasIcon])
    [self setIcon:[object icon] forObject:object];
}

//- (void)didUpdateObject:(NSNotification *)aNotification {
//  SparkObject *object = SparkNotificationObject(aNotification);
//  SparkObject *updated = SparkNotificationUpdatedObject(aNotification);
//  /* should no longer save icon or has no icon */
//  if (![object shouldSaveIcon] || ![object hasIcon]) {
//    /* Remove previous */
//    if ([updated shouldSaveIcon])
//      [self setIcon:nil forObject:object];
//  } else {
//    [self setIcon:[object icon] forObject:object];
//  }
//}

- (void)willRemoveObject:(NSNotification *)aNotification {
  SparkObject *object = SparkNotificationObject(aNotification);
  if ([object shouldSaveIcon])
    [self setIcon:nil forObject:object];
}

@end

#pragma mark -
@implementation _SparkIconEntry {
  BOOL _clean;
  BOOL _loaded;

@private
  NSImage *_icon;
  NSImage *_ondisk;
}

- (id)initWithObject:(SparkObject *)object {
	return [self initWithObjectType:__SparkIconTypeForObject(object) uid:[object uid]];
}

- (id)initWithObjectType:(NSUInteger)type uid:(SparkUID)anUID {
  if (self = [super init]) {
    _clean = YES;
    _path = [[NSString alloc] initWithFormat:@"%lu/%lu", (long)type, (long)anUID];
  }
  return self;
}

#pragma mark -
- (NSImage *)icon {
  return _clean ? _ondisk : _icon;
}
/* If disk icon loaded an is the same as disk icon => clean = YES */
- (void)setIcon:(NSImage *)anImage {
  if (_icon != anImage) {
    _icon = nil;
    if (_loaded && anImage == _ondisk) {
      _clean = YES;
    } else {
      _clean = NO;
      _icon = anImage;
    }
  } else if (_icon != _ondisk) {
    /* if delete */
    _clean = NO;
  }
}

- (void)setCachedIcon:(NSImage *)anImage {
  NSAssert(_loaded == NO, @"Try to load an already loaded icon");
  _loaded = YES;
  _ondisk = anImage;
  /* If load icon after setting it */
  if (_ondisk == _icon) {
    _clean = YES;
    _icon = nil;
  }
}

- (BOOL)loaded {
  return _loaded;
}

- (BOOL)hasChanged {
  return !_clean;
}
- (void)applyChange {
  if (!_clean) {
    _clean = YES;
    _ondisk = _icon;
    _icon = nil;
  }
}

@end
