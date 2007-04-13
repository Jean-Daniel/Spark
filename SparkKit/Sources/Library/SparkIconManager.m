/*
 *  SparkIconManager.m
 *  SparkKit
 *
 *  Created by Black Moon Team.
 *  Copyright (c) 2004 - 2007 Shadow Lab. All rights reserved.
 */

#import "SparkIconManagerPrivate.h"

#import <SparkKit/SparkList.h>
#import <SparkKit/SparkAction.h>
#import <SparkKit/SparkTrigger.h>
#import <SparkKit/SparkApplication.h>

#import <SparkKit/SparkObject.h>
#import <SparkKit/SparkLibrary.h>
#import <SparkKit/SparkObjectSet.h>

#import <ShadowKit/SKImageUtils.h>
#import <ShadowKit/SKFSFunctions.h>

enum {
  kSparkInvalidType = 0xff
};
SK_INLINE
UInt8 __SparkIconTypeForObject(SparkObject *object) {
  Class cls = [object class];
  if ([cls isSubclassOfClass:[SparkList class]])
    return 0;
  if ([cls isSubclassOfClass:[SparkAction class]])
    return 1;
  if ([cls isSubclassOfClass:[SparkTrigger class]])
    return 2;
  if ([cls isSubclassOfClass:[SparkApplication class]])
    return 3;
  return kSparkInvalidType;
}

SparkObjectSet *_SparkObjectSetForType(SparkLibrary *library, UInt8 type) {
  switch (type) {
    case 0:
      return [library listSet];
    case 1:
      return [library actionSet];
    case 2:
      return [library triggerSet];
    case 3:
      return [library applicationSet];
  }
  return nil;
}

#pragma mark -
@implementation SparkIconManager

- (id)initWithLibrary:(SparkLibrary *)aLibrary path:(NSString *)path {
  NSParameterAssert(aLibrary != nil);
  if (self = [super init]) {
    @try {
      [self setPath:path];
    } @catch (id exception) {
      [self release];
      @throw exception;
    }
    
    for (NSUInteger idx = 0; idx < 4; idx++) {
      sp_cache[idx] = NSCreateMapTable(NSIntMapKeyCallBacks, NSObjectMapValueCallBacks, 0);
    }
    
    sp_library = aLibrary;
    /* Listen notifications */
    [[sp_library notificationCenter] addObserver:self
                                        selector:@selector(didAddObject:)
                                            name:SparkObjectSetDidAddObjectNotification 
                                          object:nil];
    [[sp_library notificationCenter] addObserver:self
                                        selector:@selector(didUpdateObject:)
                                            name:SparkObjectSetDidUpdateObjectNotification 
                                          object:nil];
    [[sp_library notificationCenter] addObserver:self
                                        selector:@selector(willRemoveObject:)
                                            name:SparkObjectSetWillRemoveObjectNotification 
                                          object:nil];
  }
  return self;
}

- (void)dealloc {
  [[sp_library notificationCenter] removeObserver:self];
  for (NSUInteger idx = 0; idx < 4; idx++) {
    if (sp_cache[idx]) NSFreeMapTable(sp_cache[idx]);
  }
  [sp_path release];
  [super dealloc];
}

#pragma mark -
- (NSString *)path {
  return sp_path;
}

- (void)setPath:(NSString *)path {
  if (sp_path)
    [NSException raise:NSInvalidArgumentException format:@"%@ does not support rename", [self class]];
  
  if (path) {
    BOOL isDir = NO;
    if (![[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&isDir]) {
      if (noErr != SKFSCreateFolder((CFStringRef)path)) {
        [NSException raise:NSInvalidArgumentException format:@"could not create directory at path %@", path];
      }
    } else if (!isDir) {
      [NSException raise:NSInvalidArgumentException format:@"%@ is not a directory", path];
    }
    for (NSUInteger idx = 0; idx < 4; idx++) {
      NSString *dir = [path stringByAppendingPathComponent:[NSString stringWithFormat:@"%u", idx]];
      if (![[NSFileManager defaultManager] fileExistsAtPath:dir])
        [[NSFileManager defaultManager] createDirectoryAtPath:dir attributes:nil];
    }
    
    sp_path = [path copy];
  }
}

- (_SparkIconEntry *)entryForObject:(SparkObject *)anObject {
  _SparkIconEntry *entry = nil;
  UInt8 type = __SparkIconTypeForObject(anObject);
  if (type != kSparkInvalidType) {
    entry = NSMapGet(sp_cache[type], (void *)(long)[anObject uid]);
    if (!entry) {
      entry = [[_SparkIconEntry alloc] initWithObject:anObject];
      NSMapInsert(sp_cache[type], (void *)(long)[anObject uid], entry);
      [entry release];
    }
  }
  return entry;
}

- (NSImage *)iconForObject:(SparkObject *)anObject {
  _SparkIconEntry *entry = [self entryForObject:anObject];
  if (entry && ![entry loaded] && sp_path) {
    NSString *path = [sp_path stringByAppendingPathComponent:[entry path]];
    if ([[NSFileManager defaultManager] fileExistsAtPath:path]) {
      NSImage *icon = [[NSImage alloc] initByReferencingFile:path];
      /* Set icon from disk */
      //DLog(@"Load icon (%@): %@", [anObject name], icon);
      [entry setCachedIcon:icon];
      [icon release];
    } else {
      /* No icon on disk */
      [entry setCachedIcon:nil];
      DLog(@"Icon not found in cache for object: %@", anObject);
    }
  }
  return [entry icon];
}

- (void)setIcon:(NSImage *)icon forObject:(SparkObject *)anObject {
  _SparkIconEntry *entry = [self entryForObject:anObject];
  if (entry) {
    /* Adjust resolution */
    if (icon) {
      SKImageSetRepresentationsSize(icon, NSMakeSize(16, 16));
    }
    [entry setIcon:icon];
  }
}

- (void)synchronize:(NSMapTable *)entries {
  if (sp_path) {
    _SparkIconEntry *entry;
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    NSMapEnumerator items = NSEnumerateMapTable(entries);
    while (NSNextMapEnumeratorPair(&items, NULL, (void **)&entry)) {
      if ([entry hasChanged]) {
        NSString *path = [sp_path stringByAppendingPathComponent:[entry path]];
        if (![entry icon]) {
          DLog(@"delete icon: %@", path);
          [[NSFileManager defaultManager] removeFileAtPath:path handler:nil];
        } else {
          NSData *data = [[entry icon] TIFFRepresentationUsingCompression:NSTIFFCompressionLZW factor:1];
          if (data) {
            DLog(@"save icon: %@", path);
            [data writeToFile:path atomically:NO];
          }
        }
        [entry applyChange];
      }
    }
    NSEndMapTableEnumeration(&items);
    [pool release];
  }
}

- (BOOL)synchronize {
  if (sp_path) {
    for (NSUInteger idx = 0; idx < 4; idx++) {
      [self synchronize:sp_cache[idx]];
    }
  } else {
    DLog(@"WARNING: sync icon cache with undefined path");
  }
  return YES;
}

#pragma mark Notifications
- (void)didAddObject:(NSNotification *)aNotification {
  SparkObject *object = SparkNotificationObject(aNotification);
  if ([object shouldSaveIcon] && [object hasIcon])
    [self setIcon:[object icon] forObject:object];
}

- (void)didUpdateObject:(NSNotification *)aNotification {
  SparkObject *object = SparkNotificationObject(aNotification);
  SparkObject *updated = SparkNotificationUpdatedObject(aNotification);
  /* should no longer save icon or has no icon */
  if (![object shouldSaveIcon] || ![object hasIcon]) {
    /* Remove previous */
    if ([updated shouldSaveIcon])
      [self setIcon:nil forObject:object];
  } else {
    [self setIcon:[object icon] forObject:object];
  }
}

- (void)willRemoveObject:(NSNotification *)aNotification {
  SparkObject *object = SparkNotificationObject(aNotification);
  if ([object shouldSaveIcon])
    [self setIcon:nil forObject:object];
}

@end

#pragma mark -
@implementation _SparkIconEntry

- (id)initWithObject:(SparkObject *)object {
  if (self = [super init]) {
    sp_clean = YES;
    UInt32 uid = [object uid];
    UInt32 type = __SparkIconTypeForObject(object);
    sp_path = [[NSString alloc] initWithFormat:@"%u/%u", type, uid];
  }
  return self;
}

- (void)dealloc {
  [sp_path release];
  [sp_icon release];
  [sp_ondisk release];
  [super dealloc];
}

#pragma mark -
- (NSString *)path {
  return sp_path;
}

- (NSImage *)icon {
  return sp_clean ? sp_ondisk : sp_icon;
}
/* If disk icon loaded an is the same as disk icon => clean = YES */
- (void)setIcon:(NSImage *)anImage {
  if (sp_icon != anImage) {
    [sp_icon release];
    sp_icon = nil;
    if (sp_loaded && anImage == sp_ondisk) {
      sp_clean = YES;
    } else {
      sp_clean = NO;
      sp_icon = [anImage retain];
    }
  } else if (sp_icon != sp_ondisk) {
    /* if delete */
    sp_clean = NO;
  }
}

- (void)setCachedIcon:(NSImage *)anImage {
  NSAssert(sp_loaded == NO, @"Try to load an already loaded icon");
  sp_loaded = YES;
  sp_ondisk = [anImage retain];
  /* If load icon after setting it */
  if (sp_ondisk == sp_icon) {
    sp_clean = YES;
    [sp_icon release];
    sp_icon = nil;
  }
}

- (BOOL)loaded {
  return sp_loaded;
}

- (BOOL)hasChanged {
  return !sp_clean;
}
- (void)applyChange {
  if (!sp_clean) {
    sp_clean = YES;
    [sp_ondisk release];
    sp_ondisk = sp_icon;
    sp_icon = nil;
  }
}
@end
