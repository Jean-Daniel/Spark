//
//  Extensions.m
//  Spark Editor
//
//  Created by Fox on 02/09/04.
//  Copyright 2004 Shadow Lab. All rights reserved.
//

#import "Extensions.h"

@implementation KVBSparkObjectList

- (id)init {
  if (self = [super init]) {
    [self setLibrary:SparkDefaultLibrary()];
  }
  return self;
}

#pragma mark -
#pragma mark KVO Manual Notification

- (void)addObject:(id)object {
  id indexes = [NSIndexSet indexSetWithIndex:[self count]];
  [self willChange:NSKeyValueChangeInsertion valuesAtIndexes:indexes forKey:@"objects"];
  [super addObject:object];
  [self didChange:NSKeyValueChangeInsertion valuesAtIndexes:indexes forKey:@"objects"];
}

- (void)addObjects:(id)objects {
  id indexes = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange([self count], [objects count])];
  [self willChange:NSKeyValueChangeInsertion valuesAtIndexes:indexes forKey:@"objects"];
  [super addObjects:objects];
  [self didChange:NSKeyValueChangeInsertion valuesAtIndexes:indexes forKey:@"objects"];
}

- (void)removeObject:(id)object {
  int index = [self indexOfObject:object];
  if (NSNotFound != index) {
    id indexes = [NSIndexSet indexSetWithIndex:index];
    [self willChange:NSKeyValueChangeRemoval valuesAtIndexes:indexes forKey:@"objects"];
    [super removeObjectAtIndex:index];
    [self didChange:NSKeyValueChangeRemoval valuesAtIndexes:indexes forKey:@"objects"];
  }
}

- (void)removeObjects:(NSArray *)objects {
  id items = [objects objectEnumerator];
  id object;
  while (object = [items nextObject]) {
    [self removeObject:object];
  }
}

#pragma mark -
#pragma mark KVB Compliance Implementation

- (void)insertObject:(id)object inObjectsAtIndex:(unsigned)index {
  ShadowTrace();
  [super insertObject:object atIndex:index];
}

- (void)removeObjectFromObjectsAtIndex:(unsigned)index {
  ShadowTrace();
  [super removeObjectAtIndex:index];
}

- (void)replaceObjectInObjectsAtIndex:(unsigned)index withObject:(id)object {
  ShadowTrace();
  [super replaceObjectAtIndex:index withObject:object];
}

@end

#pragma mark -
@implementation NSArrayController (SparkExtension)

- (NSEnumerator *)objectEnumerator {
  return [[self content] objectEnumerator];
}

- (id)objectAtIndex:(unsigned)rowIndex {
  return [[self arrangedObjects] objectAtIndex:rowIndex];
}

- (id)selectedObject {
  id selection = [self selectedObjects];
  if ([selection count]) {
    return [selection objectAtIndex:0];
  }
  return nil;
}

- (BOOL)setSelectedObject:(id)object {
  return [self setSelectedObjects:[NSArray arrayWithObject:object]];
}

- (void)deleteSelection {
  [self removeObjects:[self selectedObjects]];
}

- (void)removeAllObjects {
  [self removeObjects:[self content]];
}

@end

@implementation SparkLibraryObject (DuplicateExtension)

- (id)duplicate {
  id plist = [self propertyList];
  id copy = [[[self class] alloc] initFromPropertyList:plist];
  [copy setUid:nil];
  return [copy autorelease];
}

@end

#pragma mark -
#pragma mark Missing Method
@implementation NSTabView (Extension)
- (int)indexOfSelectedTabViewItem {
  return [self indexOfTabViewItem:[self selectedTabViewItem]]; 
}
@end
