/*
 *  SELibraryDocument.m
 *  Spark Editor
 *
 *  Created by Black Moon Team.
 *  Copyright (c) 2004 - 2007 Shadow Lab. All rights reserved.
 */

#import "SELibraryDocument.h"

#import "SparkLibraryArchive.h"
#import "SEServerConnection.h"
#import "SETriggerBrowser.h"
#import "SEHTMLGenerator.h"
#import "SEExportOptions.h"
#import "SELibraryWindow.h"
#import "SEEntryEditor.h"

#import <SparkKit/SparkEntry.h>
#import <SparkKit/SparkAction.h>
#import <SparkKit/SparkPrivate.h>
#import <SparkKit/SparkLibrary.h>
#import <SparkKit/SparkTrigger.h>
#import <SparkKit/SparkObjectSet.h>
#import <SparkKit/SparkApplication.h>
#import <SparkKit/SparkEntryManager.h>

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

@interface SELibraryDocument () <SEEntryEditorDelegate>

@end

@implementation SELibraryDocument {
@private
  SEEntryEditor *_editor;
}

- (instancetype)initWithType:(NSString *)typeName error:(__autoreleasing NSError **)outError {
  if (self = [super initWithType:typeName error:outError]) {
    //_library = [[SparkLibrary alloc] init];
  }
  return self;
}

- (instancetype)initWithContentsOfURL:(NSURL *)absoluteURL ofType:(NSString *)typeName error:(__autoreleasing NSError **)outError {
  if (self = [super initWithContentsOfURL:absoluteURL ofType:typeName error:outError]) {
    
  }
  return self;
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
	return nil;
  //return [self se_windowController:[SETriggerBrowser class]];
}

- (void)makeWindowControllers {
  NSWindowController *ctrl = [[SELibraryWindow alloc] init];
  [ctrl setShouldCloseDocument:YES];
  [self addWindowController:ctrl];
	if ([[ctrl window] respondsToSelector:@selector(setRepresentedURL:)])
		[[ctrl window] setRepresentedURL:nil];
  [self displayFirstRunIfNeeded];
}

- (void)setLibrary:(SparkLibrary *)aLibrary {
  if (_library != aLibrary) {
    if (_library) {
      [_library setUndoManager:nil];
    }
    _library = aLibrary;
    /* Cleanup undo stack */
    [self updateChangeCount:NSChangeCleared];
    if (_library) {
      [_library setUndoManager:[self undoManager]];
      /* Just to hide title menu and proxy icon */
      if (_library.URL)
        self.displayName = @"Spark";
			
      [[NSNotificationCenter defaultCenter] postNotificationName:SEDocumentDidSetLibraryNotification
                                                          object:self];
    }
  }
}

- (void)setApplication:(SparkApplication *)anApplication {
  if (_application != anApplication) {
    NSNotification *notify = [NSNotification notificationWithName:SEApplicationDidChangeNotification
                                                           object:self 
                                                         userInfo:_application ? [NSDictionary dictionaryWithObject:_application
                                                                                                             forKey:SEPreviousApplicationKey] : nil];
    _application = anApplication;
    /* Notify change */
    [_library.notificationCenter postNotification:notify];
  }
}

- (IBAction)openTriggerBrowser:(id)sender {
  SETriggerBrowser *browser = [self browser];
  if (!browser) {
    browser = [[SETriggerBrowser alloc] init];
    [self addWindowController:browser];
  }
  [browser showWindow:sender];
}

- (IBAction)saveAsArchive:(id)sender {
  NSSavePanel *panel = [NSSavePanel savePanel];
  NSCalendarDate *date = [NSCalendarDate date];
  NSString *filename = [NSString stringWithFormat:NSLocalizedString(@"SparkLibrary - %.4d-%.2d-%.2d", @"Backup filename"),
												[date yearOfCommonEra], [date monthOfYear], [date dayOfMonth]];
  panel.canCreateDirectories = YES;
  panel.allowedFileTypes = @[kSparkLibraryArchiveExtension];
  panel.allowsOtherFileTypes = NO;
  panel.nameFieldStringValue = filename;
  [panel beginSheetModalForWindow:self.windowForSheet completionHandler:^(NSInteger result) {
    if (NSOKButton == result) {
      NSURL *url = panel.URL;
      if (url) {
        [self.library archiveToURL:url];
        NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:
                              @(kSparkLibraryArchiveHFSType), NSFileHFSTypeCode,
                              @(kSparkEditorSignature), NSFileHFSCreatorCode, nil];
        [[NSFileManager defaultManager] setAttributes:dict ofItemAtPath:[url path] error:NULL];
      }
    }
  }];
}

- (IBAction)revertDocumentToBackup:(id)sender {
  NSOpenPanel *panel = [NSOpenPanel openPanel];
  panel.canChooseDirectories = NO;
  panel.canCreateDirectories = NO;
  panel.allowsMultipleSelection = NO;
  panel.allowedFileTypes = @[kSparkLibraryArchiveExtension, NSFileTypeForHFSTypeCode(kSparkLibraryArchiveHFSType)];
  [panel beginSheetModalForWindow:self.windowForSheet completionHandler:^(NSInteger result) {
    if (NSOKButton == result && [panel.URLs count] > 0) {
      NSURL *url = panel.URLs[0];
      [self revertToBackup:url];
    }
  }];
}

- (void)revertToBackup:(NSURL *)archive {
  // TODO: allow restore from standard library bundle (with warning)
  SparkLibrary *library = [[SparkLibrary alloc] initFromArchiveAtURL:archive];
  if (library) {
    NSInteger result = NSRunAlertPanel(NSLocalizedString(@"REVERT_BACKUP", @"Revert to Backup - Title"), 
                                       NSLocalizedString(@"REVERT_MESSAGE", @"Revert to Backup - Message"),
                                       NSLocalizedString(@"Replace", @"Replace - Button"),
                                       NSLocalizedString(@"Cancel", @"Cancel - Button"),
                                       nil, [archive lastPathComponent]);
    if (result == NSOKButton) {
      SparkLibrary *previous = _library;
      if (SparkActiveLibrary() == previous) {
        SparkSetActiveLibrary(library);
      }
      SparkLibraryUnregisterLibrary(previous);
      SparkLibraryDeleteIconCache(previous);

      library.URL = previous.URL;
      [self setLibrary:library];
      [library synchronize];
      
      [previous unload];
      
      /* Restart daemon if needed */
      if ([[SEServerConnection defaultConnection] isRunning] && _library == SparkActiveLibrary()) {
        [[SEServerConnection defaultConnection] restart];
      }
    }
  } else {
    SPXDebug(@"Invalid archive: %@", archive);
  }
}

#pragma mark -
- (void)canCloseDocumentWithDelegate:(id)delegate shouldCloseSelector:(SEL)shouldCloseSelector contextInfo:(void *)contextInfo {
  if (_library == SparkActiveLibrary()) {
    [_library synchronize];
    [self updateChangeCount:NSChangeCleared];
  } 
  [super canCloseDocumentWithDelegate:delegate shouldCloseSelector:shouldCloseSelector contextInfo:contextInfo];
}

- (BOOL)revertToContentsOfURL:(NSURL *)absoluteURL ofType:(NSString *)typeName error:(__autoreleasing NSError **)outError {
  if (outError) *outError = nil;
  
  SparkLibrary *library = [[SparkLibrary alloc] initWithURL:_library.URL];
  if ([library load:outError]) {
    SparkLibrary *previous = _library;
    if (SparkActiveLibrary() == previous) {
      SparkSetActiveLibrary(library);
    }
    SparkLibraryUnregisterLibrary(previous);
    
    [self setLibrary:library];
    
    [previous unload];
    
    /* Restart daemon if needed */
    if ([[SEServerConnection defaultConnection] isRunning] && _library == SparkActiveLibrary()) {
      [[SEServerConnection defaultConnection] restart];
    }
    return YES;
  }
  return NO;
}

#pragma mark Export
- (IBAction)exportPrintable:(id)sender {
  SEExportOptions *ctrl = [[SEExportOptions alloc] init]; // release in didEnd callback.
  NSSavePanel *panel = [NSSavePanel savePanel];
  panel.accessoryView = [ctrl view];
  panel.allowedFileTypes = @[ @"html"];
  panel.nameFieldStringValue = NSLocalizedString(@"SparkLibrary - HTML" , @"SparkLibrary Export as HTML Filename");
  [panel beginSheetModalForWindow:[self windowForSheet]
                completionHandler:^(NSInteger result) {
                  if (NSOKButton == result) {
                    NSError *error = nil;
                    SEHTMLGenerator *generator = [[SEHTMLGenerator alloc] initWithDocument:self];
                    [generator setGroupBy:[ctrl groupBy]];
                    [generator setStrikeDisabled:[ctrl strike]];
                    [generator setIncludesIcons:[ctrl includeIcons]];
                    /* generator setOptions */
                    if (![generator writeToURL:[panel URL] atomically:YES error:&error]) {
                      if (error)
                        [self presentError:error];
                    }
                  }
                  [panel setAccessoryView:nil]; // may fix a crash on Tiger ?
                }];
}

#pragma mark -
#pragma mark Editor
- (SEEntryEditor *)editor {
  if (!_editor) {
    _editor = [[SEEntryEditor alloc] init];
    /* Load */
    [_editor window];
    _editor.delegate = self;
  }
  /* Update application */
  [_editor setApplication:[self application]];
  return _editor;
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
  __block SparkTrigger *member = nil;
  [self.library.triggerSet enumerateObjectsUsingBlock:^(id obj, BOOL *stop) {
    if ([aTrigger isEqualToTrigger:obj]) {
      member = obj;
      *stop = YES;
    }
  }];
  return member;
}

static 
NSAlert *_SELibraryTriggerAlreadyUsedAlert(SparkEntry *previous, SparkEntry *entry) {
	NSString *title = [NSString stringWithFormat:NSLocalizedString(@"CREATE_TRIGGER_CONFLICT_TITLE",
                                                                 @"Trigger already used (%@ => entry name, %@ => previous name, %@ => shortcut) - Title"), 
										 [entry name], [previous name], [entry triggerDescription]];
	
  NSString *msg = NSLocalizedString(@"CREATE_TRIGGER_CONFLICT_MSG", 
                                    @"Trigger already used (%@ => entry name, %@ => previous name, %@ entry name) - Message");

  NSAlert *alert = [NSAlert alertWithMessageText:title
                                   defaultButton:NSLocalizedString(@"Enable", @"Enable - Button")
                                 alternateButton:NSLocalizedString(@"Keep disabled", @"Keep disabled - Button")
                                     otherButton:nil
                       informativeTextWithFormat:msg, [entry name], [previous name], [entry name]];
  return alert;
}

- (BOOL)editor:(SEEntryEditor *)theEditor shouldCreateEntryWithAction:(SparkAction *)anAction
			 trigger:(SparkTrigger *)aTrigger application:(SparkApplication *)anApplication {
  NSParameterAssert(anAction && aTrigger && anApplication);
  
  SparkLibrary *library = [self library];
  SparkEntryManager *manager = [library entryManager];
  
  /* First validate entry type: check if trigger do not already exist for globals */
	SparkTrigger *trigger = [self memberTrigger:aTrigger];
  /* If trigger already exists use it in the new entry */
  if (trigger) {
    aTrigger = trigger;
	} else {
    /* else add it in the library */
    [[library triggerSet] addObject:aTrigger];
	}
	
	/* Now add action in the library */
	NSAssert([anAction uid] == 0, @"Invalid uid for new action. should be 0.");
  [[library actionSet] addObject:anAction];

  /* and finaly, add the entry */
	SparkEntry *entry = [manager addEntryWithAction:anAction trigger:aTrigger application:anApplication];

	/* now check if we can enable this new action */
	SparkEntry *active = [manager activeEntryForTrigger:trigger application:anApplication];
	if (active) {
		NSAlert *alert = _SELibraryTriggerAlreadyUsedAlert(active, entry);
		if (NSOKButton == [alert runModal]) {
			[active setEnabled:NO];
			[entry setEnabled:YES];
		}
	} else {
		[entry setEnabled:YES];
	}
	
  [[self mainWindowController] revealEntry:entry];
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

- (BOOL)editor:(SEEntryEditor *)theEditor shouldUpdateEntry:(SparkEntry *)entry 
		 setAction:(SparkAction *)anAction
			 trigger:(SparkTrigger *)aTrigger
	 application:(SparkApplication *)anApplication {
  SparkLibrary *library = [self library];
  SparkEntryManager *manager = [library entryManager];
  
  /* action is null when "Use global entry" is selected */
  if (!anAction) {
    /* If the edited entry was a custom entry, remove it */
    if (kSparkEntryTypeOverWrite == [entry type]) {
			[manager removeEntry:entry];
    }
		return YES;
  } else {
		SparkEntry *updated = nil;
		BOOL enabled = [entry isEnabled];
		
		/* If trigger has changed */
		SparkTrigger *trigger = [self memberTrigger:aTrigger];
		/* If trigger already exists use it in the new entry */
		if (trigger) {
			aTrigger = trigger;
		} else {
			/* else add it in the library */
			[[library triggerSet] addObject:aTrigger];
		}
		
		NSAssert([anAction uid] == 0, @"Invalid uid for new action. should be 0.");
		[[library actionSet] addObject:anAction];
		
		/* Now update the old Entry */
		if ([entry.application isEqual:anApplication]) {
			[entry beginEditing];
			[entry replaceAction:anAction];
			[entry replaceTrigger:aTrigger];
			/* application are equals, so no need to replace it */
			[entry endEditing];
			updated = entry;
		} else {
			/* create a new entry */
			updated = [entry createVariantWithAction:anAction trigger:aTrigger application:anApplication];
		}
		
		/* and was enabled and is no longer enabled */
		if (enabled && ![updated isEnabled]) {
			/* now check if we can enable this new action */
			SparkEntry *active = [manager activeEntryForTrigger:[updated trigger] application:[updated application]];
			if (active) {
				NSAlert *alert = _SELibraryTriggerAlreadyUsedAlert(active, updated);
				if (NSOKButton == [alert runModal]) {
					[active setEnabled:NO];
					[updated setEnabled:YES];
				}
			} else {
				[updated setEnabled:YES];
			}
		}
		
		[[self mainWindowController] revealEntry:updated];
	}
  return YES;
}

#pragma mark Remove
- (NSUInteger)removeEntriesInArray:(NSArray *)entries {
	BOOL hasCustom = NO;
  SparkApplication *application = [self application];
	if (kSparkApplicationSystemUID == [application uid]) {
		NSUInteger count = [entries count];
		while (count-- > 0 && !hasCustom) {
			SparkEntry *entry = [entries objectAtIndex:count];
			hasCustom |= [entry hasVariant];
		}
		if (hasCustom) {
			SPXDebug(@"WARNING: Has Custom");
		}
	}

	NSUInteger removed = 0;
	NSUInteger count = [entries count];
	SparkEntryManager *manager = [_library entryManager];
	while (count-- > 0) {
		SparkEntry *entry = [entries objectAtIndex:count];
		/* Remove only custom entry */
		if (kSparkApplicationSystemUID == [[self application] uid]) {
			/* First, check & remove weak */
			if ([entry isSystem] && [entry hasVariant]) {
				/* Remove weak entries */
				NSArray *variants = [entry variants];
				for (NSUInteger idx = 0; idx < [variants count]; idx++) {
					SparkEntry *variant = [variants objectAtIndex:idx];
					if ([variant type] == kSparkEntryTypeWeakOverWrite)
						[manager removeEntry:variant];
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
