/*
 *  SparkList.m
 *  SparkKit
 *
 *  Created by Black Moon Team.
 *  Copyright (c) 2004 - 2007 Shadow Lab. All rights reserved.
 */

#import <SparkKit/SparkList.h>
#import <SparkKit/SparkLibrary.h>
#import <SparkKit/SparkObjectSet.h>

#import <ShadowKit/SKSerialization.h>
#import <ShadowKit/SKAppKitExtensions.h>

/* Reload when filter change */
NSString * const SparkListDidReloadNotification = @"SparkListDidReload";

NSString * const SparkListDidAddObjectNotification = @"SparkListDidAddObject";
NSString * const SparkListDidAddObjectsNotification = @"SparkListDidAddObjects";

NSString * const SparkListDidUpdateObjectNotification = @"SparkListDidUpdateObject";

NSString * const SparkListDidRemoveObjectNotification = @"SparkListDidRemoveObject";
NSString * const SparkListDidRemoveObjectsNotification = @"SparkListDidRemoveObjects";

static 
NSString * const kSparkObjectsKey = @"SparkObjects";

@implementation SparkList

- (id)init {
  return [self initWithObjectSet:nil];
}

- (id)initWithObjectSet:(SparkObjectSet *)aLibrary {
  if (self = [self initWithName:nil icon:nil]) {
    [self setObjectSet:aLibrary];
  }
  return self;
}

- (id)initWithName:(NSString *)name icon:(NSImage *)icon {
  if (self = [super initWithName:name icon:icon]) {
    sp_entries = [[NSMutableArray alloc] init];
  }
  return self;
}

- (void)dealloc {
  [self setObjectSet:nil];
  [sp_entries release];
  [sp_ctxt release];
  [super dealloc];
}

#pragma mark -
- (BOOL)serialize:(NSMutableDictionary *)plist {
  if ([super serialize:plist]) {
    NSMutableArray *objects = [[NSMutableArray alloc] init];
    
    SparkObject *entry;
    NSEnumerator *entries = [sp_entries objectEnumerator];
    while (entry = [entries nextObject]) {
      [objects addObject:SKUInt([entry uid])];
    }
    [plist setObject:objects forKey:kSparkObjectsKey];
    
    [objects release];
    return YES;
  }
  return NO;
}

- (id)initWithSerializedValues:(NSDictionary *)plist objectSet:(SparkObjectSet *)library  {
  if (self = [super initWithSerializedValues:plist]) {
    [self setObjectSet:library];
    // Load plist
    NSNumber *entry;
    sp_entries = [[NSMutableArray alloc] init];
    NSEnumerator *entries = [[plist objectForKey:kSparkObjectsKey] objectEnumerator];
    while (entry = [entries nextObject]) {
      SparkObject *object = [library objectForUID:[entry unsignedIntValue]];
      if (object)
        [sp_entries addObject:object];
      else
        DLog(@"Cannot resolve reference %@", entry);
    }
  }
  return self;
}

#pragma mark -
- (NSImage *)icon {
  NSImage *icon = [super icon];
  if (!icon) {
    icon = [NSImage imageNamed:@"SimpleList" inBundle:SKCurrentBundle()];
    [self setIcon:icon];
  }
  return icon;
}

- (BOOL)shouldSaveIcon {
  return NO;
}

- (void)reload {
  if ([self isDynamic]) {
    /* Refresh objects */
    [sp_entries removeAllObjects];
    if (sp_filter && sp_set) {
      SparkObject *object;
      NSEnumerator *objects = [sp_set objectEnumerator];
      while (object = [objects nextObject]) {
        if (sp_filter(object, sp_ctxt)) {
          [sp_entries addObject:object];
        }
      }
    }
    SparkLibraryPostNotification([sp_set library], SparkListDidReloadNotification, self, nil);
  }
}

- (BOOL)isDynamic {
  return sp_filter != NULL;
}

- (void)setObjectSet:(SparkObjectSet *)library {
  if (sp_set != library) {
    /* unregister notifications */
    if (sp_set) {
      [[[sp_set library] notificationCenter] removeObserver:self
                                                       name:nil
                                                     object:sp_set];
    }
    sp_set = library;
    /* register notifications */
    if (sp_set) {
      /* Add */
      [[[sp_set library] notificationCenter] addObserver:self
                                                selector:@selector(didAddObject:)
                                                    name:SparkObjectSetDidAddObjectNotification
                                                  object:sp_set];
      /* Remove */
      [[[sp_set library] notificationCenter] addObserver:self
                                                selector:@selector(didRemoveObject:)
                                                    name:SparkObjectSetDidRemoveObjectNotification
                                                  object:sp_set];
      /* Update */
      [[[sp_set library] notificationCenter] addObserver:self
                                                selector:@selector(didUpdateObject:)
                                                    name:SparkObjectSetDidUpdateObjectNotification
                                                  object:sp_set];
    }
    /* Refresh contents if smart list */
    if (sp_filter)
      [self reload];
  }
}

- (id)filterContext {
  return sp_ctxt;
}
- (void)setListFilter:(SparkListFilter)aFilter context:(id)aCtxt {
  sp_filter = aFilter;
  SKSetterRetain(sp_ctxt, aCtxt);
  /* Refresh contents */
  [self reload];
}

#pragma mark -
#pragma mark Array
- (unsigned)count {
  return [sp_entries count];
}
- (BOOL)containsObject:(SparkObject *)anObject {
  return [sp_entries containsObject:anObject];
}
- (NSEnumerator *)objectEnumerator {
  return [sp_entries objectEnumerator];
}

#pragma mark Modification
- (NSUndoManager *)undoManager {
  return [[sp_set library] undoManager];
}

- (void)addObject:(SparkObject *)anObject {
  /* Undo Manager */
  [[self undoManager] registerUndoWithTarget:self selector:@selector(removeObject:) object:anObject];
  [sp_entries addObject:anObject];
  SparkLibraryPostNotification([sp_set library], SparkListDidAddObjectNotification, self, anObject);
}
- (void)addObjectsFromArray:(NSArray *)anArray {
  /* Undo Manager */
  [[self undoManager] registerUndoWithTarget:self selector:@selector(removeObjectsInArray:) object:anArray];
  [sp_entries addObjectsFromArray:anArray];
  SparkLibraryPostNotification([sp_set library], SparkListDidAddObjectsNotification, self, anArray);
}

- (void)removeObject:(SparkObject *)anObject {
  unsigned idx = [sp_entries indexOfObject:anObject];
  if (idx != NSNotFound) {
    [anObject retain];
    /* Undo Manager */
    [[self undoManager] registerUndoWithTarget:self selector:@selector(addObject:) object:[sp_entries objectAtIndex:idx]];
    [sp_entries removeObjectAtIndex:idx];
    SparkLibraryPostNotification([sp_set library], SparkListDidRemoveObjectNotification, self, anObject);
    [anObject release];
  }
}
- (void)removeObjectsInArray:(NSArray *)anArray {
  unsigned count = [anArray count];
  NSMutableArray *removed = [[NSMutableArray alloc] init];
  while (count-- > 0) {
    unsigned idx = [sp_entries indexOfObject:[anArray objectAtIndex:count]];
    if (NSNotFound != idx) {
      [removed addObject:[sp_entries objectAtIndex:idx]];
      [sp_entries removeObjectAtIndex:idx];
    }
  }
  if ([removed count]) {
    /* Undo Manager */
    [[self undoManager] registerUndoWithTarget:self selector:@selector(addObjectsFromArray:) object:removed];    
    SparkLibraryPostNotification([sp_set library], SparkListDidRemoveObjectsNotification, self, removed);
  }
  [removed release];    
}

#pragma mark -
#pragma mark Notifications
- (void)didAddObject:(NSNotification *)aNotification {
  SparkObject *object = SparkNotificationObject(aNotification);
  if (object && sp_filter && sp_filter(object, sp_ctxt)) {
    [self addObject:object];
  }
}
- (void)didUpdateObject:(NSNotification *)aNotification {
  unsigned idx = 0;
  SparkObject *object = SparkNotificationObject(aNotification);
  SparkObject *previous = SparkNotificationUpdatedObject(aNotification);
  /* If contains old value */
  if (previous && (idx = [sp_entries indexOfObject:previous]) != NSNotFound) {
    /* If is not smart, or updated object is always valid, replace old value */
    if (!sp_filter || sp_filter(object, sp_ctxt)) {
      [sp_entries replaceObjectAtIndex:idx withObject:object];
      SparkLibraryPostUpdateNotification([sp_set library], SparkListDidUpdateObjectNotification, self, previous, object);
    } else {
      /* remove old value */
      [self removeObject:object];
    }
  } else {
    /* Do not contains previous value but updated object is valid */
    if (sp_filter && sp_filter(object, sp_ctxt)) {
      [self addObject:object];
    }
  }
}

- (void)didRemoveObject:(NSNotification *)aNotification {
  SparkObject *object = SparkNotificationObject(aNotification);
  if (object)
    [self removeObject:object];
}

@end

#pragma mark -
@implementation SparkListSet

static id _SparkListDeserialize(Class cls, NSDictionary *plist, void *ctxt) {
  return [cls instancesRespondToSelector:@selector(initWithSerializedValues:objectSet:)] ? 
  [[cls alloc] initWithSerializedValues:plist objectSet:[(id)ctxt triggerSet]] : nil;
}

- (SparkObject *)deserialize:(NSDictionary *)plist error:(OSStatus *)error {
  return SKDeserializeObjectWithFunction(plist, error, _SparkListDeserialize, [self library]);
}

@end
