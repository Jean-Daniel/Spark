/*
 *  SEEntryEditor.m
 *  Spark Editor
 *
 *  Created by Grayfox on 09/07/06.
 *  Copyright 2006 Shadow Lab. All rights reserved.
 */

#import "SEEntryEditor.h"
#import "SETriggerEntry.h"

#import "SETableView.h"
#import "SEHeaderCell.h"
#import "SEHotKeyTrap.h"

#import <SparkKit/SparkPlugIn.h>
#import <SparkKit/SparkHotKey.h>
#import <SparkKit/SparkApplication.h>
#import <SparkKit/SparkActionLoader.h>
#import <SparkKit/SparkActionPlugIn.h>

#import <HotKeyToolKit/HotKeyToolKit.h>

@interface SETrapWindow : HKTrapWindow {
}
@end

#pragma mark -
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

    /* Add special objects and separator */
//    plugin = [[SparkPlugIn alloc] init];
//    [plugin setName:@"Globals Setting"];
//    [plugin setIcon:[NSImage imageNamed:@"applelogo"]];
//    [se_plugins insertObject:plugin atIndex:0];
//    [plugin release];
//    
//    plugin = [[SparkPlugIn alloc] init];
//    [plugin setName:@"Ignore Spark"];
//    [plugin setIcon:[NSImage imageNamed:@"IgnoreAction"]];
//    [se_plugins insertObject:plugin atIndex:1];
//    [plugin release];
//    
//    plugin = [[SparkPlugIn alloc] init];
//    [plugin setName:SETableSeparator];
//    [se_plugins insertObject:plugin atIndex:2];
//    [plugin release];
    
    unsigned count = [se_plugins count];
    se_instances = [[NSMutableArray alloc] initWithCapacity:count];
    while (count-- > 0) {
      [se_instances addObject:[NSNull null]];
    }
    se_views = [se_instances mutableCopy];
    
  }
  return self;
}

- (void)dealloc {
  [se_views release];
  [se_plugins release];
  [se_instances release];
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
}

- (void)windowDidLoad {
  [super windowDidLoad];
  /* Compute minimum plugin view size */
  NSSize smin = [[self window] contentMinSize];
  NSSize scur = [[self window] frame].size;
  NSSize delta = { scur.width - smin.width, scur.height - smin.height };
  
  se_min = [pluginView frame].size;
  se_min.width -= delta.width;
  se_min.height -= delta.height;
}

- (IBAction)ok:(id)sender {
  [self close:sender];
}

- (IBAction)cancel:(id)sender {
  [self close:sender];
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

SK_INLINE
BOOL _IsViewResizable(NSView *aView) {
  unsigned int mask = [aView autoresizingMask];
  return (mask & (NSViewWidthSizable | NSViewHeightSizable)) != 0;
}

- (void)setActionType:(SparkPlugIn *)aPlugin {
  unsigned int row = [se_plugins indexOfObject:aPlugin];
  if (row != NSNotFound) {
    SparkActionPlugIn *plugin = [se_instances objectAtIndex:row];
    if ([NSNull null] == (id)plugin) {
      if ([[se_plugins objectAtIndex:row] pluginClass]) {
        // create plugin instance when needed
        plugin = [[[[se_plugins objectAtIndex:row] pluginClass] alloc] init];
        [se_instances replaceObjectAtIndex:row withObject:plugin];
        [plugin release];
        
        // Load plugin view
        NSView *view = [plugin actionView];
        [view setFrameOrigin:NSZeroPoint];
        [se_views replaceObjectAtIndex:row withObject:view];
        // load action into plugin.
      } else {
        DLog(@"Special plugin");
      }     
    }
    /* Remove previous view */
    if (se_view)
      [se_view removeFromSuperview];
    
    se_view = [se_views objectAtIndex:row];
    NSAssert2([se_view isKindOfClass:[NSView class]], @"Invalid view for plugin: %@, row: %u", plugin, row);
    
    // Adjust view and window frame
    NSRect vrect = NSZeroRect; /* view rect */
    vrect.size = [se_view frame].size;
    
    // View smaller than limit.
    if (NSWidth(vrect) < se_min.width) {
      // Adjust width
      if ([se_view autoresizingMask] & NSViewWidthSizable) {
        vrect.size.width = se_min.width;
      } else {
        vrect.origin.x = roundf(AVG(se_min.width, -NSWidth(vrect)));
      }
    }
    if (NSHeight(vrect) < se_min.height) {
      // Adjust height
      if ([se_view autoresizingMask] & NSViewHeightSizable) {
        vrect.size.height = se_min.height;
      } else {
        vrect.origin.y = roundf(AVG(se_min.height, -NSHeight(vrect)));
      }
    }
    [se_view setFrame:vrect];
    
    /* current size */
    NSSize csize = [pluginView frame].size;
    /* destination rect */
    NSRect drect = vrect;
    drect.size.width = MAX(NSWidth(vrect), se_min.width);
    drect.size.height = MAX(NSHeight(vrect), se_min.height);
    /* compute delta between current size and destination size */
    NSSize delta = {NSWidth(drect) - csize.width, NSHeight(drect) - csize.height};
    
    /* Resize window frame */
    NSRect wframe = [[self window] frame];
    wframe.size.width += delta.width;
    wframe.size.height += delta.height;
    wframe.origin.x -= delta.width / 2;
    wframe.origin.y -= delta.height;
    [[self window] setFrame:wframe display:YES animate:YES];
    
    /* Adjust window attributes */
    NSSize smax = [[self window] frame].size;
    smax.height += 22;
    unsigned int mask = [se_view autoresizingMask];
    if (mask & NSViewWidthSizable) {
      smax.width = MAXFLOAT;
    }
    if (mask & NSViewHeightSizable) {
      smax.height = MAXFLOAT;
    }
    if (MAXFLOAT <= smax.width || MAXFLOAT <= smax.height) {
      [[self window] setShowsResizeIndicator:YES];
      [[self window] setContentMinSize:NSMakeSize(0, 300)];
    } else {
      [[self window] setShowsResizeIndicator:NO];
      [[self window] setContentMinSize:smax];
    }
    [[self window] setContentMaxSize:smax];
    
    [pluginView addSubview:se_view];
  }
}

- (void)tableViewSelectionDidChange:(NSNotification *)aNotification {
  int row = [[aNotification object] selectedRow];
  if (row >= 0) {
    [self setActionType:[se_plugins objectAtIndex:row]];
  }
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

#pragma mark -
@implementation SETrapWindow

- (NSTimeInterval)animationResizeTime:(NSRect)newFrame {
  float delta = ABS(NSHeight([self frame]) - NSHeight(newFrame));
  return (0.13 * delta / 150.);
}

@end
