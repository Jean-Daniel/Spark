/*
 *  SEApplicationSource.m
 *  Spark Editor
 *
 *  Created by Black Moon Team.
 *  Copyright (c) 2004 - 2007 Shadow Lab. All rights reserved.
 */

#import "SEApplicationSource.h"

#import "SELibraryWindow.h"
#import "SELibraryDocument.h"

#import <SparkKit/SparkLibrary.h>
#import <SparkKit/SparkObjectSet.h>
#import <SparkKit/SparkApplication.h>
#import <SparkKit/SparkEntryManager.h>

#import <WonderBox/WonderBox.h>

@implementation SEApplicationSource {
@private
  BOOL se_locked;
  NSMutableSet *se_urls;
  SparkLibrary *se_library;
}

- (SparkObjectSet *)applicationSet {
  return [se_library applicationSet];
}

- (void)reload {
  [self removeAllObjects];
  if (se_library) {
    [self addObject:[se_library systemApplication]];
    [self addObjects:[[self applicationSet] allObjects]];
    [self rearrangeObjects];
  }
}

- (void)se_init {
  self.comparator = SparkObjectCompare;
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
}

- (void)awakeFromNib {
  [uiTable registerForDraggedTypes:@[NSFilenamesPboardType]];
  
  uiTable.target = self;
  uiTable.doubleAction = @selector(revealApplication:);
}

- (void)setLibrary:(SparkLibrary *)aLibrary {
  if (se_library != aLibrary) {
    if (se_library) {
      [se_library.notificationCenter removeObserver:self];
    }
    se_library = aLibrary;
    [self reload];
    if (se_library) {
      [se_library.notificationCenter addObserver:self
                                        selector:@selector(didAddApplication:)
                                            name:SparkObjectSetDidAddObjectNotification
                                          object:[self applicationSet]];
      [se_library.notificationCenter addObserver:self
                                        selector:@selector(willRemoveApplication:)
                                            name:SparkObjectSetWillRemoveObjectNotification
                                          object:[self applicationSet]];

      [se_library.notificationCenter addObserver:self
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

WB_INLINE
bool __IsApplicationAtURL(NSURL *path) {
  Boolean app = false;
  return path && (noErr == WBLSIsApplicationAtURL(SPXNSToCFURL(path), &app)) && app;
}

- (NSUInteger)addApplications:(NSArray *)urls {
  se_locked = YES;
  NSUInteger count = 0;
  SparkObjectSet *library = [self applicationSet];
  /* search if contains at least one application */
  for (__strong NSURL *url in urls) {
    /* Resolve Aliases */
    url = [NSURL URLByResolvingAliasFileAtURL:url options:NSURLBookmarkResolutionWithoutMounting error:NULL];
    if (url && __IsApplicationAtURL(url)) {
      SparkApplication *app = [[SparkApplication alloc] initWithURL:url];
      if (app && ![[self applicationSet] containsObject:app]) {
        // Add application
        [library addObject:app];
        count++;
      }
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
    NSURL *url = application.URL;
    if (url) {
      [NSWorkspace.sharedWorkspace activateFileViewerSelectingURLs:@[ url ]];
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
  se_urls = [[NSMutableSet alloc] init];
  [se_library.applicationSet enumerateObjectsUsingBlock:^(SparkApplication *app, BOOL *stop) {
    NSURL *url = app.URL;
    if (url)
      [self->se_urls addObject:url];
  }];
  openPanel.allowedFileTypes = @[@"app", NSFileTypeForHFSTypeCode('APPL')];
  [openPanel beginSheetModalForWindow:ibWindow.window completionHandler:^(NSInteger result) {
    if (NSModalResponseOK == result) {
      [self addApplications:[openPanel URLs]];
    }
    self->se_urls = nil;
  }];
}

- (BOOL)panel:(id)sender shouldEnableURL:(NSURL *)url {
  url = [NSURL URLByResolvingAliasFileAtURL:url options:NSURLBookmarkResolutionWithoutMounting error:NULL];
  return url && ![se_urls containsObject:url];
}

#pragma mark Misc
- (IBAction)deleteSelection:(id)sender {
  if ([[ibWindow window] attachedSheet] == nil) { /* Ignore if modal sheet open on main window */
    NSUInteger idx = [self selectionIndex];
    if (idx > 0) { /* If valid selection (should always append) */
      NSInteger result = NSAlertFirstButtonReturn;
      SparkApplication *object = [self objectAtArrangedObjectIndex:idx];
      if ([object uid] > kSparkLibraryReserved) { /* If not a reserved object */
        bool hasActions = [[se_library entryManager] containsEntryForApplication:object];
        /* If no custom key or if user want to ignore warning, do not display sheet */
        if (hasActions && ![[NSUserDefaults standardUserDefaults] boolForKey:@"SparkConfirmDeleteApplication"]) {
          NSAlert *alert = [[NSAlert alloc] init];
          alert.alertStyle = NSInformationalAlertStyle;
          alert.messageText = @"Deleting app will delete all custom hotkeys";
          alert.informativeText = @"This is just an information message.";

          [alert addButtonWithTitle:@"Delete"];
          [alert addButtonWithTitle:@"Cancel"];

          [alert bindSuppressionButtonToUserDefault:@"SparkConfirmDeleteApplication"];
          /* Do not use sheet because caller assume it is synchrone */
          result = [alert runModal];
        } 
        if (NSAlertFirstButtonReturn == result) {
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
  if (NSTableViewDropAbove == operation) {
    /* search if contains at least one application */
    NSArray *urls = [pboard readObjectsForClasses:@[NSURL.class] options:@{ NSPasteboardURLReadingFileURLsOnlyKey: @YES }];
    for (NSURL *url in urls) {
      if (__IsApplicationAtURL(url))
        return NSDragOperationCopy;
    }
  }
  return NSDragOperationNone;
}

- (BOOL)tableView:(NSTableView *)aTableView acceptDrop:(id <NSDraggingInfo>)info row:(NSInteger)row dropOperation:(NSTableViewDropOperation)operation {
  NSUInteger count = 0;
  NSPasteboard *pboard = [info draggingPasteboard];
  /* Drop above and contains files */
  if (NSTableViewDropAbove == operation) {
    NSArray *urls = [pboard readObjectsForClasses:@[NSURL.class] options:@{ NSPasteboardURLReadingFileURLsOnlyKey: @YES }];
    count = [self addApplications:urls];
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
  [self didSelectApplication:[aNotification.object selectedRow]];
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
  SparkApplication *item = [self objectAtArrangedObjectIndex:rowIndex];
  if ([item uid] && [[se_library entryManager] containsEntryForApplication:item]) {
    [aCell setFont:[NSFont boldSystemFontOfSize:[NSFont smallSystemFontSize]]];
  } else {
    [aCell setFont:[NSFont systemFontOfSize:[NSFont smallSystemFontSize]]];
  }
  /* Set Line status */
  if ([aCell respondsToSelector:@selector(setDrawsLineOver:)])
    [aCell setDrawsLineOver:![item isEnabled]];
}

#pragma mark Notifications
- (void)didAddApplication:(NSNotification *)aNotification {
  /* Add and select application */
  [self addObject:SparkNotificationObject(aNotification)];
  if (!se_locked) {
    [self rearrangeObjects];
  }
}

- (void)willRemoveApplication:(NSNotification *)aNotification {
  [self removeObject:SparkNotificationObject(aNotification)];
}

@end

@implementation SparkApplication (SparkEditorExtension)

+ (void)load {
  if ([SparkApplication class] == self) {
		WBRuntimeExchangeInstanceMethods(self, @selector(setEnabled:), @selector(se_setEnabled:));
  }
}

- (void)se_setEnabled:(BOOL)enabled {
  [self willChangeValueForKey:@"representation"];
  [self se_setEnabled:enabled];
  [self didChangeValueForKey:@"representation"];
}

- (id)representation {
  return self;
}

@end
