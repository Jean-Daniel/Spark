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
#import "SELibraryWindow.h"
#import "SELibraryDocument.h"
#import "SESeparatorCellView.h"
#import "SETriggersController.h"

#import <SparkKit/SparkList.h>
#import <SparkKit/SparkEntry.h>
#import <SparkKit/SparkAction.h>
#import <SparkKit/SparkTrigger.h>
#import <SparkKit/SparkLibrary.h>
#import <SparkKit/SparkObjectSet.h>
#import <SparkKit/SparkApplication.h>
#import <SparkKit/SparkEntryManager.h>

#import <SparkKit/SparkPlugIn.h>
#import <SparkKit/SparkActionLoader.h>

#import <WonderBox/WonderBox.h>

#pragma mark -
#pragma mark Implementation
@implementation SELibrarySource {
  NSMapTable *se_plugins;
  SparkLibrary *se_library;
  SEEntryList *se_overwrite;
}

#pragma mark -
- (void)se_init {
  /* Dynamic PlugIn */
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(didChangePlugInList:)
                                               name:SESparkEditorDidChangePlugInStatusNotification
                                             object:nil];
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(didChangePlugInList:)
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
//  [se_overwrite release];
  [self setLibrary:nil];
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
}

/* Create and update plugins list */
- (void)buildPlugInLists {
  [self setSelectsInsertedObjects:NO];
  
  NSArray *plugins = [[SparkActionLoader sharedLoader] plugIns];
  if (se_plugins) {
    [self removeObjects:NSAllMapTableKeys(se_plugins)];
    [se_plugins removeAllObjects];
  } else {
    se_plugins = [NSMapTable mapTableWithKeyOptions:NSPointerFunctionsStrongMemory | NSPointerFunctionsObjectPersonality
                                       valueOptions:NSPointerFunctionsStrongMemory | NSPointerFunctionsObjectPersonality];
  }

  for (SparkPlugIn *plugin in plugins) {
    if ([plugin isEnabled]) {
      SEEntryList *list = [[SEEntryList alloc] initWithName:[plugin name] icon:[plugin icon]];
      [list setDocument:[self document]];
      list.filter = ^bool(SparkList *_, SparkEntry *entry) {
        return [entry.action isKindOfClass:[plugin actionClass]];
      };
      [list setGroup:3];
      [se_plugins setObject:plugin forKey:list];
      
      [self addObject:list];
    }
  }
  [self setSelectsInsertedObjects:YES];
}

- (void)buildLists {
  /* Add library… */
  SEEntryList *library = [[SEEntryList alloc] initWithName:NSLocalizedString(@"Library", @"Library list name")
                                                      icon:[NSImage imageNamed:@"SELibrary"]];
  [library setDocument:[self document]];
  library.filter = ^bool(SparkList *list, SparkEntry *entry) {
    return true;
  };
  [library setGroup:0];
  [self addObject:library];
  
  /* …, plugins list… */
  [self buildPlugInLists];
  
	[self setSelectsInsertedObjects:NO];
  /* …and User defined lists */
  [se_library.listSet enumerateObjectsUsingBlock:^(id obj, BOOL *stop) {
    [self addUserEntryList:obj];
  }];
	
  /* Overwrite list */
  se_overwrite = [[SEEntryList alloc] initWithName:@"Overwrite" icon:[NSImage imageNamed:@"application"]];
  [se_overwrite setDocument:[self document]];
  se_overwrite.filter = ^bool(SparkList *list, SparkEntry *entry) {
    return entry.type != kSparkEntryTypeDefault;
  };
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
  [uiTable noteHeightOfRowsWithIndexesChanged:SPXIndexesForCount([self.arrangedObjects count])];
}

- (void)setLibrary:(SparkLibrary *)aLibrary {
  if (se_library) {
    [[se_library notificationCenter] removeObserver:self];
    
    /* Cleanup */
		NSArray *lists = [self arrangedObjects];
		NSInteger idx = [lists count];
		while (idx-- > 0) {
			SEEntryList *list = [lists objectAtIndex:idx];
			if ([list group] > 4) {
				[[list sparkList] removeObserver:self forKeyPath:@"name"];
			}
		}
    [self removeAllObjects];
    /* Free plugin <=> lists map */
    if (se_plugins)
      se_plugins = nil;
    /* Free 'overwrite' special list */
    se_overwrite = nil;
  }
  se_library = aLibrary;
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
  NSSortDescriptor *group = [[NSSortDescriptor alloc] initWithKey:@"representation" ascending:YES];
  self.sortDescriptors = @[ group ];

  [uiTable registerForDraggedTypes:@[SparkEntriesPboardType]];
}

#pragma mark -
- (SparkLibrary *)library {
  return se_library;
}

- (SEEntryList *)listForPlugIn:(SparkPlugIn *)aPlugin {
  if (!se_plugins)
    return nil;

  for (SEEntryList *list in se_plugins) {
    SparkPlugIn *plugin = [se_plugins objectForKey:list];
    if ([aPlugin isEqual:plugin])
      return list;
  }
  
  return nil;
}

- (SparkPlugIn *)plugInForList:(SEEntryList *)aList {
  return se_plugins ? [se_plugins objectForKey:aList] : nil;
}

#pragma mark Data Source
- (void)tableView:(NSTableView *)tableView setObjectValue:(id)object forTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
  // useless with bindings, but needed to activate "option + click" editing with WBTableView.
}

- (BOOL)tableView:(NSTableView *)aTableView shouldEditTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex {
  if (rowIndex >= 0) {
    SEEntryList *item = [self objectAtArrangedObjectIndex:rowIndex];
    return [item isEditable];
  }
  return NO;
}

#pragma mark Drag & Drop
/* Allow drop only in editable list (uid > kSparkLibraryReserved && not dynamic) */
- (NSDragOperation)tableView:(NSTableView *)aTableView validateDrop:(id <NSDraggingInfo>)info proposedRow:(NSInteger)row proposedDropOperation:(NSTableViewDropOperation)operation {
  if (NSTableViewDropOn == operation) {
    SEEntryList *list = [self objectAtArrangedObjectIndex:row];
    if ([list isEditable] && [[[info draggingPasteboard] types] containsObject:SparkEntriesPboardType])
      return NSDragOperationCopy;
  }
  return NSDragOperationNone;
}

/* Add entries trigger into the target list */
- (BOOL)tableView:(NSTableView *)aTableView acceptDrop:(id <NSDraggingInfo>)info row:(NSInteger)row dropOperation:(NSTableViewDropOperation)operation {
  if (NSTableViewDropOn == operation) {
    NSDictionary *pboard = [[info draggingPasteboard] propertyListForType:SparkEntriesPboardType];
    uuid_t bytes;
    SparkLibrary *library = nil;
    SELibraryDocument *doc = nil;
    [[pboard objectForKey:@"uuid"] getBytes:bytes length:sizeof(bytes)];
    NSUUID *uuid = [[NSUUID alloc] initWithUUIDBytes:bytes];
    if (uuid) {
      library = SparkLibraryGetLibraryWithUUID(uuid);
      doc = library ? SEGetDocumentForLibrary(library) : nil;
    }
    
    if (doc) {
      NSArray *uids = [pboard objectForKey:@"entries"];
			SparkEntryManager *manager = [library entryManager];
      NSMutableArray *items = [[NSMutableArray alloc] init];
      for (NSUInteger idx = 0; idx < [uids count]; idx++) {
				NSNumber *uid = [uids objectAtIndex:idx];
        SparkEntry *entry = [manager entryWithUID:(SparkUID)[uid integerValue]];
				if (entry) {
					[items addObject:entry];
				}
      }
      if ([items count]) {
				SparkList *list = [[self objectAtArrangedObjectIndex:row] sparkList];
        [list addEntriesFromArray:items];
      }
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
  
  /* Edit new list name */
  NSUInteger idx = [self indexOfUserList:list];
  if (idx != NSNotFound) {
    @try {
      [uiTable editColumn:0 row:idx withEvent:nil select:YES];
    } @catch (id exception) {
      SPXLogException(exception);
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
    SEEntryList *list = [self listForPlugIn:plugin];
    if (list) {
      [self setSelectedObject:list];
    }
  }
}

#pragma mark Delegate
- (void)deleteSelectionInTableView:(NSTableView *)aTableView {
  NSUInteger idx = [self selectionIndex];
  if (idx != NSNotFound) {
    SEEntryList *list = [self objectAtArrangedObjectIndex:idx];
    if ([list isEditable]) {
      /* Remove list from library */
      [[[self library] listSet] removeObject:[list sparkList]];
    } else {
      NSBeep();
    }
  }
}
- (BOOL)canDeleteSelectionInTableView:(NSTableView *)aTableView {
  NSUInteger idx = [self selectionIndex];
  if (idx != NSNotFound) {
    SEEntryList *list = [self objectAtArrangedObjectIndex:idx];
    if ([list isEditable]) {
      /* Remove list from library */
      return YES;
    }
  }
  return NO;
}

/* Separator Implementation */
- (CGFloat)tableView:(NSTableView *)tableView heightOfRow:(NSInteger)row {
  return row >= 0 && (NSUInteger)row < [self.arrangedObjects count] && [[[self objectAtArrangedObjectIndex:row] name] isEqualToString:SETableSeparator] ? 1 : [tableView rowHeight];
}

- (BOOL)tableView:(NSTableView *)aTableView shouldSelectRow:(NSInteger)rowIndex {
  return rowIndex >= 0 && (NSUInteger)rowIndex < [self.arrangedObjects count] ? ![[[self objectAtArrangedObjectIndex:rowIndex] name] isEqualToString:SETableSeparator] : YES;
}

- (nullable NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(nullable NSTableColumn *)tableColumn row:(NSInteger)row {
  if (row >= 0 && (NSUInteger)row < [self.arrangedObjects count] && [[[self objectAtArrangedObjectIndex:row] name] isEqualToString:SETableSeparator]) {
    return [tableView makeViewWithIdentifier:@"separator" owner:self];
  }
  return [tableView makeViewWithIdentifier:@"default" owner:self];
}

#pragma mark Notifications
- (void)checkSelection {
  NSUInteger idx = [self selectionIndex];
  if (idx != NSNotFound) {
    NSUInteger row = idx;
    while (idx > 0) {
      SEEntryList *list = [self objectAtArrangedObjectIndex:idx];
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

- (void)didChangePlugInList:(NSNotification *)aNotification {
  [self buildPlugInLists];
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
  [uiTable noteHeightOfRowsWithIndexesChanged:SPXIndexesForCount([self.arrangedObjects count])];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
	if ([@"name" isEqualToString:keyPath]) {
		if ([self indexOfUserList:object] != NSNotFound)
			[self rearrangeObjects];
    [uiTable noteHeightOfRowsWithIndexesChanged:SPXIndexesForCount([self.arrangedObjects count])];
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
