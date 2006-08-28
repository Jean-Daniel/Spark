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

- (void)removeEntry:(SparkEntry *)anEntry {
  DLog(@"Remove %@", anEntry);
}
- (void)removeEntries:(NSArray *)entries {
  DLog(@"Remove %@", entries);
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
  /* If already exist a trigger */
  if (trigger) {
    [anEntry setTrigger:trigger];
    SparkEntry *previous = [SparkSharedManager() entryForTrigger:[trigger uid]
                                                     application:[[anEntry application] uid]];
    if (previous) {
      if (kSparkEntryTypeWeakOverWrite == [previous type]) {
        DLog(@"Overwrite a weak overwrite entry");
        // Should add action to library, and update the entry.
        [SparkSharedActionSet() addObject:[anEntry action]];
        /* 'anEntry' MUST have same trigger and application than 'previous', else update will failed. */
        [SparkSharedManager() updateEntry:anEntry];
        [self refresh];
      } else {
        NSRunAlertPanel(@"This action could not be created because an other action already use the same shortcut.",
                        @"Change the shortcut for your new action.",
                        @"OK", nil, nil);
        DLog(@"Already contains an entry for this application and trigger");
        return NO;
      }
    } else {
      DLog(@"Create new action using existing trigger");
      /* Trigger exist but is not used for this application */
      [SparkSharedActionSet() addObject:[anEntry action]];
      [SparkSharedManager() addEntry:anEntry];
      [self refresh];
    }
  } else {
    /* Trigger does not exist */
    DLog(@"Create new action with new trigger");
    [[anEntry action] setUID:[SparkSharedActionSet() nextUID]];
    [[anEntry trigger] setUID:[SparkSharedTriggerSet() nextUID]];
    
    [SparkSharedManager() addEntry:anEntry];
    
    /* We have to update manager first, because dynamic lists filters use it */
    if (0 == [[anEntry application] uid]) {
      [se_globals addEntry:anEntry];
      [se_snapshot addEntry:anEntry];
    } else if ([[self application] uid] == [[anEntry application] uid]) {
      [se_overwrites addEntry:anEntry];
      [se_snapshot addEntry:anEntry];
    }
    
    /* Then we add the object into the library */
    [SparkSharedActionSet() addObject:[anEntry action]];
    [SparkSharedTriggerSet() addObject:[anEntry trigger]];
  }
  /* Enable hotkey */
  [SparkSharedManager() setStatus:YES forEntry:anEntry];
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
      [self removeEntry:edited];
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
            DLog(@"Overwrite a weak overwrite entry");
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
      /* Trigger has changed and edited entry is a default entry */
      if ([edited type] == kSparkEntryTypeDefault) {
        /* Update weak entry */
        // TODO
        // [[edited trigger] uid] => [[anEntry trigger] uid]
      }
    } else { /* Trigger does not change */
      [anEntry setTrigger:[edited trigger]];
    }
    /* Now update action */
    [SparkSharedActionSet() addObject:[anEntry action]];
    if ([edited type] == kSparkEntryTypeDefault && [[edited application] uid] != 0) {
      [SparkSharedManager() addEntry:anEntry];
    } else {
      [SparkSharedManager() replaceEntry:edited withEntry:anEntry];
    }
    [SparkSharedManager() setStatus:YES forEntry:anEntry];
  }
  [self refresh];
  return YES;
}

@end

SKSingleton(SEEntriesManager, sharedManager);
