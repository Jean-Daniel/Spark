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
#import <SparkKit/SparkObjectSet.h>
#import <SparkKit/SparkEntryManager.h>

#import <SparkKit/SparkPlugIn.h>
#import <SparkKit/SparkActionLoader.h>

#import <ShadowKit/SKExtensions.h>
#import <ShadowKit/SKAppKitExtensions.h>

static
BOOL SELibraryFilter(SEEntryList *list, SparkEntry *object, id ctxt) {
  return YES;
}

static
BOOL SEPluginFilter(SEEntryList *list, SparkEntry *object, Class cls) {
  return [[object action] isKindOfClass:cls];
}

static
BOOL SEOverwriteFilter(SEEntryList *list, SparkEntry *object, SparkApplication *app) {
  return [[object application] uid] != 0;
}

#pragma mark -
#pragma mark Implementation
@implementation SELibrarySource

#pragma mark -
- (void)se_init {
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

- (id)init {
  if (self = [super init]) {
    [self se_init];
  }
  return self;
}

- (id)initWithCoder:(NSCoder *)aCoder {
  if (self = [super initWithCoder:aCoder]) {
    [self se_init];
  }
  return self;
}

- (void)dealloc {
  [self setLibrary:nil];
  
  /* should be useless */
  if (se_plugins)
    NSFreeMapTable(se_plugins);
  [se_overwrite release];
  
  [[NSNotificationCenter defaultCenter] removeObserver:self];
  [super dealloc];
}

- (void)addUserEntryList:(SEUserEntryList *)list {
  [list setDocument:[ibWindow document]];
  [list setGroup:5];
  [self addObject:list];
}

/* Create and update plugins list */
- (void)buildPluginLists {
  [self setSelectsInsertedObjects:NO];
  
  NSArray *plugins = [[SparkActionLoader sharedLoader] plugins];
  if (se_plugins) {
    [self removeObjects:NSAllMapTableKeys(se_plugins)];
    NSResetMapTable(se_plugins);
  } else {
    se_plugins = NSCreateMapTable(NSObjectMapKeyCallBacks, NSObjectMapValueCallBacks, [plugins count]);
  }
  
  NSUInteger idx = [plugins count];
  while (idx-- > 0) {
    SparkPlugIn *plugin = [plugins objectAtIndex:idx];
    if ([plugin isEnabled]) {
      SESmartEntryList *list = [[SESmartEntryList alloc] initWithName:[plugin name] icon:[plugin icon]];
      [list setListFilter:SEPluginFilter context:[plugin actionClass]];
      [list setDocument:[ibWindow document]];
      [list setGroup:3];
      NSMapInsert(se_plugins, list, plugin);
      
      [self addObject:list];
      [list release];
    }
  }
  [self setSelectsInsertedObjects:YES];
}

- (void)buildLists {
  /* Add library… */
  SESmartEntryList *library = [[SESmartEntryList alloc] initWithName:NSLocalizedString(@"Library", @"Library list name")
                                                                icon:[NSImage imageNamed:@"SELibrary"]];
  [library setListFilter:SELibraryFilter context:nil];
  [library setDocument:[ibWindow document]];
  [library setGroup:0];
  [self addObject:library];
  [library release];
  
  /* …, plugins list… */
  [self buildPluginLists];
  
  /* …and User defined lists */
  SparkList *user = nil;
  NSEnumerator *users = [[se_library listSet] objectEnumerator];
  while (user = [users nextObject]) {
    SEUserEntryList *list = [[SEUserEntryList alloc] initWithList:user];
    [self addUserEntryList:list];
    [list release];
  }
  
  /* Overwrite list */
  se_overwrite = [[SESmartEntryList alloc] initWithName:@"Overwrite" icon:[NSImage imageNamed:@"application"]];
  [se_overwrite setListFilter:SEOverwriteFilter context:nil];
  [se_overwrite setDocument:[ibWindow document]];
  [se_overwrite setGroup:1];
  
  /* First Separators */
  SEEntryList *separator = [[SEEntryList alloc] initWithName:SETableSeparator icon:nil];
  [separator setGroup:2];
  [self addObject:separator];
  [separator release];
  
  /* Second Separators */
  separator = [[SEEntryList alloc] initWithName:SETableSeparator icon:nil];
  [separator setGroup:4];
  [self addObject:separator];
  [separator release];
  
  [self rearrangeObjects];
}

- (void)setLibrary:(SparkLibrary *)aLibrary {
  if (se_library) {
    [[se_library notificationCenter] removeObserver:self];
    
    /* Cleanup */
    [self removeAllObjects];
    /* Free plugin <=> lists map */
    if (se_plugins) {
      NSFreeMapTable(se_plugins);
      se_plugins = nil;
    }
    /* Free 'overwrite' special list */
    [se_overwrite release];
    se_overwrite = nil;
    
    [se_library release];
  }
  se_library = [aLibrary retain];
  if (se_library) {
    [self buildLists];
    /* Register for notifications */
    [[se_library notificationCenter] addObserver:self
                                        selector:@selector(applicationDidChange:)
                                            name:SEApplicationDidChangeNotification
                                          object:[ibWindow document]];
    
    [[se_library notificationCenter] addObserver:self
                                        selector:@selector(didAddList:)
                                            name:SparkObjectSetDidAddObjectNotification
                                          object:[se_library listSet]];
    [[se_library notificationCenter] addObserver:self
                                        selector:@selector(willRemoveList:)
                                            name:SparkObjectSetWillRemoveObjectNotification
                                          object:[se_library listSet]];
    
    [[se_library notificationCenter] addObserver:self
                                        selector:@selector(didRenameList:)
                                            name:SEEntryListDidChangeNameNotification
                                          object:se_library];
  }
}

- (void)awakeFromNib {
  /* Configure Library Header Cell */
  SEHeaderCell *header = [[SEHeaderCell alloc] initTextCell:NSLocalizedString(@"HotKey Groups", @"Library Header Cell")];
  [header setAlignment:NSCenterTextAlignment];
  [header setFont:[NSFont systemFontOfSize:11]];
  [[[uiTable tableColumns] objectAtIndex:0] setHeaderCell:header];
  [header release];
  [uiTable setCornerView:[[[SEHeaderCellCorner alloc] init] autorelease]];
  
  NSSortDescriptor *group = [[NSSortDescriptor alloc] initWithKey:@"representation" ascending:YES];
  [uiTable setSortDescriptors:[NSArray arrayWithObject:group]];
  [group release];
  
  //  NSRect rect = [[uiTable headerView] frame];
  //  rect.size.height += 1;
  //  [[uiTable headerView] setFrame:rect];
  [uiTable registerForDraggedTypes:[NSArray arrayWithObject:SparkEntriesPboardType]];
}

#pragma mark -
- (SparkLibrary *)library {
  return se_library;
}

- (SEEntryList *)listForPlugin:(SparkPlugIn *)aPlugin {
  if (!se_plugins) return nil;
  
  SEEntryList *list = nil;
  SparkPlugIn *plugin = nil;
  NSMapEnumerator iter = NSEnumerateMapTable(se_plugins);
  while (NSNextMapEnumeratorPair(&iter, (void **)&list, (void **)&plugin)) {
    if ([aPlugin isEqual:plugin])
      break;
    else
      list = nil;
  }
  NSEndMapTableEnumeration(&iter);
  
  return list;
}

- (SparkPlugIn *)pluginForList:(SEEntryList *)aList {
  return se_plugins ? NSMapGet(se_plugins, aList) : nil;
}

#pragma mark Data Source
- (void)tableView:(NSTableView *)tableView setObjectValue:(id)object forTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
  // useless with bindings, but needed to activate "option + click" editing with SKTableView.
}

- (BOOL)tableView:(NSTableView *)aTableView shouldEditTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex {
  if (rowIndex >= 0) {
    SEEntryList *item = [self objectAtIndex:rowIndex];
    return [item isEditable];
  }
  return NO;
}

#pragma mark Drag & Drop
/* Allow drop only in editable list (uid > kSparkLibraryReserved && not dynamic) */
- (NSDragOperation)tableView:(NSTableView *)aTableView validateDrop:(id <NSDraggingInfo>)info proposedRow:(NSInteger)row proposedDropOperation:(NSTableViewDropOperation)operation {
  if (NSTableViewDropOn == operation) {
    SEEntryList *list = [self objectAtIndex:row];
    if ([list isEditable] && [[[info draggingPasteboard] types] containsObject:SparkEntriesPboardType])
      return NSDragOperationCopy;
  }
  return NSDragOperationNone;
}

/* Add entries trigger into the target list */
- (BOOL)tableView:(NSTableView *)aTableView acceptDrop:(id <NSDraggingInfo>)info row:(NSInteger)row dropOperation:(NSTableViewDropOperation)operation {
  if (NSTableViewDropOn == operation) {
    NSDictionary *pboard = [[info draggingPasteboard] propertyListForType:SparkEntriesPboardType];
    CFUUIDBytes bytes;
    SparkLibrary *library = nil;
    SELibraryDocument *doc = nil;
    [[pboard objectForKey:@"uuid"] getBytes:&bytes length:sizeof(bytes)];
    CFUUIDRef uuid = CFUUIDCreateFromUUIDBytes(kCFAllocatorDefault, bytes);
    if (uuid) {
      library = SparkLibraryGetLibraryWithUUID(uuid);
      doc = library ? SEGetDocumentForLibrary(library) : nil;
      CFRelease(uuid);
    }
    
    if (doc) {
      SEEntryCache *cache = [doc cache];
      SESparkEntrySet *entries = [cache entries];
      NSArray *uids = [pboard objectForKey:@"triggers"];
      NSMutableArray *items = [[NSMutableArray alloc] init];
      for (NSUInteger idx = 0; idx < [uids count]; idx++) {
        NSNumber *uid = [uids objectAtIndex:idx];
        SparkTrigger *trigger = [library triggerWithUID:[uid unsignedIntValue]];
        if (trigger) {
          SparkEntry *entry = [entries entryForTrigger:trigger];
          if (entry)
            [items addObject:entry];
        }
      }
      if ([items count]) {
        [[self objectAtIndex:row] addEntries:items];
      }
      [items release];
    }
    return YES;
  }
  return NO;
}

#pragma mark Actions
- (NSUInteger)indexOfUserList:(SparkList *)aList {
  NSUInteger idx = [self count];
  while (idx-- > 0) {
    SEEntryList *list = [self objectAtIndex:idx];
    if ([list isKindOfClass:[SEUserEntryList class]] && [[(id)list list] isEqual:aList]) {
      return idx;
    }
  }
  return NSNotFound;
}

- (IBAction)newGroup:(id)sender {
  SparkList *list = [[SparkList alloc] initWithName:NSLocalizedString(@"<New Group>", @"New List default name")];
  [[[self library] listSet] addObject:list];
  [list release];
  
  /* Edit new list name */
  NSUInteger idx = [self indexOfUserList:list];
  if (idx != NSNotFound) {
    @try {
      [uiTable editColumn:0 row:idx withEvent:nil select:YES];
    } @catch (id exception) {
      SKLogException(exception);
    }
  }
}

- (IBAction)selectLibrary:(id)sender {
  [self setSelectionIndex:0];
}

- (IBAction)selectApplicationList:(id)sender {
  NSUInteger idx = [[self arrangedObjects] indexOfObject:se_overwrite];
  if (idx != NSNotFound)
    [self setSelectionIndex:idx];
}

- (void)selectListForAction:(SparkAction *)anAction {
  SparkPlugIn *plugin = [[SparkActionLoader sharedLoader] plugInForAction:anAction];
  if (plugin) {
    SEEntryList *list = [self listForPlugin:plugin];
    if (list) {
      [self setSelectedObject:list];
    }
  }
}

#pragma mark Delegate
- (void)deleteSelectionInTableView:(NSTableView *)aTableView {
  NSUInteger idx = [self selectionIndex];
  if (idx != NSNotFound) {
    SEUserEntryList *list = [self objectAtIndex:idx];
    if ([list isEditable]) {
      /* Remove list from library */
      [[[self library] listSet] removeObject:[list list]];
    } else {
      NSBeep();
    }
  }
}

/* Separator Implementation */
- (CGFloat)tableView:(NSTableView *)tableView heightOfRow:(NSInteger)row {
  return row >= 0 && (NSUInteger)row < [self count] && [[[self objectAtIndex:row] name] isEqualToString:SETableSeparator] ? 1 : [tableView rowHeight];
}
- (BOOL)tableView:(NSTableView *)aTableView shouldSelectRow:(NSInteger)rowIndex {
  return rowIndex >= 0 && (NSUInteger)rowIndex < [self count] ? ![[[self objectAtIndex:rowIndex] name] isEqualToString:SETableSeparator] : YES;
}

#pragma mark Notifications
- (void)checkSelection {
  NSUInteger idx = [self selectionIndex];
  if (idx != NSNotFound) {
    NSUInteger row = idx;
    while (idx > 0) {
      SEEntryList *list = [self objectAtIndex:idx];
      if ([[list name] isEqualToString:SETableSeparator]) {
        idx--;
      } else {
        break;
      }
    }
    if (row != idx)
      [self setSelectionIndex:idx];
  }
}

- (void)didChangePluginList:(NSNotification *)aNotification {
  [self buildPluginLists];
  [self rearrangeObjects];
  [self checkSelection];
  /* Change row height */
  [uiTable reloadData];
}

/* This method insert, update and remove the 'current application' list */
- (void)applicationDidChange:(NSNotification *)aNotification {
  SELibraryDocument *document = [aNotification object];
  /* If should add list */
  if ([[document application] uid]) {
    [se_overwrite setName:[[document application] name]];
    [se_overwrite setIcon:[[document application] icon]];
    /* If list is not in data source, add it and adjust selection */
    if (![[self arrangedObjects] containsObjectIdenticalTo:se_overwrite]) {
      [self setSelectsInsertedObjects:NO];
      [self insertObject:se_overwrite atArrangedObjectIndex:1];
      /* Some Row height changed */
      [uiTable reloadData];
      [self setSelectsInsertedObjects:YES];
    }
  } else {
    NSUInteger idx = [[self arrangedObjects] indexOfObjectIdenticalTo:se_overwrite];
    /* List should be removed */
    if (NSNotFound != idx) {
      [self removeObjectAtArrangedObjectIndex:idx];
      [self checkSelection];
      /* Some Row height changed */
      [uiTable reloadData];
    }
  }
}

- (void)didAddList:(NSNotification *)aNotification {
  SparkList *list = SparkNotificationObject(aNotification);
  SEUserEntryList *user = [[SEUserEntryList alloc] initWithList:list];
  [self addUserEntryList:user];
  [user release];
  
  [self rearrangeObjects];
}

- (void)didRenameList:(NSNotification *)aNotification {
  NSUInteger idx = [self indexOfUserList:SparkNotificationObject(aNotification)];
  if (idx != NSNotFound) {
    [self rearrangeObjects];
  }
}

- (void)willRemoveList:(NSNotification *)aNotification {
  NSUInteger idx = [self indexOfUserList:SparkNotificationObject(aNotification)];
  if (idx != NSNotFound) {
    [self removeObjectAtArrangedObjectIndex:idx];
    [self checkSelection];
  }
}

@end
