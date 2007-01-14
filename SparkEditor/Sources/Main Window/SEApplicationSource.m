/*
 *  SEApplicationSource.m
 *  Spark Editor
 *
 *  Created by Black Moon Team.
 *  Copyright (c) 2004 - 2006, Shadow Lab. All rights reserved.
 */

#import "SEApplicationSource.h"

#import "SELibraryWindow.h"

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
  
  [self addObject:[SparkApplication objectWithName:@"Globals" icon:[NSImage imageNamed:@"System"]]];
  [self addObjects:[[self applicationSet] objects]];
  [self rearrangeObjects];
}

- (void)se_init {
  [self setCompareFunction:SparkObjectCompare];
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(didReloadLibrary:)
                                               name:@"SEDidReloadLibrary"
                                             object:nil];
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
  [se_path release];
  [[se_library notificationCenter] removeObserver:self];
  [se_library release];
  [[NSNotificationCenter defaultCenter] removeObserver:self];
  [super dealloc];
}

- (void)awakeFromNib {
  se_library = [[ibWindow library] retain];
  /* Load applications */
  [self reload];
  [self setSelectionIndex:0];
  [[se_library notificationCenter] addObserver:self
                                      selector:@selector(didAddApplication:)
                                          name:kSparkLibraryDidAddObjectNotification
                                        object:[se_library applicationSet]];
  [[se_library notificationCenter] addObserver:self
                                      selector:@selector(didRemoveApplication:)
                                          name:kSparkLibraryDidRemoveObjectNotification
                                        object:[se_library applicationSet]];  
}

#pragma mark -
- (void)didReloadLibrary:(NSNotification *)aNotification {
  SparkApplication *app = [self selectedObject];
  [self reload];
  if (![self setSelectedObject:app] || NSNotFound == [self selectionIndex]) {
    [self setSelectionIndex:0];
  }
}

- (unsigned)addApplications:(NSArray *)files {
  unsigned count = 0;
  unsigned idx = [files count];
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
      if (![[[self applicationSet] objects] containsObject:app]) {
        // Add application
        [library addObject:app];
//        [self addObject:app];
        count++;
      }
      [app release];
    }
  }
//  if (count > 0)
//    [self rearrangeObjects];
  return count;
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

- (void)newApplicationDidEnd:(NSOpenPanel *)panel returnCode:(int)result object:(id)object {
  if (NSOKButton == result) {
    [self addApplications:[panel filenames]];
  }
  [se_path release];
  se_path = nil;
}

- (IBAction)deleteSelection:(id)sender {
  if ([[ibWindow window] attachedSheet] == nil) { /* Ignore if modal sheet open on main window */
    unsigned idx = [self selectionIndex];
    if (idx > 0) { /* If valid selection (should always append) */
      int result = NSOKButton;
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
          //[self removeObject:object];
          return;
        }
      }
    }
  }
  NSBeep();
}

- (NSDragOperation)tableView:(NSTableView *)tableView validateDrop:(id <NSDraggingInfo>)info proposedRow:(int)row proposedDropOperation:(NSTableViewDropOperation)operation {
  NSPasteboard *pboard = [info draggingPasteboard];
  /* Drop above and contains files */
  if (NSTableViewDropAbove == operation && [[pboard types] containsObject:NSFilenamesPboardType]) {
    /* search if contains at least one application */
    NSArray *files = [pboard propertyListForType:NSFilenamesPboardType];
    unsigned idx = [files count];
    while (idx-- > 0) {
      NSString *file = [files objectAtIndex:idx];
      if ([[NSWorkspace sharedWorkspace] isApplicationAtPath:file]) {
        
        return NSDragOperationCopy;
      }
    }
  }
  return NSDragOperationNone;
}

- (BOOL)tableView:(NSTableView *)aTableView acceptDrop:(id <NSDraggingInfo>)info row:(int)row dropOperation:(NSTableViewDropOperation)operation {
  unsigned count = 0;
  NSPasteboard *pboard = [info draggingPasteboard];
  /* Drop above and contains files */
  if (NSTableViewDropAbove == operation && [[pboard types] containsObject:NSFilenamesPboardType]) {
    NSArray *files = [pboard propertyListForType:NSFilenamesPboardType];
    count = [self addApplications:files];
  }
  return count > 0;
}

- (BOOL)panel:(id)sender shouldShowFilename:(NSString *)filename {
  if ([[NSFileManager defaultManager] isAliasFileAtPath:filename]) {
    filename = [[NSFileManager defaultManager] resolveAliasFileAtPath:filename isFolder:NULL];
  }
  return ![se_path containsObject:filename];
}


- (void)didAddApplication:(NSNotification *)aNotification {
  [self addObject:SparkNotificationObject(aNotification)];
  [self rearrangeObjects];
}

- (void)didRemoveApplication:(NSNotification *)aNotification {
  [self removeObject:SparkNotificationObject(aNotification)];
}


@end
