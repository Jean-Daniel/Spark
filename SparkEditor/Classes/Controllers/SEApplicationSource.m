/*
 *  SEApplicationSource.m
 *  Spark Editor
 *
 *  Created by Black Moon Team.
 *  Copyright (c) 2004 - 2006 Shadow Lab. All rights reserved.
 */

#import "SEApplicationSource.h"

#import <ShadowKit/SKFSFunctions.h>
#import <ShadowKit/SKAppKitExtensions.h>

#import <SparkKit/SparkLibrary.h>
#import <SparkKit/SparkObjectSet.h>
#import <SparkKit/SparkApplication.h>

@implementation SEApplicationSource

- (void)se_init {
  [self setCompareFunction:SparkObjectCompare];
  /* Load applications */
  SparkObjectSet *library = SparkSharedApplicationSet();
  [self addObject:[SparkApplication objectWithName:@"Globals" icon:[NSImage imageNamed:@"System"]]];
  [self addObjects:[library objects]];
  [self rearrangeObjects];
  [self setSelectionIndex:0];
  se_cache = [[NSMutableSet alloc] initWithArray:[library objects]];
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
  [se_cache release];
  [super dealloc];
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

- (unsigned)addApplications:(NSArray *)files {
  unsigned count = 0;
  unsigned idx = [files count];
  SparkObjectSet *library = SparkSharedApplicationSet();
  
  /* search if contains at least one application */
  while (idx-- > 0) {
    NSString *file = [files objectAtIndex:idx];
    /* Resolve Aliases */
    if ([[NSFileManager defaultManager] isAliasFileAtPath:file]) {
      file = [[NSFileManager defaultManager] resolveAliasFileAtPath:file isFolder:NULL];
    }
    if (file && [[NSWorkspace sharedWorkspace] isApplicationAtPath:file]) {
      SparkApplication *app = [[SparkApplication alloc] initWithPath:file];
      if (![se_cache containsObject:app]) {
        // Add application
        [se_cache addObject:app];
        [library addObject:app];
        [self addObject:app];
        count++;
      }
      [app release];
    }
  }
  if (count > 0)
    [self rearrangeObjects];
  return count;
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
  NSEnumerator *apps = [SparkSharedApplicationSet() objectEnumerator];
  while (app = [apps nextObject]) {
    NSString *path = [app path];
    if (path)
      [se_path addObject:path];
  }
  [openPanel beginSheetForDirectory:nil
                               file:nil
                              types:[NSArray arrayWithObjects:@"app", nil, NSFileTypeForHFSTypeCode('APPL'), nil]
                     modalForWindow:libraryWindow
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
  NSArray *selection = [self selectedObjects];
  unsigned idx = [selection count];
  while (idx-- > 0) {
    SparkObjectSet *library = SparkSharedApplicationSet();
    SparkObject *object = [selection objectAtIndex:idx];
    if ([object uid] > kSparkLibraryReserved) {
      [se_cache removeObject:object];
      [library removeObject:object];
      [self removeObject:object];
    } else {
      NSBeep();
    }
  }
}

- (BOOL)panel:(id)sender shouldShowFilename:(NSString *)filename {
  if ([[NSFileManager defaultManager] isAliasFileAtPath:filename]) {
    filename = [[NSFileManager defaultManager] resolveAliasFileAtPath:filename isFolder:NULL];
  }
  return ![se_path containsObject:filename];
}

@end
