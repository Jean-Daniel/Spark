//
//  SELibrarySource.m
//  Spark Editor
//
//  Created by Jean-Daniel Dupas on 31/07/06.
//  Copyright 2006 Adamentium. All rights reserved.
//

#import "SELibrarySource.h"
#import "SETableView.h"
#import "SEHeaderCell.h"
#import "SETriggerEntry.h"
#import "SELibraryWindow.h"

#import <SparkKit/SparkList.h>
#import <SparkKit/SparkPlugIn.h>
#import <SparkKit/SparkLibrary.h>
#import <SparkKit/SparkActionLoader.h>

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

@interface SEPluginFilter : NSObject {
  @private
  Class se_action;
  SETriggerEntrySet *se_triggers;
}

- (Class)actionClass;
- (void)setActionClass:(Class)cls;
- (void)setTriggers:(SETriggerEntrySet *)triggers;

- (BOOL)isValidTrigger:(SparkTrigger *)aTrigger;

@end

static 
BOOL SEPluginListFilter(SparkObject *object, id ctxt) {
  return [ctxt isValidTrigger:(id)object];
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
      NSMapInsert(se_plugins, list, plugin);
      [list setObjectSet:SparkSharedTriggerSet()];
      [list setUID:uid++];
      
      SEPluginFilter *filter = [[SEPluginFilter alloc] init];
      [filter setActionClass:[plugin actionClass]];
      [filter setTriggers:nil];
      [list setListFilter:SEPluginListFilter context:filter];
      [filter release];
      
      [se_content addObject:list];
      [list release];
    }
    /* …and User defined lists */
    [se_content addObjectsFromArray:[SparkSharedListSet() objects]];
    /* Separators */
    SparkObject *separator = [SparkList objectWithName:SETableSeparator icon:nil];
    [separator setUID:10];
    [se_content addObject:separator];
    
    separator = [SparkList objectWithName:SETableSeparator icon:nil];
    [separator setUID:200];
    [se_content addObject:separator];
    
    [self rearrangeObjects];
  }
  return self;
}

- (void)dealloc {
  [se_content release];
  if (se_plugins)
    NSFreeMapTable(se_plugins);
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
  unsigned idx = [se_content indexOfObjectIdenticalTo:list];
  // Notify delegate with list and index.
  if (SKDelegateHandle(se_delegate, source:didAddList:atIndex:)) {
    [se_delegate source:self didAddList:list atIndex:idx];
  } else {
    [table selectRow:idx byExtendingSelection:NO];
    [table editColumn:0 row:idx withEvent:nil select:YES];
  }
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
  return row >= 0 && [[[se_content objectAtIndex:row] name] isEqualToString:SETableSeparator] ? 1 : [tableView rowHeight];
}
- (BOOL)tableView:(NSTableView *)aTableView shouldSelectRow:(int)rowIndex {
  return rowIndex >= 0 ? ![[[se_content objectAtIndex:rowIndex] name] isEqualToString:SETableSeparator] : YES;
}

- (void)setTriggers:(SETriggerEntrySet *)triggers application:(SparkApplication *)anApplication {
  SparkList *list;
  NSEnumerator *lists = [se_content objectEnumerator];
  while (list = [lists nextObject]) {
    SEPluginFilter *ctxt = [list filterContext];
    if (ctxt && [ctxt isKindOfClass:[SEPluginFilter class]]) {
      [ctxt setTriggers:triggers];
      [list reload];
    }
  }
}

@end

#pragma mark -
@implementation SEPluginFilter

- (void)dealloc {
  [se_triggers release];
  [super dealloc];
}

- (Class)actionClass {
  return se_action;
}
- (void)setActionClass:(Class)cls {
  se_action = cls;
}

- (void)setTriggers:(SETriggerEntrySet *)triggers {
  SKSetterRetain(se_triggers, triggers);
}

- (BOOL)isValidTrigger:(SparkTrigger *)aTrigger {
  if (se_triggers && se_action) {
    SparkAction *action = [se_triggers actionForTrigger:aTrigger];
    if (action)
      return [action isKindOfClass:se_action];
  }
  return NO;
}

@end
