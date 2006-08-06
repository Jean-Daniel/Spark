//
//  SETriggersController.m
//  Spark Editor
//
//  Created by Jean-Daniel Dupas on 07/07/06.
//  Copyright 2006 Shadow Lab. All rights reserved.
//

#import "SETriggersController.h"
#import "SELibraryWindow.h"
#import "SETriggerEntry.h"
#import "SETriggerCell.h"
#import "SEEntryEditor.h"

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
    se_defaults = [[SETriggerEntrySet alloc] init];
    [se_defaults addEntriesFromDictionary:[SparkSharedLibrary() triggersForApplication:0]];
  }
  return self;
}

- (void)dealloc {
  [se_list release];
  [se_entries release];
  [se_defaults release];
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
    if (!se_editor) {
      se_editor = [[SEEntryEditor alloc] init];
      /* Load */
      [se_editor window];
    }
    [se_editor setEntry:[se_entries objectAtIndex:idx]];
    [se_editor setApplication:se_application];
    
    [NSApp beginSheet:[se_editor window]
       modalForWindow:[sender window]
        modalDelegate:self
       didEndSelector:@selector(editorDidEnd:returnCode:contextInfo:)
          contextInfo:nil];
  }
}

- (void)editorDidEnd:(NSWindow *)sheet returnCode:(int)returnCode  contextInfo:(void  *)contextInfo {
  ShadowTrace();
}

- (IBAction)changeFilter:(id)sender {
  switch ([sender indexOfSelectedItem]) {
    case 0:
      se_filter = 0;
      break;
    case 1:
      se_filter = 1;
      break;
  }
  [self loadTriggers];
}

- (void)sortTriggers:(NSArray *)descriptors {
  [se_entries sortUsingDescriptors:descriptors ? : gSortByNameDescriptors];
}

- (void)setTriggers:(SETriggerEntrySet *)triggers application:(SparkApplication *)anApplication {
  se_triggers = triggers;
  se_application = anApplication;
  // Reload data
  [self loadTriggers];
}

- (void)loadTriggers {
  [se_entries removeAllObjects];
  if (se_list) {
    SparkTrigger *trigger;
    NSEnumerator *triggers = [se_list objectEnumerator];
    while (trigger = [triggers nextObject]) {
      SETriggerEntry *entry = [se_triggers entryForTrigger:trigger];
      if (entry) {
        if ([se_application uid] == 0 || !se_filter || [entry action] != [se_defaults actionForTrigger:trigger]) 
          [se_entries addObject:entry];
      }
    }
    [self sortTriggers:[table sortDescriptors]];
  }
  [table reloadData];
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
    if ([se_application uid] != 0 && [[entry action] isEqualToLibraryObject:[se_defaults actionForTrigger:[entry trigger]]]) {
      //    [cell setFont:[NSFont systemFontOfSize:[NSFont smallSystemFontSize]]];
      [aCell setFont:[NSFont systemFontOfSize:[NSFont smallSystemFontSize]]];
      [aCell setTextColor:[aTableView isRowSelected:rowIndex] ? [NSColor selectedControlTextColor] : [NSColor darkGrayColor]];
    } else {
      [aCell setTextColor:[NSColor blackColor]];
      /* If gloabl action and global app is selected */
      if ([se_application uid] == 0) {
        [aCell setFont:[NSFont systemFontOfSize:[NSFont smallSystemFontSize]]];
      } else {
        if ([aCell respondsToSelector:@selector(setDrawLineOver:)])
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
  return [[tableColumn identifier] isEqualToString:@"__item__"];
}

@end

