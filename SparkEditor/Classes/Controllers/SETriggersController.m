//
//  SETriggersController.m
//  Spark Editor
//
//  Created by Jean-Daniel Dupas on 07/07/06.
//  Copyright 2006 Adamentium. All rights reserved.
//

#import "SETriggersController.h"
#import "SEVirtualPlugIn.h"
#import "SETriggerEntry.h"

#import <ShadowKit/SKCFContext.h>
#import <ShadowKit/SKOutlineView.h>

#import <SparkKit/SparkLibrary.h>

#import <SparkKit/SparkAction.h>
#import <SparkKit/SparkTrigger.h>
#import <SparkKit/SparkApplication.h>
#import <SparkKit/SparkActionLoader.h>

@implementation SETriggersController

- (id)init {
  if (self = [super init]) {
    se_entries = NSCreateMapTable(NSNonRetainedObjectMapKeyCallBacks, NSObjectMapValueCallBacks, 0);
    se_triggers = [[SETriggerEntrySet alloc] init];
    se_defaults = [[SETriggerEntrySet alloc] init];
    /* Load defaults triggers */
    
    [se_defaults addEntriesFromDictionary:[SparkSharedLibrary() triggersForApplication:0]];
    
    se_plugins = [[[SparkActionLoader sharedLoader] plugins] mutableCopy];
    [se_plugins sortUsingDescriptors:gSortByNameDescriptors];
  }
  return self;
}

- (void)dealloc {
  [se_app release];
  [se_plugins release];
  [se_triggers release];
  [se_defaults release];
  if (se_entries)
    NSFreeMapTable(se_entries);
  [super dealloc];
}

#pragma mark -
- (void)awakeFromNib {
  [outline setTarget:self];
  [outline setDoubleAction:@selector(doubleAction:)];
  [outline setOutlineTableColumn:[outline tableColumnWithIdentifier:@"__item__"]];
  
  [outline setAutosaveName:@"SparkTriggerTable"];
  [outline setAutosaveTableColumns:YES];
  [outline setAutosaveExpandedItems:YES];
}

- (IBAction)doubleAction:(id)sender {
  int idx = -1;
  NSEvent *event = [NSApp currentEvent];
  if ([event type] == NSKeyDown) {
    idx = [outline selectedRow];
  } else {
    idx = [outline clickedRow];
  }
  if (idx >= 0) {
    DLog(@"%@", [outline itemAtRow:idx]);
  }
}

- (void)sortTriggers:(NSArray *)descriptors {
  NSMutableArray *triggers;
  NSMapEnumerator enumerator = NSEnumerateMapTable(se_entries);
  while (NSNextMapEnumeratorPair(&enumerator, NULL, (void **)&triggers)) {
    [triggers sortUsingDescriptors:descriptors];
  }
  NSEndMapTableEnumeration(&enumerator);
}

- (void)clear {
  NSResetMapTable(se_entries);
  [se_triggers removeAllEntries];
  id plugin = [se_plugins lastObject];
  if ([plugin isKindOfClass:[SEVirtualPlugIn class]]) {
    [se_plugins removeObjectAtIndex:[se_plugins count] -1];
  }
}

- (void)loadTriggers {
  [self clear];
  if (se_app) {
    //if ([se_app uid] == 0)
    [se_triggers addEntriesFromEntrySet:se_defaults];
    if ([se_app uid] != 0) {
      [se_triggers addEntriesFromDictionary:[SparkSharedLibrary() triggersForApplication:[se_app uid]]];
    }
    SETriggerEntry *entry = nil;
    NSEnumerator *entries = [se_triggers entryEnumerator];
    SparkActionLoader *loader = [SparkActionLoader sharedLoader];
    while (entry = [entries nextObject]) {
      SparkPlugIn *plugin = [loader plugInForAction:[entry action]];
      if (!plugin) {
        plugin = [se_plugins lastObject];
        if (![plugin isKindOfClass:[SEVirtualPlugIn class]]) {
          plugin = [[SEVirtualPlugIn alloc] initWithName:@"Missing" icon:[NSImage imageNamed:@"Warning"]];
          [se_plugins addObject:plugin];
          [plugin release];
        }
      }
      if (plugin) {
        NSMutableArray *items = NSMapGet(se_entries, plugin);
        if (!items) {
          items = [[NSMutableArray alloc] init];
          NSMapInsert(se_entries, plugin, items);
          [items release];
        }
        [items addObject:entry];
      } else {
        
        DLog(@"Missing plugin for item: %@", [entry action]);
      }
    }
    [self sortTriggers:gSortByNameDescriptors];
  }
}

- (SparkApplication *)application {
  return se_app;
}

- (void)setApplication:(SparkApplication *)application {
  if (![se_app isEqualToLibraryObject:application]) {
    [se_app release];
    se_app = [application retain];
    // Reload application
    [self loadTriggers];
    [outline reloadData];
  }
}

#pragma mark -
- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item {
  return [item isKindOfClass:[SparkPlugIn class]];
}

- (int)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item {
  if (!item) {
    return [se_plugins count];
  } else if ([item isKindOfClass:[SparkPlugIn class]]) {
    NSArray *entries = NSMapGet(se_entries, item);
    return entries ? [entries count] : 0;
  } else {
    return 0;
  }
}

- (id)outlineView:(NSOutlineView *)outlineView child:(int)anIndex ofItem:(id)item {
  if (!item) {
    return [se_plugins objectAtIndex:anIndex];
  } else if ([item isKindOfClass:[SparkPlugIn class]]) {
    NSArray *entries = NSMapGet(se_entries, item);
    return entries ? [entries objectAtIndex:anIndex] : nil;
  } else {
    return nil;
  }
}

- (id)outlineView:(NSOutlineView *)outlineView objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(id)item {
  if ([[tableColumn identifier] isEqualToString:@"__item__"]) {
    return item;
  } else if ([item isKindOfClass:[SparkPlugIn class]]) {
    return nil;
  } else {
    if ([[tableColumn identifier] isEqualToString:@"trigger"]) {
      return [item triggerDescription];
    } else if ([[tableColumn identifier] isEqualToString:@"enabled"]) {
      return SKBool([item isEnabled]);
    } else {
      return [item valueForKey:[tableColumn identifier]];
    }
  }
}

- (void)outlineView:(NSOutlineView *)outlineView willDisplayCell:(id)cell forTableColumn:(NSTableColumn *)tableColumn item:(id)item {
  if ([item isKindOfClass:[SparkPlugIn class]]) {
    if ([[tableColumn identifier] isEqualToString:@"enabled"]) {
      [cell setTransparent:YES];
//      [cell setEnabled:NO];
    } else {
      [cell setTextColor:[NSColor blackColor]];
      [cell setFont:[NSFont systemFontOfSize:[NSFont smallSystemFontSize]]];
    }
  } else {
    SETriggerEntry *entry = item;
    if ([[tableColumn identifier] isEqualToString:@"enabled"]) {
      [cell setTransparent:NO];
//      [cell setEnabled:YES];
    } else if ([se_app uid] != 0 && [[entry action] isEqualToLibraryObject:[se_defaults actionForTrigger:[entry trigger]]]) {
      [cell setFont:[NSFont systemFontOfSize:[NSFont smallSystemFontSize]]];
      [cell setTextColor:[outlineView isRowSelected:[outlineView rowForItem:item]] ? [NSColor selectedControlTextColor] : [NSColor grayColor]];
    } else {
      [cell setTextColor:[NSColor blackColor]];
      if ([se_app uid] == 0) {
        [cell setFont:[NSFont systemFontOfSize:[NSFont smallSystemFontSize]]];
      } else {
        [cell setFont:[NSFont boldSystemFontOfSize:[NSFont smallSystemFontSize]]];
      }
    }
  }
}

- (void)outlineView:(NSOutlineView *)outlineView setObjectValue:(id)object forTableColumn:(NSTableColumn *)tableColumn byItem:(id)item {
  if ([item isKindOfClass:[SparkPlugIn class]]) {
    return;
  }
  SETriggerEntry *entry = item;
  if ([[tableColumn identifier] isEqualToString:@"enabled"]) {
    [[entry trigger] setEnabled:[object boolValue]];
  } else if ([[tableColumn identifier] isEqualToString:@"__item__"]) {
    if ([object length] > 0) {
      [[entry action] setName:object];
    } else {
      NSBeep();
      // Be more verbose maybe?
    }
  }
}

- (void)outlineView:(NSOutlineView *)outlineView sortDescriptorsDidChange:(NSArray *)oldDescriptors {
  [self sortTriggers:[outlineView sortDescriptors]];
  [outline reloadData];
}

- (id)outlineView:(NSOutlineView *)outlineView itemForPersistentObject:(id)object {
  return [[SparkActionLoader sharedLoader] pluginForBundleIdentifier:object];
}
- (id)outlineView:(NSOutlineView *)outlineView persistentObjectForItem:(id)item {
  return [item isKindOfClass:[SparkPlugIn class]] ? [item bundleIdentifier] : nil;
}

- (BOOL)outlineView:(NSOutlineView *)outlineView shouldEditTableColumn:(NSTableColumn *)tableColumn item:(id)item {
  return ![item isKindOfClass:[SparkPlugIn class]];
}

@end
