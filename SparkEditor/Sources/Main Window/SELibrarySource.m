/*
 *  SELibrarySource.m
 *  Spark Editor
 *
 *  Created by Black Moon Team.
 *  Copyright (c) 2004 - 2007 Shadow Lab. All rights reserved.
 */

#import "SELibrarySource.h"
#import "Spark.h"
#import "SETableView.h"
#import "SEEntryList.h"
#import "SEHeaderCell.h"
#import "SELibraryWindow.h"
#import "SELibraryDocument.h"
#import "SETriggersController.h"

#import <SparkKit/SparkList.h>
#import <SparkKit/SparkEntry.h>
#import <SparkKit/SparkTrigger.h>
#import <SparkKit/SparkLibrary.h>
#import <SparkKit/SparkObjectSet.h>
#import <SparkKit/SparkApplication.h>
#import <SparkKit/SparkEntryManager.h>


#import <SparkKit/SparkPlugIn.h>
#import <SparkKit/SparkActionLoader.h>

#import <ShadowKit/SKExtensions.h>
#import <ShadowKit/SKAppKitExtensions.h>

static
BOOL SELibraryFilter(SparkList *list, SparkEntry *entry, id ctxt) {
  return YES;
}

static
BOOL SEPluginFilter(SparkList *list, SparkEntry *object, Class cls) {
  return [[object action] isKindOfClass:cls];
}

static
BOOL SEOverwriteFilter(SparkList *list, SparkEntry *entry, id ctxt) {
  return [entry type] != kSparkEntryTypeDefault;
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
  [[NSNotificationCenter defaultCenter] removeObserver:self];
	/* setLibrary:nil take care if this for us */
//  if (se_plugins) NSFreeMapTable(se_plugins);
//  [se_overwrite release];
  [self setLibrary:nil];
  [super dealloc];
}

#pragma mark -
- (SELibraryDocument *)document {
  return [ibWindow document];
}

- (void)addUserEntryList:(SparkList *)list {
	[list addObserver:self forKeyPath:@"name" options:NSKeyValueObservingOptionNew context:nil];
	SEEntryList *elist = [[SEEntryList alloc] initWithList:list];
	[elist setGroup:[list isDynamic] ? 5 : 6];
	[self addObject:elist];
	[elist release];
}

/* Create and update plugins list */
- (void)buildPluginLists {
  [self setSelectsInsertedObjects:NO];
  
  NSArray *plugins = [[SparkActionLoader sharedLoader] plugins];
  if (se_plugins) {
    [self removeObjects:NSAllMapTableKeys(se_plugins)];
    NSResetMapTable(se_plugins);
  } else {
		/* library objects used UID for hash. SEEntryLists do not have uid, we have to use a custom hash function */
		NSMapTableKeyCallBacks cb = NSObjectMapKeyCallBacks;
		cb.hash = NSOwnedPointerMapKeyCallBacks.hash;
		cb.isEqual = NSOwnedPointerMapKeyCallBacks.isEqual;
		se_plugins = NSCreateMapTable(cb, NSObjectMapValueCallBacks, [plugins count]);
  }
  
  NSUInteger idx = [plugins count];
  while (idx-- > 0) {
    SparkPlugIn *plugin = [plugins objectAtIndex:idx];
    if ([plugin isEnabled]) {
      SEEntryList *list = [[SEEntryList alloc] initWithName:[plugin name] icon:[plugin icon]];
      [list setDocument:[self document]];
      [list setListFilter:SEPluginFilter context:[plugin actionClass]];
      [list setGroup:3];
      NSMapInsertKnownAbsent(se_plugins, list, plugin);
      
      [self addObject:list];
      [list release];
    }
  }
  [self setSelectsInsertedObjects:YES];
}

- (void)buildLists {
  /* Add library… */
  SEEntryList *library = [[SEEntryList alloc] initWithName:NSLocalizedString(@"Library", @"Library list name")
                                                      icon:[NSImage imageNamed:@"SELibrary"]];
  [library setDocument:[self document]];
  [library setListFilter:SELibraryFilter context:nil];
  [library setGroup:0];
  [self addObject:library];
  [library release];
  
  /* …, plugins list… */
  [self buildPluginLists];
  
	[self setSelectsInsertedObjects:NO];
  /* …and User defined lists */
  SparkList *user = nil;
  NSEnumerator *users = [se_library listEnumerator];
  while (user = [users nextObject]) {
    [self addUserEntryList:user];
  }
	
  /* Overwrite list */
  se_overwrite = [[SEEntryList alloc] initWithName:@"Overwrite" icon:[NSImage imageNamed:@"application"]];
  [se_overwrite setDocument:[self document]];
  [se_overwrite setListFilter:SEOverwriteFilter context:nil];
	[se_overwrite setSpecificFilter:YES];
  [se_overwrite setGroup:1];
  
  /* First Separators */
  SEEntryList *separator = [SEEntryList separatorList];
  [separator setGroup:2];
  [self addObject:separator];
  
  /* Second Separators */
  separator = [SEEntryList separatorList];
  [separator setGroup:4];
  [self addObject:separator];
  
	[self setSelectsInsertedObjects:YES];
	
  [self rearrangeObjects];
}

- (void)setLibrary:(SparkLibrary *)aLibrary {
  if (se_library) {
    [[se_library notificationCenter] removeObserver:self];
    
    /* Cleanup */
		NSArray *lists = [self arrangedObjects];
		NSUInteger idx = [lists count];
		while (idx-- > 0) {
			SEEntryList *list = [lists objectAtIndex:idx];
			if ([list group] > 4) {
				[[list sparkList] removeObserver:self forKeyPath:@"name"];
			}
		}
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
		
		/* Entry manager change */
		SparkEntryManager *manager = [se_library entryManager];
		
		[[se_library notificationCenter] addObserver:self
																				selector:@selector(reloadSelection:) 
																						name:SparkEntryManagerDidAddEntryNotification
																					object:manager];
		[[se_library notificationCenter] addObserver:self
																				selector:@selector(reloadSelection:) 
																						name:SparkEntryManagerDidUpdateEntryNotification
																					object:manager];
		[[se_library notificationCenter] addObserver:self
																				selector:@selector(reloadSelection:) 
																						name:SparkEntryManagerDidRemoveEntryNotification
																					object:manager];
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
      NSArray *uids = [pboard objectForKey:@"entries"];
			SparkEntryManager *manager = [library entryManager];
      NSMutableArray *items = [[NSMutableArray alloc] init];
      for (NSUInteger idx = 0; idx < [uids count]; idx++) {
				NSNumber *uid = [uids objectAtIndex:idx];
        SparkEntry *entry = [manager entryWithUID:SKIntegerValue(uid)];
				if (entry) {
					[items addObject:entry];
				}
      }
      if ([items count]) {
				SparkList *list = [[self objectAtIndex:row] sparkList];
        [list addEntriesFromArray:items];
      }
      [items release];
    }
    return YES;
  }
  return NO;
}

#pragma mark Actions
- (NSUInteger)indexOfUserList:(SparkList *)aList {
	NSArray *lists = [self arrangedObjects];
	for (NSUInteger idx = 0; idx < [lists count]; idx++) {
		SEEntryList *elist = [lists objectAtIndex:idx];
		if ([elist group] > 4 && [[elist sparkList] isEqual:aList])
			return idx;
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
    SEEntryList *list = [self objectAtIndex:idx];
    if ([list isEditable]) {
      /* Remove list from library */
      [[[self library] listSet] removeObject:[list sparkList]];
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
	/* reload list contents if needed */
	SparkApplication *application = [[aNotification object] application];
	[[self arrangedObjects] makeObjectsPerformSelector:@selector(setApplication:) withObject:application];
	
  /* If should add list */
  if ([application uid]) {
    [se_overwrite setName:[application name]];
    [se_overwrite setIcon:[application icon]];
    /* If list is not in data source, add it and adjust selection */
    if (![[self arrangedObjects] containsObjectIdenticalTo:se_overwrite]) {
      [self setSelectsInsertedObjects:NO];
			[se_overwrite setApplication:application];
			
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
	
	/* refresh */
	SparkApplication *previous = [[aNotification userInfo] objectForKey:SEPreviousApplicationKey];
	if (!previous || ![[[[aNotification object] library] applicationSet] containsObject:previous]) {
		[[self selectedObject] snapshot];
	} else {
		/* Reload when switching to/from global */
		if ([application uid] == 0 || [previous uid] == 0) {
			[[self selectedObject] snapshot];
		} else {
			/* Reload if previous or current contains custom entries */
			SparkEntryManager *manager = [[[aNotification object] library] entryManager];
			if ([manager containsEntryForApplication:previous] || [manager containsEntryForApplication:application]) {
				/* I don't understand why snapshot does not trigger a reload in trigger controller, so force it to reload */
				[[self selectedObject] snapshot];
			}
		}
	}
}

- (void)didAddList:(NSNotification *)aNotification {
	SparkList *list = SparkNotificationObject(aNotification);
	[self addUserEntryList:list];
  [self rearrangeObjects];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
	if ([@"name" isEqualToString:keyPath]) {
		if ([self indexOfUserList:object] != NSNotFound)
			[self rearrangeObjects];
	} else {
		[super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
	}
}

- (void)willRemoveList:(NSNotification *)aNotification {
	SparkList *list = SparkNotificationObject(aNotification);
  NSUInteger idx = [self indexOfUserList:list];
  if (idx != NSNotFound) {
		[list removeObserver:self forKeyPath:@"name"];
    [self removeObjectAtArrangedObjectIndex:idx];
    [self checkSelection];
  }
}

- (void)reloadSelection:(NSNotification *)aNotification {
	[[self selectedObject] snapshot];
}

@end
