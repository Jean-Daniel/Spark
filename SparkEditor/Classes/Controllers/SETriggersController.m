//
//  SETriggersController.m
//  Spark Editor
//
//  Created by Jean-Daniel Dupas on 07/07/06.
//  Copyright 2006 Shadow Lab. All rights reserved.
//

#import "SETriggersController.h"
#import "SELibraryWindow.h"
#import "SEVirtualPlugIn.h"
#import "SETriggerEntry.h"

#import <ShadowKit/SKTableView.h>

#import <SparkKit/SparkLibrary.h>

#import <SparkKit/SparkAction.h>
#import <SparkKit/SparkTrigger.h>
#import <SparkKit/SparkApplication.h>
#import <SparkKit/SparkActionLoader.h>

@implementation SETriggersController

- (id)init {
  if (self = [super init]) {
    se_entries = [[NSMutableArray alloc] init];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didChangeTriggers:)
                                                 name:SETriggersDidChangeNotification
                                               object:nil];
  }
  return self;
}

- (void)dealloc {
  [[NSNotificationCenter defaultCenter] removeObserver:self];
  [se_list release];
  [se_entries release];
  [super dealloc];
}

#pragma mark -
- (void)awakeFromNib {
  [table setTarget:self];
  [table setDoubleAction:@selector(doubleAction:)];
  
  [table setAutosaveName:@"SparkTriggerTable"];
  [table setAutosaveTableColumns:YES];
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
    DLog(@"%@", [se_entries objectAtIndex:idx]);
  }
}

- (void)sortTriggers:(NSArray *)descriptors {
  [se_entries sortUsingDescriptors:descriptors];
}

- (void)didChangeTriggers:(NSNotification *)aNotification {
  se_triggers = [aNotification object];
  // Reload data
  [self loadTriggers];
}

- (void)loadTriggers {
  [se_entries removeAllObjects];
  if (se_list) {
    SETriggerEntry *entry = nil;
    NSEnumerator *entries = [se_triggers entryEnumerator];
    while (entry = [entries nextObject]) {
      [se_entries addObject:entry];
    }
    [self sortTriggers:gSortByNameDescriptors];
    [table reloadData];
  }
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
  SETriggerEntry *entry = [se_entries objectAtIndex:rowIndex];
//  if ([se_app uid] != 0 && [[entry action] isEqualToLibraryObject:[se_defaults actionForTrigger:[entry trigger]]]) {
//    [cell setFont:[NSFont systemFontOfSize:[NSFont smallSystemFontSize]]];
//    [cell setTextColor:[outlineView isRowSelected:[outlineView rowForItem:item]] ? [NSColor selectedControlTextColor] : [NSColor grayColor]];
//  } else {
//    [cell setTextColor:[NSColor blackColor]];
//    if ([se_app uid] == 0) {
//      [cell setFont:[NSFont systemFontOfSize:[NSFont smallSystemFontSize]]];
//    } else {
//      [cell setFont:[NSFont boldSystemFontOfSize:[NSFont smallSystemFontSize]]];
//    }
//  }
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
  return YES;
}

@end

