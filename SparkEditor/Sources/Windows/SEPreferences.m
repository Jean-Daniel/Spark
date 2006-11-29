/*
 *  SEPreferences.m
 *  Spark Editor
 *
 *  Created by Grayfox on 07/09/06.
 *  Copyright 2006 Shadow Lab. All rights reserved.
 */

#import "SEPreferences.h"

#import "Spark.h"

#import <SparkKit/SparkActionLoader.h>

@implementation SEPreferences

- (id)init {
  if (self = [super init]) {
    se_plugins = [[NSMutableArray alloc] init];
  }
  return self;
}

- (void)dealloc {
  ShadowTrace();
  [se_plugins release];
  [super dealloc];
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
    [ibPlugins expandItem:[se_plugins objectAtIndex:idx]];
  }
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
    else if ([[tableColumn identifier] isEqualToString:@"path"])
      return [[item path] lastPathComponent];
    else
      return [item valueForKey:[tableColumn identifier]];
  } else if ([item isKindOfClass:[NSDictionary class]]) {
    if ([[tableColumn identifier] isEqualToString:@"__item__"])
      return item;
  }
  return nil;
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

@end
