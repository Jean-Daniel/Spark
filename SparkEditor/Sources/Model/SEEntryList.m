/*
 *  SEEntryList.m
 *  Spark Editor
 *
 *  Created by Black Moon Team.
 *  Copyright (c) 2004 - 2007 Shadow Lab. All rights reserved.
 */

#import "SEEntryList.h"
#import "SETableView.h"
#import "SELibraryDocument.h"

#import <SparkKit/SparkEntry.h>
#import <SparkKit/SparkPrivate.h>

SK_INLINE
SparkEntry *__SEEntryForApplication(SparkEntry *entry, SparkApplication *app, bool specific) {
  if ([[entry application] isEqual:app])
    return entry;
  
  /* entry application match */
	if ([entry isSystem]) {
		SparkEntry *child = [entry variantWithApplication:app];
		/* return child if one exists, else returns entry (if not specific) */
		return child ? : (specific ? nil : entry);
	}
	/* specific entry for another application */
  return nil;
}

@implementation SEEntryList

+ (SEEntryList *)separatorList {
	SEEntryList *separator = [[SEEntryList alloc] initWithName:SETableSeparator icon:nil];
	separator->se_selFlags.separator = 1;
	return [separator autorelease];
}

- (id)init {
	return [self initWithName:nil icon:nil];
}

- (id)initWithName:(NSString *)name icon:(NSImage *)icon {
	if (self = [super init]) {
		se_selFlags.isVirtual = 1;
		se_list = [[SparkList alloc] initWithName:name icon:icon];
		[se_list addObserver:self forKeyPath:@"entries" 
								 options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:nil];
		[self setNeedsReload:YES];
	}
	return self;	
}

- (id)initWithList:(SparkList *)aList {
	NSParameterAssert(aList);
	if (self = [super init]) {
		se_list = [aList retain];
		[se_list addObserver:self forKeyPath:@"entries" 
								 options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:nil];
		[self setNeedsReload:YES];
	}
	return self;
}

- (void)dealloc {
	[se_list removeObserver:self forKeyPath:@"entries"];
	[se_application release];
	[se_snapshot release];
	[se_list release];
  [super dealloc];
}

#pragma mark -
- (void)snapshot {
	if (se_selFlags.separator) return;
	[self willChangeValueForKey:@"entries"];
	if (se_snapshot)
		[se_snapshot removeAllObjects];
	else
		se_snapshot = [[NSMutableArray alloc] init];
	
	NSArray *entries = [se_list entries];
	NSUInteger count = [entries count];
	for (NSUInteger idx = 0; idx < count; idx++) {
		SparkEntry *entry = __SEEntryForApplication([entries objectAtIndex:idx], se_application, se_selFlags.specific);
		if (entry) {
			/* if dynamic list, we have to revalidate the entry */
			if (![se_list isDynamic] || [se_list acceptsEntry:entry])
				[se_snapshot addObject:entry];
		}
	}
	se_selFlags.dirty = 0;
	//DLog(@"snapshot: %@", [self name]);
	[self didChangeValueForKey:@"entries"];
}

- (SparkList *)sparkList {
	return se_list;
}

- (NSImage *)icon {
	return [se_list icon];
}
- (void)setIcon:(NSImage *)icon {
	[self willChangeValueForKey:@"representation"];
	[se_list setIcon:icon];
	[self didChangeValueForKey:@"representation"];
}

- (NSString *)name {
	return [se_list name];
}
- (void)setName:(NSString *)aName {
	[self willChangeValueForKey:@"representation"];
	[se_list setName:aName];
	[self didChangeValueForKey:@"representation"];
}

#pragma mark Spark Editor
- (UInt8)group {
  return se_selFlags.group;
}
- (void)setGroup:(UInt8)group {
  se_selFlags.group = group;
}

- (BOOL)isEditable {
  return !se_selFlags.isVirtual && !se_selFlags.separator;
}

- (NSComparisonResult)compare:(id)object {
  NSInteger g1 = [self group], g2 = [object group];
  if (g1 != g2)
    return g1 - g2;
  else return [[self name] caseInsensitiveCompare:[object name]];
}

- (void)setDocument:(SELibraryDocument *)aDocument {
	if (se_selFlags.isVirtual) {
		[se_list setLibrary:[aDocument library]];
	}
}

- (void)setApplication:(SparkApplication *)anApplication {
	SKSetterRetain(se_application, anApplication);
	[self setNeedsReload:YES];
}

- (void)setSpecificFilter:(BOOL)flag {
	SKFlagSet(se_selFlags.specific, flag);
}
- (void)setListFilter:(SparkListFilter)aFilter context:(id)aCtxt {
	[se_list setListFilter:aFilter context:aCtxt];
}

- (id)representation {
	return self;
}
- (void)setRepresentation:(id)rep {
	return [se_list setRepresentation:rep];
}

#pragma mark KVC
- (void)setNeedsReload:(BOOL)flag {
	SKFlagSet(se_selFlags.dirty, flag);
}

- (NSArray *)entries {
	if (se_selFlags.dirty) [self snapshot];
	return se_snapshot;
}
//- (void)setEntries:(NSArray *)entries {
//	
//}

- (NSUInteger)countOfEntries {
	if (se_selFlags.dirty) [self snapshot];
  return [se_snapshot count];
}

- (SparkEntry *)objectInEntriesAtIndex:(NSUInteger)idx {
	if (se_selFlags.dirty) [self snapshot];
  return [se_snapshot objectAtIndex:idx];
}

- (void)getEntries:(id *)aBuffer range:(NSRange)range {
	if (se_selFlags.dirty) [self snapshot];
  [se_snapshot getObjects:aBuffer range:range];
}

//- (void)insertObject:(SparkEntry *)anEntry inEntriesAtIndex:(NSUInteger)idx {
//	ShadowDTrace();
//}
//- (void)removeObjectFromEntriesAtIndex:(NSUInteger)idx {
//	ShadowDTrace();
//}
//- (void)replaceObjectInEntriesAtIndex:(NSUInteger)idx withObject:(SparkEntry *)object {
//	ShadowDTrace();
//}

#pragma mark Sync with SparkList
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
  if ([@"entries" isEqualToString:keyPath]) {
		[self snapshot];
		//DLog(@"%@", change);
  } else {
		[super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
	}
}

@end

