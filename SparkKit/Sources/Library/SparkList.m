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

@implementation SparkList

- (id)initWithName:(NSString *)name icon:(NSImage *)icon {
  if (self = [super initWithName:name icon:icon]) {
    sp_entries = [[NSMutableArray alloc] init];
  }
  return self;
}

- (void)dealloc {
  [self setLibrary:nil];
  [sp_entries release];
  [sp_ctxt release];
  [super dealloc];
}

#pragma mark -
- (id)initWithCoder:(NSCoder *)coder {
  if (self = [super initWithCoder:coder]) {
    NSAssert([self library], @"invalid unarchiver");
    sp_entries = [[coder decodeObjectForKey:@"entries"] retain];
  }
  return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
  [super encodeWithCoder:coder];
  [coder encodeObject:sp_entries forKey:@"entries"];
}

- (BOOL)serialize:(NSMutableDictionary *)plist {
  return NO;
}

- (id)initWithSerializedValues:(NSDictionary *)plist  {
  return nil;
}

#pragma mark -
- (NSImage *)icon {
  NSImage *icon = [super icon];
  if (!icon) {
    icon = [NSImage imageNamed:@"SimpleList" inBundle:kSparkKitBundle];
    [self setIcon:icon];
  }
  return icon;
}

- (BOOL)shouldSaveIcon {
  return NO;
}

- (void)reload {
  if ([self isDynamic]) {
    [self willChangeValueForKey:@"entries"];
    /* Refresh objects */
    [sp_entries removeAllObjects];
    if (sp_filter) {
      SparkEntry *entry;
      NSEnumerator *entries = [[self library] entryEnumerator];
      while (entry = [entries nextObject]) {
        if ([entry isRoot] && [self acceptsEntryOrChild:entry]) {
					[sp_entries addObject:entry];
        }
      }
    }
    [self didChangeValueForKey:@"entries"];
    SparkLibraryPostNotification([self library], SparkListDidReloadNotification, self, nil);
  }
}

- (BOOL)isDynamic {
  return sp_filter != NULL;
}

- (void)setLibrary:(SparkLibrary *)aLibrary {
  if (aLibrary != [self library]) {
    if ([self library]) {
      [[[self library] notificationCenter] removeObserver:self
                                                     name:SparkEntryManagerDidAddEntryNotification
                                                   object:nil];
      [[[self library] notificationCenter] removeObserver:self
                                                     name:SparkEntryManagerDidUpdateEntryNotification
                                                   object:nil];
      [[[self library] notificationCenter] removeObserver:self
                                                     name:SparkEntryManagerWillRemoveEntryNotification
                                                   object:nil];
			/* Entry tree */
//			[[[self library] notificationCenter] removeObserver:self
//																										 name:SparkEntryDidAppendChildNotification
//																									 object:nil];
      [[[self library] notificationCenter] removeObserver:self
																										 name:SparkEntryWillRemoveChildNotification
																									 object:nil];
    }
    [super setLibrary:aLibrary];
    if ([self library]) {
      /* Add */
      [[[self library] notificationCenter] addObserver:self
                                              selector:@selector(didAddEntry:)
                                                  name:SparkEntryManagerDidAddEntryNotification
                                                object:nil];
      /* Update */
      [[[self library] notificationCenter] addObserver:self
                                              selector:@selector(didUpdateEntry:)
                                                  name:SparkEntryManagerDidUpdateEntryNotification
                                                object:nil];
      /* Remove */
      [[[self library] notificationCenter] addObserver:self
                                              selector:@selector(willRemoveEntry:)
                                                  name:SparkEntryManagerWillRemoveEntryNotification
                                                object:nil];
			/* Entry tree */
//			[[[self library] notificationCenter] addObserver:self
//                                              selector:@selector(didAppendEntryChild:)
//                                                  name:SparkEntryDidAppendChildNotification
//                                                object:nil];
//      [[[self library] notificationCenter] addObserver:self
//                                              selector:@selector(willRemoveEntryChild:)
//                                                  name:SparkEntryWillRemoveChildNotification
//                                                object:nil];
    }
  }
}

- (id)filterContext {
  return sp_ctxt;
}
- (void)setListFilter:(SparkListFilter)aFilter context:(id)aCtxt {
  sp_filter = aFilter;
  SPXSetterRetain(sp_ctxt, aCtxt);
  [self reload]; // Refresh contents
}
- (void)reloadWithFilter:(SparkListFilter)aFilter context:(id)aCtxt {
  sp_filter = aFilter;
  SPXSetterRetain(sp_ctxt, aCtxt);
  /* Refresh contents */
  [self reload];
  /* Remove dynamic */
  sp_filter = NULL;
  SPXSetterRetain(sp_ctxt, nil);
}

#pragma mark -
#pragma mark Array
- (NSUInteger)count {
  return [sp_entries count];
}
- (BOOL)containsEntry:(SparkEntry *)anEntry {
	return [sp_entries containsObject:[anEntry root]];
}
- (NSUInteger)indexOfEntry:(SparkEntry *)anEntry {
	return [sp_entries indexOfObject:[anEntry root]];
}

- (NSArray *)entriesForApplication:(SparkApplication *)anApplication {
	NSUInteger count = [self count];
	NSMutableArray *entries = [NSMutableArray array];
	bool isSystem = kSparkApplicationSystemUID == [anApplication uid];
	for (NSUInteger idx = 0; idx < count; idx++) {
		SparkEntry *entry = [sp_entries objectAtIndex:idx];
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
  return [[self library] undoManager];
}

- (void)addEntry:(SparkEntry *)anEntry {
	NSParameterAssert(![self isDynamic]);
	if ([self containsEntry:anEntry])
			 return;
	
	[self insertObject:anEntry inEntriesAtIndex:[sp_entries count]];
}
- (void)addEntriesFromArray:(NSArray *)anArray {
	NSParameterAssert(![self isDynamic]);
	
	NSUInteger count = [anArray count];
	NSMutableArray *inserted = [[NSMutableArray alloc] init];
	
	while (count-- > 0) {
    SparkEntry *entry = [anArray objectAtIndex:count];
		if (![inserted containsObjectIdenticalTo:[entry root]] && 
				![sp_entries containsObjectIdenticalTo:[entry root]])
			[inserted addObject:[entry root]];
	}
	if ([inserted count] > 0) {
		/* Undo Manager */
		if (![self isDynamic])
			[[self undoManager] registerUndoWithTarget:self selector:@selector(removeEntriesInArray:) object:inserted];
		
		NSRange range = NSMakeRange([sp_entries count], [inserted count]);
		NSIndexSet *idxs = [NSIndexSet indexSetWithIndexesInRange:range];
		[self willChange:NSKeyValueChangeInsertion valuesAtIndexes:idxs forKey:@"entries"];
		[sp_entries addObjectsFromArray:inserted];
		[self didChange:NSKeyValueChangeInsertion valuesAtIndexes:idxs forKey:@"entries"];
		SparkLibraryPostNotification([self library], SparkListDidAddObjectsNotification, self, inserted);
	}
	[inserted release];
}

- (void)removeEntry:(SparkEntry *)anEntry {
	NSParameterAssert(![self isDynamic]);
	
  NSUInteger idx = [sp_entries indexOfObject:anEntry];
  if (idx != NSNotFound)
    [self removeObjectFromEntriesAtIndex:idx];
}
- (void)removeEntriesInArray:(NSArray *)anArray {
	NSParameterAssert(![self isDynamic]);
	
	NSUInteger count = [anArray count];
	NSMutableIndexSet *idxs = [[NSMutableIndexSet alloc] init];
	
	while (count-- > 0) {
    NSUInteger idx = [self indexOfEntry:[anArray objectAtIndex:count]];
		if (NSNotFound != idx)
			[idxs addIndex:idx];
	}
	if ([idxs count]) {
		NSArray *removed = [sp_entries objectsAtIndexes:idxs];
		/* Undo Manager */
    if (![self isDynamic])
      [[self undoManager] registerUndoWithTarget:self selector:@selector(addEntriesFromArray:) object:removed];
		
		[self willChange:NSKeyValueChangeRemoval valuesAtIndexes:idxs forKey:@"entries"];
		[sp_entries removeObjectsAtIndexes:idxs];
		[self didChange:NSKeyValueChangeRemoval valuesAtIndexes:idxs forKey:@"entries"];
		
		SparkLibraryPostNotification([self library], SparkListDidRemoveObjectsNotification, self, removed);
  }
	[idxs release];
}

#pragma mark -
#pragma mark Notifications
- (BOOL)acceptsEntry:(SparkEntry *)anEntry {
  return sp_filter && sp_filter(self, anEntry, sp_ctxt);
}
- (BOOL)acceptsEntryOrChild:(SparkEntry *)anEntry {
  if (sp_filter) {
		/* a specific entry (root but not system) */
		if (![anEntry isSystem])
			return sp_filter(self, anEntry, sp_ctxt);
			
		SparkEntry *entry = [anEntry root];
		if (sp_filter(self, entry, sp_ctxt)) 
			return YES;
		
		entry = [entry firstChild];
		while (entry) {
			if (sp_filter(self, entry, sp_ctxt)) 
				return YES;			
			entry = [entry sibling];
		}
	}
	return NO;
}

//- (void)didAppendEntryChild:(NSNotification *)aNotification {
//	if ([self isDynamic] && ![self containsEntry:[aNotification object]]) {
//		SparkEntry *child = SparkNotificationObject(aNotification);
//		if ([self acceptsEntry:child])
//			[self insertObject:child inEntriesAtIndex:[sp_entries count]];
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
	if ([self isDynamic]) {
		SparkEntry *entry = SparkNotificationObject(aNotification);
		NSAssert1(entry, @"invalid notification: %@", aNotification);
		/* we do not have to check the entry children */
		if (![self containsEntry:entry] && [self acceptsEntry:entry])
			[self insertObject:entry inEntriesAtIndex:[sp_entries count]];
	}
}
- (void)didUpdateEntry:(NSNotification *)aNotification {
  SparkEntry *entry = [SparkNotificationObject(aNotification) root];
	
	NSUInteger idx = [self indexOfEntry:entry];
	/* If contains old value */
	if (NSNotFound != idx) {
		/* If is not smart, or updated object is always valid, replace old value */
		if (![self isDynamic] || [self acceptsEntryOrChild:entry]) {
			[sp_entries replaceObjectAtIndex:idx withObject:entry];
		} else {
			/* remove old value */
			[self removeObjectFromEntriesAtIndex:idx];
		}
	} else if ([self isDynamic] && [self acceptsEntryOrChild:entry]) {
		/* Do not contains previous value but updated object is valid */
		[self insertObject:entry inEntriesAtIndex:[sp_entries count]];
	}
}

- (void)willRemoveEntry:(NSNotification *)aNotification {
  SparkEntry *entry = SparkNotificationObject(aNotification);
  NSAssert1(entry, @"invalid notification: %@", aNotification);
	
	/* 'remove' will be handle by the redo if needed */
	if (![self isDynamic] && [[self undoManager] isRedoing])
		return;
	
	NSUInteger idx = [self indexOfEntry:entry];
	if (idx != NSNotFound) {
		/* do not remove entry if entry is not a root entry and entry has a sibling (or parent) valid */
		if (![entry isRoot]) {
			if ([self isDynamic]) {
				SparkEntry *root = [entry root];
				if (sp_filter(self, root, sp_ctxt))
					return;
				root = [root firstChild];
				while (root) {
					if (root != entry && sp_filter(self, root, sp_ctxt)) 
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
  return sp_entries;
}

- (NSUInteger)countOfEntries {
  return [sp_entries count];
}

- (void)setEntries:(NSArray *)entries {
  SPXSetterMutableCopy(sp_entries, entries);
}

- (SparkEntry *)objectInEntriesAtIndex:(NSUInteger)idx {
  return [sp_entries objectAtIndex:idx];
}

- (void)getEntries:(id *)aBuffer range:(NSRange)range {
  [sp_entries getObjects:aBuffer range:range];
}

- (void)insertObject:(SparkEntry *)anEntry inEntriesAtIndex:(NSUInteger)idx {
  /* try to insert a non root entry */
  if (![anEntry isRoot]) {
    if ([sp_entries containsObjectIdenticalTo:[anEntry root]]) {
			SPXDebug(@"already in => skip");
      return;
		}
    /* insert root instead */
    anEntry = [anEntry root];
  }
	if (![self isDynamic]) {
		[[[self undoManager] prepareWithInvocationTarget:self] removeObjectFromEntriesAtIndex:idx];
	}
  [sp_entries insertObject:anEntry atIndex:idx];
  SparkLibraryPostNotification([self library], SparkListDidAddObjectNotification, self, anEntry);
}
- (void)removeObjectFromEntriesAtIndex:(NSUInteger)idx {
  SparkEntry *entry = [[sp_entries objectAtIndex:idx] retain];
  /* Undo Manager */
  if (![self isDynamic]) {
    [[[self undoManager] prepareWithInvocationTarget:self] insertObject:entry inEntriesAtIndex:idx];
	}
  [sp_entries removeObjectAtIndex:idx];
  SparkLibraryPostNotification([self library], SparkListDidRemoveObjectNotification, self, entry);
  [entry release];
}
- (void)replaceObjectInEntriesAtIndex:(NSUInteger)idx withObject:(SparkEntry *)object {
	SparkEntry *previous = [sp_entries objectAtIndex:idx];
	if ([object root] == previous) return;
	
	if (![self isDynamic])
    [[[self undoManager] prepareWithInvocationTarget:self] replaceObjectAtIndex:idx withObject:previous];
	[previous retain];
  [sp_entries replaceObjectAtIndex:idx withObject:object];
	SparkLibraryPostUpdateNotification([self library], SparkListDidUpdateObjectNotification, self, previous, object);
	[previous release];
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
