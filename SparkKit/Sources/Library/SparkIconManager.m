/*
 *  SparkIconManager.m
 *  SparkKit
 *
 *  Created by Black Moon Team.
 *  Copyright (c) 2004 - 2007 Shadow Lab. All rights reserved.
 */

#import <SparkKit/SparkIconManager.h>
#import <SparkKit/SparkObject.h>
#import <SparkKit/SparkLibrary.h>
#import <SparkKit/SparkObjectSet.h>

#import <ShadowKit/SKFSFunctions.h>

enum {
  kSparkInvalidType = 0xff
};
@class SparkList, SparkAction, SparkTrigger, SparkApplication;
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

@interface _SparkIconEntry : NSObject {
  BOOL sp_clean;
  BOOL sp_loaded;

  @private
  NSImage *sp_icon;
  NSString *sp_path;
  NSImage *sp_ondisk;
}

- (BOOL)loaded;
- (BOOL)hasChanged;
- (void)applyChange;

- (id)initWithObject:(SparkObject *)object;

- (NSString *)path;

- (NSImage *)icon;
- (void)setIcon:(NSImage *)anImage;

- (void)setCachedIcon:(NSImage *)anImage;

@end

#pragma mark -
@implementation SparkIconManager

- (id)initWithLibrary:(SparkLibrary *)aLibrary path:(NSString *)path {
  if (self = [super init]) {
    BOOL isDir = NO;
    sp_path = [path copy];
    if (![[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&isDir]) {
      SKFSCreateFolder((CFStringRef)path);
    } else if (!isDir) {
      [self release];
      [NSException raise:NSInvalidArgumentException format:@"%@ MUST be a directory", path];
    }
    for (unsigned idx = 0; idx < 4; idx++) {
      sp_cache[idx] = NSCreateMapTable(NSIntMapKeyCallBacks, NSObjectMapValueCallBacks, 0);
      NSString *dir = [path stringByAppendingPathComponent:[NSString stringWithFormat:@"%u", idx]];
      if (![[NSFileManager defaultManager] fileExistsAtPath:dir])
        SKFSCreateFolder((CFStringRef)dir);
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
  for (unsigned idx = 0; idx < 4; idx++) {
    if (sp_cache[idx]) NSFreeMapTable(sp_cache[idx]);
  }
  [sp_path release];
  [super dealloc];
}

- (NSImage *)iconForObject:(SparkObject *)anObject {
  UInt8 type = __SparkIconTypeForObject(anObject);
  if (type != kSparkInvalidType) {
    _SparkIconEntry *entry = NSMapGet(sp_cache[type], (void *)[anObject uid]);
    if (!entry) {
      entry = [[_SparkIconEntry alloc] initWithObject:anObject];
      NSMapInsert(sp_cache[type], (void *)[anObject uid], entry);
      [entry release];
    }
    if (![entry loaded]) {
      NSString *path = [sp_path stringByAppendingPathComponent:[entry path]];
      if ([[NSFileManager defaultManager] fileExistsAtPath:path]) {
        NSImage *icon = [[NSImage alloc] initByReferencingFile:path];
        /* Set icon from disk */
        [entry setCachedIcon:icon];
        [icon release];
      } else {
        /* No icon on disk */
        [entry setCachedIcon:nil];
        DLog(@"Request invalid icon for object: %@", anObject);
      }
    }
    return [entry icon];
  }
  return nil;
}

- (void)setIcon:(NSImage *)icon forObject:(SparkObject *)anObject {
  UInt8 type = __SparkIconTypeForObject(anObject);
  if (type != kSparkInvalidType) {
    _SparkIconEntry *entry = NSMapGet(sp_cache[type], (void *)[anObject uid]);
    if (!entry) {
      entry = [[_SparkIconEntry alloc] initWithObject:anObject];
      NSMapInsert(sp_cache[type], (void *)[anObject uid], entry);
      [entry release];
    }
    
    /* Adjust resolution */
    if (icon) {
      NSArray *reps = [icon representations];
      if ([reps count] > 1) {
        for (unsigned idx = 0; idx < [reps count]; idx++) {
          NSImageRep *rep = [reps objectAtIndex:idx];
          if ([rep isKindOfClass:[NSBitmapImageRep class]])
            if ([rep size].height > 16 || [rep size].width > 16)
              [rep setSize:NSMakeSize(16, 16)];
        }
      }
    }
    [entry setIcon:icon];
  }
}

- (void)synchronize:(NSMapTable *)entries {
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

- (BOOL)synchronize {
  for (unsigned idx = 0; idx < 4; idx++) {
    [self synchronize:sp_cache[idx]];
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
