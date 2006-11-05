/*
 *  SETriggersController.m
 *  Spark Editor
 *
 *  Created by Black Moon Team.
 *  Copyright (c) 2004 - 2006, Shadow Lab. All rights reserved.
 */

#import "SETriggersController.h"
#import "SEEntriesManager.h"
#import "SELibraryWindow.h"
#import "SESparkEntrySet.h"
#import "SETriggerCell.h"
#import "SEEntryEditor.h"

#import <ShadowKit/SKTableView.h>

#import <SparkKit/SparkLibrary.h>

#import <SparkKit/SparkList.h>
#import <SparkKit/SparkAction.h>
#import <SparkKit/SparkHotKey.h>
#import <SparkKit/SparkTrigger.h>
#import <SparkKit/SparkApplication.h>
#import <SparkKit/SparkEntryManager.h>

#if 0
static BOOL SearchHotKey(NSString *search, id object, void *context) {
  BOOL ok;
  if (nil == search) return YES;
  ok = [[object name] rangeOfString:search options:NSCaseInsensitiveSearch].location != NSNotFound;
  if (!ok) 
    ok = [[object shortDescription] rangeOfString:search options:NSCaseInsensitiveSearch].location != NSNotFound;
  return ok;
}
#endif

@implementation SETriggersController

- (id)init {
  if (self = [super init]) {
    se_entries = [[NSMutableArray alloc] init];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(listDidChange:) 
                                                 name:SparkListDidChangeNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didUpdateEntry:) 
                                                 name:SEEntriesManagerDidUpdateEntryNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(managerDidReload:) 
                                                 name:SEEntriesManagerDidReloadNotification
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
  
  [table setAutosaveName:@"SparkMainEntryTable"];
  [table setAutosaveTableColumns:YES];
}

- (IBAction)doubleAction:(id)sender {
  /* Does not support multi-edition */
  if ([table numberOfSelectedRows] != 1) {
    NSBeep();
    return;
  }
  
  int idx = -1;
  NSEvent *event = [NSApp currentEvent];
  if ([event type] == NSKeyDown) {
    idx = [table selectedRow];
  } else {
    idx = [table clickedRow];
  }
  if (idx >= 0) {
    SparkEntry *entry = [se_entries objectAtIndex:idx];
    [[SEEntriesManager sharedManager] editEntry:entry modalForWindow:[sender window]];
  }
}
/* Select updated entry */
- (void)didUpdateEntry:(NSNotification *)aNotification {
  SparkEntry *entry = [aNotification object];
  if (entry && [se_entries containsObject:entry]) {
    int idx = [se_entries indexOfObject:entry];
    [table selectRow:idx byExtendingSelection:NO];
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
    SESparkEntrySet *snapshot = [[SEEntriesManager sharedManager] snapshot];
    while (trigger = [triggers nextObject]) {
      SparkEntry *entry = [snapshot entryForTrigger:trigger];
      if (entry) {
        [se_entries addObject:entry];
      }
    }
    [self sortTriggers:[table sortDescriptors]];
  }
  [table reloadData];
}

- (void)managerDidReload:(NSNotification *)notification {
  /* Static list will not notify change, so we have to force reload */
  if (se_list && ![se_list isDynamic])
    [self loadTriggers];
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
- (void)deleteSelectionInTableView:(NSTableView *)aTableView {
  NSIndexSet *indexes = [aTableView selectedRowIndexes];
  NSArray *items = indexes ? [se_entries objectsAtIndexes:indexes] : nil;
  if (items) {
    BOOL hasCustom = NO;
    SparkApplication *application = [[SEEntriesManager sharedManager] application];
    if ([application uid] == 0) {
      int count = [items count];
      while (count-- > 0 && !hasCustom) {
        SparkEntry *entry = [se_entries objectAtIndex:count];
        hasCustom |= [SparkSharedManager() containsOverwriteEntryForTrigger:[[entry trigger] uid]];
      }
      if (hasCustom) {
        DLog(@"WARNING: Has Custom");
      }
    }
    // TODO: Check item consequences.
    [[SEEntriesManager sharedManager] removeEntries:items];
  }
}

- (int)numberOfRowsInTableView:(NSTableView *)aTableView {
  return [se_entries count];
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex {
  SparkEntry *entry = [se_entries objectAtIndex:rowIndex];
  if ([[aTableColumn identifier] isEqualToString:@"__item__"]) {
    return entry;
  } else {
    if ([[aTableColumn identifier] isEqualToString:@"trigger"]) {
      return [entry triggerDescription];
    } else if ([[aTableColumn identifier] isEqualToString:@"enabled"]) {
      return SKBool([SparkSharedManager() statusForEntry:entry]);
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
    SparkEntry *entry = [se_entries objectAtIndex:rowIndex];
    SparkApplication *application = [[SEEntriesManager sharedManager] application];
    
    if (0 == [application uid]) {
      [aCell setTextColor:[NSColor controlTextColor]];
      if ([SparkSharedManager() containsOverwriteEntryForTrigger:[[entry trigger] uid]]) {
        [aCell setFont:[NSFont boldSystemFontOfSize:[NSFont smallSystemFontSize]]];
      } else {
        [aCell setFont:[NSFont systemFontOfSize:[NSFont smallSystemFontSize]]];
      }
    } else {
      switch ([entry type]) {
        case kSparkEntryTypeDefault:
          /* Inherits */
          [aCell setFont:[NSFont systemFontOfSize:[NSFont smallSystemFontSize]]];
          [aCell setTextColor:[aTableView isRowSelected:rowIndex] ? [NSColor selectedControlTextColor] : [NSColor darkGrayColor]];
          break;
        case kSparkEntryTypeSpecific:
          [aCell setTextColor:[NSColor orangeColor]];
          [aCell setFont:[NSFont boldSystemFontOfSize:[NSFont smallSystemFontSize]]];
          break;
        case kSparkEntryTypeOverWrite:
          [aCell setTextColor:[NSColor greenColor]];
          [aCell setFont:[NSFont boldSystemFontOfSize:[NSFont smallSystemFontSize]]];
          break;
        case kSparkEntryTypeWeakOverWrite:
          [aCell setTextColor:[NSColor magentaColor]];
          [aCell setFont:[NSFont systemFontOfSize:[NSFont smallSystemFontSize]]];
          if (![SparkSharedManager() statusForEntry:entry] && [aCell respondsToSelector:@selector(setDrawLineOver:)]) {
            [aCell setDrawLineOver:YES];
          }
          break;
      }
    }
  }
}

- (void)tableView:(NSTableView *)aTableView setObjectValue:(id)anObject forTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex {
  SparkEntry *entry = [se_entries objectAtIndex:rowIndex];
  if ([[aTableColumn identifier] isEqualToString:@"enabled"]) {
    SparkApplication *application = [[SEEntriesManager sharedManager] application];
    if ([application uid] != 0 && kSparkEntryTypeDefault == [entry type]) {
      /* Inherits: should create an new entry */
      entry = [[SEEntriesManager sharedManager] createWeakEntryForEntry:entry];
      [se_entries replaceObjectAtIndex:rowIndex withObject:entry];
      [SparkSharedManager() setStatus:[anObject boolValue] forEntry:entry];
    }
    [SparkSharedManager() setStatus:[anObject boolValue] forEntry:entry];
    [aTableView setNeedsDisplayInRect:[aTableView rectOfRow:rowIndex]];
  } else if ([[aTableColumn identifier] isEqualToString:@"__item__"]) {
    if ([anObject length] > 0) {
      [entry setName:anObject];
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

@implementation SparkEntry (SETriggerSort)

- (UInt32)triggerValue {
  return [[self trigger] character] << 16 | [[self trigger] modifier] & 0xff;
}

@end
