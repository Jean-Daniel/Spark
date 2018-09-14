/*
 *  SEEntryList.m
 *  Spark Editor
 *
 *  Created by Black Moon Team.
 *  Copyright (c) 2004 - 2007 Shadow Lab. All rights reserved.
 */

#import "SEEntryList.h"
#import "SELibraryDocument.h"
#import "SESeparatorCellView.h"

#import <SparkKit/SparkEntry.h>
#import <SparkKit/SparkPrivate.h>
#import <SparkKit/SparkApplication.h>

SPX_INLINE
SparkEntry *__SEEntryForApplication(SparkEntry *entry, SparkApplication *app, bool specific) {
  if ([entry.application isEqual:app])
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

@implementation SEEntryList {
@private
  SparkList *se_list;
  NSMutableArray *se_snapshot;
  SparkApplication *se_application;

  BOOL _dirty;
  BOOL _virtual;
  BOOL _specific;
  BOOL _separator;
}

+ (SEEntryList *)separatorList {
	SEEntryList *separator = [[SEEntryList alloc] initWithName:SETableSeparator icon:nil];
	separator->_separator = true;
	return separator;
}

- (id)init {
	return [self initWithName:nil icon:nil];
}

- (id)initWithName:(NSString *)name icon:(NSImage *)icon {
	if (self = [super init]) {
		_virtual = true;
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
		se_list = aList;
		[se_list addObserver:self forKeyPath:@"entries" 
								 options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:nil];
		[self setNeedsReload:YES];
	}
	return self;
}

- (void)dealloc {
	[se_list removeObserver:self forKeyPath:@"entries"];
}

#pragma mark -
- (void)snapshot {
	if (_separator)
    return;
	[self willChangeValueForKey:@"entries"];
	if (se_snapshot)
		[se_snapshot removeAllObjects];
	else
		se_snapshot = [[NSMutableArray alloc] init];
	
	NSArray *entries = [se_list entries];
	NSUInteger count = [entries count];
	for (NSUInteger idx = 0; idx < count; idx++) {
		SparkEntry *entry = __SEEntryForApplication(entries[idx], se_application, _specific);
		if (entry) {
			/* if dynamic list, we have to revalidate the entry */
			if (![se_list isDynamic] || [se_list acceptsEntry:entry])
				[se_snapshot addObject:entry];
		}
	}
	_dirty = 0;
	//SPXDebug(@"snapshot: %@", [self name]);
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
- (BOOL)isEditable {
  return !_virtual && !_separator;
}

- (NSComparisonResult)compare:(SEEntryList *)object {
  uint8_t g1 = self.group, g2 = object.group;
  if (g1 != g2)
    return g1 - g2;
  else return [[self name] caseInsensitiveCompare:[object name]];
}

- (void)setDocument:(SELibraryDocument *)aDocument {
	if (_virtual) {
		[se_list setLibrary:[aDocument library]];
	}
}

- (void)setApplication:(SparkApplication *)anApplication {
	SPXSetterRetainAndDo(se_application, anApplication, {
    [self setNeedsReload:YES];
  });
}

- (void)setSpecificFilter:(BOOL)flag {
  _specific = flag;
}

- (SparkListFilter)filter {
  return se_list.filter;
}
- (void)setFilter:(SparkListFilter)aFilter {
  se_list.filter = aFilter;
}

- (id)representation {
	return self;
}
- (void)setRepresentation:(id)rep {
	return [se_list setRepresentation:rep];
}

#pragma mark KVC
- (void)setNeedsReload:(BOOL)flag {
	SPXFlagSet(_dirty, flag);
}

- (NSArray *)entries {
	if (_dirty)
    [self snapshot];
	return se_snapshot;
}
//- (void)setEntries:(NSArray *)entries {
//	
//}

- (NSUInteger)countOfEntries {
	if (_dirty)
    [self snapshot];
  return [se_snapshot count];
}

- (SparkEntry *)objectInEntriesAtIndex:(NSUInteger)idx {
	if (_dirty)
    [self snapshot];
  return se_snapshot[idx];
}

- (void)getEntries:(id __unsafe_unretained [])aBuffer range:(NSRange)range {
	if (_dirty)
    [self snapshot];
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
		//SPXDebug(@"%@", change);
  } else {
		[super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
	}
}

@end

