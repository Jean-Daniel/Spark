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
#import <SparkKit/SparkTrigger.h>
#import <SparkKit/SparkObjectSet.h>

@interface SparkEntry (SparkManagerExtension)
- (BOOL)isEnabled;
- (void)setEnabled:(BOOL)enabled;
@end

@interface SparkEntryManager (SparkPrivate)
- (SparkEntryType)typeForLibraryEntry:(const SparkLibraryEntry *)anEntry;
- (SparkLibraryEntry *)libraryEntryForTrigger:(UInt32)aTrigger application:(UInt32)anApplication;
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

NSString * const SparkEntryNotificationKey = @"SparkEntryNotificationKey";
NSString * const SparkEntryReplacedNotificationKey = @"SparkEntryReplacedNotificationKey";

NSString * const SparkEntryManagerWillAddEntryNotification = @"SparkEntryManagerWillAddEntry";
NSString * const SparkEntryManagerDidAddEntryNotification = @"SparkEntryManagerDidAddEntry";
NSString * const SparkEntryManagerWillUpdateEntryNotification = @"SparkEntryManagerWillUpdateEntry";
NSString * const SparkEntryManagerDidUpdateEntryNotification = @"SparkEntryManagerDidUpdateEntry";
NSString * const SparkEntryManagerWillRemoveEntryNotification = @"SparkEntryManagerWillRemoveEntry";
NSString * const SparkEntryManagerDidRemoveEntryNotification = @"SparkEntryManagerDidRemoveEntry";
NSString * const SparkEntryManagerWillChangeEntryStatusNotification = @"SparkEntryManagerWillChangeEntryStatus";
NSString * const SparkEntryManagerDidChangeEntryStatusNotification = @"SparkEntryManagerDidChangeEntryStatus";

SK_INLINE
void SparkEntryManagerPostNotification(NSString *name, SparkEntryManager *self, SparkEntry *object) {
  [[NSNotificationCenter defaultCenter] postNotificationName:name
                                                      object:self
                                                    userInfo:[NSDictionary dictionaryWithObject:object
                                                                                         forKey:SparkEntryNotificationKey]];
}
SK_INLINE
void SparkEntryManagerPostUpdateNotification(NSString *name, SparkEntryManager *self, SparkEntry *replaced, SparkEntry *object) {
  [[NSNotificationCenter defaultCenter] postNotificationName:name
                                                      object:self
                                                    userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
                                                      object, SparkEntryNotificationKey,
                                                      replaced, SparkEntryReplacedNotificationKey, nil]];
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
#pragma mark Low-Level Methods
SK_INLINE
BOOL SparkEntryIsCustomTrigger(const SparkLibraryEntry *entry) {
  return (entry->application);
}

/* Check if contains, and update has many status */
- (void)checkTriggerValidity:(UInt32)trigger {
  BOOL contains = NO;
  CFIndex count = CFArrayGetCount(sp_entries);
  while (count-- > 0) {
    const SparkLibraryEntry *entry = CFArrayGetValueAtIndex(sp_entries, count);
    if (entry->trigger == trigger) {
      contains = YES;
      if (SparkEntryIsCustomTrigger(entry)) {
        [[[sp_library triggerSet] objectForUID:trigger] setHasManyAction:YES];
        return;
      }
    }
  }
  if (!contains)
    [[sp_library triggerSet] removeObjectWithUID:trigger];
  else
    [[[sp_library triggerSet] objectForUID:trigger] setHasManyAction:NO];
}

- (void)addLibraryEntry:(SparkLibraryEntry *)anEntry {
  if (!CFSetContainsValue(sp_set, anEntry)) {
    SparkLibraryEntry *entry = malloc(sizeof(*entry));
    *entry = *anEntry;
    CFSetAddValue(sp_set, entry);
    CFArrayAppendValue(sp_entries, entry);
    /* Update trigger flag */
    if (SparkEntryIsCustomTrigger(entry)) {
      [[[sp_library triggerSet] objectForUID:entry->trigger] setHasManyAction:YES];
    }
  }
}
- (void)replaceLibraryEntry:(SparkLibraryEntry *)anEntry withLibraryEntry:(SparkLibraryEntry *)newEntry {
  NSParameterAssert(anEntry != NULL);
  NSParameterAssert(newEntry != NULL);
  
  /* Make sure we are using internal storage pointer */
  anEntry = (SparkLibraryEntry *)CFSetGetValue(sp_set, anEntry);
  if (anEntry) {
    UInt32 action = anEntry->action;
    UInt32 trigger = anEntry->trigger;
    
    /* Should update Set too */
    BOOL update = NO;
    if (_SparkEntryHash(anEntry) != _SparkEntryHash(newEntry)) {
      update = YES;
      CFSetRemoveValue(sp_set, anEntry);
    }
    
    /* Copy all values */
    *anEntry = *newEntry;
    
    if (update)
      CFSetAddValue(sp_set, anEntry);
    
    /* Remove orphan action */
    if (action != anEntry->action && ![self containsEntryForAction:action]) {
      [[sp_library actionSet] removeObjectWithUID:action];
    }
    /* Update trigger */
    [self checkTriggerValidity:trigger];
  }
}

- (void)removeEntriesForAction:(UInt32)action {
  CFIndex count = CFArrayGetCount(sp_entries);
  while (count-- > 0) {
    const SparkLibraryEntry *entry = CFArrayGetValueAtIndex(sp_entries, count);
    if (entry->action == action) {
      [self removeLibraryEntry:entry];
    }
  }
}

- (void)removeLibraryEntry:(const SparkLibraryEntry *)anEntry {  
  if (CFSetContainsValue(sp_set, anEntry)) {
    BOOL global = anEntry->application == 0;
    UInt32 action = anEntry->action;

    CFSetRemoveValue(sp_set, anEntry);
    CFIndex idx = CFArrayGetFirstIndexOfValue(sp_entries, CFRangeMake(0, CFArrayGetCount(sp_entries)), anEntry);
    NSAssert(idx != kCFNotFound, @"Cannot found object in manager array, but found in set");
    if (idx != kCFNotFound)
      CFArrayRemoveValueAtIndex(sp_entries, idx);
    
    if (global) {
      /* Remove weak entries */
      [self removeEntriesForAction:action];
    }
    
    /* Remove orphan action */
    if (![self containsEntryForAction:anEntry->action]) {
      [[sp_library actionSet] removeObjectWithUID:anEntry->action];
    }
    /* Remove orphan trigger */
    [self checkTriggerValidity:anEntry->trigger];
  }
}

- (void)setStatus:(BOOL)status forLibraryEntry:(SparkLibraryEntry *)anEntry {
  NSParameterAssert(anEntry != NULL);
  /* Make sure we are using internal storage pointer */
  anEntry = (SparkLibraryEntry *)CFSetGetValue(sp_set, anEntry);
  if (anEntry)
    anEntry->status = status ? 1 : 0;
}

- (SparkEntry *)entryForLibraryEntry:(const SparkLibraryEntry *)anEntry {
  NSParameterAssert(anEntry != NULL);
  SparkAction *action = [[sp_library actionSet] objectForUID:anEntry->action];
  SparkTrigger *trigger = [[sp_library triggerSet] objectForUID:anEntry->trigger];
  SparkApplication *application = [[sp_library applicationSet] objectForUID:anEntry->application];
  SparkEntry *object = [[SparkEntry alloc] initWithAction:action
                                                  trigger:trigger
                                              application:application];
  [object setType:[self typeForLibraryEntry:anEntry]];
  [object setEnabled:anEntry->status];
  return [object autorelease];
}

- (SparkEntryType)typeForLibraryEntry:(const SparkLibraryEntry *)anEntry {
  NSParameterAssert(anEntry != NULL);
  SparkEntryType type = kSparkEntryTypeDefault;
  /* If custom application */
  if (anEntry->application) {
    /* If default action (action for application 0) equals cutsom application => weak overwrite */
    SparkLibraryEntry *defaults = [self libraryEntryForTrigger:anEntry->trigger application:0];
    if (!defaults) {
      /* No default entry => specific */
      type = kSparkEntryTypeSpecific;
    } else if (defaults->action == anEntry->action) {
      /* Default entry has the same action */
      type = kSparkEntryTypeWeakOverWrite;
    } else {
      /* else full overwrite */
      type = kSparkEntryTypeOverWrite;
    }
  }
  return type;
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
      SparkEntry *object = [self entryForLibraryEntry:&entry->entry];
      if (object)
        [result addObject:object];
    }
  }
  return [result autorelease];
}

- (BOOL)containsEntryForField:(unsigned)anIndex uid:(UInt32)uid {
  UInt32 count = CFArrayGetCount(sp_entries);
  while (count-- > 0) {
    const union {
      UInt32 key[4];
      SparkLibraryEntry entry;
    } *entry = CFArrayGetValueAtIndex(sp_entries, count);
    
    if (entry->key[anIndex] == uid) {
      return YES;
    }
  }
  return NO;
}

- (BOOL)containsEntryForTrigger:(UInt32)aTrigger application:(UInt32)anApplication {
  SparkLibraryEntry search;
  search.action = 0;
  search.trigger = aTrigger;
  search.application = anApplication;
  return CFSetContainsValue(sp_set, &search);
}

- (SparkLibraryEntry *)libraryEntryForTrigger:(UInt32)aTrigger application:(UInt32)anApplication {
  SparkLibraryEntry search;
  search.action = 0;
  search.trigger = aTrigger;
  search.application = anApplication;
  return (SparkLibraryEntry *)CFSetGetValue(sp_set, &search);
}

- (SparkLibraryEntry *)libraryEntryForEntry:(SparkEntry *)anEntry {
  return [self libraryEntryForTrigger:[[anEntry trigger] uid] application:[[anEntry application] uid]];
}

#pragma mark -
#pragma mark High-Level Methods
- (void)addEntry:(SparkEntry *)anEntry {
  NSParameterAssert(![self containsEntry:anEntry]);
  
  // Will add
  SparkEntryManagerPostNotification(SparkEntryManagerWillAddEntryNotification, self, anEntry);
  SparkLibraryEntry entry;
  entry.status = 0;
  entry.action = [[anEntry action] uid];
  entry.trigger = [[anEntry trigger] uid];
  entry.application = [[anEntry application] uid];
  [self addLibraryEntry:&entry];
  /* Update type */
  [anEntry setType:[self typeForLibraryEntry:&entry]];
  // Did add
  SparkEntryManagerPostNotification(SparkEntryManagerDidAddEntryNotification, self, anEntry);
}

- (void)replaceEntry:(SparkEntry *)anEntry withEntry:(SparkEntry *)newEntry {
  NSParameterAssert([self containsEntry:anEntry]);
  SparkLibraryEntry *entry = [self libraryEntryForEntry:anEntry];
  if (entry) {
    // Will update
    SparkEntryManagerPostUpdateNotification(SparkEntryManagerWillUpdateEntryNotification, self, anEntry, newEntry);
    SparkLibraryEntry update;
    update.status = [newEntry isEnabled] ? 1 : 0;
    update.action = [[newEntry action] uid];
    update.trigger = [[newEntry trigger] uid];
    update.application = [[newEntry application] uid];
    
    [self replaceLibraryEntry:entry withLibraryEntry:&update];
    /* Update type */
    [newEntry setType:[self typeForLibraryEntry:entry]];
    // Did update
    SparkEntryManagerPostUpdateNotification(SparkEntryManagerDidUpdateEntryNotification, self, anEntry, newEntry);
  }
}

- (void)removeEntry:(SparkEntry *)anEntry {
  NSParameterAssert([self containsEntry:anEntry]);
  // Will remove
  SparkEntryManagerPostNotification(SparkEntryManagerWillRemoveEntryNotification, self, anEntry);
  SparkLibraryEntry entry;
  entry.action = [[anEntry action] uid];
  entry.trigger = [[anEntry trigger] uid];
  entry.application = [[anEntry application] uid];
  [self removeLibraryEntry:&entry];
  // Did remove
  SparkEntryManagerPostNotification(SparkEntryManagerDidRemoveEntryNotification, self, anEntry);
}

- (void)removeEntries:(NSArray *)theEntries {
  unsigned count = [theEntries count];
  while (count-- > 0) {
    [self removeEntry:[theEntries objectAtIndex:count]];
  }
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

- (BOOL)containsEntry:(SparkEntry *)anEntry {
  return [self containsEntryForTrigger:[[anEntry trigger] uid] application:[[anEntry application] uid]];
}

- (BOOL)containsEntryForAction:(UInt32)anAction {
  return [self containsEntryForField:1 uid:anAction];
}
- (BOOL)containsEntryForTrigger:(UInt32)aTrigger {
  return [self containsEntryForField:2 uid:aTrigger];
}
- (BOOL)containsEntryForApplication:(UInt32)anApplication {
  return [self containsEntryForField:3 uid:anApplication];
}
- (BOOL)containsActiveEntryForTrigger:(UInt32)aTrigger {
  UInt32 count = CFArrayGetCount(sp_entries);
  while (count-- > 0) {
    const SparkLibraryEntry *entry = CFArrayGetValueAtIndex(sp_entries, count);
    if (entry->status && (entry->trigger == aTrigger)) {
      return YES;
    }
  }
  return NO;
}
- (BOOL)containsOverwriteEntryForTrigger:(UInt32)aTrigger {
  UInt32 count = CFArrayGetCount(sp_entries);
  while (count-- > 0) {
    const SparkLibraryEntry *entry = CFArrayGetValueAtIndex(sp_entries, count);
    if (entry->application && (entry->trigger == aTrigger)) {
      return YES;
    }
  }
  return NO;
}

- (BOOL)statusForEntry:(SparkEntry *)anEntry {
  return [anEntry isEnabled];
}

- (void)setStatus:(BOOL)status forEntry:(SparkEntry *)anEntry {
  SparkLibraryEntry *entry = [self libraryEntryForEntry:anEntry];
  if (entry) {
    SparkEntryManagerPostNotification(SparkEntryManagerWillChangeEntryStatusNotification, self, anEntry);
    [anEntry setEnabled:status];
    [self setStatus:status forLibraryEntry:entry];
    SparkEntryManagerPostNotification(SparkEntryManagerDidChangeEntryStatusNotification, self, anEntry);
  }
}

- (SparkEntry *)entryForTrigger:(UInt32)aTrigger application:(UInt32)anApplication {
  const SparkLibraryEntry *entry = [self libraryEntryForTrigger:aTrigger application:anApplication];
  if (entry) {
    return [self entryForLibraryEntry:entry];
  }
  return nil;
}

- (SparkAction *)actionForTrigger:(UInt32)aTrigger application:(UInt32)anApplication status:(BOOL *)status {
  const SparkLibraryEntry *entry = [self libraryEntryForTrigger:aTrigger application:anApplication];
  if (entry) {
    if (status)
      *status = entry->status;
    return [[sp_library actionSet] objectForUID:entry->action];
  }
  return nil;
}

@end

@implementation SparkEntryManager (SparkVersion1Library)

- (void)postProcess {
  CFIndex idx = CFArrayGetCount(sp_entries) -1;
  /* Resolve Ignore Actions */
  while (idx >= 0) {
    SparkLibraryEntry *entry = (SparkLibraryEntry *)CFArrayGetValueAtIndex(sp_entries, idx);
    if (!entry->action) {
      SparkLibraryEntry *global = [self libraryEntryForTrigger:entry->trigger application:0];
      entry->action = global ? global->action : 0;
    } 
    if (!entry->action) {
      DLog(@"Remove Invalid Ignore entry.");
      [self removeLibraryEntry:entry];
    }
    idx--;
  }
  
  /* Check all triggers and actions */
  idx = CFArrayGetCount(sp_entries) -1;
  SparkObjectSet *actions = [sp_library actionSet];
  SparkObjectSet *triggers = [sp_library triggerSet];
  SparkObjectSet *applications = [sp_library applicationSet];
  /* Resolve Ignore Actions */
  while (idx >= 0) {
    SparkLibraryEntry *entry = (SparkLibraryEntry *)CFArrayGetValueAtIndex(sp_entries, idx);
    NSAssert(entry != NULL, @"Illegale null entry");
    if (![actions containsObjectWithUID:entry->action] || 
        ![triggers containsObjectWithUID:entry->trigger] || 
        (entry->application && ![applications containsObjectWithUID:entry->application])) {
      DLog(@"Remove Illegal entry { %u, %u, %u }", entry->action, entry->trigger, entry->application);
      [self removeLibraryEntry:entry];
    } else {
      if (SparkEntryIsCustomTrigger(entry))
        [[triggers objectForUID:entry->trigger] setHasManyAction:YES];
    }
    idx--;
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
  /* Cleanup */
  CFSetRemoveAllValues(sp_set);
  CFArrayRemoveAllValues(sp_entries);
  
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
  
  SparkObjectSet *triggers = [sp_library triggerSet];
  const SparkLibraryEntry *entries = header->entries;
  while (count-- > 0) {
    SparkLibraryEntry entry;
    entry.status = SparkReadField(entries->status);
    entry.action = SparkReadField(entries->action);
    entry.trigger = SparkReadField(entries->trigger);
    entry.application = SparkReadField(entries->application);
    [self addLibraryEntry:&entry];
    if (SparkEntryIsCustomTrigger(&entry))
      [[triggers objectForUID:entry.trigger] setHasManyAction:YES];
    entries++;
  }
  
  return YES;
}

@end
