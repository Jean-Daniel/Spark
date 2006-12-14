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
#import "SEPreferences.h"
#import "SETriggerCell.h"
#import "SEEntryEditor.h"
#import "Spark.h"

#import <ShadowKit/SKTableView.h>
#import <ShadowKit/SKExtensions.h>

#import <SparkKit/SparkLibrary.h>

#import <SparkKit/SparkList.h>
#import <SparkKit/SparkAction.h>
#import <SparkKit/SparkHotKey.h>
#import <SparkKit/SparkTrigger.h>
#import <SparkKit/SparkApplication.h>
#import <SparkKit/SparkEntryManager.h>

SK_INLINE
BOOL SEFilterEntry(NSString *search, SparkEntry *entry) {
  if (!search) return YES;

  if ([[entry name] rangeOfString:search options:NSCaseInsensitiveSearch].location != NSNotFound)
    return YES;
  
  if ([[entry actionDescription] rangeOfString:search options:NSCaseInsensitiveSearch].location != NSNotFound)
    return YES;
  
  if ([[entry categorie] rangeOfString:search options:NSCaseInsensitiveSearch].location != NSNotFound)
    return YES;
  
  return NO;
}

typedef struct _SETriggerStyle {
  BOOL bold;
  BOOL strike;
  NSColor *standard, *selected;
} SETriggerStyle;

static
SETriggerStyle styles[6];

@implementation SETriggersController

+ (void)initialize {
  if ([SETriggersController class] == self) {
    /* Standard (global) */
    styles[0] = (SETriggerStyle){NO, NO,
      [[NSColor controlTextColor] retain],
      [[NSColor selectedTextColor] retain]};
    /* Global overrided */
    styles[1] = (SETriggerStyle){YES, NO,
      [[NSColor controlTextColor] retain],
      [[NSColor selectedTextColor] retain]};
    /* Inherits */
    styles[2] = (SETriggerStyle){NO, NO,
      [[NSColor darkGrayColor] retain],
      [[NSColor selectedTextColor] retain]};
    /* Override */
    styles[3] = (SETriggerStyle){YES, NO,
      [[NSColor colorWithCalibratedRed:.067f green:.357f blue:.420f alpha:1] retain],
      [[NSColor colorWithCalibratedRed:.886f green:.914f blue:.996f alpha:1] retain]};
    /* Specifics */
    styles[4] = (SETriggerStyle){NO, NO,
      [[NSColor orangeColor] retain],
      [[NSColor colorWithCalibratedRed:.992f green:.875f blue:.749f alpha:1] retain]};
    /* Weak Override */
    styles[5] = (SETriggerStyle){NO, YES,
      [[NSColor colorWithCalibratedRed:.463f green:.016f blue:.314f alpha:1] retain],
      [[NSColor colorWithCalibratedRed:.984f green:.890f blue:1.00f alpha:1] retain]};
  }
}

- (id)init {
  if (self = [super init]) {
    se_entries = [[NSMutableArray alloc] init];
    se_snapshot = [[NSMutableArray alloc] init];
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
  [se_snapshot release];
  [[NSNotificationCenter defaultCenter] removeObserver:self];
  [super dealloc];
}

#pragma mark -
- (void)awakeFromNib {
  [table setTarget:self];
  [table setDoubleAction:@selector(doubleAction:)];
  
  [table setAutosaveName:@"SparkMainEntryTable"];
  [table setAutosaveTableColumns:YES];
  
  [table setVerticalMotionCanBeginDrag:YES];
  
  [table setContinueEditing:NO];
}

- (void)setListEnabled:(BOOL)flag {
  UInt32 app = [[[SEEntriesManager sharedManager] application] uid];
  int idx = [se_entries count];
  SparkEntryManager *manager = SparkSharedManager();
  SEL method = flag ? @selector(enableEntry:) : @selector(disableEntry:);
  while (idx-- > 0) {
    SparkEntry *entry = [se_entries objectAtIndex:idx];
    if ([[entry application] uid] == app) {
      if (XOR([entry isEnabled], flag)) {
        [manager performSelector:method withObject:entry];
      }
    }
  }
  [table reloadData];
}

- (void)sortTriggers:(NSArray *)descriptors {
  [se_entries sortUsingDescriptors:descriptors ? : gSortByNameDescriptors];
}

- (void)filterEntries:(NSString *)search {
  [se_entries removeAllObjects];
  if (!search || ![search length]) {
    [se_entries addObjectsFromArray:se_snapshot];
  } else {
    unsigned count = [se_snapshot count];
    while (count-- > 0) {
      SparkEntry *entry = [se_snapshot objectAtIndex:count];
      if (SEFilterEntry(search, entry))
        [se_entries addObject:entry];
    }
  }
  [self sortTriggers:[table sortDescriptors]];
}

- (IBAction)search:(id)sender {
  [self filterEntries:[sender stringValue]];
  [table reloadData];
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
    if ([entry isPlugged])
      [[SEEntriesManager sharedManager] editEntry:entry modalForWindow:[sender window]];
    else
      NSBeep();
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

- (void)loadTriggers {
  [se_snapshot removeAllObjects];
  if (se_list) {
    SparkTrigger *trigger;
    NSEnumerator *triggers = [se_list objectEnumerator];
    /*  Get current snapshot */
    SESparkEntrySet *snapshot = [[SEEntriesManager sharedManager] snapshot];
    BOOL hide = [[NSUserDefaults standardUserDefaults] boolForKey:kSparkPrefHideDisabled];
    while (trigger = [triggers nextObject]) {
      SparkEntry *entry = [snapshot entryForTrigger:trigger];
      if (entry && (!hide || [entry isPlugged])) {
        [se_snapshot addObject:entry];
      }
    }
    /* Filter entries */
    [self filterEntries:[ibSearch stringValue]];
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
  if (items && [items count]) {
    if ([se_list isDynamic]) {
      BOOL hasCustom = NO;
      SparkApplication *application = [[SEEntriesManager sharedManager] application];
      if ([application uid] == 0) {
        int count = [items count];
        while (count-- > 0 && !hasCustom) {
          SparkEntry *entry = [items objectAtIndex:count];
          hasCustom |= [SparkSharedManager() containsOverwriteEntryForTrigger:[[entry trigger] uid]];
        }
        if (hasCustom) {
          DLog(@"WARNING: Has Custom");
        }
      }
      // TODO: Check item consequences.
      [[SEEntriesManager sharedManager] removeEntries:items];
    } else {
      // User list
      int count = [items count];
      while (count-- > 0) {
        SparkEntry *entry = [items objectAtIndex:count];
        [se_list removeObject:[entry trigger]];
      }
    }
  }
}

- (int)numberOfRowsInTableView:(NSTableView *)aTableView {
  return [se_entries count];
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex {
  SparkEntry *entry = [se_entries objectAtIndex:rowIndex];
  if ([[aTableColumn identifier] isEqualToString:@"__item__"]) {
    return entry;
  } else if ([[aTableColumn identifier] isEqualToString:@"trigger"]) {
    return [entry triggerDescription];
  } else {
    return [entry valueForKey:[aTableColumn identifier]];
  }
}

- (void)tableView:(NSTableView *)aTableView willDisplayCell:(id)aCell forTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex {
  SparkEntry *entry = [se_entries objectAtIndex:rowIndex];
  
  /* Text field cell */
  if ([aCell respondsToSelector:@selector(setTextColor:)]) {  
    SparkApplication *application = [[SEEntriesManager sharedManager] application];
    
    SInt32 idx = -1;
    if (0 == [application uid]) {
      /* Global key */
      if ([SparkSharedManager() containsOverwriteEntryForTrigger:[[entry trigger] uid]]) {
        idx = 1;
      } else {
        idx = 0;
      }
    } else {
      switch ([entry type]) {
        case kSparkEntryTypeDefault:
          /* Inherits */
          idx = 2;
          break;
        case kSparkEntryTypeOverWrite:
          idx = 3;
          break;
        case kSparkEntryTypeSpecific: 
          /* Is only defined for a specific application */
          idx = 4;
          break;
        case kSparkEntryTypeWeakOverWrite:
          idx = 5;
          break;
      }
    }
    if (idx >= 0) {
      NSWindow *window = [aTableView window];
      BOOL selected = ([window isKeyWindow] && [window firstResponder] == aTableView) && [aTableView isRowSelected:rowIndex];
      if ([entry isPlugged]) {
        [aCell setTextColor:selected ? styles[idx].selected : styles[idx].standard];
      } else {
        /* handle case where plugin is disabled */
        [aCell setTextColor:selected ? [NSColor selectedControlTextColor] : [NSColor disabledControlTextColor]];
      }
      /* Set Line status */
      if ([aCell respondsToSelector:@selector(setDrawLineOver:)])
        [aCell setDrawLineOver:styles[idx].strike && ![entry isEnabled]];
      
      float size = [NSFont smallSystemFontSize];
      [aCell setFont:styles[idx].bold ? [NSFont boldSystemFontOfSize:size] : [NSFont systemFontOfSize:size]];
    }
  } else if ([aCell respondsToSelector:@selector(setEnabled:)]) {
    /* Button cell */
    /* handle case where plugin is disabled */
    [aCell setEnabled:[entry isPlugged]];
  }
}

- (void)tableView:(NSTableView *)aTableView setObjectValue:(id)anObject forTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex {
  SparkEntry *entry = [se_entries objectAtIndex:rowIndex];
  if ([[aTableColumn identifier] isEqualToString:@"active"]) {
    NSEvent *evnt = [NSApp currentEvent];
    if (evnt && [evnt type] == NSLeftMouseUp && ([evnt modifierFlags] & NSAlternateKeyMask)) {
      [self setListEnabled:[anObject boolValue]];
    } else {
      SparkApplication *application = [[SEEntriesManager sharedManager] application];
      if ([application uid] != 0 && kSparkEntryTypeDefault == [entry type]) {
        /* Inherits: should create an new entry */
        entry = [[SEEntriesManager sharedManager] createWeakEntryForEntry:entry];
        [se_entries replaceObjectAtIndex:rowIndex withObject:entry];
      }
      if ([anObject boolValue])
        [SparkSharedManager() enableEntry:entry];
      else
        [SparkSharedManager() disableEntry:entry];
      
      [aTableView setNeedsDisplayInRect:[aTableView rectOfRow:rowIndex]];
    }
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

#pragma mark Drag & Drop
- (BOOL)tableView:(NSTableView *)aTableView writeRows:(NSArray *)rows toPasteboard:(NSPasteboard *)pboard {
  NSMutableIndexSet *idxes = [NSMutableIndexSet indexSet];
  unsigned count = [rows count];
  while (count-- > 0) {
    [idxes addIndex:[[rows objectAtIndex:count] unsignedIntValue]];
  }
  return [self tableView:aTableView writeRowsWithIndexes:idxes toPasteboard:pboard];
}
- (BOOL)tableView:(NSTableView *)aTableView writeRowsWithIndexes:(NSIndexSet *)rowIndexes toPasteboard:(NSPasteboard*)pboard {
  if (![rowIndexes count])
    return NO;
  
  int idx = 0;
  NSMutableArray *triggers = [[NSMutableArray alloc] init];
  SKIndexEnumerator *indexes = [rowIndexes indexEnumerator];
  while ((idx = [indexes nextIndex]) != NSNotFound) {
    SparkTrigger *trigger = [[se_entries objectAtIndex:idx] trigger];
    [triggers addObject:[NSNumber numberWithUnsignedInt:[trigger uid]]];
  }
  [pboard declareTypes:[NSArray arrayWithObject:SparkTriggerListPboardType] owner:self];
  [pboard setPropertyList:triggers forType:SparkTriggerListPboardType];
  [triggers release];
  
  return YES;
}

@end

@implementation SparkEntry (SETriggerSort)

- (UInt32)triggerValue {
  return [[self trigger] character] << 16 | [[self trigger] modifier] & 0xff;
}

@end
