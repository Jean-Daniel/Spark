/*
 *  SEApplicationSource.m
 *  Spark Editor
 *
 *  Created by Black Moon Team.
 *  Copyright (c) 2004 - 2007 Shadow Lab. All rights reserved.
 */

#import "SEApplicationSource.h"

#import "SEHeaderCell.h"
#import "SELibraryWindow.h"
#import "SELibraryDocument.h"

#import <ShadowKit/SKAEFunctions.h>
#import <ShadowKit/SKFSFunctions.h>
#import <ShadowKit/SKLSFunctions.h>
#import <ShadowKit/SKAppKitExtensions.h>

#import <SparkKit/SparkLibrary.h>
#import <SparkKit/SparkObjectSet.h>
#import <SparkKit/SparkApplication.h>
#import <SparkKit/SparkEntryManager.h>

@implementation SEApplicationSource

- (SparkObjectSet *)applicationSet {
  return [se_library applicationSet];
}

- (void)reload {
  [self removeAllObjects];
  if (se_library) {
    [self addObject:[SparkLibrary systemApplication]];
    [self addObjects:[[self applicationSet] objects]];
    [self rearrangeObjects];
  }
}

- (void)se_init {
  [self setCompareFunction:SparkObjectCompare];
}

- (id)initWithCoder:(NSCoder *)aCoder {
  if (self = [super initWithCoder:aCoder]) {
    [self se_init];
  }
  return self;
}

- (id)init {
  if (self = [super init]) {
    [self se_init];
  }
  return self;
}

- (void)dealloc {
  [self setLibrary:nil];
  [se_path release];
  [super dealloc];
}

- (void)awakeFromNib {
  [uiTable registerForDraggedTypes:[NSArray arrayWithObjects:NSFilenamesPboardType, nil]];
  
  /* Configure Application Header Cell */
  SEHeaderCell *header = [[SEHeaderCell alloc] initTextCell:NSLocalizedString(@"Front Application", @"Front Applications - header cell")];
  [header setAlignment:NSCenterTextAlignment];
  [header setFont:[NSFont systemFontOfSize:11]];
  [[[uiTable tableColumns] objectAtIndex:0] setHeaderCell:header];
  [header release];
  [uiTable setCornerView:[[[SEHeaderCellCorner alloc] init] autorelease]];
  
  [uiTable setTarget:self];
  [uiTable setDoubleAction:@selector(revealApplication:)];
}

- (void)setLibrary:(SparkLibrary *)aLibrary {
  if (se_library != aLibrary) {
    if (se_library) {
      [[se_library notificationCenter] removeObserver:self];
      [se_library release];
    }
    se_library = [aLibrary retain];
    [self reload];
    if (se_library) {
      [[se_library notificationCenter] addObserver:self
                                          selector:@selector(didAddApplication:)
                                              name:SparkObjectSetDidAddObjectNotification
                                            object:[se_library applicationSet]];
      [[se_library notificationCenter] addObserver:self
                                          selector:@selector(didRemoveApplication:)
                                              name:SparkObjectSetDidRemoveObjectNotification
                                            object:[se_library applicationSet]];  
      
      [[se_library notificationCenter] addObserver:self
                                          selector:@selector(didReloadLibrary:)
                                              name:SELibraryDocumentDidReloadNotification
                                            object:[ibWindow document]];
    }
  }
}

#pragma mark -
- (void)didReloadLibrary:(NSNotification *)aNotification {
  SparkApplication *app = [self selectedObject];
  [self reload];
  if (![self setSelectedObject:app] || NSNotFound == [self selectionIndex]) {
    [self setSelectionIndex:0];
  }
}

- (NSUInteger)addApplications:(NSArray *)files {
  se_locked = YES;
  NSUInteger count = 0;
  NSUInteger idx = [files count];
  SparkObjectSet *library = [self applicationSet];
  
  /* search if contains at least one application */
  while (idx-- > 0) {
    NSString *file = [files objectAtIndex:idx];
    /* Resolve Aliases */
    if ([[NSFileManager defaultManager] isAliasFileAtPath:file]) {
      file = [[NSFileManager defaultManager] resolveAliasFileAtPath:file isFolder:NULL];
    }
    if (file && [[NSWorkspace sharedWorkspace] isApplicationAtPath:file]) {
      SparkApplication *app = [[SparkApplication alloc] initWithPath:file];
      if (app && ![[[self applicationSet] objects] containsObject:app]) {
        // Add application
        [library addObject:app];
        count++;
      }
      [app release];
    }
  }
  se_locked = NO;
  if (count > 0) {
    [self rearrangeObjects];
  }
  return count;
}

- (IBAction)revealApplication:(id)sender {
  NSArray *array = [self selectedObjects];
  if ([array count] > 0) {
    SparkApplication *application = [array objectAtIndex:0];
    NSString *path = [application path];
    FSRef ref;
    if (path && [path getFSRef:&ref]) {
      SKAEFinderRevealFSRef(&ref, TRUE);
    } else {
      NSBeep();
    }
  }
}

- (IBAction)newApplication:(id)sender {
  NSOpenPanel *openPanel = [NSOpenPanel openPanel];
  [openPanel setDelegate:self];
  [openPanel setAllowsMultipleSelection:YES];
  [openPanel setCanChooseFiles:YES];
  [openPanel setCanChooseDirectories:NO];
  [openPanel setCanCreateDirectories:NO];
  /* Init path cache */
  se_path = [[NSMutableSet alloc] init];
  SparkApplication *app;
  NSEnumerator *apps = [[self applicationSet] objectEnumerator];
  while (app = [apps nextObject]) {
    NSString *path = [app path];
    if (path)
      [se_path addObject:path];
  }
  [openPanel beginSheetForDirectory:nil
                               file:nil
                              types:[NSArray arrayWithObjects:@"app", nil, NSFileTypeForHFSTypeCode('APPL'), nil]
                     modalForWindow:[ibWindow window]
                      modalDelegate:self
                     didEndSelector:@selector(newApplicationDidEnd:returnCode:object:)
                        contextInfo:nil];
}

- (void)newApplicationDidEnd:(NSOpenPanel *)panel returnCode:(NSInteger)result object:(id)object {
  if (NSOKButton == result) {
    [self addApplications:[panel filenames]];
  }
  [se_path release];
  se_path = nil;
}

- (BOOL)panel:(id)sender shouldShowFilename:(NSString *)filename {
  if ([[NSFileManager defaultManager] isAliasFileAtPath:filename]) {
    filename = [[NSFileManager defaultManager] resolveAliasFileAtPath:filename isFolder:NULL];
  }
  return ![se_path containsObject:filename];
}

#pragma mark Misc
- (IBAction)deleteSelection:(id)sender {
  if ([[ibWindow window] attachedSheet] == nil) { /* Ignore if modal sheet open on main window */
    NSUInteger idx = [self selectionIndex];
    if (idx > 0) { /* If valid selection (should always append) */
      NSInteger result = NSOKButton;
      SparkObject *object = [self objectAtIndex:idx];
      if ([object uid] > kSparkLibraryReserved) { /* If not a reserved object */
        Boolean hasActions = [[se_library entryManager] containsEntryForApplication:[object uid]];
        /* If no custom key or if user want to ignore warning, do not display sheet */
        if (hasActions && ![[NSUserDefaults standardUserDefaults] boolForKey:@"SparkConfirmDeleteApplication"]) {
          NSAlert *alert = [NSAlert alertWithMessageText:@"Deleting app will delete all custom hotkeys"
                                           defaultButton:@"Delete"
                                         alternateButton:@"Cancel"
                                             otherButton:nil
                               informativeTextWithFormat:@"Cannot be cancel, etc."];
          [alert addUserDefaultCheckBoxWithTitle:@"do not show again" andKey:@"SparkConfirmDeleteApplication"];
          /* Do not use sheet because caller assume it is synchrone */
          result = [alert runModal];
        } 
        if (NSOKButton == result) {
          if (hasActions) {
            SparkEntryManager *manager = [se_library entryManager];
            [manager removeEntries:[manager entriesForApplication:[object uid]]];
          }
          [[self applicationSet] removeObject:object];
          return;
        }
      }
    }
  }
  NSBeep();
}

- (NSDragOperation)tableView:(NSTableView *)tableView validateDrop:(id <NSDraggingInfo>)info proposedRow:(NSInteger)row proposedDropOperation:(NSTableViewDropOperation)operation {
  NSPasteboard *pboard = [info draggingPasteboard];
  /* Drop above and contains files */
  if (NSTableViewDropAbove == operation && [[pboard types] containsObject:NSFilenamesPboardType]) {
    /* search if contains at least one application */
    NSArray *files = [pboard propertyListForType:NSFilenamesPboardType];
    NSUInteger idx = [files count];
    while (idx-- > 0) {
      NSString *file = [files objectAtIndex:idx];
      if ([[NSWorkspace sharedWorkspace] isApplicationAtPath:file]) {
        
        return NSDragOperationCopy;
      }
    }
  }
  return NSDragOperationNone;
}

- (BOOL)tableView:(NSTableView *)aTableView acceptDrop:(id <NSDraggingInfo>)info row:(NSInteger)row dropOperation:(NSTableViewDropOperation)operation {
  NSUInteger count = 0;
  NSPasteboard *pboard = [info draggingPasteboard];
  /* Drop above and contains files */
  if (NSTableViewDropAbove == operation && [[pboard types] containsObject:NSFilenamesPboardType]) {
    NSArray *files = [pboard propertyListForType:NSFilenamesPboardType];
    count = [self addApplications:files];
  }
  return count > 0;
}

#pragma mark Delegate
- (void)didSelectApplication:(NSInteger)anIndex {
  SparkApplication *application = nil;
  NSArray *objects = [self arrangedObjects];
  if (anIndex >= 0 && (NSUInteger)anIndex < [objects count]) {
    application = [objects objectAtIndex:anIndex];
    // Set current application
    [[ibWindow document] setApplication:application];
  } else {
    [[ibWindow document] setApplication:nil];
  }
}

/* Selected application change */
- (void)tableViewSelectionDidChange:(NSNotification *)aNotification {
  [self didSelectApplication:[[aNotification object] selectedRow]];
}

- (void)deleteSelectionInTableView:(NSTableView *)aTableView {
  SparkApplication *application = nil;
  NSInteger idx = [aTableView selectedRow];
  NSArray *objects = [self arrangedObjects];
  if (idx >= 0 && (NSUInteger)idx < [objects count]) {
    application = [objects objectAtIndex:idx];
  }
  [self deleteSelection:nil];
  
  if (application && idx == [aTableView selectedRow] && [objects objectAtIndex:idx] != application) {
    [self didSelectApplication:idx];
  }
}

/* Display bold if has some custom actions */
- (void)tableView:(NSTableView *)aTableView willDisplayCell:(id)aCell forTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex {
  SparkApplication *item = [self objectAtIndex:rowIndex];
  if ([item uid] && [[se_library entryManager] containsEntryForApplication:[item uid]]) {
    [aCell setFont:[NSFont boldSystemFontOfSize:[NSFont smallSystemFontSize]]];
  } else {
    [aCell setFont:[NSFont systemFontOfSize:[NSFont smallSystemFontSize]]];
  }
}

#pragma mark Notifications
- (void)didAddApplication:(NSNotification *)aNotification {
  /* Add and select application */
  [self addObject:SparkNotificationObject(aNotification)];
  if (!se_locked) {
    [self rearrangeObjects];
  }
}

- (void)didRemoveApplication:(NSNotification *)aNotification {
  [self removeObject:SparkNotificationObject(aNotification)];
}


@end
