/*
 *  SparkList.m
 *  SparkKit
 *
 *  Created by Black Moon Team.
 *  Copyright (c) 2004 - 2007 Shadow Lab. All rights reserved.
 */

#import <SparkKit/SparkList.h>
#import <SparkKit/SparkEntry.h>
#import <SparkKit/SparkPrivate.h>
#import <SparkKit/SparkApplication.h>
#import <SparkKit/SparkEntryManager.h>

#import <WonderBox/NSArray+WonderBox.h>
#import <WonderBox/NSImage+WonderBox.h>

#import "SparkEntryPrivate.h"

/* Reload when filter change */
NSString * const SparkListDidReloadNotification = @"SparkListDidReload";

NSString * const SparkListDidAddObjectNotification = @"SparkListDidAddObject";
NSString * const SparkListDidAddObjectsNotification = @"SparkListDidAddObjects";

NSString * const SparkListDidUpdateObjectNotification = @"SparkListDidUpdateObject";

NSString * const SparkListDidRemoveObjectNotification = @"SparkListDidRemoveObject";
NSString * const SparkListDidRemoveObjectsNotification = @"SparkListDidRemoveObjects";

static 
NSString * const kSparkObjectsKey = @"SparkObjects";

@implementation SparkList {
@private
  SparkListFilter _filter;
  NSMutableArray *_entries;
}

- (id)initWithName:(NSString *)name icon:(NSImage *)icon {
  if (self = [super initWithName:name icon:icon]) {
    _entries = [[NSMutableArray alloc] init];
  }
  return self;
}

- (void)dealloc {
  [self setLibrary:nil];
}

#pragma mark -
- (id)initWithCoder:(NSCoder *)coder {
  if (self = [super initWithCoder:coder]) {
    NSAssert([self library], @"invalid unarchiver");
    _entries = [coder decodeObjectForKey:@"entries"];
  }
  return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
  [super encodeWithCoder:coder];
  [coder encodeObject:_entries forKey:@"entries"];
}

- (BOOL)serialize:(NSMutableDictionary *)plist {
  return NO;
}

- (id)initWithSerializedValues:(NSDictionary *)plist  {
  return [super initWithSerializedValues:plist];
}

#pragma mark -
- (NSImage *)icon {
  NSImage *icon = [super icon];
  if (!icon) {
    icon = [NSImage imageNamed:@"SimpleList" inBundle:SparkKitBundle()];
    [self setIcon:icon];
  }
  return icon;
}

- (BOOL)shouldSaveIcon {
  return NO;
}

- (void)reload {
  if (self.isDynamic) {
    [self willChangeValueForKey:@"entries"];
    /* Refresh objects */
    [_entries removeAllObjects];
    if (_filter) {
      [self.library.entryManager enumerateEntriesUsingBlock:^(SparkEntry *entry, BOOL *stop) {
        if ([entry isRoot] && [self acceptsEntryOrChild:entry]) {
          [self->_entries addObject:entry];
        }
      }];
    }
    [self didChangeValueForKey:@"entries"];
    SparkLibraryPostNotification([self library], SparkListDidReloadNotification, self, nil);
  }
}

- (BOOL)isDynamic {
  return _filter != NULL;
}

- (void)setLibrary:(SparkLibrary *)aLibrary {
  if (aLibrary != self.library) {
    if (self.library) {
      NSNotificationCenter *nc = self.library.notificationCenter;
      [nc removeObserver:self
                    name:SparkEntryManagerDidAddEntryNotification
                  object:nil];
      [nc removeObserver:self
                    name:SparkEntryManagerDidUpdateEntryNotification
                  object:nil];
      [nc removeObserver:self
                    name:SparkEntryManagerWillRemoveEntryNotification
                  object:nil];
      /* Entry tree */
      //			[nc removeObserver:self
      //																										 name:SparkEntryDidAppendChildNotification
      //																									 object:nil];
      [nc removeObserver:self
                    name:SparkEntryWillRemoveChildNotification
                  object:nil];
    }
    [super setLibrary:aLibrary];
    if (self.library) {
      NSNotificationCenter *nc = self.library.notificationCenter;
      /* Add */
      [nc addObserver:self
             selector:@selector(didAddEntry:)
                 name:SparkEntryManagerDidAddEntryNotification
               object:nil];
      /* Update */
      [nc addObserver:self
             selector:@selector(didUpdateEntry:)
                 name:SparkEntryManagerDidUpdateEntryNotification
               object:nil];
      /* Remove */
      [nc addObserver:self
             selector:@selector(willRemoveEntry:)
                 name:SparkEntryManagerWillRemoveEntryNotification
               object:nil];
      /* Entry tree */
      //			[nc addObserver:self
      //                                              selector:@selector(didAppendEntryChild:)
      //                                                  name:SparkEntryDidAppendChildNotification
      //                                                object:nil];
      //      [nc addObserver:self
      //                                              selector:@selector(willRemoveEntryChild:)
      //                                                  name:SparkEntryWillRemoveChildNotification
      //                                                object:nil];
    }
  }
}

- (void)setFilter:(SparkListFilter)aFilter {
  _filter = aFilter;
  [self reload]; // Refresh contents
}

#pragma mark -
#pragma mark Array
- (NSUInteger)count {
  return [_entries count];
}
- (BOOL)containsEntry:(SparkEntry *)anEntry {
	return [_entries containsObject:[anEntry root]];
}
- (NSUInteger)indexOfEntry:(SparkEntry *)anEntry {
	return [_entries indexOfObject:[anEntry root]];
}

- (NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state objects:(id __unsafe_unretained [])buffer count:(NSUInteger)len {
  return [_entries countByEnumeratingWithState:state objects:buffer count:len];
}

- (NSArray *)entriesForApplication:(SparkApplication *)anApplication {
	NSMutableArray *entries = [NSMutableArray array];
	bool isSystem = kSparkApplicationSystemUID == [anApplication uid];
	for (SparkEntry *entry in _entries) {
		if (isSystem) {
			/* looking for system entries */
			if ([entry isSystem]) 
				[entries addObject:entry];
		} else if ([entry isSystem]) {
			/* looking for custom entries and entry is a system entry... */
			SparkEntry *child = [entry variantWithApplication:anApplication];
			if (child)
				[entries addObject:child];
			else
				[entries addObject:entry];
		} else if ([anApplication isEqual:[entry application]]) {
			/* looking for custom entry and entry is an specific entry */
			[entries addObject:entry];
		}
	}
  return entries;
}

#pragma mark Modification
- (NSUndoManager *)undoManager {
  return self.library.undoManager;
}

- (void)addEntry:(SparkEntry *)anEntry {
	NSParameterAssert(!self.isDynamic);
	if ([self containsEntry:anEntry])
			 return;
	
	[self insertObject:anEntry inEntriesAtIndex:_entries.count];
}
- (void)addEntriesFromArray:(NSArray *)anArray {
	NSParameterAssert(!self.isDynamic);

	NSMutableArray *inserted = [[NSMutableArray alloc] init];
	
  for (SparkEntry *entry in anArray) {
    if (![inserted containsObjectIdenticalTo:[entry root]] &&
        ![_entries containsObjectIdenticalTo:[entry root]])
      [inserted addObject:[entry root]];
  }
	if ([inserted count] > 0) {
		/* Undo Manager */
		if (!self.isDynamic)
			[self.undoManager registerUndoWithTarget:self selector:@selector(removeEntriesInArray:) object:inserted];
		
		NSRange range = NSMakeRange([_entries count], [inserted count]);
		NSIndexSet *idxs = [NSIndexSet indexSetWithIndexesInRange:range];
		[self willChange:NSKeyValueChangeInsertion valuesAtIndexes:idxs forKey:@"entries"];
		[_entries addObjectsFromArray:inserted];
		[self didChange:NSKeyValueChangeInsertion valuesAtIndexes:idxs forKey:@"entries"];
		SparkLibraryPostNotification([self library], SparkListDidAddObjectsNotification, self, inserted);
	}
}

- (void)removeEntry:(SparkEntry *)anEntry {
	NSParameterAssert(!self.isDynamic);
	
  NSUInteger idx = [_entries indexOfObject:anEntry];
  if (idx != NSNotFound)
    [self removeObjectFromEntriesAtIndex:idx];
}
- (void)removeEntriesInArray:(NSArray *)anArray {
	NSParameterAssert(!self.isDynamic);
	
	NSUInteger count = [anArray count];
	NSMutableIndexSet *idxs = [[NSMutableIndexSet alloc] init];
	
	while (count-- > 0) {
    NSUInteger idx = [self indexOfEntry:[anArray objectAtIndex:count]];
		if (NSNotFound != idx)
			[idxs addIndex:idx];
	}
	if ([idxs count]) {
		NSArray *removed = [_entries objectsAtIndexes:idxs];
		/* Undo Manager */
    if (!self.isDynamic)
      [self.undoManager registerUndoWithTarget:self selector:@selector(addEntriesFromArray:) object:removed];
		
		[self willChange:NSKeyValueChangeRemoval valuesAtIndexes:idxs forKey:@"entries"];
		[_entries removeObjectsAtIndexes:idxs];
		[self didChange:NSKeyValueChangeRemoval valuesAtIndexes:idxs forKey:@"entries"];
		
		SparkLibraryPostNotification([self library], SparkListDidRemoveObjectsNotification, self, removed);
  }
}

#pragma mark -
#pragma mark Notifications
- (BOOL)acceptsEntry:(SparkEntry *)anEntry {
  return _filter && _filter(self, anEntry);
}
- (BOOL)acceptsEntryOrChild:(SparkEntry *)anEntry {
  if (_filter) {
		/* a specific entry (root but not system) */
		if (![anEntry isSystem])
			return _filter(self, anEntry);
			
		SparkEntry *entry = [anEntry root];
		if (_filter(self, entry))
			return YES;
		
		entry = [entry firstChild];
		while (entry) {
			if (_filter(self, entry))
				return YES;			
			entry = [entry sibling];
		}
	}
	return NO;
}

//- (void)didAppendEntryChild:(NSNotification *)aNotification {
//	if (self.isDynamic && ![self containsEntry:[aNotification object]]) {
//		SparkEntry *child = SparkNotificationObject(aNotification);
//		if ([self acceptsEntry:child])
//			[self insertObject:child inEntriesAtIndex:[_entries count]];
//	}
//}
//
//- (void)willRemoveEntryChild:(NSNotification *)aNotification {
//	
//}

/* 
 Add a new entry in the entry manager.:
 - if list is dynamic and entry is accepted, insert the entry 
 */
- (void)didAddEntry:(NSNotification *)aNotification {
	if (self.isDynamic) {
		SparkEntry *entry = SparkNotificationObject(aNotification);
		NSAssert1(entry, @"invalid notification: %@", aNotification);
		/* we do not have to check the entry children */
		if (![self containsEntry:entry] && [self acceptsEntry:entry])
			[self insertObject:entry inEntriesAtIndex:[_entries count]];
	}
}
- (void)didUpdateEntry:(NSNotification *)aNotification {
  SparkEntry *entry = [SparkNotificationObject(aNotification) root];
	
	NSUInteger idx = [self indexOfEntry:entry];
	/* If contains old value */
	if (NSNotFound != idx) {
		/* If is not smart, or updated object is always valid, replace old value */
		if (!self.isDynamic || [self acceptsEntryOrChild:entry]) {
			[_entries replaceObjectAtIndex:idx withObject:entry];
		} else {
			/* remove old value */
			[self removeObjectFromEntriesAtIndex:idx];
		}
	} else if (self.isDynamic && [self acceptsEntryOrChild:entry]) {
		/* Do not contains previous value but updated object is valid */
		[self insertObject:entry inEntriesAtIndex:[_entries count]];
	}
}

- (void)willRemoveEntry:(NSNotification *)aNotification {
  SparkEntry *entry = SparkNotificationObject(aNotification);
  NSAssert1(entry, @"invalid notification: %@", aNotification);
	
	/* 'remove' will be handle by the redo if needed */
	if (!self.isDynamic && [self.undoManager isRedoing])
		return;
	
	NSUInteger idx = [self indexOfEntry:entry];
	if (idx != NSNotFound) {
		/* do not remove entry if entry is not a root entry and entry has a sibling (or parent) valid */
		if (![entry isRoot]) {
			if (self.isDynamic) {
				SparkEntry *root = [entry root];
				if (_filter(self, root))
					return;
				root = [root firstChild];
				while (root) {
					if (root != entry && _filter(self, root))
						return;
					root = [root sibling];
				}
			} else {
				return;
			}
		}
		[self removeObjectFromEntriesAtIndex:idx];
	}
}
	
#pragma mark KVC
- (NSArray *)entries {
  return _entries;
}

- (NSUInteger)countOfEntries {
  return [_entries count];
}

- (void)setEntries:(NSArray *)entries {
  SPXSetterMutableCopy(_entries, entries);
}

- (SparkEntry *)objectInEntriesAtIndex:(NSUInteger)idx {
  return [_entries objectAtIndex:idx];
}

- (void)getEntries:(id __unsafe_unretained [])aBuffer range:(NSRange)range {
  [_entries getObjects:aBuffer range:range];
}

- (void)insertObject:(SparkEntry *)anEntry inEntriesAtIndex:(NSUInteger)idx {
  /* try to insert a non root entry */
  if (![anEntry isRoot]) {
    if ([_entries containsObjectIdenticalTo:[anEntry root]]) {
			SPXDebug(@"already in => skip");
      return;
		}
    /* insert root instead */
    anEntry = [anEntry root];
  }
	if (!self.isDynamic) {
		[[self.undoManager prepareWithInvocationTarget:self] removeObjectFromEntriesAtIndex:idx];
	}
  [_entries insertObject:anEntry atIndex:idx];
  SparkLibraryPostNotification([self library], SparkListDidAddObjectNotification, self, anEntry);
}
- (void)removeObjectFromEntriesAtIndex:(NSUInteger)idx {
  SparkEntry *entry = [_entries objectAtIndex:idx];
  /* Undo Manager */
  if (!self.isDynamic) {
    [[self.undoManager prepareWithInvocationTarget:self] insertObject:entry inEntriesAtIndex:idx];
	}
  [_entries removeObjectAtIndex:idx];
  SparkLibraryPostNotification([self library], SparkListDidRemoveObjectNotification, self, entry);
}
- (void)replaceObjectInEntriesAtIndex:(NSUInteger)idx withObject:(SparkEntry *)object {
	SparkEntry *previous = [_entries objectAtIndex:idx];
	if ([object root] == previous) return;
	
	if (!self.isDynamic)
    [[self.undoManager prepareWithInvocationTarget:self] replaceObjectAtIndex:idx withObject:previous];
  [_entries replaceObjectAtIndex:idx withObject:object];
	SparkLibraryPostUpdateNotification([self library], SparkListDidUpdateObjectNotification, self, previous, object);
}

@end

//- (void)didUpdateEntry:(NSNotification *)aNotification {
//  SparkEntry *entry = SparkNotificationObject(aNotification);
//  SparkEntry *updated = SparkNotificationUpdatedObject(aNotification);
//  if ([self acceptsEntry:entry]) {
//    /* First, get index of the previous entry */
//    NSUInteger idx = [[self entries] indexOfObject:updated];
//    if (idx != NSNotFound) {
//      // if contains updated->trigger, replace updated.
//      [self replaceObjectInEntriesAtIndex:idx withObject:entry];
//    } else {
//      // if does not contains updated->trigger, add entry
//      [self insertObject:entry inEntriesAtIndex:[[self entries] count]];
//    }
//  } else {
//    // se_list does not contain the new entry->trigger, so if se_entries contains updated, remove updated
//    NSUInteger idx = [[self entries] indexOfObject:updated];
//    if (idx != NSNotFound) {
//      [self removeObjectFromEntriesAtIndex:idx];
//    }
//  }
//}
