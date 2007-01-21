/*
 *  SELibraryDocument.m
 *  Spark Editor
 *
 *  Created by Black Moon Team.
 *  Copyright (c) 2004 - 2007 Shadow Lab. All rights reserved.
 */

#import "SELibraryDocument.h"
#import "SELibraryWindow.h"
#import "SEEntryEditor.h"
#import "SEEntryCache.h"

#import <SparkKit/SparkEntry.h>
#import <SparkKit/SparkAction.h>
#import <SparkKit/SparkLibrary.h>
#import <SparkKit/SparkTrigger.h>
#import <SparkKit/SparkObjectSet.h>
#import <SparkKit/SparkEntryManager.h>


NSString * const SEPreviousApplicationKey = @"SEPreviousApplicationKey";
NSString * const SEApplicationDidChangeNotification = @"SEApplicationDidChange";

@implementation SELibraryDocument

- (id)init {
  if (self = [super init]) {
  }
  return self;
}

- (void)dealloc {
  [se_cache release];
  [se_editor release];
  [se_library release];
  [se_application release];
  [super dealloc];
}

- (void)makeWindowControllers {
  NSWindowController *ctrl = [[SELibraryWindow alloc] init];
  [self addWindowController:ctrl];
  [ctrl release];
  [self displayFirstRunIfNeeded];
}

- (SparkLibrary *)library {
  return se_library;
}
- (void)setLibrary:(SparkLibrary *)aLibrary {
  if (se_library)
    [NSException raise:NSInternalInconsistencyException format:@"Library cannot be changed"];
  
  se_library = [aLibrary retain];
  if (se_library) {
    [se_library setUndoManager:[self undoManager]];
    if ([se_library path])
      [self setFileName:@"Spark"];
    
    if (se_cache) [se_cache release];
    se_cache = [[SEEntryCache alloc] initWithDocument:self];
  }
}

- (SEEntryCache *)cache {
  return se_cache;
}

- (SparkApplication *)application {
  return se_application;
}
- (void)setApplication:(SparkApplication *)anApplication {
  if (se_application != anApplication) {
    NSNotification *notify = [NSNotification notificationWithName:SEApplicationDidChangeNotification
                                                           object:self 
                                                         userInfo:se_application ? [NSDictionary dictionaryWithObject:se_application 
                                                                                                               forKey:SEPreviousApplicationKey] : nil];
    [se_application release];
    se_application = [anApplication retain];
    /* Refresh cache */
    [se_cache refresh];
    /* Notify change */
    [[NSNotificationCenter defaultCenter] postNotification:notify];
  }
}

- (void)canCloseDocumentWithDelegate:(id)delegate shouldCloseSelector:(SEL)shouldCloseSelector contextInfo:(void *)contextInfo {
  if (se_library == SparkActiveLibrary()) {
    [se_library synchronize];
    [self updateChangeCount:NSChangeCleared];
  } 
  [super canCloseDocumentWithDelegate:delegate shouldCloseSelector:shouldCloseSelector contextInfo:contextInfo];
}

#pragma mark -
#pragma mark Editor
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

#pragma mark Create
- (void)makeEntryOfType:(SparkPlugIn *)type {
  SEEntryEditor *editor = [self editor];
  [editor setEntry:nil];
  [editor setActionType:type];
  
  [NSApp beginSheet:[editor window]
     modalForWindow:[self windowForSheet]
      modalDelegate:nil
     didEndSelector:NULL
        contextInfo:nil];
}

/* Find equivalent trigger in library */
- (SparkTrigger *)memberTrigger:(SparkTrigger *)aTrigger {
  SparkTrigger *trigger;
  NSEnumerator *triggers = [[[self library] triggerSet] objectEnumerator];
  while (trigger = [triggers nextObject]) {
    if ([trigger isEqualToTrigger:aTrigger]) {
      return trigger;
    }
  }
  return nil;
}

- (BOOL)editor:(SEEntryEditor *)theEditor shouldCreateEntry:(SparkEntry *)anEntry {
  NSParameterAssert(anEntry != nil);
  
  SparkEntry *previous = nil;
  SparkLibrary *library = [self library];
  SparkEntryManager *manager = [library entryManager];
  
  /* First validate entry type: check if trigger do not already exist for globals */
  SparkTrigger *trigger = [self memberTrigger:[anEntry trigger]];
  /* If trigger already exists */
  if (trigger) {
    /* Get previous entry that use this trigger */
    previous = [manager entryForTrigger:[trigger uid]
                            application:[[anEntry application] uid]];
    /* Already used by previous */
    if (previous) {
      /* Is previous isn't a weak action */
      if (kSparkEntryTypeWeakOverWrite != [previous type]) {
        /* Already used by a real entry */
        int result = NSRunAlertPanel([NSString stringWithFormat:@"The '%@' action already use the same shortcut.", [previous name]],
                                     @"Do you want to replace the action '%@' by your new action?",
                                     @"Replace", @"Cancel", nil, [previous name]);
        if (NSOKButton != result) {
          return NO;
        }
      }
    }
    /* Update new entry trigger */
    [anEntry setTrigger:trigger];
  } else { 
    /* Trigger does not already exists */
    [[library triggerSet] addObject:[anEntry trigger]];
  }
  /* Now add action */
  [[library actionSet] addObject:[anEntry action]];

  /* and entry */
  if (previous) {
    [manager replaceEntry:previous withEntry:anEntry];
  } else {
    [manager addEntry:anEntry];
  }
  [manager enableEntry:anEntry];

  return YES;
}

#pragma mark Edit
- (void)editEntry:(SparkEntry *)anEntry {
  SEEntryEditor *editor = [self editor];
  [editor setEntry:anEntry];
  
  [NSApp beginSheet:[editor window]
     modalForWindow:[self windowForSheet]
      modalDelegate:nil
     didEndSelector:NULL
        contextInfo:nil];
}

- (BOOL)editor:(SEEntryEditor *)theEditor shouldReplaceEntry:(SparkEntry *)entry withEntry:(SparkEntry *)newEntry {
  SparkLibrary *library = [self library];
  SparkEntryManager *manager = [library entryManager];
  
  /* newEntry is null when "Use global entry" is selected */
  if (!newEntry) {
    /* If the edited entry was a custom entry, remove it */
    if (kSparkEntryTypeOverWrite == [entry type])
      [manager removeEntry:entry];
    return YES;
  } else {
    NSParameterAssert([[newEntry trigger] isValid]);
    
    SparkEntry *previous = nil;
    /* If trigger has changed */
    if (![[entry trigger] isEqualToTrigger:[newEntry trigger]]) {
      SparkTrigger *trigger = [self memberTrigger:[newEntry trigger]];
      /* If trigger already exists */
      if (trigger) {
        /* Get previous entry that use this trigger */
        previous = [manager entryForTrigger:[trigger uid]
                                application:[[newEntry application] uid]];
        /* Already used by previous */
        if (previous) {
          /* Is previous isn't a weak action */
          if (kSparkEntryTypeWeakOverWrite != [previous type]) {
            /* Already used by a real entry */
            int result = NSRunAlertPanel([NSString stringWithFormat:@"The '%@' action already use the same shortcut.", [previous name]],
                                         @"Do you want to replace the action '%@' by your new action?",
                                         @"Replace", @"Cancel", nil, [previous name]);
            if (NSOKButton != result) {
              return NO;
            }
          }
        }
        /* Update new entry trigger */
        [newEntry setTrigger:trigger];
      } else { /* Trigger does not already exists */
        DLog(@"Add new trigger");
        [[library triggerSet] addObject:[newEntry trigger]];
      }
      
      /* Trigger has changed and edited entry is a default entry */
      if ([entry type] == kSparkEntryTypeDefault && [[newEntry application] uid] == 0) {
        /* Update weak entry */
        NSArray *entries = [manager entriesForAction:[[entry action] uid]];
        unsigned count = [entries count];
        /* At least two */
        if (count > 1) {
          while (count-- > 0) {
            SparkEntry *weak = [entries objectAtIndex:count];
            /* Do not update edited entry */
            if ([[weak application] uid] != 0) {
              SparkEntry *update = [weak copy];
              [update setTrigger:[newEntry trigger]];
              [manager replaceEntry:weak withEntry:update];
              [update release];
            }
          }
        }
      }
    } else { /* Trigger does not change */
      [newEntry setTrigger:[entry trigger]];
    }
    
    /* Now update action. 
      We have to create a new one if the old one is used by an other entry: weak and inherit */
    BOOL newAction = ([entry type] == kSparkEntryTypeWeakOverWrite) ||
      ([entry type] == kSparkEntryTypeDefault && [[newEntry application] uid] != 0);
    if (newAction) {
      /* Add new action */
      [[newEntry action] setUID:0];
      [[library actionSet] addObject:[newEntry action]];
    } else {
      /* Update existing action */
      [[newEntry action] setUID:[[entry action] uid]];
      [[library actionSet] updateObject:[newEntry action]];
    }
    
    /* If overwrite a global entry, create a new entry */
    if ([entry type] == kSparkEntryTypeDefault && [[newEntry application] uid] != 0) {
      DLog(@"Add Entry");
      [manager addEntry:newEntry];
    } else if (previous) {
      /* Note: removing 'previous' can also remove 'previous->trigger', 
      so we remove 'entry' instead */
      DLog(@"Update previous");
      [manager removeEntry:entry];
      [manager replaceEntry:previous withEntry:newEntry];
    } else {
      DLog(@"Update Entry");
      [manager replaceEntry:entry withEntry:newEntry];
    }
    /* Preserve status */
    if ([entry isEnabled])
      [manager enableEntry:newEntry];
  }
  return YES;
}

#pragma mark Remove
- (unsigned)removeEntries:(NSArray *)entries {
  BOOL hasCustom = NO;
  SparkApplication *application = [self application];
  if ([application uid] == 0) {
    int count = [entries count];
    while (count-- > 0 && !hasCustom) {
      SparkEntry *entry = [entries objectAtIndex:count];
      hasCustom |= [[[self library] entryManager] containsOverwriteEntryForTrigger:[[entry trigger] uid]];
    }
    if (hasCustom) {
      DLog(@"WARNING: Has Custom");
    }
  }
  
  unsigned removed = 0;
  int count = [entries count];
  while (count-- > 0) {
    SparkEntry *entry = [entries objectAtIndex:count];
    /* Remove only custom entry */
    if ([[self application] uid] == 0 || [entry type] != kSparkEntryTypeDefault) {
      removed++;
      [[se_library entryManager] removeEntry:entry];
    }
  }
  return removed;
}

@end
