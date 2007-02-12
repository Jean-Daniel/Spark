/*
 *  SEEntryList.h
 *  Spark Editor
 *
 *  Created by Black Moon Team.
 *  Copyright (c) 2004 - 2007 Shadow Lab. All rights reserved.
 */

#import <Cocoa/Cocoa.h>

@class SparkEntry;
@class SELibraryDocument;
@interface SEEntryList : NSObject {
  @private
  NSImage *se_icon;
  NSString *se_name;
  NSMutableArray *se_entries;
  SELibraryDocument *se_document;
  
  struct _se_elFlags {
    unsigned int group:8;
    unsigned int reserved:24;
  } se_elFlags;
}

- (id)initWithName:(NSString *)name icon:(NSImage *)icon;

- (NSString *)name;
- (void)setName:(NSString *)name;

- (NSImage *)icon;
- (void)setIcon:(NSImage *)icon;

- (UInt8)group;
- (void)setGroup:(UInt8)group;

- (SELibraryDocument *)document;
- (void)setDocument:(SELibraryDocument *)aDocument;

- (BOOL)isEditable;

- (void)addEntries:(NSArray *)entries;
- (void)removeEntries:(NSArray *)entries;

- (void)applicationDidChange:(NSNotification *)aNotification;

- (void)reload;
- (void)removeAllObjects;

#pragma mark KVC
- (NSArray *)entries;
- (NSUInteger)countOfEntries;
- (void)setEntries:(NSArray *)entries;
- (SparkEntry *)objectInEntriesAtIndex:(NSUInteger)idx;
- (void)getEntries:(id *)aBuffer range:(NSRange)range;
- (void)insertObject:(SparkEntry *)anEntry inEntriesAtIndex:(NSUInteger)idx;
- (void)removeObjectFromEntriesAtIndex:(NSUInteger)idx;
- (void)replaceObjectInEntriesAtIndex:(NSUInteger)idx withObject:(SparkEntry *)object;

@end

SK_PRIVATE
NSString * const SEEntryListDidChangeNameNotification;

@class SparkList;
@interface SEUserEntryList : SEEntryList {
  @private
  SparkList *se_list;
}

- (id)initWithList:(SparkList *)aList;

- (SparkList *)list;

@end

@class SparkEntry;
typedef BOOL(*SEEntryListFilter)(SEEntryList *, SparkEntry *, id ctxt);

@interface SESmartEntryList : SEEntryList {
  @private
  id se_ctxt;
  SEEntryListFilter se_filter;
}

- (void)setListFilter:(SEEntryListFilter)aFilter context:(id)aCtxt;

@end
