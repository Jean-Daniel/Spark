/*
 *  SparkList.m
 *  SparkKit
 *
 *  Created by Grayfox on 30/07/06.
 *  Copyright 2006 Shadow Lab. All rights reserved.
 */

#import <SparkKit/SparkList.h>
#import <SparkKit/SparkLibrary.h>
#import <SparkKit/SparkObjectSet.h>

#import <ShadowKit/SKSerialization.h>
#import <ShadowKit/SKAppKitExtensions.h>

NSString * const SparkListDidChangeNotification = @"SparkListDidReload";

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

- (NSImage *)icon {
  NSImage *icon = [super icon];
  if (!icon) {
    icon = [NSImage imageNamed:@"SimpleList" inBundle:SKCurrentBundle()];
    [self setIcon:icon];
  }
  return icon;
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
    [[[sp_set library] notificationCenter] postNotificationName:SparkListDidChangeNotification
                                                         object:self];
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

- (BOOL)serialize:(NSMutableDictionary *)plist {
  /* Do not save list icon */
  NSImage *icon = [[super icon] retain];
  [super setIcon:nil];
  [super serialize:plist];
  [super setIcon:icon];
  [icon release];
  
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

- (unsigned)count {
  return [sp_entries count];
}
- (NSEnumerator *)objectEnumerator {
  return [sp_entries objectEnumerator];
}
- (void)addObject:(SparkObject *)anObject {
  [sp_entries addObject:anObject];
  [[[sp_set library] notificationCenter] postNotificationName:SparkListDidChangeNotification
                                                       object:self];
}
- (void)addObjectsFromArray:(NSArray *)anArray {
  [sp_entries addObjectsFromArray:anArray];
  [[[sp_set library] notificationCenter] postNotificationName:SparkListDidChangeNotification
                                                       object:self];  
}

- (BOOL)containsObject:(SparkObject *)anObject {
  return [sp_entries containsObject:anObject];
}

- (void)removeObject:(SparkObject *)anObject {
  unsigned idx = [sp_entries indexOfObject:anObject];
  if (idx != NSNotFound) {
    [sp_entries removeObjectAtIndex:idx];
    [[[sp_set library] notificationCenter] postNotificationName:SparkListDidChangeNotification
                                                         object:self];
  }
}
- (void)removeObjectsInArray:(NSArray *)anArray {
  unsigned cnt = [sp_entries count];
  [sp_entries removeObjectsInArray:anArray];
  if (cnt != [sp_entries count])
    [[[sp_set library] notificationCenter] postNotificationName:SparkListDidChangeNotification
                                                         object:self];
}

#pragma mark -
- (void)didAddObject:(NSNotification *)aNotification {
  SparkObject *object = SparkNotificationObject(aNotification);
  if (object && sp_filter && sp_filter(object, sp_ctxt)) {
    [self addObject:object];
  }
}
- (void)didUpdateObject:(NSNotification *)aNotification {
  unsigned idx = 0;
  SparkObject *object = SparkNotificationObject(aNotification);
  SparkObject *previous = [[aNotification userInfo] objectForKey:kSparkNotificationUpdatedObject];
  /* If contains old value */
  if (previous && (idx = [sp_entries indexOfObject:previous]) != NSNotFound) {
    /* If is not smart, or updated object is always valid, replace old value */
    if (!sp_filter || sp_filter(object, sp_ctxt)) {
      [sp_entries replaceObjectAtIndex:idx withObject:object];
    } else {
      /* remove old value */
      [sp_entries removeObjectAtIndex:idx];
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
    [sp_entries removeObject:object];
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
