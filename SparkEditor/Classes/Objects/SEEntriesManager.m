/*
 *  SEEntriesManager.m
 *  Spark Editor
 *
 *  Created by Black Moon Team.
 *  Copyright (c) 2004 - 2006 Shadow Lab. All rights reserved.
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

#import <ShadowKit/SKSingleton.h>

NSString * const SEApplicationDidChangeNotification = @"SEApplicationDidChange";
NSString * const SEEntriesManagerDidReloadNotification = @"SEEntriesManagerDidReload";
NSString * const SEEntriesManagerDidCreateEntryNotification = @"SEEntriesManagerDidCreateEntry";
NSString * const SEEntriesManagerDidUpdateEntryNotification = @"SEEntriesManagerDidUpdateEntry";

@implementation SEEntriesManager

- (id)init {
  if (self = [super init]) {
    se_globals = [[SESparkEntrySet alloc] init];
    se_snapshot = [[SESparkEntrySet alloc] init];
    se_overwrites = [[SESparkEntrySet alloc] init];
    /* Init globals */
    [se_globals addEntriesFromArray:[SparkSharedManager() entriesForApplication:0]];
  }
  return self;
}

- (void)dealloc {
  [se_app release];
  [se_editor release];
  [se_globals release];
  [se_snapshot release];
  [se_overwrites release];
  [super dealloc];
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
    NSArray *entries = [SparkSharedManager() entriesForApplication:[se_app uid]];
    
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
  [se_globals addEntriesFromArray:[SparkSharedManager() entriesForApplication:0]];
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
      reload = [se_overwrites count] != 0 || [SparkSharedManager() containsEntryForApplication:[anApplication uid]];
    
    [se_app release];
    se_app = [anApplication retain];
    [[NSNotificationCenter defaultCenter] postNotificationName:SEApplicationDidChangeNotification
                                                        object:self];
    /* Avoid useless reload */
    if (reload)
      [self refresh];
  }
}

- (SEEntryEditor *)editor {
  if (!se_editor) {
    se_editor = [[SEEntryEditor alloc] init];
    /* Load */
    [se_editor window];
    [se_editor setDelegate:self];
  }
  /* Update application */
  [se_editor setApplication:[self application]];
  return se_editor;
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
      [SparkSharedManager() removeEntry:entry];
    }
  }
  if (refresh)
    [self refresh];
  return removed;
}

/* Create Entry with type */
- (void)createEntry:(SparkPlugIn *)aPlugin modalForWindow:(NSWindow *)aWindow {
  SEEntryEditor *editor = [self editor];
  [editor setEntry:nil];
  [editor setActionType:aPlugin];

  [NSApp beginSheet:[editor window]
     modalForWindow:aWindow
      modalDelegate:nil
     didEndSelector:NULL
        contextInfo:nil];
}

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
  NSEnumerator *triggers = [SparkSharedTriggerSet() objectEnumerator];
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
    SparkEntry *previous = [SparkSharedManager() entryForTrigger:[trigger uid]
                                                     application:[[anEntry application] uid]];
    /* Already used by previous */
    if (previous) {
      /* Is previous a weak action */
      if (kSparkEntryTypeWeakOverWrite == [previous type]) {
        DLog(@"Remove weak entry");
        /* Remove weak entry */
        [SparkSharedManager() removeEntry:previous];
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
    [SparkSharedTriggerSet() addObject:[anEntry trigger]];
  }
  /* Now create action */
  [SparkSharedActionSet() addObject:[anEntry action]];
  [SparkSharedManager() addEntry:anEntry];
  [SparkSharedManager() setStatus:YES forEntry:anEntry];
  
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
      [SparkSharedManager() removeEntry:edited];
  } else {
    /* If trigger has changed */
    if (![[edited trigger] isEqualToTrigger:[anEntry trigger]]) {
      SparkTrigger *trigger = [self libraryTriggerForTrigger:[anEntry trigger]];
      /* If trigger already exists */
      if (trigger) {
        /* Update new entry trigger */
        [anEntry setTrigger:trigger];
        /* Get previous entry that use this trigger */
        SparkEntry *previous = [SparkSharedManager() entryForTrigger:[trigger uid]
                                                         application:[[anEntry application] uid]];
        /* Already used by previous */
        if (previous) {
          /* Is previous a weak action */
          if (kSparkEntryTypeWeakOverWrite == [previous type]) {
            DLog(@"Remove weak entry");
            /* Remove weak entry */
            [SparkSharedManager() removeEntry:previous];
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
        [SparkSharedTriggerSet() addObject:[anEntry trigger]];
      }
      /* Trigger has changed and edited entry is a default entry */
      if ([edited type] == kSparkEntryTypeDefault && [[edited application] uid] == 0) {
        /* Update weak entry */
        NSArray *entries = [SparkSharedManager() entriesForAction:[[edited action] uid]];
        unsigned count = [entries count];
        /* At least two */
        if (count > 1) {
          while (count-- > 0) {
            SparkEntry *weak = [entries objectAtIndex:count];
            /* Do not update edited entry */
            if ([[weak application] uid] != 0) {
              SparkEntry *update = [weak copy];
              [update setTrigger:[anEntry trigger]];
              [SparkSharedManager() replaceEntry:weak withEntry:update];
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
      [SparkSharedActionSet() addObject:[anEntry action]];
    } else {
      [[anEntry action] setUID:[[edited action] uid]];
      [SparkSharedActionSet() updateObject:[anEntry action]];
    }
    if ([edited type] == kSparkEntryTypeDefault && [[anEntry application] uid] != 0) {
      DLog(@"Add Entry");
      [SparkSharedManager() addEntry:anEntry];
    } else {
      DLog(@"Replace Entry");
      [SparkSharedManager() replaceEntry:edited withEntry:anEntry];
    }
    if ([SparkSharedManager() statusForEntry:edited])
      [SparkSharedManager() setStatus:YES forEntry:anEntry];
    
    /* Update cache */
    if ([[anEntry application] uid] == 0) {
      [se_globals replaceEntry:edited withEntry:anEntry];
    }
  }
  [self refresh];
  [[NSNotificationCenter defaultCenter] postNotificationName:SEEntriesManagerDidUpdateEntryNotification
                                                      object:anEntry ? : [se_snapshot entryForTrigger:[[edited trigger] uid]]
                                                    userInfo:nil];
  return YES;
}

@end

SKSingleton(SEEntriesManager, sharedManager);
