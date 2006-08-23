//
//  SEEntriesManager.m
//  Spark Editor
//
//  Created by Jean-Daniel Dupas on 22/08/06.
//  Copyright 2006 Adamentium. All rights reserved.
//

#import "SEEntriesManager.h"
#import "SETriggerEntry.h"
#import "SEEntryEditor.h"

#import <SparkKit/SparkAction.h>
#import <SparkKit/SparkLibrary.h>
#import <SparkKit/SparkObjectSet.h>
#import <SparkKit/SparkApplication.h>

#import <ShadowKit/SKSingleton.h>

NSString * const SEApplicationDidChangeNotification = @"SEApplicationDidChange";
NSString * const SEEntriesManagerDidReloadNotification = @"SEEntriesManagerDidReload";
NSString * const SEEntriesManagerDidCreateEntryNotification = @"SEEntriesManagerDidCreateEntry";

@implementation SEEntriesManager

- (id)init {
  if (self = [super init]) {
    se_globals = [[SETriggerEntrySet alloc] init];
    se_snapshot = [[SETriggerEntrySet alloc] init];
    se_overwrites = [[SETriggerEntrySet alloc] init];
    /* Init globals */
    [se_globals addEntriesFromDictionary:[SparkSharedLibrary() triggersForApplication:0]];
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

- (SETriggerEntrySet *)globals {
  return se_globals;
}
- (SETriggerEntrySet *)snapshot {
  return se_snapshot;
}
- (SETriggerEntrySet *)overwrites {
  return se_overwrites;
}

- (void)refresh {
  [se_snapshot removeAllEntries];
  [se_overwrites removeAllEntries];
  
  /* Add defaults */
  [se_snapshot addEntriesFromEntrySet:se_globals];

  /* Add overwrite if needed */
  if ([se_app uid] != 0) {
    NSDictionary *entries = [SparkSharedLibrary() triggersForApplication:[se_app uid]];
    if ([entries count]) {
      SparkTrigger *key = nil;
      NSEnumerator *keys = [entries keyEnumerator];
      while (key = [keys nextObject]) {
        SETriggerEntry *entry = [[SETriggerEntry alloc] initWithTrigger:key action:[entries objectForKey:key]];
        
        /* If not ignore, overwrite defaults action */
        if (0 == [[entry action] uid]) {
          [entry setType:kSEEntryTypeIgnore];
        } else {
          [entry setType:kSEEntryTypeOverwrite];
        }
        
        [se_overwrites addEntry:entry];
        [entry release];
      }
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

- (void)editEntry:(SETriggerEntry *)anEntry modalForWindow:(NSWindow *)aWindow {
  SEEntryEditor *editor = [self editor];
  [editor setEntry:anEntry];
  
  [NSApp beginSheet:[editor window]
     modalForWindow:aWindow
      modalDelegate:nil
     didEndSelector:NULL
        contextInfo:nil];
}

- (BOOL)editor:(SEEntryEditor *)theEditor shouldCreateEntry:(SETriggerEntry *)entry {
  /* We have to update manager first, because dynamic lists filters use it */
  [[entry action] setUID:[SparkSharedActionSet() nextUID]];
  [[entry trigger] setUID:[SparkSharedTriggerSet() nextUID]];
  
  /* Create an entry with new uid */
  SparkEntry spEntry;
  spEntry.action = [[entry action] uid];
  spEntry.trigger = [[entry trigger] uid];
  spEntry.application = [[theEditor application] uid];
  
  if (0 == spEntry.application) {
    [se_globals addEntry:entry];
  } else if ([[self application] uid] == spEntry.application) {
    [se_overwrites addEntry:entry];
  }
  [se_snapshot addEntry:entry];
  
  /* Then we add the object into the library */
  [SparkSharedTriggerSet() addObject:[entry trigger]];
  [SparkSharedActionSet() addObject:[entry action]];
  
  /* And we create the library entry */
  [SparkSharedLibrary() addEntry:&spEntry];
  
  /* Enable the new trigger if possible */
  // TODO
  
  /* Notify listeners */
  [[NSNotificationCenter defaultCenter] postNotificationName:SEEntriesManagerDidCreateEntryNotification
                                                      object:entry
                                                    userInfo:nil];
  return YES;
}

@end

SKSingleton(SEEntriesManager, sharedManager);