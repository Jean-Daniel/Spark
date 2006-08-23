//
//  SETriggersController.m
//  Spark Editor
//
//  Created by Jean-Daniel Dupas on 07/07/06.
//  Copyright 2006 Shadow Lab. All rights reserved.
//

#import "SETriggersController.h"
#import "SEEntriesManager.h"
#import "SELibraryWindow.h"
#import "SETriggerEntry.h"
#import "SETriggerCell.h"
#import "SEEntryEditor.h"

#import <ShadowKit/SKTableView.h>

#import <SparkKit/SparkLibrary.h>

#import <SparkKit/SparkList.h>
#import <SparkKit/SparkAction.h>
#import <SparkKit/SparkTrigger.h>
#import <SparkKit/SparkApplication.h>
#import <SparkKit/SparkActionLoader.h>

@implementation SETriggersController

- (id)init {
  if (self = [super init]) {
    se_entries = [[NSMutableArray alloc] init];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(listDidChange:) 
                                                 name:SparkListDidChangeNotification
                                               object:nil];
  }
  return self;
}

- (void)dealloc {
  [se_list release];
  [se_entries release];
  [[NSNotificationCenter defaultCenter] removeObserver:self];
  [super dealloc];
}

#pragma mark -
- (void)awakeFromNib {
  [table setTarget:self];
  [table setDoubleAction:@selector(doubleAction:)];
  
//  [table setAutosaveName:@"SparkTriggerTable"];
//  [table setAutosaveTableColumns:YES];
}

- (IBAction)doubleAction:(id)sender {
  int idx = -1;
  NSEvent *event = [NSApp currentEvent];
  if ([event type] == NSKeyDown) {
    idx = [table selectedRow];
  } else {
    idx = [table clickedRow];
  }
  if (idx >= 0) {
    SETriggerEntry *entry = [se_entries objectAtIndex:idx];
    [[SEEntriesManager sharedManager] editEntry:entry modalForWindow:[sender window]];
  }
}

- (void)sortTriggers:(NSArray *)descriptors {
  [se_entries sortUsingDescriptors:descriptors ? : gSortByNameDescriptors];
}

- (void)loadTriggers {
  [se_entries removeAllObjects];
  if (se_list) {
    SparkTrigger *trigger;
    NSEnumerator *triggers = [se_list objectEnumerator];
    /*  Get current snapshot */
    SETriggerEntrySet *snapshot = [[SEEntriesManager sharedManager] snapshot];
    while (trigger = [triggers nextObject]) {
      SETriggerEntry *entry = [snapshot entryForTrigger:trigger];
      if (entry) {
        [se_entries addObject:entry];
      }
    }
    [self sortTriggers:[table sortDescriptors]];
  }
  [table reloadData];
}

- (void)listDidChange:(NSNotification *)notification {
  if ([notification object] == se_list)
    [self loadTriggers];
}

- (void)setList:(SparkList *)aList {
  if (se_list != aList) {
    [se_list release];
    se_list = [aList retain];
    // Reload data
    [self loadTriggers];
  }
}

#pragma mark -
- (int)numberOfRowsInTableView:(NSTableView *)aTableView {
  return [se_entries count];
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex {
  SETriggerEntry *entry = [se_entries objectAtIndex:rowIndex];
  if ([[aTableColumn identifier] isEqualToString:@"__item__"]) {
    return entry;
  } else {
    if ([[aTableColumn identifier] isEqualToString:@"trigger"]) {
      return [[entry trigger] triggerDescription];
    } else if ([[aTableColumn identifier] isEqualToString:@"enabled"]) {
      return SKBool([[entry trigger] isEnabled]);
    } else {
      return [entry valueForKey:[aTableColumn identifier]];
    }
  }
}

- (void)tableView:(NSTableView *)aTableView willDisplayCell:(id)aCell forTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex {
  /* Reset Line status */
  if ([aCell respondsToSelector:@selector(setDrawLineOver:)])
    [aCell setDrawLineOver:NO];
  
  /* Text field cell */
  if ([aCell respondsToSelector:@selector(setTextColor:)]) {
    SETriggerEntry *entry = [se_entries objectAtIndex:rowIndex];
    SparkApplication *application = [[SEEntriesManager sharedManager] application];
    /* If Inherits */
    if ([application uid] != 0 && kSEEntryTypeGlobal == [entry type]) {
      [aCell setFont:[NSFont systemFontOfSize:[NSFont smallSystemFontSize]]];
      [aCell setTextColor:[aTableView isRowSelected:rowIndex] ? [NSColor selectedControlTextColor] : [NSColor darkGrayColor]];
    } else {
      [aCell setTextColor:[NSColor blackColor]];
      /* If Global application */
      if ([application uid] == 0) {
        [aCell setFont:[NSFont systemFontOfSize:[NSFont smallSystemFontSize]]];
      } else { /* Custom action */
        if ([entry type] == kSEEntryTypeIgnore && [aCell respondsToSelector:@selector(setDrawLineOver:)])
          [aCell setDrawLineOver:YES];
        [aCell setFont:[NSFont boldSystemFontOfSize:[NSFont smallSystemFontSize]]];
      }
    }
  }
}

- (void)tableView:(NSTableView *)aTableView setObjectValue:(id)anObject forTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex {
  SETriggerEntry *entry = [se_entries objectAtIndex:rowIndex];
  if ([[aTableColumn identifier] isEqualToString:@"enabled"]) {
    [[entry trigger] setEnabled:[anObject boolValue]];
  } else if ([[aTableColumn identifier] isEqualToString:@"__item__"]) {
    if ([anObject length] > 0) {
      [[entry action] setName:anObject];
    } else {
      NSBeep();
      // Be more verbose maybe?
    }
  }
}

- (void)tableView:(NSTableView *)aTableView sortDescriptorsDidChange:(NSArray *)oldDescriptors {
  [self sortTriggers:[aTableView sortDescriptors]];
  [aTableView reloadData];
}

- (BOOL)tableView:(NSTableView *)aTableView shouldEditTableColumn:(NSTableColumn *)tableColumn row:(int)rowIndex {
  /* Should not allow all columns */
  return [[tableColumn identifier] isEqualToString:@"__item__"] || [[tableColumn identifier] isEqualToString:@"enabled"];
}

@end

