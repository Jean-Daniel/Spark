/*
 *  SEEntryEditor.m
 *  Spark Editor
 *
 *  Created by Grayfox on 09/07/06.
 *  Copyright 2006 Shadow Lab. All rights reserved.
 */

#import "SEEntryEditor.h"
#import "SEActionEditor.h"
#import "SETriggerEntry.h"

#import "SETableView.h"
#import "SEHeaderCell.h"
#import "SEHotKeyTrap.h"

#import <SparkKit/SparkPlugIn.h>
#import <SparkKit/SparkHotKey.h>
#import <SparkKit/SparkApplication.h>
#import <SparkKit/SparkActionLoader.h>

#import <HotKeyToolKit/HotKeyToolKit.h>

@implementation SEEntryEditor

- (id)init {
  if (self = [super init]) {
    SparkPlugIn *plugin; 
    se_plugins = [[NSMutableArray alloc] init];
    NSEnumerator *plugins = [[SparkActionLoader sharedLoader] objectEnumerator];
    while (plugin = [plugins nextObject]) {
      [se_plugins addObject:plugin];
    }
    [se_plugins sortUsingDescriptors:gSortByNameDescriptors];
    
    plugin = [[SparkPlugIn alloc] init];
    [plugin setName:@"Globals Setting"];
    [plugin setIcon:[NSImage imageNamed:@"applelogo"]];
    [se_plugins insertObject:plugin atIndex:0];
    [plugin release];
    
    plugin = [[SparkPlugIn alloc] init];
    [plugin setName:@"Ignore Spark"];
    [plugin setIcon:[NSImage imageNamed:@"IgnoreAction"]];
    [se_plugins insertObject:plugin atIndex:1];
    [plugin release];
    
    plugin = [[SparkPlugIn alloc] init];
    [plugin setName:SETableSeparator];
    [se_plugins insertObject:plugin atIndex:2];
    [plugin release];
  }
  return self;
}

- (void)dealloc {

  [super dealloc];
}

- (void)awakeFromNib {
  /* Configure Library Header Cell */
  SEHeaderCell *header = [[SEHeaderCell alloc] initTextCell:@"HotKey Type"];
  [header setAlignment:NSCenterTextAlignment];
  [header setFont:[NSFont systemFontOfSize:11]];
  [[[typeTable tableColumns] objectAtIndex:0] setHeaderCell:header];
  [header release];
  [typeTable setCornerView:[[[SEHeaderCellCorner alloc] initWithFrame:NSMakeRect(0, 0, 22, 22)] autorelease]];
  
  [typeTable setHighlightShading:[NSColor colorWithDeviceRed:.340f
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
  
  id plugin = [[[[se_plugins objectAtIndex:7] pluginClass] alloc] init];
  NSView *view = [plugin actionView];
  [view setFrameOrigin:NSZeroPoint];
  [view setFrameSize:[pluginView frame].size];
  [pluginView addSubview:view];
}

- (IBAction)ok:(id)sender {
  [self close:sender];
}

- (IBAction)cancel:(id)sender {
  [self close:sender];
}

- (void)setActionType:(SparkPlugIn *)type {
  //[se_editor setActionType:type];
}
- (void)setEntry:(SETriggerEntry *)anEntry {
  //[se_editor setSparkAction:[anEntry action]];
}
- (void)setApplication:(SparkApplication *)anApplication {
  [appField setApplication:anApplication];
  [appField setTitle:[NSString stringWithFormat:@"%@ HotKey", [anApplication name]]];
}

- (int)numberOfRowsInTableView:(NSTableView *)aTableView {
  return [se_plugins count];
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex {
  return [se_plugins objectAtIndex:rowIndex];
}

/* Separator Implementation */
- (float)tableView:(NSTableView *)tableView heightOfRow:(int)row {
  return row >= 0 && [[[se_plugins objectAtIndex:row] name] isEqualToString:SETableSeparator] ? 1 : [tableView rowHeight];
}
- (BOOL)tableView:(NSTableView *)aTableView shouldSelectRow:(int)rowIndex {
  return rowIndex >= 0 ? ![[[se_plugins objectAtIndex:rowIndex] name] isEqualToString:SETableSeparator] : YES;
}

#pragma mark Trap Delegate
- (BOOL)trapWindow:(HKTrapWindow *)window needPerformKeyEquivalent:(NSEvent *)theEvent {
  /* No modifier and cancel pressed */
  return ([theEvent modifierFlags] & SEValidModifiersFlags) == 0
  && [[theEvent characters] isEqualToString:@"\e"];
}

- (BOOL)trapWindow:(HKTrapWindow *)window needProceedKeyEvent:(NSEvent *)theEvent {
  if (kSparkEnableAllSingleKey == SparkKeyStrokeFilterMode) {
    return NO;
  } else {
    UInt16 code = [theEvent keyCode];
    UInt32 mask = [theEvent modifierFlags] & SEValidModifiersFlags;
    return mask ? NO : (code == kVirtualEnterKey)
      || (code == kVirtualReturnKey)
      || (code == kVirtualEscapeKey)
      || (code == kVirtualTabKey);
  }
}

@end
