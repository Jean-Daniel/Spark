/*
 *  SparkEntryManagerPrivate.m
 *  SparkKit
 *
 *  Created by Black Moon Team.
 *  Copyright (c) 2004 - 2007 Shadow Lab. All rights reserved.
 */

#import "SparkEntryManagerPrivate.h"

#import <SparkKit/SparkEntry.h>

//#import <SparkKit/SparkPrivate.h>
#import <SparkKit/SparkTrigger.h>
#import <SparkKit/SparkLibrary.h>
#import <SparkKit/SparkObjectSet.h>

//#import <SparkKit/SparkPlugIn.h>
//#import <SparkKit/SparkActionLoader.h>

@implementation SparkEntryManager (SparkEntryEditor)

- (void)beginEditing:(SparkEntry *)anEntry {
}
- (void)endEditing:(SparkEntry *)anEntry {
}

- (void)enableEntry:(SparkEntry *)anEntry {
}
- (void)disableEntry:(SparkEntry *)anEntry {
}

//- (void)setEnabled:(BOOL)flag forEntry:(SparkEntry *)anEntry {
//  SparkLibraryEntry *entry = [self libraryEntryForEntry:anEntry];
//  if (entry && XOR(flag, SparkLibraryEntryIsEnabled(entry))) {
//    /* Undo management */
//    [[[self undoManager] prepareWithInvocationTarget:self] setEnabled:!flag forEntry:anEntry];
//    /* update entry */
//    [anEntry setEnabled:flag];
//    /* Update library entry => Undo */
//    [self setEnabled:flag forLibraryEntry:entry];
//    SparkLibraryPostNotification([self library], SparkEntryManagerDidChangeEntryEnabledNotification, self, anEntry);
//  }
//}
//
//- (void)enableEntry:(SparkEntry *)anEntry {
//  [self setEnabled:YES forEntry:anEntry];
//}
//- (void)disableEntry:(SparkEntry *)anEntry {
//  [self setEnabled:NO forEntry:anEntry];
//}

@end

@implementation SparkEntryManager (SparkEntryManagerInternal)

/* Check if contains, and update has many status */
- (void)checkTriggerValidity:(SparkTrigger *)trigger {
  BOOL contains = NO;
  SparkUID tuid = [trigger uid];
  CFIndex count = CFArrayGetCount(sp_entries);
  while (count-- > 0) {
    SparkEntry *entry = (SparkEntry *)CFArrayGetValueAtIndex(sp_entries, count);
    if ([entry triggerUID] == tuid) {
      contains = YES;
      if ([entry applicationUID] != kSparkApplicationSystemUID) {
        [[entry trigger] setHasManyAction:YES];
        return;
      }
    }
  }
  if (!contains)
    [[[self library] triggerSet] removeObject:trigger];
  else
    [trigger setHasManyAction:NO];
}

- (void)removeEntriesForAction:(SparkUID)action {
  CFIndex count = CFArrayGetCount(sp_entries);
  while (count-- > 0) {
    SparkEntry *entry = (SparkEntry *)CFArrayGetValueAtIndex(sp_entries, count);
    if ([entry actionUID] == action) {
      [self removeEntry:entry];
    }
  }
}

@end

#if 0
static
void _SparkEntryRelease(CFAllocatorRef allocator, const void *value) {
  CFAllocatorDeallocate(kCFAllocatorDefault, (void *)value);
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

@implementation SparkEntryManager (SparkEntryManagerInternal)

- (void)initInternal {
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

- (void)deallocInternal {
  if (sp_set)
    CFRelease(sp_set);
  if (sp_entries)
    CFRelease(sp_entries);
}

#pragma mark Entry Manipulation
- (void)addLibraryEntry:(SparkLibraryEntry *)anEntry {
  if (!CFSetContainsValue(sp_set, anEntry)) {
    SparkLibraryEntry *entry = CFAllocatorAllocate(kCFAllocatorDefault, sizeof(*entry), 0);
    *entry = *anEntry;
    CFSetAddValue(sp_set, entry);
    CFArrayAppendValue(sp_entries, entry);
    
    SparkTrigger *trigger = [[self library] triggerWithUID:entry->trigger];
    /* Update trigger flag */
    if (SparkLibraryEntryIsOverwrite(entry))
      [trigger setHasManyAction:YES];
  }
}
- (void)replaceLibraryEntry:(SparkLibraryEntry *)anEntry withLibraryEntry:(SparkLibraryEntry *)newEntry {
  NSParameterAssert(anEntry != NULL);
  NSParameterAssert(newEntry != NULL);
  
  /* Make sure we are using internal storage pointer */
  anEntry = (SparkLibraryEntry *)CFSetGetValue(sp_set, anEntry);
  if (!anEntry)
    [NSException raise:NSInternalInconsistencyException format:@"Requested entry does not exists"];
  
  SparkUID action = anEntry->action;
  SparkUID trigger = anEntry->trigger;
  
  /* Should update CFSet if the hash change */
  BOOL update = NO;
  if (_SparkEntryHash(anEntry) != _SparkEntryHash(newEntry)) {
    update = YES;
    CFSetRemoveValue(sp_set, anEntry);
  }
  
  /* Copy all values */
  *anEntry = *newEntry;
  
  if (update)
    CFSetAddValue(sp_set, anEntry);
  
  /* Remove orphan action or update action flag */
  if (action != newEntry->action && ![self containsEntryForAction:action]) {
//    SparkAction *act = [[self library] actionWithUID:action];
//    if ([act isRegistred])
//      [act setRegistred:NO];
    [[[self library] actionSet] removeObjectWithUID:action];
  }
//  else {
//    [self checkActionRegistration:anEntry];
//  }
  /* Update trigger */
  [self checkTriggerValidity:trigger];
  /* update newEntry flag */
//  [self checkActionRegistration:newEntry];
}

- (void)removeLibraryEntry:(const SparkLibraryEntry *)anEntry {  
  if (CFSetContainsValue(sp_set, anEntry)) {
//    BOOL global = anEntry->application == kSparkApplicationSystemUID;
    /* copy anEntry on stack */
    const SparkLibraryEntry lEntry = *anEntry;
    
    CFSetRemoveValue(sp_set, anEntry);
    CFIndex idx = CFArrayGetFirstIndexOfValue(sp_entries, CFRangeMake(0, CFArrayGetCount(sp_entries)), anEntry);
    NSAssert(idx != kCFNotFound, @"Cannot found object in manager array, but found in set");
    if (idx != kCFNotFound)
      CFArrayRemoveValueAtIndex(sp_entries, idx);
    /* Note: anEntry could be freed an should no longer be used, lEntry MUST be used instead. */
    
    /* Should not automagically remove weak entries */
//    if (global) {
//      /* Remove weak entries */
//      [self removeEntriesForAction:lEntry.action];
//    }
    
    /* Remove orphan action or update action status */
    if (![self containsEntryForAction:lEntry.action]) {
//      SparkAction *action = [[self library] actionWithUID:lEntry.action];
//      if ([action isRegistred])
//        [action setRegistred:NO];
      [[[self library] actionSet] removeObjectWithUID:lEntry.action];
    }
//    else {
//      [self checkActionRegistration:&lEntry];
//    }
    /* Remove orphan trigger */
    [self checkTriggerValidity:lEntry.trigger];
  }
}

- (void)setEnabled:(BOOL)flag forLibraryEntry:(SparkLibraryEntry *)anEntry {
  NSParameterAssert(anEntry != NULL);
  /* Make sure we are using internal storage pointer */
  anEntry = (SparkLibraryEntry *)CFSetGetValue(sp_set, anEntry);
  if (!anEntry)
    [NSException raise:NSInvalidArgumentException format:@"Requested entry does not exists"];
  
  SparkLibraryEntrySetEnabled(anEntry, flag);
//  [self checkActionRegistration:anEntry];
}

#pragma mark Conversion
- (SparkLibraryEntry *)libraryEntryForEntry:(SparkEntry *)anEntry {
  return [self libraryEntryForTrigger:[[anEntry trigger] uid] application:[[anEntry application] uid]];
}

- (SparkEntry *)entryForLibraryEntry:(const SparkLibraryEntry *)anEntry {
  NSParameterAssert(anEntry != NULL);
  /* Make sure we are using internal storage pointer */
  anEntry = (SparkLibraryEntry *)CFSetGetValue(sp_set, anEntry);
  if (!anEntry)
    [NSException raise:NSInternalInconsistencyException format:@"Requested entry does not exists"];
  
  SparkAction *action = [[self library] actionWithUID:anEntry->action];
  SparkTrigger *trigger = [[self library] triggerWithUID:anEntry->trigger];
  SparkApplication *application = [[self library] applicationWithUID:anEntry->application];
  
  SparkEntry *object = [[SparkEntry alloc] initWithAction:action
                                                  trigger:trigger
                                              application:application];
  [object setType:[self typeForLibraryEntry:anEntry]];
  /* Set flags */
  [object setEnabled:SparkLibraryEntryIsEnabled(anEntry)];
  [object setPlugged:SparkLibraryEntryIsPlugged(anEntry)];
  
  return [object autorelease];
}

- (SparkLibraryEntry *)libraryEntryForTrigger:(SparkUID)aTrigger application:(SparkUID)anApplication {
  SparkLibraryEntry search;
  search.action = 0;
  search.trigger = aTrigger;
  search.application = anApplication;
  return (SparkLibraryEntry *)CFSetGetValue(sp_set, &search);
}

#pragma mark Entry Management - Plugged
- (void)didChangePluginStatus:(NSNotification *)aNotification {
  SparkPlugIn *plugin = [aNotification object];
  
  BOOL flag = [plugin isEnabled];
  Class cls = [plugin actionClass];
  CFIndex count = CFArrayGetCount(sp_entries);
  SparkObjectSet *actions = [[self library] actionSet];
  while (count-- > 0) {
    SparkLibraryEntry *entry = (SparkLibraryEntry *)CFArrayGetValueAtIndex(sp_entries, count);
    NSAssert(entry, @"Invalid entry in entry manager");
    
    SparkAction *act = [actions objectWithUID:entry->action];
    if ([act isKindOfClass:cls]) {
      /* Update library entry */
      SparkLibraryEntrySetPlugged(entry, flag);
//      [self checkActionRegistration:entry];
    }
  }
}

#pragma mark Internal
//- (void)checkActionRegistration:(const SparkLibraryEntry *)entry {
//  SparkAction *action = [[self library] actionWithUID:entry->action];
//  /* If active, sync with trigger (if needed) */
//  if (SparkLibraryEntryIsActive(entry)) {
//    SparkTrigger *trigger = [[self library] triggerWithUID:entry->trigger];
//    if (XOR([trigger isRegistred], [action isRegistred]))
//      [action setRegistred:[trigger isRegistred]];
//  } else if ([action isRegistred]) {
//    /* else, set unregistred */
//    [action setRegistred:NO];
//  }
//}

- (SparkEntryType)typeForLibraryEntry:(const SparkLibraryEntry *)anEntry {
  NSParameterAssert(anEntry != NULL);
  SparkEntryType type = kSparkEntryTypeDefault;
  /* If custom application */
  if (anEntry->application != kSparkApplicationSystemUID) {
    /* If default action (action for application kSparkApplicationSystemUID) equals cutsom application => weak overwrite */
    SparkLibraryEntry *defaults = [self libraryEntryForTrigger:anEntry->trigger application:kSparkApplicationSystemUID];
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

@end

#endif /* 0 */

#pragma mark -
typedef struct _SparkLibraryEntry {
  SparkUID flags;
  SparkUID action;
  SparkUID trigger;
  SparkUID application;
} SparkLibraryEntry_v0;

typedef struct {
  OSType magic;
  UInt32 version; /* Version 0 header */
  UInt32 count;
  SparkLibraryEntry_v0 entries[0];
} SparkEntryHeader;


#define SPARK_MAGIC		'SpEn'
#define SPARK_CIGAM		'nEpS'

@implementation SparkEntryManager (SparkSerialization)

- (NSFileWrapper *)fileWrapper:(NSError **)outError {
//  CFIndex count = CFArrayGetCount(sp_entries);
//  NSUInteger size = count * sizeof(SparkLibraryEntry) + sizeof(SparkEntryHeader);
  NSData *data = [NSKeyedArchiver archivedDataWithRootObject:(NSArray *)sp_entries];

//  /* Write header */
//  [data setLength:sizeof(SparkEntryHeader)];
//  SparkEntryHeader *header = [data mutableBytes];
//  header->magic = SPARK_MAGIC;
//  header->version = 0;
//  header->count = (UInt32)count;
//  
//  /* Write contents */
//  while (count-- > 0) {
//    const SparkLibraryEntry *entry = CFArrayGetValueAtIndex(sp_entries, count);
//    SparkLibraryEntry buffer = *entry;
//    buffer.flags &= kSparkPersistentFlagsMask;
//    [data appendBytes:&buffer length:sizeof(buffer)];
//  } 
//  
  NSFileWrapper *wrapper = [[NSFileWrapper alloc] initRegularFileWithContents:data];
//  [data release];
  
  return [wrapper autorelease];
}

#define SparkReadField(field)	({swap ? OSSwapInt32(field) : field; })

- (BOOL)readVersion0FromData:(NSData *)data error:(NSError **)outError {
  BOOL swap = NO;
  const void *bytes = [data bytes];
  const SparkEntryHeader *header = bytes;
  switch (header->magic) {
    case SPARK_CIGAM:
      swap = YES;
      // fall 
    case SPARK_MAGIC:
      break;
    default:
      DLog(@"Invalid header");
      if (outError) *outError = [NSError errorWithDomain:kSparkErrorDomain
                                                    code:-1
                                                userInfo:nil];
        return NO;
  }
  
  if (SparkReadField(header->version) != 0) {
    DLog(@"Unsupported version: %x", SparkReadField(header->version));
    if (outError) *outError = [NSError errorWithDomain:kSparkErrorDomain
                                                  code:-2
                                              userInfo:nil];
    return NO;
  }
  
  NSUInteger count = SparkReadField(header->count);
  if ([data length] < count * sizeof(SparkLibraryEntry_v0) + sizeof(SparkEntryHeader)) {
    DLog(@"Unexpected end of file");
    if (outError) *outError = [NSError errorWithDomain:kSparkErrorDomain
                                                  code:-3
                                              userInfo:nil];
    return NO;
  }
  
  const SparkLibraryEntry_v0 *entries = header->entries;
  while (count-- > 0) {
    SparkLibraryEntry_v0 entry;
    entry.flags = SparkReadField(entries->flags);
    entry.action = SparkReadField(entries->action);
    entry.trigger = SparkReadField(entries->trigger);
    entry.application = SparkReadField(entries->application);
    [self addLibraryEntry:&entry];
    entries++;
  }
  return YES;
}

- (void)postProcess {
  /* Check all triggers and actions */
  CFIndex idx = CFArrayGetCount(sp_entries);
  /* Resolve Ignore Actions */
  while (idx-- > 0) {
    SparkEntry *entry = (SparkEntry *)CFArrayGetValueAtIndex(sp_entries, idx);
    
    /* Invalid entry if: 
    - action does not exists.
    - trigger does not exists.
    - application does not exists.
    */
    if (![entry action] || ![entry trigger] || ![entry application]) {
      DLog(@"Remove Invalid entry %@", entry);
      [self removeEntry:entry];
    } else {
      if ([entry applicationUID] != kSparkApplicationSystemUID)
        [[entry trigger] setHasManyAction:YES];
    }
  }
}

- (BOOL)readFromFileWrapper:(NSFileWrapper *)fileWrapper error:(NSError **)outError {
  /* Cleanup */
  CFArrayRemoveAllValues(sp_entries);
  
  NSData *data = [fileWrapper regularFileContents];
  
  const void *bytes = [data bytes];
  const SparkEntryHeader *header = bytes;
  switch (header->magic) {
    case SPARK_CIGAM:
    case SPARK_MAGIC:
      return [self readVersion0FromData:data error:outError];
    default:
      /* read version 1 */
      break;
  }
  
  /* cleanup */
  [self postProcess];
  
  return YES;
}

#pragma mark Debug
- (void)dumpEntries {
  CFIndex idx = CFArrayGetCount(sp_entries);
  fprintf(stderr, "Entries: %lu\n {", idx);
  while (idx-- > 0) {
    SparkEntry *entry = (SparkEntry *)CFArrayGetValueAtIndex(sp_entries, idx);

    fprintf(stderr, "\t- Flags: ");
    if ([entry isEnabled])
      fprintf(stderr, "enabled ");
    else
      fprintf(stderr, "disabled ");
    if ([entry isPlugged])
      fprintf(stderr, "unplugged ");
    if ([entry isPersistent])
      fprintf(stderr, "persistent ");
    fprintf(stderr, "\n");
      
    SparkAction *action = [entry action];
    fprintf(stderr, "\t- Action (%lu): %s\n", (long)[action uid], [[action name] UTF8String]);
    
    SparkTrigger *trigger = [entry trigger];
    fprintf(stderr, "\t- Trigger (%lu): %s\n", (long)[trigger uid], [[trigger triggerDescription] UTF8String]);
    
    SparkApplication *application = [entry application];
    fprintf(stderr, "\t- Application (%lu): %s\n", (long)[application uid], [[application name] UTF8String]);
    
    fprintf(stderr, "----------------------------------\n");
  }
  fprintf(stderr, "}\n");
}

@end

@implementation SparkEntryManager (SparkLegacyLibraryImporter)

- (SparkEntry *)entryForTrigger:(SparkUID)aTrigger application:(SparkUID)anApplication {
  CFIndex count = CFArrayGetCount(sp_entries);
  while (count-- > 0) {
    SparkEntry *entry = (SparkEntry *)CFArrayGetValueAtIndex(sp_entries, count);
    if ([entry triggerUID] == aTrigger && [entry applicationUID] == anApplication) {
      return entry;
    }
  }
  return NULL;
}

- (void)postProcessLegacy {
  CFIndex idx = CFArrayGetCount(sp_entries);
  /* Resolve Ignore Actions */
  while (idx-- > 0) {
    SparkEntry *entry = (SparkEntry *)CFArrayGetValueAtIndex(sp_entries, idx);
    if (![entry action]) {
      SparkEntry *global = [self entryForTrigger:[entry triggerUID] application:kSparkApplicationSystemUID];
      if ([global action]) {
        [entry setParent:global];
        [entry setAction:[global action]];
      }
    } 
  }
  [self postProcess];
}


@end

#pragma mark -
void SparkDumpEntries(SparkLibrary *aLibrary) {
  [[aLibrary entryManager] dumpEntries];
}
