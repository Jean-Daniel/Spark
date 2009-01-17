/*
 *  SparkEntryManagerPrivate.m
 *  SparkKit
 *
 *  Created by Black Moon Team.
 *  Copyright (c) 2004 - 2007 Shadow Lab. All rights reserved.
 */

#import "SparkEntryManagerPrivate.h"
#import "SparkLibraryPrivate.h"
#import "SparkEntryPrivate.h"

#import <SparkKit/SparkEntry.h>

#import <SparkKit/SparkPlugIn.h>
#import <SparkKit/SparkAction.h>
#import <SparkKit/SparkTrigger.h>
#import <SparkKit/SparkLibrary.h>
#import <SparkKit/SparkObjectSet.h>
#import <SparkKit/SparkApplication.h>

@interface SparkEntry (SparkEntryInternal)
/* direct object access */
- (NSArray *)children;
/* children */
- (void)addChild:(SparkEntry *)aChild;
- (void)addChildrenFromArray:(NSArray *)children;

- (void)removeChild:(SparkEntry *)aChild;
- (void)removeAllChildren;
@end

@implementation SparkEntryManager (SparkEntryEditor)

- (void)beginEditing:(SparkEntry *)anEntry {
	NSParameterAssert(anEntry);
	NSParameterAssert(nil == sp_edit.entry);
	NSParameterAssert([anEntry manager] == self);
	/* copy informations */
	sp_edit.entry = anEntry;
}
- (void)endEditing:(SparkEntry *)anEntry {
	NSParameterAssert(anEntry);
	NSParameterAssert(sp_edit.entry == anEntry);
	NSParameterAssert([anEntry manager] == self);	
	
	if (sp_edit.action || sp_edit.trigger || sp_edit.application) {
		/* entry has change, proceed */
		[self updateEntry:anEntry
						setAction:sp_edit.action
							trigger:sp_edit.trigger
					application:sp_edit.application];
		
		/* cleanup */
		[sp_edit.application release]; sp_edit.application = nil;
		[sp_edit.trigger release]; sp_edit.trigger = nil;
		[sp_edit.action release]; sp_edit.action = nil;
	}
	sp_edit.entry = nil;
}

- (void)replaceAction:(SparkAction *)anAction inEntry:(SparkEntry *)anEntry {
	NSParameterAssert(anEntry);
	NSParameterAssert(sp_edit.entry == anEntry);
	NSParameterAssert([anEntry manager] == self);
	if (anAction != sp_edit.action) {
		[sp_edit.action release];
		sp_edit.action = [[anEntry action] isEqual:anAction] ? nil : [anAction retain];
	}
}

- (void)replaceTrigger:(SparkTrigger *)aTrigger inEntry:(SparkEntry *)anEntry {
	NSParameterAssert(anEntry);
	NSParameterAssert(sp_edit.entry == anEntry);
	NSParameterAssert([anEntry manager] == self);
	if (aTrigger != sp_edit.trigger) {
		[sp_edit.trigger release];
		sp_edit.trigger = [[anEntry trigger] isEqual:aTrigger] ? nil : [aTrigger retain];
	}
}

- (void)replaceApplication:(SparkApplication *)anApplication inEntry:(SparkEntry *)anEntry {
	NSParameterAssert(anEntry);
	NSParameterAssert(sp_edit.entry == anEntry);
	NSParameterAssert([anEntry manager] == self);	
	if (anApplication != sp_edit.application) {
		[sp_edit.application release];
		sp_edit.application = [[anEntry application] isEqual:anApplication] ? nil : [anApplication retain];
	}
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
	NSParameterAssert(NSMapGet(sp_objects, (const void *)(intptr_t)[anEntry uid]));
	
	/* check conflict before undo and notify to avoid inconsistency */
	if ([anEntry isEnabled] && (newTrigger || newApplication)) {
		/* check conflict */
		if ([self activeEntryForTrigger:newTrigger ? : [anEntry trigger]
												application:newApplication ? : [anEntry application]])
			[anEntry setEnabled:NO];
	}
	
	/* create a copy that will reflect the old entry */
	SparkEntry *ghost = [anEntry copy];
	
	/* undo manager */
	[[[self undoManager] prepareWithInvocationTarget:self] updateEntry:anEntry 
																													 setAction:newAction ? [anEntry action] : nil
																														 trigger:newTrigger ? [anEntry trigger] : nil
																												 application:newApplication ? [anEntry application] : nil];
	// will update
	SparkLibraryPostNotification([self library], SparkEntryManagerWillUpdateEntryNotification, self, anEntry);

	if (newAction) {
		[anEntry setAction:newAction];
		
		/* update weak entries */
		if ([anEntry isSystem] && [anEntry hasVariant]) {
			SparkEntry *child = [anEntry firstChild];
			do {
				if ([[child action] isEqual:[ghost action]])
					[child setAction:newAction];
			} while (child = [child sibling]);
		}
	}
	
	if (newTrigger) [anEntry setTrigger:newTrigger];
	if (newApplication) [anEntry setApplication:newApplication];
	
	// did update
	SparkLibraryPostUpdateNotification([self library], SparkEntryManagerDidUpdateEntryNotification, self, ghost, anEntry);
	
	/* Remove orphan action */
	if (newAction && ![self containsEntryForAction:[ghost action]]) {
		[[[self library] actionSet] removeObject:[ghost action]];
	}
	
	/* If trigger has changed */
	if (newTrigger)
		[self updateTriggerStatus:[ghost trigger]];
	
	[ghost release];
}

static SparkUID sUID = 0;

- (void)sp_addEntry:(SparkEntry *)anEntry parent:(SparkEntry *)aParent {
  /* add entry */
  if (![anEntry uid]) {
    [anEntry setUID:++sUID];
  } else {
    DLog(@"Insert entry with UID: %u", [anEntry uid]);
  }
  NSMapInsertKnownAbsent(sp_objects, (const void *)(intptr_t)[anEntry uid], anEntry);
  
  /* Update trigger flag */
  if (![anEntry isSystem])
    [[anEntry trigger] setHasSpecificAction:YES];
  
  [anEntry setManager:self];
	if (aParent) {
		/* update relations */
		[aParent addChild:anEntry];
		/* do not register undo since, undoing addEntry will call removeEntry which call removeChild */
		//[[sp_manager undoManager] registerUndoWithTarget:self selector:@selector(removeChild:) object:anEntry];
	}
}

- (void)sp_removeEntry:(SparkEntry *)anEntry {
	NSParameterAssert([anEntry manager] == self);
  NSParameterAssert(NSMapGet(sp_objects, (const void *)(intptr_t)[anEntry uid]));
	
  SparkAction *action = [anEntry action];
  SparkTrigger *trigger = [anEntry trigger];
	
	/* update entries relations */
	if (![anEntry isRoot]) {
		/* undo will call addEntry:parent: and will restore the parent */
		[[anEntry parent] removeChild:anEntry];
	} else if ([anEntry isSystem] && [anEntry hasVariant]) {
		/* here undo will call addEntry:anEntry parent:nil and we have to restore the relationship */
		[[self undoManager] registerUndoWithTarget:anEntry selector:@selector(addChildrenFromArray:) object:[anEntry children]];
		[anEntry removeAllChildren];
	}
	[anEntry setManager:nil];
	
  NSMapRemove(sp_objects, (const void *)(intptr_t)[anEntry uid]);
  
  /* when undoing, we decrement sUID */
  if ([[self undoManager] isUndoing]) {
    NSAssert([anEntry uid] == sUID, @"'next UID' does not match [entry uid]");
    sUID--;
  }
  
  /* Remove orphan action */
  if (![self containsEntryForAction:action]) {
    [[[self library] actionSet] removeObject:action];
  }
  /* Remove orphan trigger */
  [self updateTriggerStatus:trigger];
}

/* Check if contains, and update 'has many' status */
- (void)updateTriggerStatus:(SparkTrigger *)trigger {
  SparkEntry *entry;
  BOOL contains = NO;
  SparkUID tuid = [trigger uid];
  
  NSMapEnumerator iter = NSEnumerateMapTable(sp_objects);
  while (NSNextMapEnumeratorPair(&iter, NULL, (void * *)&entry)) {
    if ([entry triggerUID] == tuid) {
      if (![entry isSystem]) {
        [[entry trigger] setHasSpecificAction:YES];
        NSEndMapTableEnumeration(&iter);
        return;
      } else {
        /* it contains at least one entry, but we have to continue the loop
				 to check if it contains a system entry */
        contains = YES;
      }
    }
  }
  NSEndMapTableEnumeration(&iter);
  /* no entry, or no system entry found */
  if (!contains)
    [[[self library] triggerSet] removeObject:trigger];
  else
    [trigger setHasSpecificAction:NO];
}

#pragma mark Notification
- (void)didRemoveApplication:(NSNotification *)aNotification {
	[self removeEntriesInArray:[self entriesForApplication:SparkNotificationObject(aNotification)]];
}

#pragma mark Entry Management - Plugged
- (void)didChangePlugInStatus:(NSNotification *)aNotification {
  SparkPlugIn *plugin = [aNotification object];
  
	SparkEntry *entry;
  BOOL flag = [plugin isEnabled];
  Class cls = [plugin actionClass];
  NSMapEnumerator iter = NSEnumerateMapTable(sp_objects);
  while (NSNextMapEnumeratorPair(&iter, NULL, (void * *)&entry)) {
		SparkAction *act = [entry action];
		if ([act isKindOfClass:cls]) {
			/* auto disabled entry that will conflict if replug */
			if (flag && [entry isEnabled] && [self activeEntryForTrigger:[entry trigger] application:[entry application]])
				[entry setEnabled:NO];
      /* Update library entry */
      [entry setPlugged:flag];
    }
  }
  NSEndMapTableEnumeration(&iter);
}

@end

#pragma mark -
@implementation SparkEntryManager (SparkArchiving)

- (void)cleanup {
  SparkEntry *entry;
  /* Check all triggers and actions */
  NSMapEnumerator iter = NSEnumerateMapTable(sp_objects);
  while (NSNextMapEnumeratorPair(&iter, NULL, (void * *)&entry)) {
    /* Invalid entry if: 
		 - action does not exists.
		 - trigger does not exists.
		 - application does not exists.
		 */
    if (![entry action] || ![entry trigger] || ![entry application]) {
      DLog(@"Remove Invalid entry %@", entry);
      [self sp_removeEntry:entry];
    } else {
      if (![entry isSystem])
        [[entry trigger] setHasSpecificAction:YES];
			/* restore UID counter */
			sUID = MAX(sUID, [entry uid]);
    }
  }
  NSEndMapTableEnumeration(&iter);
}

- (id)initWithCoder:(NSCoder *)coder {
  NSParameterAssert([coder isKindOfClass:[SparkLibraryUnarchiver class]]);
  NSParameterAssert([(SparkLibraryUnarchiver *)coder library]);
  
  if (self = [self initWithLibrary:[(SparkLibraryUnarchiver *)coder library]]) {
    NSArray *entries = [coder decodeObjectForKey:@"entries"];
    NSUInteger idx = [entries count];
    while (idx-- > 0) {
      SparkEntry *entry = [entries objectAtIndex:idx];
      NSMapInsert(sp_objects, (const void *)(intptr_t)[entry uid], entry);
			[entry setManager:self];
    }
		[self cleanup];
  }
  return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
  NSParameterAssert([coder isKindOfClass:[SparkLibraryArchiver class]]);
  [coder encodeObject:NSAllMapTableValues(sp_objects) forKey:@"entries"];
}

@end

#pragma mark -
@implementation SparkEntryManager (SparkLegacyLibraryImporter)

/* returns the firt entry that match the criterias */
- (SparkEntry *)entryForTrigger:(SparkTrigger *)aTrigger application:(SparkApplication *)anApplication {
  SparkEntry *entry;
  SparkUID trigger = [aTrigger uid], application = [anApplication uid];
  NSMapEnumerator iter = NSEnumerateMapTable(sp_objects);
  while (NSNextMapEnumeratorPair(&iter, NULL, (void * *)&entry)) {
    if ([entry triggerUID] == trigger && [entry applicationUID] == application) {
      NSEndMapTableEnumeration(&iter);
      return entry;
    }
  }
  NSEndMapTableEnumeration(&iter);
  return NULL;
}

- (void)resolveParents {
  SparkEntry *entry;
  NSMapEnumerator iter = NSEnumerateMapTable(sp_objects);
  while (NSNextMapEnumeratorPair(&iter, NULL, (void * *)&entry)) {
    if (![entry isSystem]) {
      SparkEntry *parent = [self entryForTrigger:[entry trigger] application:[sp_library systemApplication]];
      if (parent)
        [parent addChild:entry];
    }
  }
  NSEndMapTableEnumeration(&iter);
}

- (void)postProcessLegacy {
  /* Resolve Ignore Actions */
  SparkEntry *entry;
  NSMapEnumerator iter = NSEnumerateMapTable(sp_objects);
  while (NSNextMapEnumeratorPair(&iter, NULL, (void * *)&entry)) {
    if (![entry action] && [[entry parent] action]) {
      [entry setAction:[[entry parent] action]];
    }
  }
  NSEndMapTableEnumeration(&iter);
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

- (BOOL)readFromFileWrapper:(NSFileWrapper *)fileWrapper error:(NSError **)outError {
  /* Cleanup */
  NSResetMapTable(sp_objects);
  
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
      DLog(@"Invalid header");
      if (outError) *outError = [NSError errorWithDomain:NSCocoaErrorDomain code:NSFileReadCorruptFileError userInfo:nil];
      return NO;
  }
  
  if (SparkReadField(header->version) != 0) {
    DLog(@"Unsupported version: %x", SparkReadField(header->version));
    if (outError) *outError = [NSError errorWithDomain:NSCocoaErrorDomain code:NSFileReadCorruptFileError userInfo:nil];
    return NO;
  }
  
  NSUInteger count = SparkReadField(header->count);
  if ([data length] < count * sizeof(SparkLibraryEntry_v0) + sizeof(SparkEntryHeader)) {
    DLog(@"Unexpected end of file");
    if (outError) *outError = [NSError errorWithDomain:NSCocoaErrorDomain code:NSFileReadCorruptFileError userInfo:nil];
    return NO;
  }
  
  const SparkLibraryEntry_v0 *entries = header->entries;
  while (count-- > 0) {
    SparkEntry *entry = [[SparkEntry alloc] init];
    [entry setEnabled:(SparkReadField(entries->flags) & 1) != 0];
    
    [entry setAction:[sp_library actionWithUID:SparkReadField(entries->action)]];
    [entry setTrigger:[sp_library triggerWithUID:SparkReadField(entries->trigger)]];
    [entry setApplication:[sp_library applicationWithUID:SparkReadField(entries->application)]];
    
    [self sp_addEntry:entry parent:nil];
    [entry release];
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
  SparkEntry *entry;
  fprintf(stderr, "Entries: %lu\n {\n", (long)NSCountMapTable(sp_objects));
  NSMapEnumerator iter = NSEnumerateMapTable(sp_objects);
  while (NSNextMapEnumeratorPair(&iter, NULL, (void * *)&entry)) {
    if (![entry parent]) {
      if ([entry isSystem]) {
        _SparkDumpEntry(entry, false);
        fprintf(stderr, "----------------------------------\n");
				SparkEntry *child = [entry firstChild];
				while (child) {
					_SparkDumpEntry(child, true);
					child = [child sibling];
					fprintf(stderr, "----------------------------------\n");
				}
      } else {
        /* specific entry */
        fprintf(stderr, "----------------------------------\n");
        _SparkDumpEntry(entry, true);
      }
    }
  }
  NSEndMapTableEnumeration(&iter);
  fprintf(stderr, "}\n");
}

@end

#pragma mark -
void SparkDumpEntries(SparkLibrary *aLibrary) {
  [[aLibrary entryManager] dumpEntries];
}
