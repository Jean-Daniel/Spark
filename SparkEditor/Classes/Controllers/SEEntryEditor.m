/*
 *  SEEntryEditor.m
 *  Spark Editor
 *
 *  Created by Black Moon Team.
 *  Copyright (c) 2004 - 2006 Shadow Lab. All rights reserved.
 */

#import "SEEntryEditor.h"
#import "SETriggerEntry.h"

#import "SETableView.h"
#import "SEHeaderCell.h"
#import "SEHotKeyTrap.h"
#import "SEBuiltInPlugin.h"
#import "SEApplicationView.h"

#import <SparkKit/SparkPlugIn.h>
#import <SparkKit/SparkHotKey.h>
#import <SparkKit/SparkPrivate.h>
#import <SparkKit/SparkApplication.h>
#import <SparkKit/SparkActionLoader.h>
#import <SparkKit/SparkActionPlugIn.h>

#import <ShadowKit/SKFunctions.h>
#import <ShadowKit/SKExtensions.h>
#import <HotKeyToolKit/HotKeyToolKit.h>

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

    se_views = [[NSMutableArray alloc] init];
    se_instances = NSCreateMapTable(NSObjectMapKeyCallBacks, NSObjectMapValueCallBacks, [se_plugins count]);
  }
  return self;
}

- (void)dealloc {
  [se_views release];
  [se_plugins release];
  if (se_instances)
    NSFreeMapTable(se_instances);
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

- (id)delegate {
  return se_delegate;
}
- (void)setDelegate:(id)aDelegate {
  se_delegate = aDelegate;
}

- (IBAction)close:(id)sender {
  [super close:sender];
  /* Cleanup */
  [se_view removeFromSuperview];
  se_view = nil;
  se_plugin = nil;
  /* Remove plugins instances */
  [se_views removeAllObjects];
  NSResetMapTable(se_instances);
}

- (void)create:(SETriggerEntry *)entry {
  if (!SKDelegateHandle(se_delegate, editor:shouldCreateEntry:) || [se_delegate editor:self shouldCreateEntry:entry])
    [self close:nil];
}
- (void)update:(SETriggerEntry *)entry {
  if (!SKDelegateHandle(se_delegate, editor:shouldUpdateEntry:) || [se_delegate editor:self shouldUpdateEntry:entry])
    [self close:nil];
}

- (IBAction)ok:(id)sender {
  /* Check trigger */
  NSAlert *alert = nil;
  SEHotKey key = [trap hotkey];
  if (kHKInvalidVirtualKeyCode == key.keycode || kHKNilUnichar == key.character) {
    alert = [NSAlert alertWithMessageText:NSLocalizedStringFromTable(@"INVALID_TRIGGER_ALERT",
                                                                     @"EntryEditor", @"Invalid HotKey - Title")
                            defaultButton:NSLocalizedStringFromTable(@"OK",
                                                                     @"EntryEditor", @"Alert default button")
                          alternateButton:nil
                              otherButton:nil
                informativeTextWithFormat:NSLocalizedStringFromTable(@"INVALID_TRIGGER_ALERT_MSG",
                                                                     @"EntryEditor", @"Invalid HotKey - Message")];
  }
  /* Then check action */
  if (!alert)
    alert = [se_plugin sparkEditorShouldConfigureAction];
  if (!alert) {
    [se_plugin configureAction];
    // Check name
    NSString *name = [[se_plugin sparkAction] name];
    if ([[name stringByTrimmingWhitespace] length] == 0) {
      alert = [NSAlert alertWithMessageText:NSLocalizedStringFromTable(@"EMPTY_NAME_ALERT",
                                                                       @"EntryEditor", @"Empty Action Name - Title")
                              defaultButton:NSLocalizedStringFromTable(@"OK",
                                                                       @"EntryEditor", @"Alert default button")
                            alternateButton:nil
                                otherButton:nil
                  informativeTextWithFormat:NSLocalizedStringFromTable(@"EMPTY_NAME_ALERT_MSG",
                                                                       @"EntryEditor", @"Empty Action Name - Message")];
    }
  }
  if (alert) { 
    [alert runModal];
  } else {
    SparkHotKey *hkey = [[SparkHotKey alloc] init];
    [hkey setKeycode:key.keycode];
    [hkey setModifier:key.modifiers];
    [hkey setCharacter:key.character];
    SETriggerEntry *entry = [[SETriggerEntry alloc] initWithTrigger:hkey action:[se_plugin sparkAction]];
    if ([se_plugin respondsToSelector:@selector(se_type)]) {
      [entry setType:[(SEIgnorePlugin *)se_plugin se_type]];
    } else { /* Standard Spark Plugin: Set Global if application is 0 else set overwrite */
      [entry setType:[[self application] uid] == 0 ? kSEEntryTypeGlobal : kSEEntryTypeOverwrite];
    }
    if (se_entry) {
      [self update:entry];
    } else {
      [self create:entry];
    }
    [entry release];
    [hkey release];
  }
}

- (IBAction)cancel:(id)sender {
  [self close:sender];
}

- (void)updatePlugins {
  /* plugins list should contains global and ignore if:
   - Application uid != 0.
   - Edit an existing entry (is updating).
  */
  BOOL advanced = [[appField application] uid] != 0;
  advanced = advanced && (se_entry != nil);
  
  if (advanced) {
    if ([[se_plugins objectAtIndex:0] actionClass] != Nil) {
      /* Should add custom plugins */
      
      /* Create Inherits plugin */
      SparkPlugIn *plugin = [[SparkPlugIn alloc] initWithClass:[SEInheritsPlugin class]];
      [se_plugins insertObject:plugin atIndex:0];
      [plugin release];
      
      /* Create Ignore plugin */
      plugin = [[SparkPlugIn alloc] initWithClass:[SEIgnorePlugin class]];
      [se_plugins insertObject:plugin atIndex:1];
      [plugin release];
      
      plugin = [[SparkPlugIn alloc] init];
      [plugin setName:SETableSeparator];
      [se_plugins insertObject:plugin atIndex:2];
      [plugin release];
      /* Reload new plugins */
      [typeTable reloadData];
    }
  } else {
    if ([[se_plugins objectAtIndex:0] actionClass] == Nil) {
      /* Should remove custom plugins */
      [se_plugins removeObjectsInRange:NSMakeRange(0, 3)];
      /* Reload to remove plugins */
      [typeTable reloadData];
    }
  }
}
- (SparkPlugIn *)actionType {
  int row = [typeTable selectedRow];
  return row >= 0 ? [se_plugins objectAtIndex:row] : nil;
}

- (SETriggerEntry *)entry {
  return se_entry;
}
- (void)setEntry:(SETriggerEntry *)anEntry {
  SKSetterRetain(se_entry, anEntry);
  
  /* Update plugins list if needed */
  [self updatePlugins];
  
  /* Select plugin type */
  SparkPlugIn *type = nil;
  if (se_entry) {
    switch ([se_entry type]) {
      case kSEEntryTypeIgnore:
        type = [se_plugins objectAtIndex:1];
        [trap setEnabled:NO];
        break;
      case kSEEntryTypeGlobal:
        if ([[appField application] uid] != 0) {
          type = [se_plugins objectAtIndex:0];
          [trap setEnabled:NO];
          break;
        }
        // else fall througt
      case kSEEntryTypeOverwrite:
        type = [[SparkActionLoader sharedLoader] plugInForAction:[se_entry action]];
        [trap setEnabled:YES];
        break;
    }
    [ibConfirm setTitle:@"Update"];
  } else {
    // set create
    [trap setEnabled:YES];
    [ibConfirm setTitle:@"Create"];
  }
  if (type)
    [self setActionType:type];
  
  /* Load trigger value */
  SEHotKey key = {kHKInvalidVirtualKeyCode, 0, kHKNilUnichar};
  if (se_entry) {
    SparkHotKey *hotkey = [se_entry trigger];
    key.keycode = [hotkey keycode];
    key.modifiers = [hotkey modifier];
    key.character = [hotkey character];
  }
  [trap setHotKey:key];
}

- (SparkApplication *)application {
  return [appField application];
}
- (void)setApplication:(SparkApplication *)anApplication {
  SparkApplication *previous = [appField application];
  if (previous != anApplication) {
    /* Set Application */
    [appField setApplication:anApplication];
    [appField setTitle:[NSString stringWithFormat:@"%@ HotKey", [anApplication name]]];
    [self updatePlugins];
  }
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

- (void)recalculateKeyViewLoop {
  if ([[self window] respondsToSelector:@selector(recalculateKeyViewLoop)]) {
    [[self window] recalculateKeyViewLoop];
    return;
  }
  NSView *first = [se_view nextValidKeyView];
  NSView *last = nil;
  NSView *view = first;
  NSMutableSet *views = [[NSMutableSet alloc] initWithObjects:first, nil];
  
  while ((view = [view nextKeyView]) && ![views containsObject:view] && [view isDescendantOf:se_view]) {
    last = view;
    [views addObject:view];
  }
  [views release];
  
  if (first && first != se_view) {
    [trap setNextKeyView:first];
    if (last) {
      [last setNextKeyView:[pluginView nextValidKeyView]];
    } else {
      [first setNextKeyView:[pluginView nextValidKeyView]];
    }
  } else {
    /* Could not create a valid loop, ask he window to do it */
    if ([[self window] respondsToSelector:@selector(recalculateKeyViewLoop)]) {
      [[self window] recalculateKeyViewLoop];
    } else {
      [trap setNextKeyView:[pluginView nextValidKeyView]];
    }
  }
}

- (void)setActionType:(SparkPlugIn *)aPlugin {
  se_plugin = NSMapGet(se_instances, aPlugin);
  if (!se_plugin) {
    se_plugin = [aPlugin instantiatePlugin];
    if (se_plugin) {
      NSMapInsert(se_instances, aPlugin, se_plugin);
      
      /* Become view ownership */
      [se_views addObject:[se_plugin actionView]];
      /* Say se_plugin to no longer retain the view, so we no longer get a retain cycle. */
      [se_plugin releaseViewOwnership];
      
      // Set plugin action
      BOOL edit = NO;
      Class cls = [aPlugin actionClass];
      SparkAction *action = nil;
      
      if (!cls) { /* Special built-in plugins, do not copy */
        edit = YES;
        action = [se_entry action];
      } else if ([[se_entry action] isKindOfClass:cls]) { /* If is action editor, set a copy */ 
        edit = YES;
        action = [se_entry action];
        if (SKImplementsSelector(action, @selector(copyWithZone:))) {
          action = [[action copy] autorelease];
        } else {
          DLog(@"WARNING: %@ does not implements NSCopying.", [action class]);
          action = [action duplicate];
        }
      } else { /* Other cases, create new action */
        action = [[[cls alloc] init] autorelease];
      }
      /* Set plugin's spark action */
      [se_plugin setSparkAction:action];
      /* Send plugin API notification */
      [se_plugin loadSparkAction:action toEdit:edit];
    }
  }
  /* Remove previous view */
  if (se_view != [se_plugin actionView]) {
    [se_view removeFromSuperview];
    
    se_view = [se_plugin actionView];
    NSAssert1([se_view isKindOfClass:[NSView class]], @"Invalid view for plugin: %@", se_plugin);
    
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
    [self recalculateKeyViewLoop];
    
    unsigned row = [se_plugins indexOfObject:aPlugin];
    if (row != NSNotFound && (int)row != [typeTable selectedRow])
      [typeTable selectRow:row byExtendingSelection:NO];
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
/* Custom resize animation time */
@interface SETrapWindow : HKTrapWindow {
}
- (NSTimeInterval)animationResizeTime:(NSRect)newFrame;
@end

@implementation SETrapWindow

- (NSTimeInterval)animationResizeTime:(NSRect)newFrame {
  float delta = ABS(NSHeight([self frame]) - NSHeight(newFrame));
  return (0.13 * delta / 150.);
}

@end
