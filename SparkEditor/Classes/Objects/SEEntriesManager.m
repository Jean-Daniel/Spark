/*
 *  SEEntriesManager.m
 *  Spark Editor
 *
 *  Created by Black Moon Team.
 *  Copyright (c) 2004 - 2006 Shadow Lab. All rights reserved.
 */

#import "SEEntriesManager.h"
#import "SETriggerEntry.h"
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
    [se_app release];
    se_app = [anApplication retain];
    [[NSNotificationCenter defaultCenter] postNotificationName:SEApplicationDidChangeNotification
                                                        object:self];
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

- (BOOL)editor:(SEEntryEditor *)theEditor shouldCreateEntry:(SparkEntry *)entry {
  /* First validate entry type: check if trigger do not already exist for globals */
//  SETriggerEntry *global;
//  SparkTrigger *trig = [entry trigger];
//  NSEnumerator *globals = [se_globals entryEnumerator];
//  while (global = [globals nextObject]) {
//    if ([trig isEqualToTrigger:[global trigger]]) {
//      [entry setTrigger:[global trigger]];
//      break;
//    }
//  }
  
//  /* Get UID "manually" to update manager first */
//  [[entry action] setUID:[SparkSharedActionSet() nextUID]];
//  /* If trigger is not already in the library */
//  if (![SparkSharedTriggerSet() containsObject:[entry trigger]])
//    [[entry trigger] setUID:[SparkSharedTriggerSet() nextUID]];
//  
//  /* Create an entry with new uid */
//  SparkEntry spEntry;
//  spEntry.action = [[entry action] uid];
//  spEntry.trigger = [[entry trigger] uid];
//  spEntry.application = [[theEditor application] uid];
//  
//  /* We have to update manager first, because dynamic lists filters use it */
//  if (0 == spEntry.application) {
//    [se_globals addEntry:entry];
//  } else if ([[self application] uid] == spEntry.application) {
//    [se_overwrites addEntry:entry];
//  }
//  [se_snapshot addEntry:entry];
//  
//  /* Then we add the object into the library */
//  [SparkSharedTriggerSet() addObject:[entry trigger]];
//  [SparkSharedActionSet() addObject:[entry action]];
//  
//  /* And we create the library entry */
//  [SparkSharedLibrary() addEntry:&spEntry];
//  
//  /* Enable the new action if possible */
//  // TODO
//  
//  /* Notify listeners */
//  [[NSNotificationCenter defaultCenter] postNotificationName:SEEntriesManagerDidCreateEntryNotification
//                                                      object:entry
//                                                    userInfo:nil];
  return YES;
}

- (BOOL)editor:(SEEntryEditor *)theEditor shouldUpdateEntry:(SparkEntry *)entry {
//  SETriggerEntry *orig = [theEditor entry];
//  
//  /* First case: global context */
//  if ([[self application] uid] == 0) {
//    /* First set uid */
//    [[entry action] setUID:[[orig action] uid]];
//    /* Then update original entry */
//    [orig setAction:[entry action]];
//    /* Finally update library */
//    [SparkSharedActionSet() updateObject:[orig action]];
//  } else {
//    int tOrig = [orig type];
//    int tEntry = [entry type];
//    if (tOrig == tEntry) {
//      if (kSEEntryTypeOverwrite == tOrig) {
//        // Update
//      }
//    } else if (kSEEntryTypeGlobal == tOrig) {
//      // Create
//    } else if (kSEEntryTypeGlobal == tEntry) {
//      // Remove
//    } else {
//      // Update
//    }
//  }
//  
//  return YES;
//  /* If global context and trigger change, should ask user if we have to change all entries */
//  if ([[self application] uid] == 0 && ![[entry trigger] isEqualToTrigger:[orig trigger]]) {
//    DLog(@"Ask for change");
//    /* If change all */
//    if (YES) {
//      /* Set UID */
//      [[entry trigger] setUID:[[orig trigger] uid]];
//      /* Update old entry */
//      [orig setTrigger:[entry trigger]];
//      /* Update library */
//      [SparkSharedTriggerSet() updateObject:[entry trigger]];
//    } else {
//      /* Create an new trigger */
//      [[entry trigger] setUID:[SparkSharedTriggerSet() nextUID]];
//      /* Should remove old trigger if no longer used */
//      // TODO
//      
//      /* Update old entry */
//      [orig setTrigger:[entry trigger]];
//      /* Update library */
//      [SparkSharedTriggerSet() addObject:[entry trigger]];
//    }
//  }
//  return YES;
  return YES;
}

@end

SKSingleton(SEEntriesManager, sharedManager);
