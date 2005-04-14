//
//  ChoosePanel.m
//  Spark Editor
//
//  Created by Grayfox on 03/10/04.
//  Copyright 2004 Shadow Lab. All rights reserved.
//

#import "ChoosePanel.h"

#import "Preferences.h"
#import "CustomTableView.h"
#import "KeyLibraryController.h"
#import "ActionLibraryController.h"
#import "ApplicationLibraryController.h"

@implementation ChoosePanel

- (id)init {
  NSAssert(NO, @"Cannot init Chooser without type.");
  return nil;
}

- (id)initWithObjectType:(SparkObjectType)type {
  if (self = [super initWithWindowNibName:@"ObjectChooser"]) {
    switch (type) {
      case kSparkAction:
        _library = [[ActionLibraryController alloc] init];
        break;
      case kSparkHotKey:
        _library = [[KeyLibraryController alloc] init];
        break;
      case kSparkApplication:
        _library = [[ApplicationLibraryController alloc] init];
        break;
      default:
        [self release];
        self = nil;
    }
    [_library setDelegate:self];
  }
  return self;
}

- (void)dealloc {
  ShadowTrace();
  [_library release];
  [super dealloc];
}

- (void)awakeFromNib {
  [_library setEditable:NO];
  [[_library objectsTable] setAllowsMultipleSelection:NO];
  [[_library objectsTable] setAllowsEmptySelection:NO];
  id view = [_library libraryView];
  [_library restoreWorkspaceWithKey:kSparkPrefChoosePanelActionLibrary];
  [view setFrameSize:[libraryView frame].size];
  [libraryView addSubview:view];
}

- (id)object {
  return _object;
}

- (IBAction)choose:(id)sender {
  id objects = [_library selectedObjects];
  if ([objects count]) {
    _object = [objects objectAtIndex:0];
    DLog(@"Select Object: %@", _object);
    [self close];
  } else {
    NSBeep();
    DLog(@"No Object selected.");
  }
}

- (IBAction)cancel:(id)sender {
  _object = nil;
  [self close];
}

- (void)close {
  if ([[self window] isSheet]) {
    [NSApp endSheet:[self window]];
  }
  [_library saveWorkspaceWithKey:kSparkPrefChoosePanelActionLibrary];
  [super close];
}

- (void)libraryControllerSelectedObjectsDidChange:(NSNotification *)aNotification {
  [defaultButton setEnabled:[[[aNotification object] selectedObjects] count]];
}

- (BOOL)libraryController:(LibraryController *)controller shouldPerformObjectsTableDoubleAction:(id)sender {
  [self choose:sender];
  return NO;
}

@end
