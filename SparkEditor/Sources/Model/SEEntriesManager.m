/*
 *  SEEntriesManager.m
 *  Spark Editor
 *
 *  Created by Black Moon Team.
 *  Copyright (c) 2004 - 2007 Shadow Lab. All rights reserved.
 */

#import "SEEntriesManager.h"
#import "SESparkEntrySet.h"
#import "SEEntryEditor.h"

#import <SparkKit/SparkAction.h>
#import <SparkKit/SparkTrigger.h>
#import <SparkKit/SparkLibrary.h>
#import <SparkKit/SparkObjectSet.h>
#import <SparkKit/SparkApplication.h>
#import <SparkKit/SparkEntryManager.h>

NSString * const SEEntriesManagerDidReloadNotification = @"SEEntriesManagerDidReload";
NSString * const SEEntriesManagerDidCreateEntryNotification = @"SEEntriesManagerDidCreateEntry";
NSString * const SEEntriesManagerDidUpdateEntryNotification = @"SEEntriesManagerDidUpdateEntry";
NSString * const SEEntriesManagerDidCreateWeakEntryNotification = @"SEEntriesManagerDidCreateWeakEntry";

@implementation SEEntriesManager

- (id)init {
  [self release];
  [NSException raise:NSInvalidArgumentException format:@"Invalid initializer"];
  return nil;
}

- (id)initWithLibrary:(SparkLibrary *)aLibrary {
  if (self = [super init]) {
    se_globals = [[SESparkEntrySet alloc] init];
    se_snapshot = [[SESparkEntrySet alloc] init];
    se_overwrites = [[SESparkEntrySet alloc] init];
    
    /* Init globals */
    se_library = [aLibrary retain];
    [se_globals addEntriesFromArray:[[se_library entryManager] entriesForApplication:0]];
  }
  return self;
}

- (void)dealloc {
  [se_app release];
  [se_editor release];
  [se_library release];
  [se_globals release];
  [se_snapshot release];
  [se_overwrites release];
  [super dealloc];
}

- (SparkLibrary *)library {
  return se_library;
}

- (SESparkEntrySet *)globals {
  return se_globals;
}
- (SESparkEntrySet *)snapshot {
  return se_snapshot;
}
- (SESparkEntrySet *)overwrites {
  return se_overwrites;
}

- (void)refresh {
  [se_snapshot removeAllEntries];
  [se_overwrites removeAllEntries];
  
  /* Add defaults */
  [se_snapshot addEntriesFromEntrySet:se_globals];
  
  /* Add overwrite if needed */
  if ([se_app uid] != 0) {
    NSArray *entries = [[se_library entryManager] entriesForApplication:[se_app uid]];
    
    if ([entries count]) {
      [se_overwrites addEntriesFromArray:entries];
      /* Merge */
      [se_snapshot addEntriesFromEntrySet:se_overwrites];
    }
  }
  [[NSNotificationCenter defaultCenter] postNotificationName:SEEntriesManagerDidReloadNotification
                                                      object:self];
}
- (void)reload {
  [se_globals removeAllEntries];
  [se_globals addEntriesFromArray:[[se_library entryManager] entriesForApplication:0]];
  [self refresh];
}

- (void)libraryDidReload:(NSNotification *)aNotification {
  [self reload];
}

- (SparkApplication *)application {
  return se_app;
}
- (void)setApplication:(SparkApplication *)anApplication {
  if (se_app != anApplication) {
    /* Optimization: should reload if switch from/to global */
    BOOL reload = [anApplication uid] == 0 || [se_app uid] == 0;
    /* Sould not reload if overwrite change, ie it is not empty or it will not be. */
    if (!reload)
      reload = [se_overwrites count] != 0 || [[se_library entryManager] containsEntryForApplication:[anApplication uid]];
    
    [se_app release];
    se_app = [anApplication retain];
    /* Avoid useless reload */
    if (reload)
      [self refresh];
  }
}

- (unsigned)removeEntries:(NSArray *)entries {
  BOOL refresh = NO;
  unsigned removed = 0;
  int count = [entries count];
  while (count-- > 0) {
    SparkEntry *entry = [entries objectAtIndex:count];
    if ([entry type] != kSparkEntryTypeDefault || [[self application] uid] == 0) {
      removed++;
      refresh = YES;
      [[se_library entryManager] removeEntry:entry];
    }
  }
  if (refresh)
    [self reload]; // full reload
  return removed;
}

- (SparkEntry *)createWeakEntryForEntry:(SparkEntry *)anEntry {
  NSParameterAssert([[self application] uid] != 0);
  SparkEntry *weak = [anEntry copy];
  [weak setApplication:[self application]];
  /* Update storage */
  [se_snapshot addEntry:weak];
  [se_overwrites addEntry:weak];
  
  [[se_library entryManager] addEntry:weak];
  
  [[NSNotificationCenter defaultCenter] postNotificationName:SEEntriesManagerDidCreateWeakEntryNotification
                                                      object:weak];
  return [weak autorelease];
}

/* Create Entry with type */
- (void)editEntry:(SparkEntry *)anEntry modalForWindow:(NSWindow *)aWindow {
  SEEntryEditor *editor = [self editor];
  [editor setEntry:anEntry];
  
  [NSApp beginSheet:[editor window]
     modalForWindow:aWindow
      modalDelegate:nil
     didEndSelector:NULL
        contextInfo:nil];
}

/* Find equivalent trigger in library */
- (SparkTrigger *)libraryTriggerForTrigger:(SparkTrigger *)aTrigger {
  SparkTrigger *trigger;
  NSEnumerator *triggers = [[se_library triggerSet] objectEnumerator];
  while (trigger = [triggers nextObject]) {
    if ([trigger isEqualToTrigger:aTrigger]) {
      return trigger;
    }
  }
  return nil;
}

- (BOOL)editor:(SEEntryEditor *)theEditor shouldCreateEntry:(SparkEntry *)anEntry {
  NSParameterAssert(anEntry != nil);
  /* First validate entry type: check if trigger do not already exist for globals */
  SparkTrigger *trigger = [self libraryTriggerForTrigger:[anEntry trigger]];
  /* If trigger already exists */
  if (trigger) {
    /* Update new entry trigger */
    [anEntry setTrigger:trigger];
    /* Get previous entry that use this trigger */
    SparkEntry *previous = [[se_library entryManager] entryForTrigger:[trigger uid]
                                                          application:[[anEntry application] uid]];
    /* Already used by previous */
    if (previous) {
      /* Is previous a weak action */
      if (kSparkEntryTypeWeakOverWrite == [previous type]) {
        DLog(@"Remove weak entry");
        /* Remove weak entry */
        [[se_library entryManager] removeEntry:previous];
      } else {
        /* Already used by a real entry */
        int result = NSRunAlertPanel([NSString stringWithFormat:@"The '%@' action already use the same shortcut.", [previous name]],
                                     @"Do you want to replace the action '%@' by you new action?",
                                     @"Replace", @"Cancel", nil, [previous name]);
        if (NSOKButton == result) {
          [[se_library entryManager] removeEntry:previous];
          /* Removing previous can invalidate trigger */
          if (![[se_library triggerSet] containsObjectWithUID:[trigger uid]]) {
            //            [trigger setUID:0];
            [[se_library triggerSet] addObject:trigger];
          }
        } else {
          return NO;
        }
      }
    } 
  } else { /* Trigger does not already exists */
    [[se_library triggerSet] addObject:[anEntry trigger]];
  }
  /* Now create action */
  [[se_library actionSet] addObject:[anEntry action]];
  [[se_library entryManager] addEntry:anEntry];
  [[se_library entryManager] enableEntry:anEntry];
  
  /* Application uid == 0 */
  if ([anEntry type] == kSparkEntryTypeDefault) {
    [se_globals addEntry:anEntry];
  }
  [self refresh];
  
  /* Notify listeners */
  [[NSNotificationCenter defaultCenter] postNotificationName:SEEntriesManagerDidCreateEntryNotification
                                                      object:anEntry
                                                    userInfo:nil];
  return YES;
}

- (BOOL)editor:(SEEntryEditor *)theEditor shouldUpdateEntry:(SparkEntry *)anEntry {
  SparkEntry *edited = [theEditor entry];
  /* If should use default action */
  if (!anEntry) {
    if (kSparkEntryTypeOverWrite == [edited type])
      [[se_library entryManager] removeEntry:edited];
  } else {
    NSParameterAssert([[anEntry trigger] isValid]);
    /* If trigger has changed */
    if (![[edited trigger] isEqualToTrigger:[anEntry trigger]]) {
      SparkTrigger *trigger = [self libraryTriggerForTrigger:[anEntry trigger]];
      /* If trigger already exists */
      if (trigger) {
        /* Update new entry trigger */
        [anEntry setTrigger:trigger];
        /* Get previous entry that use this trigger */
        SparkEntry *previous = [[se_library entryManager] entryForTrigger:[trigger uid]
                                                              application:[[anEntry application] uid]];
        /* Already used by previous */
        if (previous) {
          /* Is previous a weak action */
          if (kSparkEntryTypeWeakOverWrite == [previous type]) {
            DLog(@"Remove weak entry");
            /* Remove weak entry */
            [[se_library entryManager] removeEntry:previous];
          } else {
            /* Already used by a real entry */
            NSRunAlertPanel(@"This action could not be created because an other action already use the same shortcut.",
                            @"Change the shortcut for your new action.",
                            @"OK", nil, nil);
            DLog(@"Already contains an entry for this application and trigger");
            return NO;
          }
        }
      } else { /* Trigger does not already exists */
        DLog(@"Create new trigger");
        [[se_library triggerSet] addObject:[anEntry trigger]];
      }
      /* Trigger has changed and edited entry is a default entry */
      if ([edited type] == kSparkEntryTypeDefault && [[edited application] uid] == 0) {
        /* Update weak entry */
        NSArray *entries = [[se_library entryManager] entriesForAction:[[edited action] uid]];
        unsigned count = [entries count];
        /* At least two */
        if (count > 1) {
          while (count-- > 0) {
            SparkEntry *weak = [entries objectAtIndex:count];
            /* Do not update edited entry */
            if ([[weak application] uid] != 0) {
              SparkEntry *update = [weak copy];
              [update setTrigger:[anEntry trigger]];
              [[se_library entryManager] replaceEntry:weak withEntry:update];
              [update release];
            }
          }
        }
      }
    } else { /* Trigger does not change */
      [anEntry setTrigger:[edited trigger]];
    }
    /* Now update action */
    BOOL newAction = ([edited type] == kSparkEntryTypeWeakOverWrite) ||
      ([edited type] == kSparkEntryTypeDefault && [[anEntry application] uid] != 0);
    if (newAction) {
      [[anEntry action] setUID:0];
      [[se_library actionSet] addObject:[anEntry action]];
    } else {
      [[anEntry action] setUID:[[edited action] uid]];
      [[se_library actionSet] updateObject:[anEntry action]];
    }
    if ([edited type] == kSparkEntryTypeDefault && [[anEntry application] uid] != 0) {
      DLog(@"Add Entry");
      [[se_library entryManager] addEntry:anEntry];
    } else {
      DLog(@"Replace Entry");
      [[se_library entryManager] replaceEntry:edited withEntry:anEntry];
    }
    if ([edited isEnabled])
      [[se_library entryManager] enableEntry:anEntry];
    
    /* Update cache */
    if ([[anEntry application] uid] == 0) {
      [se_globals replaceEntry:edited withEntry:anEntry];
    }
  }
  [self refresh];
  [[NSNotificationCenter defaultCenter] postNotificationName:SEEntriesManagerDidUpdateEntryNotification
                                                      object:anEntry ? : [se_snapshot entryForTrigger:[edited trigger]]
                                                    userInfo:nil];
  return YES;
}

@end
