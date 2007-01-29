/*
 *  SELibrarySource.m
 *  Spark Editor
 *
 *  Created by Black Moon Team.
 *  Copyright (c) 2004 - 2007 Shadow Lab. All rights reserved.
 */

#import "SELibrarySource.h"
#import "Spark.h"
#import "SEEntryList.h"
#import "SETableView.h"
#import "SEHeaderCell.h"
#import "SEEntryCache.h"
#import "SESparkEntrySet.h"
#import "SELibraryWindow.h"
#import "SELibraryDocument.h"

#import <SparkKit/SparkList.h>
#import <SparkKit/SparkTrigger.h>
#import <SparkKit/SparkLibrary.h>
#import <SparkKit/SparkEntryManager.h>

#import <SparkKit/SparkPlugIn.h>
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
BOOL SELibraryFilter(SparkList *list, SparkObject *object, id ctxt) {
  return YES;
}

static
BOOL SEOverwriteFilter(SparkList *list, SparkObject *object, SparkApplication *app) {
  SparkEntryManager *manager = [[list library] entryManager];
  return [manager containsEntryForTrigger:[object uid] application:[app uid]];
}

#pragma mark -
#pragma mark Implementation
@implementation SELibrarySource

/* Create and update plugins list */
- (void)buildPluginLists {
  NSArray *plugins = [[SparkActionLoader sharedLoader] plugins];
  if (se_plugins) {
    [se_content removeObjectsInArray:NSAllMapTableKeys(se_plugins)];
    NSResetMapTable(se_plugins);
  } else {
    se_plugins = NSCreateMapTable(NSObjectMapKeyCallBacks, NSObjectMapValueCallBacks, [plugins count]);
  }
  
  unsigned uid = 128;
  unsigned idx = [plugins count];
  while (idx-- > 0) {
    SparkPlugIn *plugin = [plugins objectAtIndex:idx];
    if ([plugin isEnabled]) {
      SparkList *list = [[SEEntryList alloc] initWithDocument:[ibWindow document] kind:plugin];
      [list setObjectSet:[se_library triggerSet]];
      [list setUID:uid++]; // UID MUST BE set before insertion, since -hash use it.
      NSMapInsert(se_plugins, list, plugin);
 
      [se_content addObject:list];
      [list release];
    }
  }
}

- (void)didChangePluginList:(NSNotification *)aNotification {
  int idx = [uiTable selectedRow];
  [self buildPluginLists];
  [self rearrangeObjects];
  [uiTable reloadData];
  /* Adjust selection */
  int row = [uiTable selectedRow];
  while (row > 0) {
    if ([[[se_content objectAtIndex:row] name] isEqualToString:SETableSeparator]) {
      row--;
    } else {
      break;
    }
  }
  if (row != [uiTable selectedRow]) {
    [uiTable selectRow:row byExtendingSelection:NO];
  } else if (idx == row)  {
    [[NSNotificationCenter defaultCenter] postNotificationName:NSTableViewSelectionDidChangeNotification
                                                        object:uiTable];
  }
}

#pragma mark -
- (id)init {
  if (self = [super init]) {
    se_content = [[NSMutableArray alloc] init];
     
    /* Dynamic plugin */
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didChangePluginList:)
                                                 name:SESparkEditorDidChangePluginStatusNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didChangePluginList:)
                                                 name:SparkActionLoaderDidRegisterPlugInNotification
                                               object:nil];
  }
  return self;
}

- (void)dealloc {
  [se_content release];
  [se_pendings release];
  [se_overwrite release];
  if (se_plugins)
    NSFreeMapTable(se_plugins);
  [[se_library notificationCenter] removeObserver:self];
  [se_library release];
  [[NSNotificationCenter defaultCenter] removeObserver:self];
  [super dealloc];
}

- (void)awakeFromNib {
  se_library = [[ibWindow library] retain];
  
  /* Configure Library Header Cell */
  SEHeaderCell *header = [[SEHeaderCell alloc] initTextCell:@"HotKey Groups"];
  [header setAlignment:NSCenterTextAlignment];
  [header setFont:[NSFont systemFontOfSize:11]];
  [[[uiTable tableColumns] objectAtIndex:0] setHeaderCell:header];
  [header release];
  [uiTable setCornerView:[[[SEHeaderCellCorner alloc] init] autorelease]];
  //  NSRect rect = [[uiTable headerView] frame];
  //  rect.size.height += 1;
  //  [[uiTable headerView] setFrame:rect];
  [uiTable registerForDraggedTypes:[NSArray arrayWithObject:SparkTriggerListPboardType]];
  
  [uiTable setHighlightShading:[NSColor colorWithCalibratedRed:.340f
                                                         green:.606f
                                                          blue:.890f
                                                         alpha:1]
                        bottom:[NSColor colorWithCalibratedRed:0
                                                         green:.312f
                                                          blue:.790f
                                                         alpha:1]
                        border:[NSColor colorWithCalibratedRed:.239f
                                                         green:.482f
                                                          blue:.855f
                                                         alpha:1]];
  
  SparkObjectSet *triggers = [se_library triggerSet];
  
  /* Add library… */
  SparkList *library = [SparkList objectWithName:@"Library" icon:[NSImage imageNamed:@"Library"]];
  [library setObjectSet:triggers];
  [library setListFilter:SELibraryFilter context:nil];
  [se_content addObject:library];
  
  /* …, plugins list… */
  [self buildPluginLists];
  
  /* …and User defined lists */
  [se_content addObjectsFromArray:[[se_library listSet] objects]];
  
  /* Overwrite list */
  se_overwrite = [[SEEntryList alloc] initWithName:@"Overwrite" icon:[NSImage imageNamed:@"application"]];
  [se_overwrite setObjectSet:triggers];
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
  
  /* Register for notifications */
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(applicationDidChange:)
                                               name:SEApplicationDidChangeNotification
                                             object:[ibWindow document]];
  
  [[se_library notificationCenter] addObserver:self
                                      selector:@selector(didAddList:)
                                          name:SparkObjectSetDidAddObjectNotification
                                        object:[se_library listSet]];
  [[se_library notificationCenter] addObserver:self
                                      selector:@selector(didRemoveList:)
                                          name:SparkObjectSetDidRemoveObjectNotification
                                        object:[se_library listSet]];
  
  [[se_library notificationCenter] addObserver:self
                                      selector:@selector(didAddEntry:)
                                          name:SEEntryCacheDidAddEntryNotification
                                        object:nil];
  [[se_library notificationCenter] addObserver:self
                                      selector:@selector(didUpdateEntry:)
                                          name:SEEntryCacheDidUpdateEntryNotification
                                        object:nil];
  [[se_library notificationCenter] addObserver:self
                                      selector:@selector(didRemoveEntry:)
                                          name:SEEntryCacheDidRemoveEntryNotification
                                        object:nil];
  
  /* Undo manager listener */
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(willUndo:)
                                               name:NSUndoManagerWillUndoChangeNotification
                                             object:[se_library undoManager]];
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(willUndo:)
                                               name:NSUndoManagerWillRedoChangeNotification
                                             object:[se_library undoManager]];
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(didUndo:)
                                               name:NSUndoManagerDidUndoChangeNotification
                                             object:[se_library undoManager]];
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(didUndo:)
                                               name:NSUndoManagerDidRedoChangeNotification
                                             object:[se_library undoManager]];
  
  /* Tell delegate to reload data */
  if (se_delegate)
    [[NSNotificationCenter defaultCenter] postNotificationName:NSTableViewSelectionDidChangeNotification
                                                        object:uiTable];
}

#pragma mark -
- (id)delegate {
  return se_delegate;
}

- (void)setDelegate:(id)aDelegate {
  se_delegate = aDelegate;
}

- (void)rearrangeObjects {
  [se_content sortUsingFunction:SECompareList context:NULL];
}

- (void)reloadPluginLists {
  /* Reload plugins lists */
  SparkList *list = nil;
  SparkPlugIn *plugin = nil;
  NSMapEnumerator iter = NSEnumerateMapTable(se_plugins);
  while (NSNextMapEnumeratorPair(&iter, (void **)&list, (void **)&plugin)) {
    [list reload];
  }
  NSEndMapTableEnumeration(&iter);
}

- (id)objectAtIndex:(unsigned)idx {
  return [se_content objectAtIndex:idx];
}

- (void)addObject:(SparkObject *)object {
  [se_content addObject:object];
}

- (void)addObjects:(NSArray *)objects {
  [se_content addObjectsFromArray:objects];
}

- (SparkPlugIn *)pluginForList:(SparkList *)aList {
  return NSMapGet(se_plugins, aList);
}
- (SparkList *)listForPlugin:(SparkPlugIn *)aPlugin {
  SparkList *list = nil;
  SparkPlugIn *plugin = nil;
  NSMapEnumerator iter = NSEnumerateMapTable(se_plugins);
  while (NSNextMapEnumeratorPair(&iter, (void **)&list, (void **)&plugin)) {
    if ([plugin isEqual:aPlugin])
      break;
    list = nil;
  }
  NSEndMapTableEnumeration(&iter);
  return list;
}

#pragma mark Data Source
- (int)numberOfRowsInTableView:(NSTableView *)tableView {
  return [se_content count];
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(int)row {
  return [se_content objectAtIndex:row];
}

- (void)setName:(NSString *)name object:(SparkList *)list reload:(BOOL)reload {
  [[[ibWindow undoManager] prepareWithInvocationTarget:self] setName:[list name] object:list reload:YES];
  [list setName:name];
  [self rearrangeObjects];
  if (reload) {
    [uiTable reloadData];
  }
  [uiTable selectRowIndexes:[NSIndexSet indexSetWithIndex:[se_content indexOfObjectIdenticalTo:list]] byExtendingSelection:NO];
}

- (void)tableView:(NSTableView *)tableView setObjectValue:(id)object forTableColumn:(NSTableColumn *)tableColumn row:(int)row {
  SparkList *item = [se_content objectAtIndex:row];
  NSString *name = [item name];
  if (![name isEqualToString:object]) {
    //  [tableView reloadData]; => End editing will call reload data.
    [self setName:object object:item reload:NO];
  }
}

/* Allow editing if not a system list (uid > kSparkLibraryReserved) */
- (BOOL)tableView:(NSTableView *)aTableView shouldEditTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex {
  if (rowIndex >= 0) {
    SparkObject *item = [se_content objectAtIndex:rowIndex];
    return [item uid] > kSparkLibraryReserved;
  }
  return NO;
}

/* Allow drop only in editable list (uid > kSparkLibraryReserved && not dynamic) */
- (NSDragOperation)tableView:(NSTableView *)aTableView validateDrop:(id <NSDraggingInfo>)info proposedRow:(int)row proposedDropOperation:(NSTableViewDropOperation)operation {
  if (NSTableViewDropOn == operation) {
    SparkList *list = [se_content objectAtIndex:row];
    if ([list uid] > kSparkLibraryReserved && ![list isDynamic] && [[[info draggingPasteboard] types] containsObject:SparkTriggerListPboardType])
      return NSDragOperationCopy;
  }
  return NSDragOperationNone;
}

/* Add entries trigger into the target list */
- (BOOL)tableView:(NSTableView *)aTableView acceptDrop:(id <NSDraggingInfo>)info row:(int)row dropOperation:(NSTableViewDropOperation)operation {
  if (NSTableViewDropOn == operation) {
    SparkList *list = [se_content objectAtIndex:row];
    SparkObjectSet *triggers = [se_library triggerSet];
    NSArray *uids = [[info draggingPasteboard] propertyListForType:SparkTriggerListPboardType];
    NSMutableArray *items = [[NSMutableArray alloc] init];
    for (unsigned idx = 0; idx < [uids count]; idx++) {
      NSNumber *uid = [uids objectAtIndex:idx];
      SparkTrigger *trigger = [triggers objectForUID:[uid unsignedIntValue]];
      if (trigger && ![list containsObject:trigger]) {
        [items addObject:trigger];
      }
    }
    if ([items count]) {
      [list addObjectsFromArray:items];
    }
    [items release];
    return YES;
  }
  return NO;
}

#pragma mark Actions
- (IBAction)newList:(id)sender {
  SparkList *list = [[SparkList alloc] initWithName:@"New List"];
  [[se_library listSet] addObject:list];
  [list release];
  
  /* Edit new list name */
  unsigned idx = [se_content indexOfObjectIdenticalTo:list];
  if (idx != NSNotFound) {
    @try {
      [uiTable editColumn:0 row:idx withEvent:nil select:YES];
    } @catch (id exception) {
      SKLogException(exception);
    }
  }
}

#pragma mark Delegate
- (void)deleteSelectionInTableView:(NSTableView *)aTableView {
  int idx = [aTableView selectedRow];
  if (idx >= 0) {
    SparkObject *object = [se_content objectAtIndex:idx];
    if ([object uid] > kSparkLibraryReserved) {
      [[se_library listSet] removeObject:object];
    } else {
      NSBeep();
    }
  }
}

- (void)tableViewSelectionDidChange:(NSNotification *)aNotification {
  int idx = [[aNotification object] selectedRow];
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

#pragma mark Notifications
/* This method insert, update and remove the 'current application' list */
- (void)applicationDidChange:(NSNotification *)aNotification {
  SELibraryDocument *document = [aNotification object];
  /* If should add list */
  if ([[document application] uid]) {
    [se_overwrite setName:[[document application] name]];
    [se_overwrite setIcon:[[document application] icon]];
    /* If list is not in data source, add it and adjust selection */
    if (![se_content containsObjectIdenticalTo:se_overwrite]) {
      int row = [uiTable selectedRow];
      [se_content insertObject:se_overwrite atIndex:1];
      [uiTable reloadData];
      /* Preserve selection */
      if (row >= 1 && (row + 1)< (int)[se_content count]) {
        [uiTable selectRow:row + 1 byExtendingSelection:NO];
      }
    } else {
      /* List already in data source, refresh the list row */
      int idx = [se_content indexOfObjectIdenticalTo:se_overwrite];
      [uiTable setNeedsDisplayInRect:[uiTable frameOfCellAtColumn:0 row:idx]];
    }
    
    if ([se_overwrite count] > 0 || [[[document library] entryManager] containsEntryForApplication:[[document application] uid]]) {
      /* Update se_overwrite content */
      [se_overwrite reloadWithFilter:SEOverwriteFilter context:[document application]];
    }
  } else {
    int idx = [se_content indexOfObjectIdenticalTo:se_overwrite];
    /* List should be removed */
    if (NSNotFound != idx) {
      int row = [uiTable selectedRow];
      [se_content removeObjectAtIndex:idx];
      /* Adjust selection */
      if (row >= idx && row != 0) {
        [uiTable selectRow:row - 1 byExtendingSelection:NO];
      }
      [uiTable reloadData];
    }
  }
  /* Check if need reload plugin lists */
  SparkApplication *app = [document application];
  SparkEntryManager *manager = [[document library] entryManager];
  SparkApplication *previous = [[aNotification userInfo] objectForKey:SEPreviousApplicationKey];
  if (!previous || 
      ([previous uid] != 0 && [manager containsEntryForApplication:[previous uid]]) ||
      ([app uid] != 0 && [manager containsEntryForApplication:[app uid]])) {
    /* Reload plugins lists */
    [self reloadPluginLists];
  }
}

- (void)didAddList:(NSNotification *)aNotification {
  unsigned selection = [uiTable selectedRow];
  SparkList *list = SparkNotificationObject(aNotification);
  [se_content addObject:list];
  [self rearrangeObjects];
  [uiTable reloadData];
  /* Select inserted list */
  unsigned idx = [se_content indexOfObjectIdenticalTo:list];
  if (idx == selection) {
    [[NSNotificationCenter defaultCenter] postNotificationName:NSTableViewSelectionDidChangeNotification
                                                        object:uiTable];
  } else {
    [uiTable selectRow:idx byExtendingSelection:NO];
  }
}
- (void)didRemoveList:(NSNotification *)aNotification {
  int idx = [uiTable selectedRow];
  [se_content removeObject:SparkNotificationObject(aNotification)];
  [uiTable reloadData];
  if (idx >= 0) {
    /* last item */
    if ((unsigned)idx == [se_content count]) {
      /* Find the first selectable row */
      while (idx-- > 0) {
        if ([self tableView:uiTable shouldSelectRow:idx]) {
          [uiTable selectRow:idx byExtendingSelection:NO];
          break;
        }
      }
    }
    if (idx == [uiTable selectedRow]) {
      [[NSNotificationCenter defaultCenter] postNotificationName:NSTableViewSelectionDidChangeNotification
                                                          object:uiTable];
    }
  }
}

#pragma mark Reveals after Undo/Redo
- (void)willUndo:(NSNotification *)aNotification {
  NSAssert(!se_pendings, @"Internal Inconsistency");
  se_pendings = [[NSMutableArray alloc] init];
}

- (void)didUndo:(NSNotification *)aNotification {
  if ([se_pendings count] > 0) {
    [ibWindow revealEntries:se_pendings];
  }
  [se_pendings release];
  se_pendings = nil;
}

- (void)didAddEntry:(NSNotification *)aNotification {
  if (se_pendings) /* Schedule update */
    [se_pendings addObject:SparkNotificationObject(aNotification)];
}

- (void)didUpdateEntry:(NSNotification *)aNotification {
  if (se_pendings) {
    /* Schedule update */
    [se_pendings removeObject:SparkNotificationUpdatedObject(aNotification)];
    [se_pendings addObject:SparkNotificationObject(aNotification)];
  }
}

- (void)didRemoveEntry:(NSNotification *)aNotification {
  if (se_pendings) /* Schedule update */
    [se_pendings removeObject:SparkNotificationObject(aNotification)];
}

@end
