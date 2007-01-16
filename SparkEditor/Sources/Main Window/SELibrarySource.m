/*
 *  SELibrarySource.m
 *  Spark Editor
 *
 *  Created by Black Moon Team.
 *  Copyright (c) 2004 - 2006, Shadow Lab. All rights reserved.
 */

#import "SELibrarySource.h"
#import "Spark.h"
#import "SETableView.h"
#import "SEHeaderCell.h"
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
BOOL SELibraryFilter(SparkObject *object, id ctxt) {
  return YES;
}

static 
BOOL SEOverwriteListFilter(SparkObject *object, SELibraryDocument *ctxt) {
  SparkApplication *app = [ctxt application];
  SparkEntryManager *manager = [[ctxt library] entryManager];
  return [manager containsEntryForTrigger:[object uid] application:[app uid]];
}

@interface _SEPluginListContext : NSObject {
  @public
  Class kind;
  SELibraryDocument *document;
}
+ (id)listContextWithClass:(Class)cls document:(SELibraryDocument *)doc;
@end

@implementation _SEPluginListContext
+ (id)listContextWithClass:(Class)cls document:(SELibraryDocument *)doc {
  _SEPluginListContext *ctxt = [[self alloc] init];
  ctxt->kind = cls;
  ctxt->document = doc;
  return [ctxt autorelease];
}
@end

static 
BOOL SEPluginListFilter(SparkObject *object, _SEPluginListContext *ctxt) {
  Class kind = ctxt ? ctxt->kind : Nil;
  if (kind) {
    SparkApplication *app = [ctxt->document application];
    SparkEntryManager *manager = [[ctxt->document library] entryManager];
    /* Get action for selected application */
    SparkAction *action = [manager actionForTrigger:[object uid] application:[app uid] isActive:NULL];
    /* If action not found, search default action */
    if (!action && [app uid] != 0)
      action = [manager actionForTrigger:[object uid] application:0 isActive:NULL];
    if (action)
      return [action isKindOfClass:kind];
  }
  return NO;
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
      SparkList *list = [[SparkList alloc] initWithName:[plugin name] icon:[plugin icon]];
      [list setObjectSet:[se_library triggerSet]];
      [list setUID:uid++]; // UID MUST BE set before insertion, since -hash use it.
      NSMapInsert(se_plugins, list, plugin);
      [list setListFilter:SEPluginListFilter context:[_SEPluginListContext listContextWithClass:[plugin actionClass]
                                                                                       document:[ibWindow document]]];
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
  se_overwrite = [[SparkList alloc] initWithName:@"Overwrite" icon:[NSImage imageNamed:@"application"]];
  [se_overwrite setListFilter:SEOverwriteListFilter context:[ibWindow document]];
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
  //    [[NSNotificationCenter defaultCenter] addObserver:self
  //                                             selector:@selector(didReloadEntries:)
  //                                                 name:SEEntriesManagerDidReloadNotification
  //                                               object:nil];
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
  //    [[NSNotificationCenter defaultCenter] addObserver:self
  //                                             selector:@selector(didCreateEntry:)
  //                                                 name:SEEntriesManagerDidCreateEntryNotification
  //                                               object:nil];
  //    [[NSNotificationCenter defaultCenter] addObserver:self
  //                                             selector:@selector(didCreateWeakEntry:)
  //                                                 name:SEEntriesManagerDidCreateWeakEntryNotification
  //                                               object:nil];
  
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
  for (unsigned idx = 0; idx < [se_content count]; idx++) {
    SparkList *list = [se_content objectAtIndex:idx];
    if ([list filterContext] == [aPlugin actionClass])
      return list;
  }
  return nil;
}

#pragma mark Data Source
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
    for (unsigned idx = 0; idx < [uids count]; idx++) {
      NSNumber *uid = [uids objectAtIndex:idx];
      SparkTrigger *trigger = [triggers objectForUID:[uid unsignedIntValue]];
      if (trigger && ![list containsObject:trigger]) {
        [list addObject:trigger];
      }
    }
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
  [uiTable selectRow:idx byExtendingSelection:NO];
  [uiTable editColumn:0 row:idx withEvent:nil select:YES];
}

#pragma mark Delegate
- (void)deleteSelectionInTableView:(NSTableView *)aTableView {
  int idx = [aTableView selectedRow];
  if (idx >= 0) {
    SparkObject *object = [se_content objectAtIndex:idx];
    if ([object uid] > kSparkLibraryReserved) {
      [[se_library listSet] removeObject:object];
      /* last item */
      if ((unsigned)idx == [se_content count]) {
        while (idx-- > 0) {
          if ([self tableView:aTableView shouldSelectRow:idx]) {
            [aTableView selectRow:idx byExtendingSelection:NO];
            break;
          }
        }
        //[aTableView selectRow:[se_content count] - 1 byExtendingSelection:NO];
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
}

- (void)didAddList:(NSNotification *)aNotification {
  [se_content addObject:SparkNotificationObject(aNotification)];
  [self rearrangeObjects];
  [uiTable reloadData];
}
- (void)didRemoveList:(NSNotification *)aNotification {
  [se_content removeObject:SparkNotificationObject(aNotification)];
  [uiTable reloadData];
}

- (void)didReloadEntries:(NSNotification *)aNotification {
  /* Reload dynamic lists (plugins + overwrite) */
  [se_overwrite reload];
  if ([se_content count]) {
    /* Reload library to notify list change */
    [[se_content objectAtIndex:0] reload];
  }
  if (se_plugins)
    [NSAllMapTableKeys(se_plugins) makeObjectsPerformSelector:@selector(reload)];
}

- (void)didCreateWeakEntry:(NSNotification *)aNotification {
  /* Reload dynamic lists (plugins + overwrite) */
  [se_overwrite reload];
}

/* Adjust list selection */
- (void)didCreateEntry:(NSNotification *)aNotification {
  unsigned idx = [uiTable selectedRow];
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
          [uiTable selectRow:idx byExtendingSelection:NO];
        }
      }
    }
  }
}

@end
