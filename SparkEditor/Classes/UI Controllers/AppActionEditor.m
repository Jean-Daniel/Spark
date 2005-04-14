//
//  AppActionEditor.m
//  Spark Editor
//
//  Created by Grayfox on 27/09/04.
//  Copyright 2004 Shadow Lab. All rights reserved.
//

#import "AppActionEditor.h"

#import "Extensions.h"
#import "Preferences.h"
#import "CustomTableView.h"
#import "ActionLibraryController.h"
#import "ApplicationLibraryController.h"

@implementation AppActionEditor

- (id)init {
  if (self= [super initWithWindowNibName:@"AppActionEditor"]) {
    _appLibrary = [[ApplicationLibraryController alloc] init];
    [_appLibrary setDelegate:self];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(firstResponderDidChange:)
                                                 name:kCustomTableViewDidBecomeFirstResponder
                                               object:[_appLibrary listsTable]];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(firstResponderDidChange:)
                                                 name:kCustomTableViewDidBecomeFirstResponder
                                               object:[_appLibrary objectsTable]];
    _actionLibrary = [[ActionLibraryController alloc] init];
    [_actionLibrary setDelegate:self];
    _object = [[NSMutableDictionary alloc] initWithCapacity:2];
    [self window];
  }
  return self;
}

- (void)dealloc {
  ShadowTrace();
  [[NSNotificationCenter defaultCenter] removeObserver:self];
  [_object release];
  [_appLibrary release];
  [_actionLibrary release];
  [super dealloc];
}

- (void)awakeFromNib {
  [[contentView tabViewItemAtIndex:0] setView:[_appLibrary libraryView]];
  [[contentView tabViewItemAtIndex:1] setView:[_actionLibrary libraryView]];
  [self updateApplicationList];
  [self updateActionsSelection];
  
  int index = [[NSUserDefaults standardUserDefaults] integerForKey:kSparkPrefAppActionSelectedTab];
  [toolbar selectCellAtRow:0 column:index];
  [self selectTab:nil];
//  [_appLibrary restoreWorkspaceWithKey:kSparkPrefAppActionApplicationLibrary];
//  [_actionLibrary restoreWorkspaceWithKey:kSparkPrefAppActionActionLibrary];
}

#pragma mark -
- (id)object {
  return _object;
}
- (void)setObject:(id)object {
  if (_object != object) {
    [super setObject:object];
    [_object release];
    _object = [object mutableCopy];
    id appli = [_object objectForKey:@"application"];
    if ([appli isKindOfClass:[SparkObjectList class]]) {
      [_appLibrary selectList:appli];
    } else {
      [_appLibrary selectObjects:[NSArray arrayWithObject:appli]];
    }
    
    [_actionLibrary selectObjects:[NSArray arrayWithObject:[_object objectForKey:@"action"]]];
  }
}

- (BOOL)applicationEnabled {
  return [_appLibrary isEnabled];
}

- (void)setApplicationEnabled:(BOOL)flag {
  [_appLibrary setEnabled:NO];
}

- (BOOL)isValidObject {
  id object = [self object];
  id alert = nil;
  if (![object objectForKey:@"application"] || ![object objectForKey:@"action"]) {
    alert = [NSAlert alertWithMessageText:NSLocalizedStringFromTable(@"INCOMPLETE_MAP_ENTRY_ALERT",
                                                                     @"Editors", @"Invalid Map Selection")
                            defaultButton:NSLocalizedStringFromTable(@"OK",
                                                                     @"Editors", @"Alert default button")
                          alternateButton:nil
                              otherButton:nil
                informativeTextWithFormat:NSLocalizedStringFromTable(@"INCOMPLETE_MAP_ENTRY_ALERT_MSG",
                                                                     @"Editors", @"Invalid Map Selection")];
    
  }
  if (alert) {
    [alert beginSheetModalForWindow:[self window]
                      modalDelegate:nil
                     didEndSelector:nil
                        contextInfo:nil];
    return NO;
  } else {
    if ([[self delegate] respondsToSelector:@selector(appActionEditor:willValidateObject:)]) {
      return [[self delegate] appActionEditor:self willValidateObject:object];
    } else {
      return YES;
    }
  }
}

- (IBAction)create:(id)sender {
  if ([self isValidObject]) {
    [_appLibrary saveWorkspaceWithKey:kSparkPrefAppActionApplicationLibrary];
    [_actionLibrary saveWorkspaceWithKey:kSparkPrefAppActionActionLibrary];
    [super create:sender];
  }
}
- (IBAction)cancel:(id)sender {
  [_appLibrary saveWorkspaceWithKey:kSparkPrefAppActionApplicationLibrary];
  [_actionLibrary saveWorkspaceWithKey:kSparkPrefAppActionActionLibrary];
  [super cancel:sender];
}

- (IBAction)update:(id)sender {
  if ([self isValidObject]) {
    [super update:sender];
  }
}

- (void)close {
  [[NSUserDefaults standardUserDefaults] setInteger:[toolbar selectedColumn] forKey:kSparkPrefAppActionSelectedTab];
  [super close];
}

- (IBAction)selectTab:(id)sender {
  int newIndex = [toolbar selectedColumn];
  if (newIndex != [contentView indexOfSelectedTabViewItem]) {
    [contentView selectTabViewItemAtIndex:newIndex];
  }
}

#pragma mark -
- (void)updateActionsSelection {
  id selection = [_actionLibrary selectedObjects];
  if ([selection count] != 1) {
    [actionName setStringValue:@""];
    [actionIcon setImage:nil];
    [_object removeObjectForKey:@"action"];
  } else {
    id object = [selection objectAtIndex:0];
    [actionName setStringValue:[object name]];
    [actionIcon setImage:[object icon]];
    [_object setObject:object forKey:@"action"];
  }
}

- (void)updateApplicationList {
  id object = [_appLibrary selectedList];
  if ([object uid]) {
    [appName setStringValue:[object name]];
    [appIcon setImage:[object icon]];
    [_object setObject:object forKey:@"application"];
  } else {
    id selection = [_appLibrary selectedObjects];
    if ([selection count] == 1) {
      [self updateApplicationObject];
    } else {
      [appName setStringValue:@""];
      [appIcon setImage:nil];
      [_object removeObjectForKey:@"application"];
    }
  }
}

- (void)updateApplicationObject {
  id selection = [_appLibrary selectedObjects];
  if ([selection count] == 1) {
    id object = [selection objectAtIndex:0];
    [appName setStringValue:[object name]];
    [appIcon setImage:[object icon]];
    [_object setObject:object forKey:@"application"];
  } else {
    [self updateApplicationList];
  }
}

- (void)updateApplicationsSelection {
  id table = [[self window] firstResponder];
  if (table == [_appLibrary listsTable]) {
    [self updateApplicationList];
  } else if (table == [_appLibrary objectsTable]) {
    [self updateApplicationObject];
  } else {
    id appli = [_object objectForKey:@"application"];
    if ([appli isKindOfClass:[SparkObjectList class]]) {
      [self updateApplicationList];
    } else {
      [self updateApplicationObject];
    }
  }
}

#pragma mark -
- (void)libraryControllerSelectedObjectsDidChange:(NSNotification *)aNotification {
  id library = [aNotification object];
  if (library == _actionLibrary) {
    [self updateActionsSelection];
  } else {
    [self updateApplicationsSelection];
  }
}

- (void)firstResponderDidChange:(NSNotification *)aNotification {
  [self updateApplicationsSelection];
}

- (void)libraryControllerSelectedListDidChange:(NSNotification *)aNotification {
  if ([aNotification object] == _appLibrary)
    [self updateApplicationsSelection];
  else {
    [self updateActionsSelection];
  }
}

- (BOOL)libraryController:(LibraryController *)controller shouldDeleteList:(SparkObjectList *)list {
  NSBeep();
  return NO;
}

- (BOOL)libraryController:(LibraryController *)controller shouldDeleteObjects:(NSArray *)objects {
  NSBeep();
  return NO;
}

//- (BOOL)libraryController:(LibraryController *)library shouldPerformObjectsTableDoubleAction:(id)sender {
//  [defaultButton performClick:nil]; 
//  return NO;
//}

@end
