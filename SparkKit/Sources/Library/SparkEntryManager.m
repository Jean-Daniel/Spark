/*
 *  SparkEntryManager.m
 *  SparkKit
 *
 *  Created by Black Moon Team.
 *  Copyright (c) 2004 - 2006 Shadow Lab. All rights reserved.
 */

#import <Sparkkit/SparkEntryManager.h>

#import <SparkKit/SparkEntry.h>
#import <SparkKit/SparkAction.h>
#import <SparkKit/SparkLibrary.h>
#import <SparkKit/SparkObjectSet.h>

@interface SparkEntry (SparkManagerExtension)
- (BOOL)isEnabled;
- (void)setEnabled:(BOOL)enabled;
@end

static
void _SparkEntryRelease(CFAllocatorRef allocator, const void *value) {
  free((void *)value);
}

/* Two entries are equals if application and trigger are equals. */
static
CFHashCode _SparkEntryHash(const void *obj) {
  const SparkLibraryEntry *entry = obj;
  return entry->application ^ entry->trigger << 16;
}
static 
Boolean _SparkEntryIsEqual(const void *obj1, const void *obj2) {
  const SparkLibraryEntry *e1 = obj1, *e2 = obj2;
  return e1->trigger == e2->trigger && e1->application == e2->application;
}

@implementation SparkEntryManager

- (id)init {
  if (self = [self initWithLibrary:nil]) {

  }
  return self;
}

- (id)initWithLibrary:(SparkLibrary *)aLibrary {
  if (self = [super init]) {
    sp_library = aLibrary;

    CFArrayCallBacks callbacks;
    bzero(&callbacks, sizeof(callbacks));
    callbacks.equal = _SparkEntryIsEqual;
    callbacks.release = _SparkEntryRelease;
    sp_entries = CFArrayCreateMutable(kCFAllocatorDefault, 0, &callbacks);
    
    CFSetCallBacks setcb;
    bzero(&setcb, sizeof(setcb));
    setcb.hash = _SparkEntryHash;
    setcb.equal = _SparkEntryIsEqual;
    sp_set = CFSetCreateMutable(kCFAllocatorDefault, 0, &setcb);
  }
  return self;
}

- (void)dealloc {
  if (sp_set)
    CFRelease(sp_set);
  if (sp_entries)
    CFRelease(sp_entries);
  [[NSNotificationCenter defaultCenter] removeObserver:self];
  [super dealloc];
}

#pragma mark -
- (void)addLibraryEntry:(SparkLibraryEntry *)anEntry {
  if (!CFSetContainsValue(sp_set, &anEntry)) {
    SparkLibraryEntry *entry = malloc(sizeof(*entry));
    *entry = *anEntry;
    CFSetAddValue(sp_set, entry);
    CFArrayAppendValue(sp_entries, entry);
  }
}
- (void)removeLibraryEntry:(SparkLibraryEntry *)anEntry {  
  if (CFSetContainsValue(sp_set, &anEntry)) {
    CFSetRemoveValue(sp_set, &anEntry);
    CFIndex idx = CFArrayGetFirstIndexOfValue(sp_entries, CFRangeMake(0, CFArrayGetCount(sp_entries)), &anEntry);
    if (idx != kCFNotFound)
      CFArrayRemoveValueAtIndex(sp_entries, idx);
  }
}

- (void)addEntry:(SparkEntry *)anEntry {
  NSParameterAssert(![self containsEntryForTrigger:[[anEntry trigger] uid] 
                                       application:[[anEntry application] uid]]);
  
  // Will add
  SparkLibraryEntry entry;
  entry.status = 0;
  entry.action = [[anEntry action] uid];
  entry.trigger = [[anEntry trigger] uid];
  entry.application = [[anEntry application] uid];
  [self addLibraryEntry:&entry];
  // Did add
}

- (void)removeEntry:(SparkEntry *)anEntry {
  NSParameterAssert([self containsEntryForTrigger:[[anEntry trigger] uid] 
                                      application:[[anEntry application] uid]]);

  // Will remove
  SparkLibraryEntry entry;
  entry.action = 0;
  entry.trigger = [[anEntry trigger] uid];
  entry.application = [[anEntry application] uid];
  [self removeLibraryEntry:&entry];
  // Did remove
}

- (NSArray *)entriesForField:(unsigned)anIndex uid:(UInt32)uid {
  NSMutableArray *result = [[NSMutableArray alloc] init];
  
  UInt32 count = CFArrayGetCount(sp_entries);
  while (count-- > 0) {
    const union {
      UInt32 key[4];
      SparkLibraryEntry entry;
    } *entry = CFArrayGetValueAtIndex(sp_entries, count);
    
    if (entry->key[anIndex] == uid) {
      SparkAction *action = [[sp_library actionSet] objectForUID:entry->entry.action];
      SparkTrigger *trigger = [[sp_library triggerSet] objectForUID:entry->entry.trigger];
      SparkApplication *application = [[sp_library applicationSet] objectForUID:entry->entry.application];
      SparkEntry *object = [[SparkEntry alloc] initWithAction:action
                                                      trigger:trigger
                                                  application:application];
      [object setEnabled:entry->entry.status];
      [result addObject:object];
      [object release];
    }
  }
  return [result autorelease];
}

- (NSArray *)entriesForAction:(UInt32)anAction {
  return [self entriesForField:1 uid:anAction];
}
- (NSArray *)entriesForTrigger:(UInt32)aTrigger {
  return [self entriesForField:2 uid:aTrigger];
}
- (NSArray *)entriesForApplication:(UInt32)anApplication {
  return [self entriesForField:3 uid:anApplication];
}

- (BOOL)statusForEntry:(SparkEntry *)anEntry {
  return [anEntry isEnabled];
}

- (void)setStatus:(BOOL)status forEntry:(SparkEntry *)anEntry {
  SparkLibraryEntry search;
  search.action = 0;
  search.trigger = [[anEntry trigger] uid];
  search.application = [[anEntry application] uid];
  SparkLibraryEntry *entry = (SparkLibraryEntry *)CFSetGetValue(sp_set, &search);
  if (entry) {
    [anEntry setEnabled:status];
    entry->status = status ? 1 : 0;
  }
}

- (BOOL)containsEntryForTrigger:(UInt32)aTrigger application:(UInt32)anApplication {
  SparkLibraryEntry search;
  search.action = 0;
  search.trigger = aTrigger;
  search.application = anApplication;
  return CFSetContainsValue(sp_set, &search);
}

- (SparkLibraryEntry *)entryForTrigger:(UInt32)aTrigger application:(UInt32)anApplication {
  SparkLibraryEntry search;
  search.action = 0;
  search.trigger = aTrigger;
  search.application = anApplication;
  return (SparkLibraryEntry *)CFSetGetValue(sp_set, &search);
}

- (SparkAction *)actionForTrigger:(UInt32)aTrigger application:(UInt32)anApplication {
  const SparkLibraryEntry *entry = [self entryForTrigger:aTrigger application:anApplication];
  if (entry && entry->status) {
    return [[sp_library actionSet] objectForUID:entry->action];
  }
  return nil;
}

@end

@implementation SparkEntryManager (SparkVersion1Library)

- (BOOL)isOrphanTrigger:(UInt32)aTrigger {
  Boolean orphan = YES;
  CFIndex count = CFArrayGetCount(sp_entries);
  while (orphan && count-- > 0) {
    const SparkLibraryEntry *entry = CFArrayGetValueAtIndex(sp_entries, count);
    if (entry->trigger == aTrigger)
      orphan = NO;
  }
  return orphan;
}

- (void)_removeInvalidEntry:(const SparkLibraryEntry *)entry atIndex:(UInt32)idx {
  CFSetRemoveValue(sp_set, entry);
  CFArrayRemoveValueAtIndex(sp_entries, idx);
  /* Check for orphan trigger */
  if ([self isOrphanTrigger:entry->trigger]) {
    DLog(@"Remove orphan trigger: %i", entry->trigger);
    [[sp_library triggerSet] removeObjectWithUID:entry->trigger];
  }
}

- (void)removeEntriesForAction:(UInt32)action {
  CFIndex count = CFArrayGetCount(sp_entries);
  while (count-- > 0) {
    const SparkLibraryEntry *entry = CFArrayGetValueAtIndex(sp_entries, count);
    if (entry->action == action) {
      [self _removeInvalidEntry:entry atIndex:count];
    }
  }
}

- (void)postProcess {
  CFIndex idx = CFArrayGetCount(sp_entries) -1;
  
  /* Resolve Ignore Actions */
  while (idx >= 0) {
    SparkLibraryEntry *entry = (SparkLibraryEntry *)CFArrayGetValueAtIndex(sp_entries, idx);
    if (!entry->action) {
      SparkLibraryEntry *global = [self entryForTrigger:entry->trigger application:0];
      entry->action = global ? global->action : 0;
    } 
    if (entry->action) {
      idx--;
    } else {
      DLog(@"Remove Invalid Ignore entry.");
      [self _removeInvalidEntry:entry atIndex:idx];
    }
  } 
}

@end

#pragma mark -
typedef struct {
  OSType magic;
  UInt32 version; /* Version 0 header */
  UInt32 count;
  SparkLibraryEntry entries[0];
} SparkEntryHeader;

#define SPARK_MAGIC		'SpEn'
#define SPARK_CIGAM		'nEpS'

@implementation SparkEntryManager (SparkSerialization)

- (NSFileWrapper *)fileWrapper:(NSError **)outError {
  UInt32 count = CFArrayGetCount(sp_entries);
  UInt32 size = count * sizeof(SparkLibraryEntry) + sizeof(SparkEntryHeader);
  NSMutableData *data = [[NSMutableData alloc] initWithCapacity:size];
  
  /* Write header */
  [data setLength:sizeof(SparkEntryHeader)];
  SparkEntryHeader *header = [data mutableBytes];
  header->magic = SPARK_MAGIC;
  header->version = 0;
  header->count = count;
  
  /* Write contents */
  while (count-- > 0) {
    const SparkLibraryEntry *entry = CFArrayGetValueAtIndex(sp_entries, count);
    [data appendBytes:entry length:sizeof(*entry)];
  } 

  NSFileWrapper *wrapper = [[NSFileWrapper alloc] initRegularFileWithContents:data];
  [data release];
  
  return [wrapper autorelease];
}

#define SparkReadField(field)	({swap ? OSSwapInt32(field) : field; })

- (BOOL)readFromFileWrapper:(NSFileWrapper *)fileWrapper error:(NSError **)outError {
  NSData *data = [fileWrapper regularFileContents];
  
  BOOL swap = NO;
  const SparkEntryHeader *header = NULL;
  
  const void *bytes = [data bytes];
  header = bytes;
  switch (header->magic) {
    case SPARK_CIGAM:
      swap = YES;
      // fall 
    case SPARK_MAGIC:
      break;
    default:
      DLog(@"Invalid header");
      if (outError) *outError = [NSError errorWithDomain:NSCocoaErrorDomain
                                                    code:-1
                                                userInfo:nil];
      return NO;
  }
  
  if (SparkReadField(header->version) != 0) {
    DLog(@"Unsupported version: %x", SparkReadField(header->version));
    if (outError) *outError = [NSError errorWithDomain:NSCocoaErrorDomain
                                                  code:-1
                                              userInfo:nil];
    return NO;
  }
  
  UInt32 count = SparkReadField(header->count);
  if ([data length] < count * sizeof(SparkLibraryEntry) + sizeof(SparkEntryHeader)) {
    DLog(@"Unexpected end of file");
    if (outError) *outError = [NSError errorWithDomain:NSCocoaErrorDomain
                                                  code:-2
                                              userInfo:nil];
    return NO;
  }
  
  const SparkLibraryEntry *entries = header->entries;
  while (count-- > 0) {
    SparkLibraryEntry entry;
    entry.status = SparkReadField(entries->status);
    entry.action = SparkReadField(entries->action);
    entry.trigger = SparkReadField(entries->trigger);
    entry.application = SparkReadField(entries->application);
    [self addLibraryEntry:&entry];
    entries++;
  }
  
  return YES;
}

@end
