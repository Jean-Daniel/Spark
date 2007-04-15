/*
 *  SELibraryDocument.m
 *  Spark Editor
 *
 *  Created by Black Moon Team.
 *  Copyright (c) 2004 - 2007 Shadow Lab. All rights reserved.
 */

#import "SELibraryDocument.h"

#import "SEServerConnection.h"
#import "SETriggerBrowser.h"
#import "SELibraryWindow.h"
#import "SEEntryEditor.h"
#import "SEEntryCache.h"

#import <SparkKit/SparkEntry.h>
#import <SparkKit/SparkAction.h>
#import <SparkKit/SparkLibrary.h>
#import <SparkKit/SparkTrigger.h>
#import <SparkKit/SparkObjectSet.h>
#import <SparkKit/SparkEntryManager.h>
#import <SparkKit/SparkLibraryArchive.h>

NSString * const SEPreviousApplicationKey = @"SEPreviousApplicationKey";
NSString * const SEApplicationDidChangeNotification = @"SEApplicationDidChange";
NSString * const SEDocumentDidSetLibraryNotification = @"SEDocumentDidSetLibrary";
NSString * const SELibraryDocumentDidReloadNotification = @"SELibraryDocumentDidReload";

SELibraryDocument *SEGetDocumentForLibrary(SparkLibrary *library) {
  id document;
  NSEnumerator *documents = [[[NSDocumentController sharedDocumentController] documents] objectEnumerator];
  while (document = [documents nextObject]) {
    if ([document respondsToSelector:@selector(library)] && [[document library] isEqual:library]) {
      return document;
    }
  }
  return nil;
}

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

- (id)se_windowController:(Class)class {
  NSArray *ctrls = [self windowControllers];
  NSUInteger count = [ctrls count];
  while (count-- > 0) {
    id ctrl = [ctrls objectAtIndex:count];
    if ([ctrl isKindOfClass:class])
      return ctrl;
  }
  return nil;
}

- (SELibraryWindow *)mainWindowController {
  return [self se_windowController:[SELibraryWindow class]];
}

- (SETriggerBrowser *)browser {
  return [self se_windowController:[SETriggerBrowser class]];
}

- (void)makeWindowControllers {
  NSWindowController *ctrl = [[SELibraryWindow alloc] init];
  [ctrl setShouldCloseDocument:YES];
  [self addWindowController:ctrl];
  [ctrl release];
  [self displayFirstRunIfNeeded];
}

- (SparkLibrary *)library {
  return se_library;
}
- (void)setLibrary:(SparkLibrary *)aLibrary {
  if (se_library != aLibrary) {
    if (se_library) {
      [se_library setUndoManager:nil];
    }
    [se_library release];
    se_library = [aLibrary retain];
    /* Cleanup undo stack */
    [self updateChangeCount:NSChangeCleared];
    if (se_library) {
      [se_library setUndoManager:[self undoManager]];
      /* Just to hide title menu and proxy icon */
      if ([se_library path])
        [self setFileName:@"Spark"];
      
      /* Invalidate cache */
      if (se_cache) [se_cache release];
      se_cache = [[SEEntryCache alloc] initWithDocument:self];
  
      [[NSNotificationCenter defaultCenter] postNotificationName:SEDocumentDidSetLibraryNotification
                                                          object:self];
    }
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
    [[se_library notificationCenter] postNotification:notify];
  }
}

- (IBAction)openTriggerBrowser:(id)sender {
  SETriggerBrowser *browser = [self browser];
  if (!browser) {
    browser = [[SETriggerBrowser alloc] init];
    [self addWindowController:browser];
    [browser release];
  }
  [browser showWindow:sender];
}

- (IBAction)saveAsArchive:(id)sender {
  NSSavePanel *panel = [NSSavePanel savePanel];
  NSCalendarDate *date = [NSCalendarDate date];
  NSString *filename = [NSString stringWithFormat:@"SparkLibrary - %.2d/%.2d/%.2d", 
    [date dayOfMonth], [date monthOfYear], [date yearOfCommonEra] % 100];
  [panel setTitle:@"Archive Library"];
  [panel setCanCreateDirectories:YES];
  [panel setRequiredFileType:kSparkLibraryArchiveExtension];
  [panel setAllowsOtherFileTypes:NO];
  [panel beginSheetForDirectory:nil
                           file:filename
                 modalForWindow:[self windowForSheet]
                  modalDelegate:self
                 didEndSelector:@selector(archivePanelDidEnd:returnCode:contextInfo:)
                    contextInfo:nil];
}

- (void)archivePanelDidEnd:(NSSavePanel *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo {
  if (NSOKButton == returnCode) {
    NSString *file = [sheet filename];
    if (file) {
      [[self library] archiveToFile:file];
      NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:
        SKUInt(kSparkLibraryArchiveHFSType), NSFileHFSTypeCode,
        SKUInt(kSparkEditorSignature), NSFileHFSCreatorCode, nil];
      [[NSFileManager defaultManager] changeFileAttributes:dict atPath:file];
    }
  }
}

- (IBAction)revertDocumentToBackup:(id)sender {
  NSOpenPanel *panel = [NSOpenPanel openPanel];
  [panel setCanChooseDirectories:NO];
  [panel setCanCreateDirectories:NO];
  [panel setAllowsMultipleSelection:NO];
  [panel setTitle:@"Revert to backup..."];
  [panel beginSheetForDirectory:nil
                           file:nil
                          types:[NSArray arrayWithObjects:kSparkLibraryArchiveExtension, 
                            NSFileTypeForHFSTypeCode(kSparkLibraryArchiveHFSType), nil]
                 modalForWindow:[self windowForSheet]
                  modalDelegate:self
                 didEndSelector:@selector(revertToBackupDidEnd:result:context:)
                    contextInfo:nil];
}
- (void)revertToBackupDidEnd:(NSOpenPanel *)panel result:(NSInteger)code context:(void *)nothing {
  if (NSOKButton == code && [[panel filenames] count] > 0) {
    NSString *filename = [[panel filenames] objectAtIndex:0];
    [self revertToBackup:filename];
  }
}

- (void)revertToBackup:(NSString *)file {
  SparkLibrary *library = [[SparkLibrary alloc] initFromArchiveAtPath:file];
  if (library) {
    NSInteger result = NSRunAlertPanel(NSLocalizedString(@"REVERT_BACKUP", @"Revert to Backup - Title"), 
                                       NSLocalizedString(@"REVERT_MESSAGE", @"Revert to Backup - Message"),
                                       NSLocalizedString(@"Replace", @"Replace - Button"),
                                       NSLocalizedString(@"Cancel", @"Cancel - Button"),
                                       nil, [file lastPathComponent]);
    if (result == NSOKButton) {
      SparkLibrary *previous = [se_library retain];
      if (SparkActiveLibrary() == previous) {
        SparkSetActiveLibrary(library);
      }
      SparkLibraryUnregisterLibrary(previous);
      SparkLibraryDeleteIconCache(previous);
      
      [library setPath:[previous path]];
      [self setLibrary:library];
      [library synchronize];
      
      [previous unload];
      [previous release];
      
      /* Restart daemon if needed */
      if ([[SEServerConnection defaultConnection] isRunning] && se_library == SparkActiveLibrary()) {
        [[SEServerConnection defaultConnection] restart];
      }
    }
    [library release];
  } else {
    DLog(@"Invalid archive: %@", file);
  }
}

#pragma mark -
- (void)canCloseDocumentWithDelegate:(id)delegate shouldCloseSelector:(SEL)shouldCloseSelector contextInfo:(void *)contextInfo {
  if (se_library == SparkActiveLibrary()) {
    [se_library synchronize];
    [self updateChangeCount:NSChangeCleared];
  } 
  [super canCloseDocumentWithDelegate:delegate shouldCloseSelector:shouldCloseSelector contextInfo:contextInfo];
}

- (BOOL)revertToContentsOfURL:(NSURL *)absoluteURL ofType:(NSString *)typeName error:(NSError **)outError {
  if (outError) *outError = nil;
  
  SparkLibrary *library = [[SparkLibrary alloc] initWithPath:[se_library path]];
  if ([library load:outError]) {
    SparkLibrary *previous = [se_library retain];
    if (SparkActiveLibrary() == previous) {
      SparkSetActiveLibrary(library);
    }
    SparkLibraryUnregisterLibrary(previous);
    
    [self setLibrary:library];
    
    [previous unload];
    [previous release];
    
    /* Restart daemon if needed */
    if ([[SEServerConnection defaultConnection] isRunning] && se_library == SparkActiveLibrary()) {
      [[SEServerConnection defaultConnection] restart];
    }
    return YES;
  }
  [library release];
  return NO;
}

- (BOOL)revertToSavedFromFile:(NSString *)fileName ofType:(NSString *)type {
  return [self revertToContentsOfURL:[NSURL fileURLWithPath:fileName] ofType:type error:NULL];
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

static 
NSAlert *_SELibraryTriggerAlreadyUsedAlert(SparkEntry *entry) {
  NSString *msg = NSLocalizedString(@"Do you want to replace the action '%@' by your new action?", 
                                    @"Trigger already used (%@ => entry name) - Message");
  NSString *title = [NSString stringWithFormat:NSLocalizedString(@"The '%@' action already use the same shortcut.",
                                                                 @"Trigger already used (%@ => entry name) - Title"), [entry name]];
  NSAlert *alert = [NSAlert alertWithMessageText:title
                                   defaultButton:NSLocalizedString(@"Replace", @"Replace - Button")
                                 alternateButton:NSLocalizedString(@"Cancel", @"Cancel - Button")
                                     otherButton:nil
                       informativeTextWithFormat:msg, [entry name]];
  return alert;
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
        NSAlert *alert = _SELibraryTriggerAlreadyUsedAlert(previous);
        NSInteger result = [alert runModal];
        if (NSAlertDefaultReturn != result) {
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
  [[self mainWindowController] revealEntry:anEntry];
  
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
    if (kSparkEntryTypeOverWrite == [entry type]) {
      [manager removeEntry:entry];
    }
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
            NSAlert *alert = _SELibraryTriggerAlreadyUsedAlert(previous);
            NSInteger result = [alert runModal];
            if (NSAlertDefaultReturn != result) {
              return NO;
            }
          }
        }
        /* Update new entry trigger */
        [newEntry setTrigger:trigger];
      } else { /* Trigger does not already exists */
        [[library triggerSet] addObject:[newEntry trigger]];
      }
      
      /* Trigger has changed and edited entry is a default entry */
      if ([entry type] == kSparkEntryTypeDefault && [[newEntry application] uid] == 0) {
        /* Update weak entry */
        NSArray *entries = [manager entriesForAction:[[entry action] uid]];
        NSUInteger count = [entries count];
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
      [manager addEntry:newEntry];
    } else if (previous) {
      /* Note: removing 'previous' can also remove 'previous->trigger', 
      so we remove 'entry' instead */
      [manager removeEntry:entry];
      [manager replaceEntry:previous withEntry:newEntry];
    } else {
      [manager replaceEntry:entry withEntry:newEntry];
    }
    /* Preserve status */
    if ([entry isEnabled])
      [manager enableEntry:newEntry];
    
    [[self mainWindowController] revealEntry:newEntry];
  }
  return YES;
}

#pragma mark Remove
- (NSUInteger)removeEntries:(NSArray *)entries {
  BOOL hasCustom = NO;
  SparkApplication *application = [self application];
  if ([application uid] == 0) {
    NSUInteger count = [entries count];
    while (count-- > 0 && !hasCustom) {
      SparkEntry *entry = [entries objectAtIndex:count];
      hasCustom |= [[[self library] entryManager] containsOverwriteEntryForTrigger:[[entry trigger] uid]];
    }
    if (hasCustom) {
      DLog(@"WARNING: Has Custom");
    }
  }
  
  NSUInteger removed = 0;
  NSUInteger count = [entries count];
  SparkEntryManager *manager = [se_library entryManager];
  while (count-- > 0) {
    SparkEntry *entry = [entries objectAtIndex:count];
    /* Remove only custom entry */
    if ([[self application] uid] == 0) {
      /* First, check & remove weak */
      NSArray *array = [manager entriesForAction:[[entry action] uid]];
      if ([array count] > 1) {
        for (NSUInteger idx = 0; idx < [array count]; idx++) {
          SparkEntry *item = [array objectAtIndex:idx];
          /* If not the original item */
          if (![item isEqual:entry]) {
            removed++;
            [manager removeEntry:item];
          }
        }
      }
      /* Remove the selected entry */
      removed++;
      [manager removeEntry:entry];
    } else if ([entry type] != kSparkEntryTypeDefault) {
      removed++;
      [manager removeEntry:entry];
    }
  }
  return removed;
}

@end
