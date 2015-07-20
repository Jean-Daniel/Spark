/*
 *  SparkEntryManager.m
 *  SparkKit
 *
 *  Created by Black Moon Team.
 *  Copyright (c) 2004 - 2007 Shadow Lab. All rights reserved.
 */

#import <Sparkkit/SparkEntryManager.h>

#import "SparkEntryManagerPrivate.h"
#import "SparkEntryPrivate.h"
#import "SparkLibraryPrivate.h"

#import <objc/objc-runtime.h>
#import <SparkKit/SparkPrivate.h>

#import <SparkKit/SparkEntry.h>
#import <SparkKit/SparkAction.h>
#import <SparkKit/SparkLibrary.h>
#import <SparkKit/SparkTrigger.h>
#import <SparkKit/SparkObjectSet.h>
#import <SparkKit/SparkApplication.h>

/* PlugIn status */
#import <SparkKit/SparkPlugIn.h>
#import <SparkKit/SparkActionLoader.h>

NSString * const SparkEntryManagerWillAddEntryNotification = @"SparkEntryManagerWillAddEntry";
NSString * const SparkEntryManagerDidAddEntryNotification = @"SparkEntryManagerDidAddEntry";

NSString * const SparkEntryManagerWillUpdateEntryNotification = @"SparkEntryManagerWillUpdateEntry";
NSString * const SparkEntryManagerDidUpdateEntryNotification = @"SparkEntryManagerDidUpdateEntry";

NSString * const SparkEntryManagerWillRemoveEntryNotification = @"SparkEntryManagerWillRemoveEntry";
NSString * const SparkEntryManagerDidRemoveEntryNotification = @"SparkEntryManagerDidRemoveEntry";

NSString * const SparkEntryManagerDidChangeEntryStatusNotification = @"SparkEntryManagerDidChangeEntryStatus";

@implementation SparkEntryManager {
@private
  NSMutableDictionary *_objects;

  /* editing context */
  SparkEntry *_entry;
  SparkAction *_action;
  SparkTrigger *_trigger;
  SparkApplication *_application;
}

- (id)init {
  if (self = [self initWithLibrary:nil]) {
    
  }
  return self;
}

- (id)initWithLibrary:(SparkLibrary *)aLibrary {
  NSParameterAssert(aLibrary);
  if (self = [super init]) {
    self.library = aLibrary;
    _objects = [[NSMutableDictionary alloc] init];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didChangePlugInStatus:) 
                                                 name:SparkPlugInDidChangeStatusNotification
                                               object:nil];
  }
  return self;
}

- (void)dealloc {
  [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)setLibrary:(SparkLibrary *)library {
	if (_library) {
		[_library.notificationCenter removeObserver:self];
	}
  _library = library;
	if (_library) {
		[_library.notificationCenter addObserver:self
                                    selector:@selector(didRemoveApplication:)
                                        name:SparkObjectSetDidRemoveObjectNotification
                                      object:_library.applicationSet];
	}
}

- (NSUndoManager *)undoManager {
  return _library.undoManager;
}

#pragma mark -
#pragma mark Query
- (void)enumerateEntriesUsingBlock:(void (^)(SparkEntry *entry, BOOL *stop))block {
  [_objects enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
    block(obj, stop);
  }];
}

- (SparkEntry *)entryWithUID:(SparkUID)uid {
  return _objects[@(uid)];
}

typedef SparkUID (*SparkEntryAccessor)(SparkEntry *, SEL);

- (NSArray *)entriesForField:(SEL)field uid:(SparkUID)uid {
  NSMutableArray *result = [[NSMutableArray alloc] init];
  SparkEntryAccessor accessor = (SparkEntryAccessor)objc_msgSend;

  [self enumerateEntriesUsingBlock:^(SparkEntry *entry, BOOL *stop) {
    if (accessor(entry, field) == uid) {
      [result addObject:entry];
    }
  }];
  return result;
}

- (BOOL)containsEntryForField:(SEL)field uid:(SparkUID)uid {
  __block BOOL found = NO;
  SparkEntryAccessor accessor = (SparkEntryAccessor)objc_msgSend;
  [self enumerateEntriesUsingBlock:^(SparkEntry *entry, BOOL *stop) {
    if (accessor(entry, field) == uid) {
      found = YES;
      *stop = YES;
    }
  }];
  return found;
}

- (BOOL)containsEntryForTrigger:(SparkUID)aTrigger application:(SparkUID)anApplication {
  __block BOOL found = NO;
  [self enumerateEntriesUsingBlock:^(SparkEntry *entry, BOOL *stop) {
    if ([entry triggerUID] == aTrigger && [entry applicationUID] == anApplication) {
      found = YES;
      *stop = YES;
    }
  }];
  return found;
}

#pragma mark -
#pragma mark High-Level Methods

- (SparkEntry *)addEntryWithAction:(SparkAction *)anAction trigger:(SparkTrigger *)aTrigger application:(SparkApplication *)anApplication {
	NSParameterAssert(anAction && aTrigger && anApplication);
	SparkEntry *entry = [SparkEntry entryWithAction:anAction trigger:aTrigger application:anApplication];
	[self addEntry:entry parent:nil];
	return entry;
}

- (void)removeEntry:(SparkEntry *)anEntry {
	if (![anEntry manager]) return;
  NSParameterAssert([anEntry manager] == self);
	
  /* Undo management */
  [[self.undoManager prepareWithInvocationTarget:self] addEntry:anEntry parent:[anEntry parent]];
  
  // Will remove
  SparkLibraryPostNotification([self library], SparkEntryManagerWillRemoveEntryNotification, self, anEntry);
  
  [self sp_removeEntry:anEntry];
	
  // Did remove
  SparkLibraryPostNotification([self library], SparkEntryManagerDidRemoveEntryNotification, self, anEntry);
}

- (void)removeEntriesInArray:(NSArray *)theEntries {
  NSUInteger count = [theEntries count];
  while (count-- > 0) {
    [self removeEntry:[theEntries objectAtIndex:count]];
  }
}

#pragma mark Getters
- (NSArray *)entriesForAction:(SparkAction *)anAction {
  return [self entriesForField:@selector(actionUID) uid:[anAction uid]];
}
- (NSArray *)entriesForTrigger:(SparkTrigger *)aTrigger {
  return [self entriesForField:@selector(triggerUID) uid:[aTrigger uid]];
}
- (NSArray *)entriesForApplication:(SparkApplication *)anApplication {
  return [self entriesForField:@selector(applicationUID) uid:[anApplication uid]];
}

- (BOOL)containsEntry:(SparkEntry *)anEntry {
  return [self containsEntryForTrigger:[[anEntry trigger] uid] application:[[anEntry application] uid]];
}
- (BOOL)containsEntryForAction:(SparkAction *)anAction{
  return [self containsEntryForField:@selector(actionUID) uid:[anAction uid]];
}
- (BOOL)containsEntryForTrigger:(SparkTrigger *)aTrigger {
  return [self containsEntryForField:@selector(triggerUID) uid:[aTrigger uid]];
}
- (BOOL)containsEntryForApplication:(SparkApplication *)anApplication {
  return [self containsEntryForField:@selector(applicationUID) uid:[anApplication uid]];
}

- (BOOL)containsRegistredEntryForTrigger:(SparkTrigger *)aTrigger {
  __block BOOL found = NO;
  SparkUID uid = [aTrigger uid];
  [_objects enumerateKeysAndObjectsUsingBlock:^(id key, SparkEntry *entry, BOOL *stop) {
    if ((entry.triggerUID == uid) && entry.registred) {
      found = YES;
      *stop = YES;
    }
  }];
  return found;
}

#pragma mark -
- (SparkEntry *)activeEntryForTrigger:(SparkTrigger *)aTrigger application:(SparkApplication *)anApplication {
  __block SparkEntry *result = nil;
  SparkUID trigger = [aTrigger uid];
  SparkUID application = [anApplication uid];
  [_objects enumerateKeysAndObjectsUsingBlock:^(id key, SparkEntry *entry, BOOL *stop) {
    if ([entry triggerUID] == trigger && [entry isActive]) {
      if ([entry applicationUID] == application) {
        /* an active entry match */
        result = entry;
        *stop = YES;
      }
    }
  }];
	return result;
}

- (SparkEntry *)resolveEntryForTrigger:(SparkTrigger *)aTrigger application:(SparkApplication *)anApplication {
  __block SparkEntry *def = nil;
  __block SparkEntry *result = nil;

  SparkUID trigger = [aTrigger uid];
  SparkUID application = [anApplication uid];
  /* special case: anApplication is "All Application" (0) => def will always be null after the loop, so we don't have to do something special */
  [_objects enumerateKeysAndObjectsUsingBlock:^(id key, SparkEntry *entry, BOOL *stop) {
    if ([entry triggerUID] == trigger && [entry isActive] && [entry isRegistred]) {
      if ([entry applicationUID] == application) {
        /* an active entry match */
        result = entry;
        *stop = YES;
      } else if (entry.isSystem) {
        def = entry;
      }
    }
  }];

  if (result)
    return result;

  /* we didn't find a matching entry, search default */
  if (def) {
    /* If the default is overwritten, we ignore it (whatever the child is) */
    if ([def variantWithApplication:anApplication]) 
      return NULL;
  }
  return def;
}

@end


@interface SparkEntry (SparkEntryInternal)
/* direct object access */
@property(nonatomic, readonly) NSArray *children;

/* children */
- (void)addChild:(SparkEntry *)aChild;
- (void)addChildrenFromArray:(NSArray *)children;

- (void)removeChild:(SparkEntry *)aChild;
- (void)removeAllChildren;
@end

@implementation SparkEntryManager (SparkEntryEditor)

- (void)beginEditing:(SparkEntry *)anEntry {
  NSParameterAssert(anEntry);
  NSParameterAssert(nil == _entry);
  NSParameterAssert([anEntry manager] == self);
  /* copy informations */
  _entry = anEntry;
}
- (void)endEditing:(SparkEntry *)anEntry {
  NSParameterAssert(anEntry);
  NSParameterAssert(_entry == anEntry);
  NSParameterAssert([anEntry manager] == self);

  if (_action || _trigger || _application) {
    /* entry has change, proceed */
    [self updateEntry:anEntry
            setAction:_action
              trigger:_trigger
          application:_application];

    /* cleanup */
    _application = nil;
    _trigger = nil;
    _action = nil;
  }
  _entry = nil;
}

- (void)replaceAction:(SparkAction *)anAction inEntry:(SparkEntry *)anEntry {
  NSParameterAssert(anEntry);
  NSParameterAssert(_entry == anEntry);
  NSParameterAssert([anEntry manager] == self);
  if (anAction != _action)
    _action = [[anEntry action] isEqual:anAction] ? nil : anAction;
}

- (void)replaceTrigger:(SparkTrigger *)aTrigger inEntry:(SparkEntry *)anEntry {
  NSParameterAssert(anEntry);
  NSParameterAssert(_entry == anEntry);
  NSParameterAssert([anEntry manager] == self);
  if (aTrigger != _trigger)
    _trigger = [[anEntry trigger] isEqual:aTrigger] ? nil : aTrigger;
}

- (void)replaceApplication:(SparkApplication *)anApplication inEntry:(SparkEntry *)anEntry {
  NSParameterAssert(anEntry);
  NSParameterAssert(_entry == anEntry);
  NSParameterAssert([anEntry manager] == self);
  if (anApplication != _application)
    _application = [[anEntry application] isEqual:anApplication] ? nil : anApplication;
}

@end

@implementation SparkEntryManager (SparkEntryManagerInternal)

- (void)addEntry:(SparkEntry *)anEntry parent:(SparkEntry *)parent {
  NSParameterAssert(![anEntry manager]); // anEntry is not managed
  NSParameterAssert([[anEntry action] uid] != 0); // has valid action
  NSParameterAssert([[anEntry trigger] uid] != 0); // has valid trigger
  NSParameterAssert(!parent || [parent manager] == self); // parent is managed

  /* sanity check, avoid entry conflict */
  NSParameterAssert(![anEntry isEnabled] || ![self activeEntryForTrigger:[anEntry trigger] application:[anEntry application]]);

  /* Undo management */
  [[self undoManager] registerUndoWithTarget:self selector:@selector(removeEntry:) object:anEntry];

  // Will add
  SparkLibraryPostNotification([self library], SparkEntryManagerWillAddEntryNotification, self, anEntry);

  [self sp_addEntry:anEntry parent:parent];

  // Did add
  SparkLibraryPostNotification([self library], SparkEntryManagerDidAddEntryNotification, self, anEntry);
}

- (void)updateEntry:(SparkEntry *)anEntry setAction:(SparkAction *)newAction
            trigger:(SparkTrigger *)newTrigger application:(SparkApplication *)newApplication {
  NSParameterAssert([anEntry manager] == self);
  NSParameterAssert(_objects[@(anEntry.uid)]);

  /* check conflict before undo and notify to avoid inconsistency */
  if (anEntry.enabled && (newTrigger || newApplication)) {
    /* check conflict */
    if ([self activeEntryForTrigger:newTrigger ? : anEntry.trigger
                        application:newApplication ? : anEntry.application])
      anEntry.enabled = NO;
  }

  /* create a copy that will reflect the old entry */
  SparkEntry *ghost = [anEntry copy];

  /* undo manager */
  [[self.undoManager prepareWithInvocationTarget:self] updateEntry:anEntry
                                                         setAction:newAction ? anEntry.action : nil
                                                           trigger:newTrigger ? anEntry.trigger : nil
                                                       application:newApplication ? anEntry.application : nil];
  // will update
  SparkLibraryPostNotification(self.library, SparkEntryManagerWillUpdateEntryNotification, self, anEntry);

  if (newAction) {
    anEntry.action = newAction;

    /* update weak entries */
    if (anEntry.isSystem && anEntry.hasVariant) {
      SparkEntry *child = anEntry.firstChild;
      do {
        if ([child.action isEqual:ghost.action])
          child.action = newAction;
      } while ((child = child.sibling));
    }
  }

  if (newTrigger)
    anEntry.trigger = newTrigger;
  if (newApplication)
    anEntry.application = newApplication;

  // did update
  SparkLibraryPostUpdateNotification(self.library, SparkEntryManagerDidUpdateEntryNotification, self, ghost, anEntry);

  /* Remove orphan action */
  if (newAction && ![self containsEntryForAction:ghost.action])
    [self.library.actionSet removeObject:ghost.action];

  /* If trigger has changed */
  if (newTrigger)
    [self updateTriggerStatus:ghost.trigger];
}

static SparkUID sUID = 0;

- (void)sp_addEntry:(SparkEntry *)anEntry parent:(SparkEntry *)aParent {
  /* add entry */
  if (![anEntry uid]) {
    [anEntry setUID:++sUID];
  } else {
    SPXDebug(@"Insert entry with UID: %lu", (long)[anEntry uid]);
  }
  _objects[@(anEntry.uid)] = anEntry;

  /* Update trigger flag */
  if (!anEntry.isSystem)
    [anEntry.trigger setHasSpecificAction:YES];

  anEntry.manager = self;
  if (aParent) {
    /* update relations */
    [aParent addChild:anEntry];
    /* do not register undo since, undoing addEntry will call removeEntry which call removeChild */
    //[[sp_manager undoManager] registerUndoWithTarget:self selector:@selector(removeChild:) object:anEntry];
  }
}

- (void)sp_removeEntry:(SparkEntry *)anEntry {
  NSParameterAssert(anEntry.manager == self);
  NSParameterAssert(_objects[@(anEntry.uid)]);

  SparkAction *action = anEntry.action;
  SparkTrigger *trigger = anEntry.trigger;

  /* update entries relations */
  if (!anEntry.isRoot) {
    /* undo will call addEntry:parent: and will restore the parent */
    [anEntry.parent removeChild:anEntry];
  } else if ([anEntry isSystem] && [anEntry hasVariant]) {
    /* here undo will call addEntry:anEntry parent:nil and we have to restore the relationship */
    [self.undoManager registerUndoWithTarget:anEntry selector:@selector(addChildrenFromArray:) object:anEntry.children];
    [anEntry removeAllChildren];
  }
  anEntry.manager = nil;

  [_objects removeObjectForKey:@(anEntry.uid)];

  /* when undoing, we decrement sUID */
  if (self.undoManager.undoing) {
    NSAssert(anEntry.uid == sUID, @"'next UID' does not match [entry uid]");
    sUID--;
  }

  /* Remove orphan action */
  if (![self containsEntryForAction:action]) {
    [self.library.actionSet removeObject:action];
  }
  /* Remove orphan trigger */
  [self updateTriggerStatus:trigger];
}

/* Check if contains, and update 'has many' status */
- (void)updateTriggerStatus:(SparkTrigger *)trigger {
  __block BOOL contains = NO;
  __block SparkEntry *specificEntry = nil;

  SparkUID tuid = trigger.uid;
  [self enumerateEntriesUsingBlock:^(SparkEntry *entry, BOOL *stop) {
    if (entry.triggerUID == tuid) {
      if (!entry.isSystem) {
        specificEntry = entry;
        *stop = YES;
        return;
      } else {
        /* it contains at least one entry, but we have to continue the loop
         to check if it contains a system entry */
        contains = YES;
      }
    }
  }];
  if (specificEntry) {
    [specificEntry.trigger setHasSpecificAction:YES];
  } else {
    /* no entry, or no system entry found */
    if (!contains)
      [[[self library] triggerSet] removeObject:trigger];
    else
      [trigger setHasSpecificAction:NO];
  }
}

#pragma mark Notification
- (void)didRemoveApplication:(NSNotification *)aNotification {
  [self removeEntriesInArray:[self entriesForApplication:SparkNotificationObject(aNotification)]];
}

#pragma mark Entry Management - Plugged
- (void)didChangePlugInStatus:(NSNotification *)aNotification {
  SparkPlugIn *plugin = [aNotification object];

  BOOL flag = plugin.enabled;
  Class cls = [plugin actionClass];

  [self enumerateEntriesUsingBlock:^(SparkEntry *entry, BOOL *stop) {
    SparkAction *act = entry.action;
    if ([act isKindOfClass:cls]) {
      /* auto disabled entry that will conflict if replug */
      if (flag && entry.enabled && [self activeEntryForTrigger:entry.trigger application:entry.application])
        entry.enabled = NO;
      /* Update library entry */
      entry.plugged = flag;
    }
  }];
}

@end

#pragma mark -
@implementation SparkEntryManager (SparkArchiving)

- (void)cleanup {
  /* Check all triggers and actions */
  for (SparkEntry *entry in _objects.allValues) {
    /* Invalid entry if:
     - action does not exists.
     - trigger does not exists.
     - application does not exists.
     */
    if (![entry action] || ![entry trigger] || ![entry application]) {
      SPXDebug(@"Remove Invalid entry %@", entry);
      [self sp_removeEntry:entry];
    } else {
      if (![entry isSystem])
        [[entry trigger] setHasSpecificAction:YES];
      /* restore UID counter */
      sUID = MAX(sUID, [entry uid]);
    }
  }
}

- (id)initWithCoder:(NSCoder *)coder {
  NSParameterAssert([coder isKindOfClass:[SparkLibraryUnarchiver class]]);
  NSParameterAssert([(SparkLibraryUnarchiver *)coder library]);

  if (self = [self initWithLibrary:[(SparkLibraryUnarchiver *)coder library]]) {
    NSArray *entries = [coder decodeObjectForKey:@"entries"];
    for (SparkEntry *entry in entries) {
      _objects[@(entry.uid)] = entry;
      entry.manager = self;
    }
    [self cleanup];
  }
  return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
  NSParameterAssert([coder isKindOfClass:[SparkLibraryArchiver class]]);
  [coder encodeObject:_objects.allValues forKey:@"entries"];
}

@end

#pragma mark -
@implementation SparkEntryManager (SparkLegacyLibraryImporter)

/* returns the firt entry that match the criterias */
- (SparkEntry *)entryForTrigger:(SparkTrigger *)aTrigger application:(SparkApplication *)anApplication {
  __block SparkEntry *result = nil;
  SparkUID trigger = [aTrigger uid], application = [anApplication uid];
  [self enumerateEntriesUsingBlock:^(SparkEntry *entry, BOOL *stop) {
    if (entry.triggerUID == trigger && entry.applicationUID == application) {
      result = entry;
      *stop = YES;
    }
  }];
  return result;
}

- (void)resolveParents {
  [self enumerateEntriesUsingBlock:^(SparkEntry *entry, BOOL *stop) {
    if (!entry.isSystem) {
      SparkEntry *parent = [self entryForTrigger:entry.trigger application:self->_library.systemApplication];
      if (parent)
        [parent addChild:entry];
    }
  }];
}

- (void)postProcessLegacy {
  /* Resolve Ignore Actions */
  [self enumerateEntriesUsingBlock:^(SparkEntry *entry, BOOL *stop) {
    if (!entry.action && entry.parent.action) {
      entry.action = entry.parent.action;
    }
  }];
  [self cleanup];
}

- (void)loadLegacyEntries:(NSArray *)entries {
  NSUInteger idx = [entries count];
  while (idx-- > 0) {
    [self sp_addEntry:[entries objectAtIndex:idx] parent:nil];
  }

  /* resolve parents */
  [self resolveParents];

  /* cleanup */
  [self postProcessLegacy];
}

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

#define SparkReadField(field)	({swap ? OSSwapInt32(field) : field; })

- (BOOL)readFromFileWrapper:(NSFileWrapper *)fileWrapper error:(__autoreleasing NSError **)outError {
  /* Cleanup */
  [_objects removeAllObjects];

  NSData *data = [fileWrapper regularFileContents];

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
      SPXDebug(@"Invalid header");
      if (outError) *outError = [NSError errorWithDomain:NSCocoaErrorDomain code:NSFileReadCorruptFileError userInfo:nil];
      return NO;
  }

  if (SparkReadField(header->version) != 0) {
    SPXDebug(@"Unsupported version: %lx", (long)SparkReadField(header->version));
    if (outError) *outError = [NSError errorWithDomain:NSCocoaErrorDomain code:NSFileReadCorruptFileError userInfo:nil];
    return NO;
  }

  NSUInteger count = SparkReadField(header->count);
  if ([data length] < count * sizeof(SparkLibraryEntry_v0) + sizeof(SparkEntryHeader)) {
    SPXDebug(@"Unexpected end of file");
    if (outError) *outError = [NSError errorWithDomain:NSCocoaErrorDomain code:NSFileReadCorruptFileError userInfo:nil];
    return NO;
  }

  const SparkLibraryEntry_v0 *entries = header->entries;
  while (count-- > 0) {
    SparkEntry *entry = [[SparkEntry alloc] init];
    entry.enabled = (SparkReadField(entries->flags) & 1) != 0;

    entry.action = [_library actionWithUID:SparkReadField(entries->action)];
    entry.trigger = [_library triggerWithUID:SparkReadField(entries->trigger)];
    entry.application = [_library applicationWithUID:SparkReadField(entries->application)];

    [self sp_addEntry:entry parent:nil];
    entries++;
  }
  /* build parent/child relations */
  [self resolveParents];

  /* cleanup */
  [self cleanup];

  return YES;
}
@end

#pragma mark Debug
static
void _SparkDumpEntry(SparkEntry *entry, bool child) {
  const char *indent = child ? "\t\t" : "\t";
  fprintf(stderr, "%s- UID: %lu\n", indent, (long)[entry uid]);

  fprintf(stderr, "%s- Type: ", indent);
  switch ([entry type]) {
    case kSparkEntryTypeDefault:
      fprintf(stderr, "default");
      break;
    case kSparkEntryTypeSpecific:
      fprintf(stderr, "specific");
      break;
    case kSparkEntryTypeOverWrite:
      fprintf(stderr, "overwrite");
      break;
    case kSparkEntryTypeWeakOverWrite:
      fprintf(stderr, "weak overwrite");
      break;
  }
  fprintf(stderr, "\n");

  fprintf(stderr, "%s- Flags: ", indent);
  if ([entry isEnabled])
    fprintf(stderr, "enabled ");
  else
    fprintf(stderr, "disabled ");
  if ([entry isPlugged])
    fprintf(stderr, "plugged ");
  else
    fprintf(stderr, "unplugged ");
  if ([entry isPersistent])
    fprintf(stderr, "persistent ");
  fprintf(stderr, "\n");

  SparkAction *action = [entry action];
  fprintf(stderr, "%s- Action (%lu): %s\n", indent, (long)[action uid], [[action name] UTF8String]);

  SparkTrigger *trigger = [entry trigger];
  fprintf(stderr, "%s- Trigger (%lu): %s\n", indent, (long)[trigger uid], [[trigger triggerDescription] UTF8String]);

  SparkApplication *application = [entry application];
  fprintf(stderr, "%s- Application (%lu): %s\n", indent, (long)[application uid], [[application name] UTF8String]);
}

@interface SparkEntryManager (SparkDebug)
- (void)dumpEntries;
@end

@implementation SparkEntryManager (SparkDebug)

- (void)dumpEntries {
  fprintf(stderr, "Entries: %lu\n {\n", [_objects count]);
  [self enumerateEntriesUsingBlock:^(SparkEntry *entry, BOOL *stop) {
    if (!entry.parent) {
      if (entry.isSystem) {
        _SparkDumpEntry(entry, false);
        fprintf(stderr, "----------------------------------\n");
        SparkEntry *child = entry.firstChild;
        while (child) {
          _SparkDumpEntry(child, true);
          child = child.sibling;
          fprintf(stderr, "----------------------------------\n");
        }
      } else {
        /* specific entry */
        fprintf(stderr, "----------------------------------\n");
        _SparkDumpEntry(entry, true);
      }
    }
  }];
  fprintf(stderr, "}\n");
}

@end

#pragma mark -
void SparkDumpEntries(SparkLibrary *aLibrary) {
  [[aLibrary entryManager] dumpEntries];
}

