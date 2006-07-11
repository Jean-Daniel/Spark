/*
 *  SEActionEditor.m
 *  Spark Editor
 *
 *  Created by Grayfox on 09/07/06.
 *  Copyright 2006 Shadow Lab. All rights reserved.
 */

#import "SEActionEditor.h"
#import "SEVirtualPlugIn.h"

#import <SparkKit/SparkActionLoader.h>

@implementation SEActionEditor

- (id)init {
  if (self = [super initWithViewNibName:@"SEActionEditor"]) {
    se_plugins = [[[SparkActionLoader sharedLoader] plugins] mutableCopy];
    [se_plugins sortUsingDescriptors:gSortByNameDescriptors];
    [se_plugins insertObject:[SEVirtualPlugIn pluginWithName:@"Ignore Spark" 
                                                        icon:[NSImage imageNamed:@"IgnoreAction"]]
                     atIndex:0];
    [se_plugins insertObject:[SEVirtualPlugIn pluginWithName:@"Inherits"
                                                        icon:[NSImage imageNamed:@"System"]]
                     atIndex:0];
  }
  return self;
}

- (void)dealloc {
  [se_plugins release];
  [super dealloc];
}

- (int)numberOfRowsInTableView:(NSTableView *)tableView {
  return [se_plugins count];
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(int)row {
  return [se_plugins objectAtIndex:row];
}

@end
