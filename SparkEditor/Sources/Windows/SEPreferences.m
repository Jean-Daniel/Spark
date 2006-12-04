/*
 *  SEPreferences.m
 *  Spark Editor
 *
 *  Created by Grayfox on 07/09/06.
 *  Copyright 2006 Shadow Lab. All rights reserved.
 */

#import "SEPreferences.h"

#import "Spark.h"
#import "SEEntriesManager.h"

#import <SparkKit/SparkKit.h>
#import <SparkKit/SparkPlugIn.h>
#import <SparkKit/SparkLibrary.h>
#import <SparkKit/SparkActionLoader.h>

@implementation SEPreferences

+ (BOOL)synchronize {
  return [[NSUserDefaults standardUserDefaults] synchronize] && CFPreferencesAppSynchronize((CFStringRef)kSparkBundleIdentifier);
}

- (id)init {
  if (self = [super init]) {
    se_counts = NSCreateMapTable(NSObjectMapKeyCallBacks, NSObjectMapValueCallBacks, 0);
    se_status = NSCreateMapTable(NSObjectMapKeyCallBacks, NSIntMapValueCallBacks, 0);
    se_plugins = [[NSMutableArray alloc] init];
  }
  return self;
}

- (void)dealloc {
  [se_plugins release];
  if (se_counts) NSFreeMapTable(se_counts);
  if (se_status) NSFreeMapTable(se_status);
  [super dealloc];
}

- (NSString *)actionCountForPlugin:(SparkPlugIn *)plugin {
  unsigned long count = 0;
  SparkAction *action;
  Class cls = [plugin actionClass];
  NSEnumerator *actions = [SparkSharedActionSet() objectEnumerator];
  while (action = [actions nextObject]) {
    if ([action isKindOfClass:cls])
      count++;
  }
  return [NSString stringWithFormat:count > 1 ? @"%lu actions" : @"%lu action", count];
}

- (void)awakeFromNib {
  /* Set outline column */
  [ibPlugins setOutlineTableColumn:[ibPlugins tableColumnWithIdentifier:@"__item__"]];
  
  /* Load plugins */
  NSMutableArray *uplugs = [NSMutableArray array];
  NSMutableArray *lplugs = [NSMutableArray array];
  NSMutableArray *bplugs = [NSMutableArray array];
  
  NSString *user = [SparkActionLoader pluginPathForDomain:kSKUserDomain];
  NSString *local = [SparkActionLoader pluginPathForDomain:kSKLocalDomain];

  SparkPlugIn *plugin;
  NSEnumerator *plugins = [[[[SparkActionLoader sharedLoader] plugins] sortedArrayUsingDescriptors:gSortByNameDescriptors] objectEnumerator];
  while (plugin = [plugins nextObject]) {
    NSString *path = [plugin path];
    if ([path hasPrefix:user]) {
      [uplugs addObject:plugin];
    } else if ([path hasPrefix:local]) {
      [lplugs addObject:plugin];
    } else {
      [bplugs addObject:plugin];
    }
    /* Save status */
    long status = [plugin isEnabled];
    NSMapInsert(se_status, plugin, (void *)status);
    /* Cache action count */
    NSMapInsert(se_counts, plugin, [self actionCountForPlugin:plugin]);
  }
  NSDictionary *item = [NSDictionary dictionaryWithObjectsAndKeys:
    @"Built-in", @"name",
    bplugs, @"plugins",
    [NSImage imageNamed:@"application"], @"icon", nil];
  [se_plugins addObject:item];
  
  item = [NSDictionary dictionaryWithObjectsAndKeys:
    @"Computer", @"name",
    lplugs, @"plugins",
    [NSImage imageNamed:@"computer"], @"icon", nil];
  [se_plugins addObject:item];
  
  item = [NSDictionary dictionaryWithObjectsAndKeys:
    @"User", @"name",
    uplugs, @"plugins",
    [NSImage imageNamed:@"user"], @"icon", nil];
  [se_plugins addObject:item];
  
  [ibPlugins reloadData];
  for (unsigned idx = 0; idx < [se_plugins count]; idx++) {
    item = [se_plugins objectAtIndex:idx];
    if ([[item objectForKey:@"plugins"] count])
      [ibPlugins expandItem:item];
  }
}

- (IBAction)close:(id)sender {
  BOOL change = NO;
  long status = status;
  SparkPlugIn *plugin = nil;
  NSMapEnumerator plugins = NSEnumerateMapTable(se_status);
  while (NSNextMapEnumeratorPair(&plugins, (void **)&plugin, (void **)&status)) {
    if (XOR(status, [plugin isEnabled])) {
      [plugin setEnabled:status];
      change = YES;
    }
  }
  if (change) {
    [[NSNotificationCenter defaultCenter] postNotificationName:SESparkEditorDidChangePluginStatusNotification
                                                        object:nil];
    /* Invalidate entries cache */
    [[SEEntriesManager sharedManager] reload];
  } else {
    [[SEEntriesManager sharedManager] refresh];
  }
  [super close:sender];
}

#pragma mark -
#pragma mark Plugin Manager
- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item {
  return !item || ![item isKindOfClass:[SparkPlugIn class]];
}
- (int)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item {
  return item ? [[item objectForKey:@"plugins"] count] : [se_plugins count];
}
- (id)outlineView:(NSOutlineView *)outlineView child:(int)anIndex ofItem:(id)item {
  return item ? [[item objectForKey:@"plugins"] objectAtIndex:anIndex] : [se_plugins objectAtIndex:anIndex];
}
- (id)outlineView:(NSOutlineView *)outlineView objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(id)item {
  if ([item isKindOfClass:[SparkPlugIn class]]) {
    if ([[tableColumn identifier] isEqualToString:@"__item__"])
      return item;
    else if ([[tableColumn identifier] isEqualToString:@"count"])
      return NSMapGet(se_counts, item);
    else if ([[tableColumn identifier] isEqualToString:@"enabled"])
      return SKBool(NSMapGet(se_status, item) != 0); 
    else
      return [item valueForKey:[tableColumn identifier]];
  } else if ([item isKindOfClass:[NSDictionary class]]) {
    if ([[tableColumn identifier] isEqualToString:@"__item__"])
      return item;
  }
  return nil;
}

- (void)outlineView:(NSOutlineView *)outlineView setObjectValue:(id)object forTableColumn:(NSTableColumn *)tableColumn byItem:(id)item {
  if ([item isKindOfClass:[SparkPlugIn class]] && [[tableColumn identifier] isEqualToString:@"enabled"]) {
    if (NSMapMember(se_status, item, NULL, NULL)) {
      NSMapInsert(se_status, item, (void *)[object longValue]);
    }
  }
}

- (void)outlineView:(NSOutlineView *)outlineView willDisplayCell:(id)cell forTableColumn:(NSTableColumn *)tableColumn item:(id)item {
  if ([item isKindOfClass:[SparkPlugIn class]]) {
    if ([[tableColumn identifier] isEqualToString:@"enabled"]) {
      [cell setEnabled:YES];
      [cell setTransparent:NO];
    }
  } else {
    if ([[tableColumn identifier] isEqualToString:@"enabled"]) {
      [cell setEnabled:NO];
      [cell setTransparent:YES];
    }
  }
}

- (void)deleteSelectionInOutlineView:(NSOutlineView *)aView {
  int row = [aView selectedRow];
  if (row > 0) {
    id item = [aView itemAtRow:row];
    if (item && [item isKindOfClass:[SparkPlugIn class]]) {
      DLog(@"Delete plugin: %@", item);
    }
  }
}

@end
