/*
 *  SELibrarySource.m
 *  Spark Editor
 *
 *  Created by Black Moon Team.
 *  Copyright (c) 2004 - 2006 Shadow Lab. All rights reserved.
 */

#import "SELibrarySource.h"
#import "SETableView.h"
#import "SEHeaderCell.h"
#import "SESparkEntrySet.h"
#import "SELibraryWindow.h"
#import "SEEntriesManager.h"

#import <SparkKit/SparkList.h>
#import <SparkKit/SparkPlugIn.h>
#import <SparkKit/SparkLibrary.h>
#import <SparkKit/SparkActionLoader.h>

#import <ShadowKit/SKExtensions.h>

static 
NSComparisonResult SECompareList(SparkList *l1, SparkList *l2, void *ctxt) {
  /* First reserved objects */
  if ([l1 uid] < 128) {
    if ([l2 uid] < 128) {
      return [l1 uid] - [l2 uid];
    } else {
      return NSOrderedAscending;
    }
  } else if ([l2 uid] < 128) {
    return NSOrderedDescending;
  }
  /* Seconds, plugins */
  if ([l1 uid] < 200) {
    if ([l2 uid] < 200) {
      return [[l1 name] caseInsensitiveCompare:[l2 name]];
    } else {
      return NSOrderedAscending;
    }
  } else if ([l2 uid] < 200) {
    return NSOrderedDescending;
  }
  /* Third, Other reserved */
  if ([l1 uid] < kSparkLibraryReserved) {
    if ([l2 uid] < kSparkLibraryReserved) {
      return [l1 uid] - [l2 uid];
    } else {
      return NSOrderedAscending;
    }
  } else if ([l2 uid] < kSparkLibraryReserved) {
    return NSOrderedDescending;
  }
  /* Finally, list */
  return [[l1 name] caseInsensitiveCompare:[l2 name]];
}

static 
BOOL SELibraryFilter(SparkObject *object, id ctxt) {
  return YES;
}

static 
BOOL SEOverwriteListFilter(SparkObject *object, id ctxt) {
  SESparkEntrySet *triggers = [[SEEntriesManager sharedManager] overwrites];
  return [triggers containsTrigger:(id)object];
}

static 
BOOL SEPluginListFilter(SparkObject *object, id ctxt) {
  Class kind = (Class)ctxt;
  if (kind) {
    SESparkEntrySet *triggers = [[SEEntriesManager sharedManager] snapshot];
    SparkAction *action = [triggers actionForTrigger:(id)object];
    if (action)
      return [action isKindOfClass:kind];
  }
  return NO;
}

@implementation SELibrarySource

- (id)init {
  if (self = [super init]) {
    se_content = [[NSMutableArray alloc] init];
    
    /* Add library… */
    SparkList *library = [SparkList objectWithName:@"Library" icon:[NSImage imageNamed:@"Library"]];
    [library setObjectSet:SparkSharedTriggerSet()];
    [library setListFilter:SELibraryFilter context:nil];
    [se_content addObject:library];
    
    /* …, plugins list… */
    NSArray *plugins = [[SparkActionLoader sharedLoader] plugins];
    se_plugins = NSCreateMapTable(NSObjectMapKeyCallBacks,NSObjectMapValueCallBacks, [plugins count]);
    unsigned uid = 128;
    unsigned idx = [plugins count];
    while (idx-- > 0) {
      SparkPlugIn *plugin = [plugins objectAtIndex:idx];
      SparkList *list = [[SparkList alloc] initWithName:[plugin name] icon:[plugin icon]];
      [list setObjectSet:SparkSharedTriggerSet()];
      NSMapInsert(se_plugins, list, plugin);
      [list setUID:uid++];
      [list setListFilter:SEPluginListFilter context:[plugin actionClass]];
      [se_content addObject:list];
      [list release];
    }
    /* …and User defined lists */
    [se_content addObjectsFromArray:[SparkSharedListSet() objects]];
    
    /* Overwrite list */
    se_overwrite = [[SparkList alloc] initWithName:@"Overwrite" icon:[NSImage imageNamed:@"Overwrite"]];
    [se_overwrite setListFilter:SEOverwriteListFilter context:nil];
    [se_overwrite setObjectSet:SparkSharedTriggerSet()];
    [se_overwrite setUID:9];
    
    /* First Separators */
    SparkObject *separator = [SparkList objectWithName:SETableSeparator icon:nil];
    [separator setUID:10];
    [se_content addObject:separator];
    
    /* Second Separators */
    separator = [SparkList objectWithName:SETableSeparator icon:nil];
    [separator setUID:200];
    [se_content addObject:separator];
    
    [self rearrangeObjects];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didReloadEntries:)
                                                 name:SEEntriesManagerDidReloadNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(applicationDidChange:)
                                                 name:SEApplicationDidChangeNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didCreateEntry:)
                                                 name:SEEntriesManagerDidCreateEntryNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didCreateWeakEntry:)
                                                 name:SEEntriesManagerDidCreateWeakEntryNotification
                                               object:nil];
  }
  return self;
}

- (void)dealloc {
  [se_content release];
  [se_overwrite release];
  if (se_plugins)
    NSFreeMapTable(se_plugins);
  [[NSNotificationCenter defaultCenter] removeObserver:self];
  [super dealloc];
}

- (void)awakeFromNib {
  /* Configure Library Header Cell */
  SEHeaderCell *header = [[SEHeaderCell alloc] initTextCell:@"HotKey Groups"];
  [header setAlignment:NSCenterTextAlignment];
  [header setFont:[NSFont systemFontOfSize:11]];
  [[[table tableColumns] objectAtIndex:0] setHeaderCell:header];
  [header release];
  [table setCornerView:[[[SEHeaderCellCorner alloc] init] autorelease]];

  [table setHighlightShading:[NSColor colorWithDeviceRed:.340f
                                                   green:.606f
                                                    blue:.890f
                                                   alpha:1]
                      bottom:[NSColor colorWithDeviceRed:0
                                                   green:.312f
                                                    blue:.790f
                                                   alpha:1]
                      border:[NSColor colorWithDeviceRed:.239f
                                                   green:.482f
                                                    blue:.855f
                                                   alpha:1]];
  
  if (se_delegate)
    [self tableViewSelectionDidChange:nil];
}

- (id)delegate {
  return se_delegate;
}

- (void)setDelegate:(id)aDelegate {
  se_delegate = aDelegate;
}

- (void)rearrangeObjects {
  [se_content sortUsingFunction:SECompareList context:NULL];
}

- (id)objectAtIndex:(unsigned)idx {
  return [se_content objectAtIndex:idx];
}

- (SparkPlugIn *)pluginForList:(SparkList *)aList {
  return NSMapGet(se_plugins, aList);
}
- (SparkList *)listForPlugin:(SparkPlugIn *)aPlugin {
  for (unsigned idx = 0; idx < [se_content count]; idx++) {
    SparkList *list = [se_content objectAtIndex:idx];
    if ([list filterContext] == [aPlugin actionClass])
      return list;
  }
  return nil;
}

- (void)addObject:(SparkObject *)object {
  [se_content addObject:object];
}

- (void)addObjects:(NSArray *)objects {
  [se_content addObjectsFromArray:objects];
}

- (int)numberOfRowsInTableView:(NSTableView *)tableView {
  return [se_content count];
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(int)row {
  return [se_content objectAtIndex:row];
}

- (void)tableView:(NSTableView *)tableView setObjectValue:(id)object forTableColumn:(NSTableColumn *)tableColumn row:(int)row {
  SparkObject *item = [se_content objectAtIndex:row];
  NSString *name = [item name];
  if (![name isEqualToString:object]) {
    [item setName:object];
    [self rearrangeObjects];
    
    //  [tableView reloadData]; => End editing already call reload data.
    [tableView selectRowIndexes:[NSIndexSet indexSetWithIndex:[se_content indexOfObjectIdenticalTo:item]] byExtendingSelection:NO];
  }
}

- (BOOL)tableView:(NSTableView *)aTableView shouldEditTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex {
  if (rowIndex >= 0) {
    SparkObject *item = [se_content objectAtIndex:rowIndex];
    return [item uid] > kSparkLibraryReserved;
  }
  return NO;
}

- (IBAction)newList:(id)sender {
  SparkList *list = [[SparkList alloc] initWithName:@"New List"];
  [SparkSharedListSet() addObject:list];
  [list release];
  [se_content addObject:list];
  [self rearrangeObjects];
  [table reloadData];
  /* Edit new list name */
  unsigned idx = [se_content indexOfObjectIdenticalTo:list];
  [table selectRow:idx byExtendingSelection:NO];
  [table editColumn:0 row:idx withEvent:nil select:YES];
}

- (void)deleteSelectionInTableView:(NSTableView *)aTableView {
  int idx = [aTableView selectedRow];
  if (idx >= 0) {
    SparkObject *object = [se_content objectAtIndex:idx];
    if ([object uid] > kSparkLibraryReserved) {
      [SparkSharedListSet() removeObject:object];
      [se_content removeObjectAtIndex:idx];
      [aTableView reloadData];
      /* last item */
      if ((unsigned)idx == [se_content count]) {
        [aTableView selectRow:[se_content count] - 1 byExtendingSelection:NO];
      }
      if (idx == [aTableView selectedRow]) {
        [[NSNotificationCenter defaultCenter] postNotificationName:NSTableViewSelectionDidChangeNotification
                                                            object:aTableView];
      }
    } else {
      NSBeep();
    }
  }
}

- (void)tableViewSelectionDidChange:(NSNotification *)aNotification {
  int idx = [table selectedRow];
  if (idx >= 0) {
    if (SKDelegateHandle(se_delegate, source:didChangeSelection:)) {
      [se_delegate source:self didChangeSelection:[se_content objectAtIndex:idx]];
    }
  }
}

/* Separator Implementation */
- (float)tableView:(NSTableView *)tableView heightOfRow:(int)row {
  return row >= 0 && (unsigned)row < [se_content count] && [[[se_content objectAtIndex:row] name] isEqualToString:SETableSeparator] ? 1 : [tableView rowHeight];
}
- (BOOL)tableView:(NSTableView *)aTableView shouldSelectRow:(int)rowIndex {
  return rowIndex >= 0 && (unsigned)rowIndex < [se_content count] ? ![[[se_content objectAtIndex:rowIndex] name] isEqualToString:SETableSeparator] : YES;
}

- (void)applicationDidChange:(NSNotification *)aNotification {
  SEEntriesManager *manager = [aNotification object];
  if ([[manager application] uid]) {
    [se_overwrite setName:[[manager application] name]];
    [se_overwrite setIcon:[[manager application] icon]];
    if (![se_content containsObjectIdenticalTo:se_overwrite]) {
      int row = [table selectedRow];
      [se_content insertObject:se_overwrite atIndex:1];
      [table reloadData];
      /* Preserve selection */
      if (row >= 1 && (row + 1)< (int)[se_content count]) {
        [table selectRow:row + 1 byExtendingSelection:NO];
      }
    } else {
      int idx = [se_content indexOfObjectIdenticalTo:se_overwrite];
      [table setNeedsDisplayInRect:[table frameOfCellAtColumn:0 row:idx]];
    }
  } else {
    int idx = [se_content indexOfObjectIdenticalTo:se_overwrite];
    if (NSNotFound != idx) {
      int row = [table selectedRow];
      [se_content removeObjectAtIndex:idx];
      if (row >= idx && row != 0) {
        [table selectRow:row - 1 byExtendingSelection:NO];
      }
      [table reloadData];
    }
  }
}

- (void)didReloadEntries:(NSNotification *)aNotification {
  /* Reload dynamic lists (plugins + overwrite) */
  [se_overwrite reload];
  /* Reload library to notify list change */
  [[se_content objectAtIndex:0] reload];
  [NSAllMapTableKeys(se_plugins) makeObjectsPerformSelector:@selector(reload)];
}

- (void)didCreateWeakEntry:(NSNotification *)aNotification {
  /* Reload dynamic lists (plugins + overwrite) */
  [se_overwrite reload];
}

/* Adjust list selection */
- (void)didCreateEntry:(NSNotification *)aNotification {
  unsigned idx = [table selectedRow];
  if (idx >= 0) {
    SparkList *list = [se_content objectAtIndex:idx];
    SparkEntry *entry = [aNotification object];
    if (![list isDynamic]) {
      [list addObject:[entry trigger]];
    } else if (NSMapMember(se_plugins, list, NULL, NULL)) {
      SparkPlugIn *plugin = [[SparkActionLoader sharedLoader] plugInForAction:[entry action]];
      if (![plugin isEqual:[self pluginForList:list]]) {
        // select plugin list
        SparkList *plist = [self listForPlugin:plugin];
        if (plist) {
          idx = [se_content indexOfObject:plist];
          [table selectRow:idx byExtendingSelection:NO];
        }
      }
    }
  }
  
}

@end
