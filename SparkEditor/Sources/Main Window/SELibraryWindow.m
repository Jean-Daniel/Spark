/*
 *  SELibraryWindow.m
 *  Spark Editor
 *
 *  Created by Black Moon Team.
 *  Copyright (c) 2004 - 2007 Shadow Lab. All rights reserved.
 */

#import "SELibraryWindow.h"

#import "Spark.h"
#import "SEEntryList.h"
#import "SETableView.h"
#import "SELibrarySource.h"
#import "SEBackgroundView.h"
#import "SELibraryDocument.h"

#import "SEApplicationView.h"
#import "SETriggersController.h"

#import "SEServerConnection.h"

#import <SparkKit/SparkEntry.h>
#import <SparkKit/SparkPlugIn.h>
#import <SparkKit/SparkLibrary.h>
#import <SparkKit/SparkFunctions.h>
#import <SparkKit/SparkActionLoader.h>

#import WBHEADER(NSImage+WonderBox.h)
#import WBHEADER(NSArrayController+WonderBox.h)

@implementation SELibraryWindow

- (id)init {
  if (self = [super initWithWindowNibName:@"SELibraryWindow"]) {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(daemonStatusDidChange:)
                                                 name:SEServerStatusDidChangeNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didChangePlugIns:)
                                                 name:SESparkEditorDidChangePlugInStatusNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didChangePlugIns:)
                                                 name:SparkActionLoaderDidRegisterPlugInNotification
                                               object:nil];
  }
  return self;
}

- (void)dealloc {
  [[NSNotificationCenter defaultCenter] removeObserver:self];
  [self setLibrary:nil];
  [super dealloc];
}

- (SparkLibrary *)library {
  return se_library;
}
- (NSUndoManager *)undoManager {
  return [[self document] undoManager];
}
- (SparkApplication *)application {
  return [[self document] application];
}

- (void)windowDidLoad {
  [[self window] center];
  [[self window] setFrameAutosaveName:@"SparkMainWindow"];
  [SEBackgroundView configureWindow:[self window]];
  [[self window] display];
}

- (void)setLibrary:(SparkLibrary *)aLibrary {
  if (se_library != aLibrary) {
    if (se_library) {
      [[se_library notificationCenter] removeObserver:self
                                                 name:SEApplicationDidChangeNotification
                                               object:[self document]];
      [se_library release];
    }
    se_library = [aLibrary retain];
    if (se_library) {
      [[se_library notificationCenter] addObserver:self
                                          selector:@selector(applicationDidChange:)
                                              name:SEApplicationDidChangeNotification
                                            object:[self document]];
    }
  }
}

- (void)setDocument:(SELibraryDocument *)aDocument {
  NSParameterAssert(!aDocument || [aDocument isKindOfClass:[SELibraryDocument class]]);
  if ([self document]) {
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:SEDocumentDidSetLibraryNotification
                                                  object:[self document]];
  }
  [super setDocument:aDocument];
  [self setLibrary:[aDocument library]];
  if ([self document]) {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(libraryDidChange:)
                                                 name:SEDocumentDidSetLibraryNotification
                                               object:[self document]];
  }
}

- (void)didChangePlugIns:(NSNotification *)aNotification {
  /* Configure New PlugIn Menu */
  NSMenu *menu = [[NSMenu alloc] initWithTitle:@"plugins"];
  SEPopulatePlugInMenu(menu);
  if ([menu numberOfItems] > 0)
    [menu addItem:[NSMenuItem separatorItem]];
  
  NSMenuItem *item = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"New Group", @"'New Group' menu item")
                                                action:@selector(newGroup:) keyEquivalent:@"N"];
  [item setImage:[NSImage imageNamed:@"SimpleList" inBundle:WBBundleForClass(SparkLibrary)]];
  [item setKeyEquivalentModifierMask:NSShiftKeyMask | NSCommandKeyMask];
  [menu addItem:item];
  [item release];
  
  [uiMenu setMenu:menu forSegment:0];
  [menu release];
}

- (void)awakeFromNib {
  /* Configure application field */
  [appField setTarget:appDrawer];
  [appField setAction:@selector(toggle:)];
  
  /* Configure list double action */
  [libraryTable setTarget:self];
  [libraryTable setDoubleAction:@selector(libraryDoubleAction:)];
  
  /* Update status */
  [self setDaemonStatus:[[SEServerConnection defaultConnection] status]];
  
  /* Populate plugin menu */
  [self didChangePlugIns:nil];
  
  /* Load applications */
  [ibApplications setLibrary:[self library]];
  [ibApplications setSelectionIndex:0];
  
  /* Load library groups */
  [ibGroups setLibrary:[self library]];
  [ibGroups setSelectionIndex:0];
}

- (SETriggersController *)triggers {
	return ibTriggers;
}

- (IBAction)libraryDoubleAction:(id)sender {
  NSInteger idx = [libraryTable selectedRow];
  if (idx > 0) {
    SEEntryList *object = [ibGroups objectAtIndex:idx];
    if ([object isEditable]) {
      [libraryTable editColumn:0 row:idx withEvent:nil select:YES];
    } else {
      SparkPlugIn *plugin = [ibGroups plugInForList:object];
      if (plugin) {
        [[self document] makeEntryOfType:plugin];
      }
    }
  }
}

- (IBAction)toggleApplications:(id)sender {
  [appDrawer toggle:sender];
}

- (SEEntryList *)selectedList {
  return [ibGroups selectedObject];
}

- (void)revealEntry:(SparkEntry *)entry {
  DLog(@"Reveal %@", entry);
  if (![[entry application] isEqual:[[self document] application]]) {
    /* Select application */
    [ibApplications setSelectedObject:[entry application]];
    if ([[entry application] uid] != kSparkApplicationSystemUID) {
      /* Show drawer */
      [appDrawer open:nil];
      /* Select application list */
      [ibGroups selectApplicationList:nil];
    }
  } 
  //if ([[entry application] uid] == kSparkApplicationSystemUID) {
	/* Select plugin list */
	if (![[ibTriggers arrangedObjects] containsObject:entry])
			[ibGroups selectListForAction:[entry action]];
  //}
  /* should not append */
  if (![[ibTriggers arrangedObjects] containsObject:entry])
    [ibGroups selectLibrary:nil];
  
  if ([[ibTriggers arrangedObjects] containsObject:entry])
		[ibTriggers setSelectedObject:entry];
}

- (void)revealEntries:(NSArray *)entries {
  if ([entries count] == 0) return;
  if ([entries count] == 1) {
    [self revealEntry:[entries objectAtIndex:0]];
  } else {
    DLog(@"Reveal %@", entries);
  }
}

- (IBAction)revealInApplication:(id)sender {
  SparkEntry *entry = [sender representedObject];
  if (entry)
    [self revealEntry:entry];
}

#pragma mark Menu
/* Enable menu item */
- (BOOL)validateMenuItem:(NSMenuItem *)menuItem {
  if ([menuItem action] == @selector(cut:) || [menuItem action] == @selector(copy:) || [menuItem action] == @selector(paste:)) {
    NSResponder *first = [[self window] firstResponder];
    return libraryTable == first || [ibTriggers tableView] == first;
  }
  return YES;
}

- (IBAction)cut:(id)sender {
  WBTrace();
  // TODO: Copy/paste
}

- (IBAction)copy:(id)sender {
  WBTrace();
  // TODO: Copy/paste
}

- (IBAction)paste:(id)sender {
  WBTrace();
  // TODO: Copy/paste
}

- (IBAction)newTriggerFromMenu:(id)sender {
  if ([sender respondsToSelector:@selector(representedObject)]) {
    id object = [sender representedObject];
    if ([object isKindOfClass:[SparkPlugIn class]])
      [[self document] makeEntryOfType:object];
    else
      NSBeep();
  }
}

/* Notification handler */
- (void)libraryDidChange:(NSNotification *)aNotification {
  [self setLibrary:[[aNotification object] library]];
  
  /* Load applications */
  [ibApplications setLibrary:[self library]];
  [ibApplications setSelectionIndex:0];
  
  /* Load library groups */
  [ibGroups setLibrary:[self library]];
  [ibGroups setSelectionIndex:0];
}

- (void)applicationDidChange:(NSNotification *)aNotification {
  [appField setSparkApplication:[[aNotification object] application]];
}

/* Selected list did change */
- (IBAction)newGroup:(id)sender {
  [ibGroups newGroup:sender];
}

- (void)setDaemonStatus:(SparkDaemonStatus)status {
  NSString *str = @"";
  NSImage *img = nil;
  BOOL disabled = NO;
  switch (status) {
    case kSparkDaemonStatusShutDown:
      img = [NSImage imageNamed:@"SparkRun"];
      str = NSLocalizedString(@"Start Spark Daemon", @"Spark Daemon status string");
      break;
    case kSparkDaemonStatusDisabled:
      disabled = YES;
      // Fall through
    default:
      img = [NSImage imageNamed:@"SparkStop"];
      str = NSLocalizedString(@"Stop Spark Daemon", @"Spark Daemon status string");
  }
  [uiStartStop setTitle:str];
  [uiStartStop setImage:img];
  [uiDisabled setHidden:!disabled];
}

- (void)daemonStatusDidChange:(NSNotification *)aNotification {
  [self setDaemonStatus:[(SEServerConnection *)[aNotification object] status]];
}

@end
