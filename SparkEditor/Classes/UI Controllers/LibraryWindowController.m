//
//  LibraryWindowController.m
//  Spark Editor
//
//  Created by Grayfox on 19/09/04.
//  Copyright 2004 Shadow Lab. All rights reserved.
//

#import "LibraryWindowController.h"
#import "ScriptHandler.h"
#import "Preferences.h"

#import "FirstRunController.h"
#import "KeyLibraryController.h"

static BOOL SearchHotKey(NSString *search, id object, void *context);

@implementation LibraryWindowController

+ (void)initialize {
  id state = [NSArray arrayWithObject:@"serverState"];
  [self setKeys:state triggerChangeNotificationsForDependentKey:@"serverStatString"];
  [self setKeys:state triggerChangeNotificationsForDependentKey:@"startStopImage"];
  [self setKeys:state triggerChangeNotificationsForDependentKey:@"browserAlternateImage"];
  [self setKeys:state triggerChangeNotificationsForDependentKey:@"startStopAlternateImage"];
}

- (id)init {
  if (self = [super initWithWindowNibName:@"Library"]) {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateServerState:) name:kSPServerStatChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateServerState:) name:NSControlTintDidChangeNotification object:nil];
    keyLibrary = [[KeyLibraryController alloc] init];
    [keyLibrary setDelegate:self];
  }
  return self;
}

- (void)dealloc {
  [[NSNotificationCenter defaultCenter] removeObserver:self];
  [firstRun release];
  [keyLibrary release];
  [super dealloc];
}

- (void)awakeFromNib {
  id lib = [keyLibrary libraryView];
  [lib setFrameSize:[contentView frame].size];
  [contentView addSubview:lib];
  [[keyLibrary objects] setFilterFunction:SearchHotKey context:self];
  [searchField setTarget:keyLibrary];
  [searchField setAction:@selector(search:)];
  [self restoreWorkspace];
  [self checkFirstRun];
  [self checkActions];
}

- (void)refresh {
  [keyLibrary refresh];
}

- (IBAction)newList:(id)sender {
  [keyLibrary newList:sender];
}

- (IBAction)newActionMenuItemSelected:(id)sender {
  id kind = [sender representedObject];
  [keyLibrary newObjectOfKind:kind];
}

- (void)libraryControllerSelectedListDidChange:(NSNotification *)aNotification {
  [searchField setStringValue:@""];
  [searchField sendAction:[searchField action] to:[searchField target]];
}

#pragma mark -
#pragma mark Loading Methods

- (void)checkActions {
  id items = [SparkDefaultActionLibrary() objectEnumerator];
  id item;
  NSMutableArray *errors = [NSMutableArray array];
  while (item = [items nextObject]) {
    id alert = ([item check]);
    if (alert != nil) {
      [item setInvalid:YES];
      [alert setHideSparkButton:YES];
      [errors addObject:alert];
    }
  }
  if ([errors count] == 1) {
    SparkAlert *alert = [errors objectAtIndex:0];
    NSBeginAlertSheet([alert messageText],
                      NSLocalizedString(@"OK", @"Alert default button")
                      , nil, nil, [self window], nil, nil, nil, nil, [alert informativeText]);
  }
  else if ([errors count] > 1) {
    id alerts = [[SparkMultipleAlerts alloc] initWithAlerts:errors];
    [alerts beginSheetModalForWindow:[self window]
                       modalDelegate:nil
                      didEndSelector:nil
                         contextInfo:nil];
    [alerts autorelease];
  }
  [self refresh];
}

- (void)checkFirstRun {
  int version = [[NSUserDefaults standardUserDefaults] integerForKey:kSparkPrefVersion];
  [self showWindow:nil];
  switch (version) {
    case 0:
      [[NSUserDefaults standardUserDefaults] setInteger:kSparkCurrentVersion forKey:kSparkPrefVersion];
      if (!firstRun) {
        firstRun = [[FirstRunController alloc] initWithWindowNibName:@"FirstRun"];
      }
        [NSApp beginSheet: [firstRun window]
           modalForWindow: [self window]
            modalDelegate: nil
           didEndSelector: nil
              contextInfo: nil];
      [NSApp runModalForWindow:[firstRun window]];
      // La session modale est arreté dans la fenêtre.
      [NSApp endSheet:[firstRun window]];
      [firstRun close];
      break;
    case kSparkVersion_2_0:
      DLog(@"Check Version: %x", version);
      break;
  }
}

#pragma mark -
#pragma mark Workspace Save & Restore
- (void)saveWorkspace {
  [[self window] saveFrameUsingName:@"SparkLibraryWindow"];
  [keyLibrary saveWorkspaceWithKey:kSparkPrefMainWindowLibrary];
}

- (void)restoreWorkspace {
  [[self window] setFrameUsingName:@"SparkLibraryWindow"];
  [keyLibrary restoreWorkspaceWithKey:kSparkPrefMainWindowLibrary];
}

//- (BOOL)validateMenuItem:(NSMenuItem*)anItem {
//  if ([anItem action] == @selector(newAction:)) {
//    id selection = [library selectedObject];
//    return (nil != selection) ? [[self pluginsLists] containsObject:selection] : NO;
//  }
//  if ([anItem action] == @selector(removeKeyList:) || [anItem action] == @selector(exportList:)) {
//    id list = [library selectedObject];
//    return [list isEditable];
//  }
//  return YES;
//}

#pragma mark -
#pragma mark UI Utils

- (void)updateServerState:(NSNotification *)aNotification {
  [self willChangeValueForKey:@"serverState"];
  [self didChangeValueForKey:@"serverState"];
}

- (NSImage *)startStopImage {
  id name = nil;
  if ([[NSApp delegate] serverState] == kSparkDaemonStarted) {
    name = @"stop";
  } else {
    name = @"start";
  }
  return [NSImage imageNamed:name];
}

- (NSImage *)startStopAlternateImage {
  id name = nil;
  if ([[NSApp delegate] serverState] == kSparkDaemonStarted) {
    name =  ([NSColor currentControlTint] == NSGraphiteControlTint) ? @"stop_down" : @"stop_downb";
  }
  else {
    name =  ([NSColor currentControlTint] == NSGraphiteControlTint) ? @"start_down" : @"start_downb";
  }
  return [NSImage imageNamed:name];
}

- (NSString *)serverStatString {
  return ([[NSApp delegate] serverState] == kSparkDaemonStarted) ? NSLocalizedString(@"SPARK_STATE_ACTIVE", @"Spark Daemon State displayed in the bottom of the main window * Active *") : NSLocalizedString(@"SPARK_STATE_INACTIVE", @"Spark Daemon State displayed in the bottom of the main window * Inactive *");
}

- (NSImage *)browserAlternateImage {
  id name =  ([NSColor currentControlTint] == NSGraphiteControlTint) ? @"Browser_down" : @"Browser_downb";
  return [NSImage imageNamed:name];
}

@end

static BOOL SearchHotKey(NSString *search, id object, void *context) {
  BOOL ok;
  if (nil == search) return YES;
  ok = [[object name] rangeOfString:search options:NSCaseInsensitiveSearch].location != NSNotFound;
  if (!ok) 
    ok = [[object shortDescription] rangeOfString:search options:NSCaseInsensitiveSearch].location != NSNotFound;
  return ok;
}
