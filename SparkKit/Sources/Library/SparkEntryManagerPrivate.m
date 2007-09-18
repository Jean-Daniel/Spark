/*
 *  SparkEntryManagerPrivate.m
 *  SparkKit
 *
 *  Created by Black Moon Team.
 *  Copyright (c) 2004 - 2007 Shadow Lab. All rights reserved.
 */

#import "SparkEntryManagerPrivate.h"

#import <SparkKit/SparkPrivate.h>
#import <SparkKit/SparkTrigger.h>
#import <SparkKit/SparkLibrary.h>
#import <SparkKit/SparkObjectSet.h>

#import <SparkKit/SparkPlugIn.h>
#import <SparkKit/SparkActionLoader.h>

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

#pragma mark -
SK_INLINE
void SparkLibraryEntrySetEnabled(SparkLibraryEntry *entry, BOOL enabled) {
  if (enabled)
    entry->flags |= kSparkEntryEnabled;
  else
    entry->flags &= ~kSparkEntryEnabled;
}

SK_INLINE
void SparkLibraryEntrySetPlugged(SparkLibraryEntry *entry, BOOL flag) {
  if (flag)
    entry->flags &= ~kSparkEntryUnplugged;
  else
    entry->flags |= kSparkEntryUnplugged;
}

SK_INLINE
void SparkLibraryEntrySetPermanent(SparkLibraryEntry *entry, BOOL flag) {
  if (flag)
    entry->flags |= kSparkEntryPermanent;
  else
    entry->flags &= ~kSparkEntryPermanent;
}

void SparkLibraryEntryInitFlags(SparkLibraryEntry *lentry, SparkEntry *entry) {
  /* Set flags */    
  SparkAction *action = [entry action];
  NSCAssert1(action, @"Invalid entry: %@", entry);
  SparkLibraryEntrySetEnabled(lentry, [entry isEnabled]);
  /* Set permanent status */
  SparkLibraryEntrySetPermanent(lentry, [action isPermanent]);
  /* Check plugin status */
  SparkPlugIn *plugin = [[SparkActionLoader sharedLoader] plugInForAction:action];
  SparkLibraryEntrySetPlugged(lentry, plugin ? [plugin isEnabled] : YES);
}

@interface SparkEntryManager (SparkPrivate)

- (void)checkTriggerValidity:(SparkUID)trigger;
- (void)removeEntriesForAction:(SparkUID)action;
- (void)checkActionRegistration:(const SparkLibraryEntry *)entry;

@end

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
    
    SparkTrigger *trigger = [[[self library] triggerSet] objectWithUID:entry->trigger];
    /* Update trigger flag */
    if (SparkLibraryEntryIsOverwrite(entry)) {
      [trigger setHasManyAction:YES];
    }
    
    [self checkActionRegistration:entry];
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
  if (action != newEntry->action && ![self containsEntryForAction:action]) {
    SparkAction *act = [[[self library] actionSet] objectWithUID:action];
    if ([act isRegistred])
      [act setRegistred:NO];
    [[[self library] actionSet] removeObjectWithUID:action];
  } else {
    [self checkActionRegistration:anEntry];
  }
  /* Update trigger */
  [self checkTriggerValidity:trigger];
  [self checkActionRegistration:newEntry];
}

- (void)removeLibraryEntry:(const SparkLibraryEntry *)anEntry {  
  if (CFSetContainsValue(sp_set, anEntry)) {
//    BOOL global = anEntry->application == kSparkApplicationSystemUID;
//    SparkUID action = anEntry->action;
    
    CFSetRemoveValue(sp_set, anEntry);
    CFIndex idx = CFArrayGetFirstIndexOfValue(sp_entries, CFRangeMake(0, CFArrayGetCount(sp_entries)), anEntry);
    NSAssert(idx != kCFNotFound, @"Cannot found object in manager array, but found in set");
    if (idx != kCFNotFound)
      CFArrayRemoveValueAtIndex(sp_entries, idx);

    /* Should not automagically remove weak entries */
//    if (global) {
//      /* Remove weak entries */
//      [self removeEntriesForAction:action];
//    }
    
    /* Remove orphan action */
    if (![self containsEntryForAction:anEntry->action]) {
      SparkAction *action = [[[self library] actionSet] objectWithUID:anEntry->action];
      if ([action isRegistred])
        [action setRegistred:NO];
      
      [[[self library] actionSet] removeObjectWithUID:anEntry->action];
    } else {
      [self checkActionRegistration:anEntry];
    }
    /* Remove orphan trigger */
    [self checkTriggerValidity:anEntry->trigger];
  }
}

- (void)setEnabled:(BOOL)flag forLibraryEntry:(SparkLibraryEntry *)anEntry {
  NSParameterAssert(anEntry != NULL);
  /* Make sure we are using internal storage pointer */
  anEntry = (SparkLibraryEntry *)CFSetGetValue(sp_set, anEntry);
  if (!anEntry)
    [NSException raise:NSInternalInconsistencyException format:@"Requested entry does not exists"];
  
  SparkLibraryEntrySetEnabled(anEntry, flag);
  [self checkActionRegistration:anEntry];
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
  
  SparkAction *action = [[[self library] actionSet] objectWithUID:anEntry->action];
  SparkTrigger *trigger = [[[self library] triggerSet] objectWithUID:anEntry->trigger];
  SparkApplication *application = nil;
  
  if (anEntry->application == kSparkApplicationSystemUID) {
    application = [SparkLibrary systemApplication];
  } else {
    application = [[[self library] applicationSet] objectWithUID:anEntry->application];
  }
  
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
      [self checkActionRegistration:entry];
    }
  }
}

#pragma mark Internal
- (void)removeEntriesForAction:(SparkUID)action {
  CFIndex count = CFArrayGetCount(sp_entries);
  while (count-- > 0) {
    const SparkLibraryEntry *entry = CFArrayGetValueAtIndex(sp_entries, count);
    if (entry->action == action) {
      [self removeLibraryEntry:entry];
    }
  }
}

/* Check if contains, and update has many status */
- (void)checkTriggerValidity:(SparkUID)trigger {
  BOOL contains = NO;
  CFIndex count = CFArrayGetCount(sp_entries);
  while (count-- > 0) {
    const SparkLibraryEntry *entry = CFArrayGetValueAtIndex(sp_entries, count);
    if (entry->trigger == trigger) {
      contains = YES;
      if (SparkLibraryEntryIsOverwrite(entry)) {
        [[[[self library] triggerSet] objectWithUID:trigger] setHasManyAction:YES];
        return;
      }
    }
  }
  if (!contains)
    [[[self library] triggerSet] removeObjectWithUID:trigger];
  else
    [[[[self library] triggerSet] objectWithUID:trigger] setHasManyAction:NO];
}

- (void)checkActionRegistration:(const SparkLibraryEntry *)entry {
  SparkAction *action = [[[self library] actionSet] objectWithUID:entry->action];
  /* If active, sync with trigger */
  if (SparkLibraryEntryIsActive(entry)) {
    SparkTrigger *trigger = [[[self library] triggerSet] objectWithUID:entry->trigger];
    if (XOR([trigger isRegistred], [action isRegistred]))
      [action setRegistred:[trigger isRegistred]];
  } else if ([action isRegistred]) {
    /* else, set unregistred */
    [action setRegistred:NO];
  }
}

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
  CFIndex count = CFArrayGetCount(sp_entries);
  NSUInteger size = count * sizeof(SparkLibraryEntry) + sizeof(SparkEntryHeader);
  NSMutableData *data = [[NSMutableData alloc] initWithCapacity:size];
  
  /* Write header */
  [data setLength:sizeof(SparkEntryHeader)];
  SparkEntryHeader *header = [data mutableBytes];
  header->magic = SPARK_MAGIC;
  header->version = 0;
  header->count = (UInt32)count;
  
  /* Write contents */
  while (count-- > 0) {
    const SparkLibraryEntry *entry = CFArrayGetValueAtIndex(sp_entries, count);
    SparkLibraryEntry buffer = *entry;
    buffer.flags &= kSparkPersistentFlagsMask;
    [data appendBytes:&buffer length:sizeof(buffer)];
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
  if ([data length] < count * sizeof(SparkLibraryEntry) + sizeof(SparkEntryHeader)) {
    DLog(@"Unexpected end of file");
    if (outError) *outError = [NSError errorWithDomain:kSparkErrorDomain
                                                  code:-3
                                              userInfo:nil];
    return NO;
  }
  
  const SparkLibraryEntry *entries = header->entries;
  while (count-- > 0) {
    SparkLibraryEntry entry;
    entry.flags = SparkReadField(entries->flags);
    entry.action = SparkReadField(entries->action);
    entry.trigger = SparkReadField(entries->trigger);
    entry.application = SparkReadField(entries->application);
    [self addLibraryEntry:&entry];
    entries++;
  }
  
  /* cleanup */
  [self postProcess];
  
  return YES;
}

- (void)postProcess {
  CFIndex idx = CFArrayGetCount(sp_entries);
  /* Resolve Ignore Actions */
  while (idx-- > 0) {
    SparkLibraryEntry *entry = (SparkLibraryEntry *)CFArrayGetValueAtIndex(sp_entries, idx);
    if (!entry->action) {
      SparkLibraryEntry *global = [self libraryEntryForTrigger:entry->trigger application:kSparkApplicationSystemUID];
      entry->action = global ? global->action : 0;
    } 
    if (!entry->action) {
      DLog(@"Remove Invalid Ignore entry.");
      [self removeLibraryEntry:entry];
    }
  }
  
  /* Check all triggers and actions */
  idx = CFArrayGetCount(sp_entries);
  SparkObjectSet *actions = [[self library] actionSet];
  SparkObjectSet *triggers = [[self library] triggerSet];
  SparkObjectSet *applications = [[self library] applicationSet];
  SparkActionLoader *loader = [SparkActionLoader sharedLoader];
  /* Resolve Ignore Actions */
  while (idx-- > 0) {
    SparkLibraryEntry *entry = (SparkLibraryEntry *)CFArrayGetValueAtIndex(sp_entries, idx);
    NSAssert(entry != NULL, @"Illegale null entry");
    SparkAction *action = [actions objectWithUID:entry->action];
    
    /* Invalid entry if: 
      - action does not exists.
      - trigger does not exists.
      - application does not exists.
      */
    if (!action || ![triggers containsObjectWithUID:entry->trigger] || 
        (entry->application != kSparkApplicationSystemUID && ![applications containsObjectWithUID:entry->application])) {
      DLog(@"Remove Invalid entry { %u, %u, %u }", entry->action, entry->trigger, entry->application);
      [self removeLibraryEntry:entry];
    } else {
      if (SparkLibraryEntryIsOverwrite(entry))
        [[triggers objectWithUID:entry->trigger] setHasManyAction:YES];
      
      /* Set permanent */
      if ([action isPermanent])
        SparkLibraryEntrySetPermanent(entry, YES);
      
      /* Check if plugin is enabled */
      SparkPlugIn *plugin = [loader plugInForAction:action];
      if (plugin)
        SparkLibraryEntrySetPlugged(entry, [plugin isEnabled]);
    }
  }
}

- (void)addEntryWithAction:(SparkUID)action trigger:(SparkUID)trigger application:(SparkUID)application enabled:(BOOL)enabled {
  SparkLibraryEntry entry;
  SparkLibraryEntrySetEnabled(&entry, enabled);
  entry.action = action;
  entry.trigger = trigger;
  entry.application = application;
  [self addLibraryEntry:&entry];
}

#pragma mark Debug
- (void)dumpEntries {
  SparkLibrary *library = [self library];
  CFIndex idx = CFArrayGetCount(sp_entries);
  fprintf(stderr, "Entries: %lu\n {", idx);
  while (idx-- > 0) {
    SparkLibraryEntry *entry = (SparkLibraryEntry *)CFArrayGetValueAtIndex(sp_entries, idx);

    fprintf(stderr, "\t- Flags (%#x): ", entry->flags);
    if (kSparkEntryEnabled & entry->flags)
      fprintf(stderr, "enabled ");
    else
      fprintf(stderr, "disabled ");
    if (kSparkEntryUnplugged & entry->flags)
      fprintf(stderr, "unplugged ");
    if (kSparkEntryPermanent & entry->flags)
      fprintf(stderr, "permanent ");
    fprintf(stderr, "\n");
      
    SparkAction *action = [[library actionSet] objectWithUID:entry->action];
    fprintf(stderr, "\t- Action (%u): %s\n", [action uid], [[action name] UTF8String]);
    
    SparkTrigger *trigger = [[library triggerSet] objectWithUID:entry->trigger];
    fprintf(stderr, "\t- Trigger (%u): %s\n", [trigger uid], [[trigger triggerDescription] UTF8String]);
    
    SparkApplication *application = entry->application == kSparkApplicationSystemUID ? 
      [SparkLibrary systemApplication] : [[library applicationSet] objectWithUID:entry->application];
    fprintf(stderr, "\t- Application (%u): %s\n", [application uid], [[application name] UTF8String]);
    
    fprintf(stderr, "----------------------------------\n");
  }
  fprintf(stderr, "}\n");
}

@end

#pragma mark -
void SparkDumpEntries(SparkLibrary *aLibrary) {
  [[aLibrary entryManager] dumpEntries];
}
