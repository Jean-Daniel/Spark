/*
 *  SEEntryEditor.m
 *  Spark Editor
 *
 *  Created by Black Moon Team.
 *  Copyright (c) 2004 - 2007 Shadow Lab. All rights reserved.
 */

#import "SEEntryEditor.h"

#import "Spark.h"
#import "SETableView.h"
#import "SEPlugInHelp.h"
#import "SEHeaderCell.h"
#import "SEHotKeyTrap.h"
#import "SEBuiltInPlugIn.h"
#import "SEApplicationView.h"

#import <SparkKit/SparkPlugIn.h>
#import <SparkKit/SparkHotKey.h>
#import <SparkKit/SparkEntry.h>
#import <SparkKit/SparkPrivate.h>
#import <SparkKit/SparkApplication.h>
#import <SparkKit/SparkActionLoader.h>
#import <SparkKit/SparkActionPlugIn.h>

#import <HotKeyToolKit/HotKeyToolKit.h>

#import WBHEADER(WBGeometry.h)
#import WBHEADER(WBFunctions.h)
#import WBHEADER(WBObjCRuntime.h)
#import WBHEADER(NSString+WonderBox.h)

/* Custom resize animation time */
@interface SETrapWindow : HKTrapWindow {
}
- (NSTimeInterval)animationResizeTime:(NSRect)newFrame;
@end

#pragma mark -
@implementation SEEntryEditor

- (id)init {
  if (self = [super init]) {
    se_views = [[NSMutableArray alloc] init];
    se_plugins = [[NSMutableArray alloc] init];
    se_sizes = NSCreateMapTable(NSObjectMapKeyCallBacks, NSObjectMapValueCallBacks, 0);
    se_instances = NSCreateMapTable(NSObjectMapKeyCallBacks, NSObjectMapValueCallBacks, 0);
    
    se_trap = [[SEHotKeyTrap alloc] initWithFrame:NSMakeRect(0, 0, 114, 22)];
  }
  return self;
}

- (void)dealloc {
  [se_trap release];
  [se_entry release];
  [se_views release];
  [se_plugins release];
  [se_application release];
  if (se_sizes) NSFreeMapTable(se_sizes);
  if (se_instances) NSFreeMapTable(se_instances);
  [super dealloc];
}

- (void)awakeFromNib {
  /* Configure Library Header Cell */
  SEHeaderCell *header = [[SEHeaderCell alloc] initTextCell:NSLocalizedStringFromTable(@"HOTKEY_TYPE_HEADER",
                                                                                       @"SEEditor", @"Hotkey Type column header")];
  [header setAlignment:NSCenterTextAlignment];
  [header setFont:[NSFont systemFontOfSize:11]];
  [[[uiTypeTable tableColumns] objectAtIndex:0] setHeaderCell:header];
  [header release];
  [uiTypeTable setCornerView:[[[SEHeaderCellCorner alloc] initWithFrame:NSMakeRect(0, 0, 22, 22)] autorelease]];
}

- (void)windowDidLoad {
  [super windowDidLoad];
  /* Compute minimum plugin view size */
  NSSize smin = [[self window] contentMinSize];
  /* Want window content size in point => window frame is in pixels */
  NSSize scur = [[self window] contentRectForFrameRect:[[self window] frame]].size;
  NSSize delta = { scur.width - smin.width, scur.height - smin.height };
  
  se_min = [uiPlugin frame].size;
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
  [se_plugin plugInViewWillBecomeHidden];
  [se_view removeFromSuperview];
  [se_plugin plugInViewDidBecomeHidden];
  se_view = nil;
  se_plugin = nil;
  /* Remove plugins instances */
  [se_views removeAllObjects];
  NSResetMapTable(se_instances);
  /* Release entry */
  [se_entry release];
  se_entry = nil;
}

- (void)createEntryWithAction:(SparkAction *)action trigger:(SparkTrigger *)trigger application:(SparkApplication *)application {
  if (!WBDelegateHandle(se_delegate, editor:shouldCreateEntryWithAction:trigger:application:) || 
			[se_delegate editor:self shouldCreateEntryWithAction:action trigger:trigger application:application])
    [self close:nil];
}
- (void)updateEntryWithAction:(SparkAction *)action trigger:(SparkTrigger *)trigger application:(SparkApplication *)application {
  if (!WBDelegateHandle(se_delegate, editor:shouldUpdateEntry:setAction:trigger:application:) ||
			[se_delegate editor:self shouldUpdateEntry:se_entry setAction:action trigger:trigger application:application])
    [self close:nil];
}

- (IBAction)ok:(id)sender {
  [[self window] endEditingFor:nil]; // commit editing
  
  /* Check trigger */
  NSAlert *alert = nil;
  /* End editing if needed */
  [se_trap validate:sender];
  SEHotKey key = [se_trap hotkey];
  if (kHKInvalidVirtualKeyCode == key.keycode || kHKNilUnichar == key.character) {
    alert = [NSAlert alertWithMessageText:NSLocalizedStringFromTable(@"EMPTY_TRIGGER_ALERT",
                                                                     @"SEEditor", @"Invalid Shortcut - Title")
                            defaultButton:NSLocalizedStringFromTable(@"OK",
                                                                     @"SEEditor", @"OK - Button")
                          alternateButton:nil
                              otherButton:nil
                informativeTextWithFormat:NSLocalizedStringFromTable(@"EMPTY_TRIGGER_ALERT_MSG",
                                                                     @"SEEditor", @"Invalid Shortcut - Message")];
  }
  /* Then check action */
  if (!alert)
    @try {
      alert = [se_plugin sparkEditorShouldConfigureAction];
    } @catch (id exception) {
      WBLogException(exception);
      NSString *name = [exception respondsToSelector:@selector(name)] ? [exception name] : @"<undefined>";
      NSString *message = [exception respondsToSelector:@selector(reason)] ? [exception reason] : [exception description];
      alert = [NSAlert alertWithMessageText:NSLocalizedStringFromTable(@"UNEXPECTED_PLUGIN_EXCEPTION",
                                                                       @"SEEditor", @"Plugin raise exception - Title")
                              defaultButton:NSLocalizedStringFromTable(@"OK",
                                                                       @"SEEditor", @"OK - Button")
                            alternateButton:nil
                                otherButton:nil
                  informativeTextWithFormat:@"%@: %@", name, message];
    }
  if (!alert) {
    @try {
      [se_plugin configureAction];
      
      // Check name
      NSString *name = [[se_plugin sparkAction] name];
      if ([[name stringByTrimmingWhitespace] length] == 0) {
        alert = [NSAlert alertWithMessageText:NSLocalizedStringFromTable(@"EMPTY_NAME_ALERT",
                                                                         @"SEEditor", @"Empty Action Name - Title")
                                defaultButton:NSLocalizedStringFromTable(@"OK",
                                                                         @"SEEditor", @"OK - Button")
                              alternateButton:nil
                                  otherButton:nil
                    informativeTextWithFormat:NSLocalizedStringFromTable(@"EMPTY_NAME_ALERT_MSG",
                                                                         @"SEEditor", @"Empty Action Name - Message")];
      }
      
    } @catch (id exception) {
      WBLogException(exception);
      NSString *name = [exception respondsToSelector:@selector(name)] ? [exception name] : @"<undefined>";
      NSString *message = [exception respondsToSelector:@selector(reason)] ? [exception reason] : [exception description];
      alert = [NSAlert alertWithMessageText:NSLocalizedStringFromTable(@"UNEXPECTED_PLUGIN_EXCEPTION",
                                                                       @"SEEditor", @"Plugin raise exception - Title")
                              defaultButton:NSLocalizedStringFromTable(@"OK",
                                                                       @"SEEditor", @"OK - Button")
                            alternateButton:nil
                                otherButton:nil
                  informativeTextWithFormat:@"%@: %@", name, message];
    }
  }
  if (alert) { 
    [alert runModal];
  } else {
    SparkHotKey *hkey = nil;
		SparkAction *action = nil;
    if (![se_plugin isKindOfClass:[SEInheritsPlugIn class]]) {
			action = [se_plugin sparkAction];
      hkey = [[[SparkHotKey alloc] init] autorelease];
      [hkey setKeycode:key.keycode character:key.character];
      [hkey setModifier:key.modifiers];
    }
    if (se_entry) {
      [self updateEntryWithAction:action trigger:hkey application:[self application]];
    } else {
      [self createEntryWithAction:action trigger:hkey application:[self application]];
    }
  }
}

- (IBAction)cancel:(id)sender {
  [self close:sender];
}

- (IBAction)openHelp:(id)sender {
  // Open plugin help (selected plugin)
  [[SEPlugInHelp sharedPlugInHelp] setPlugIn:[self actionType]];
  [[SEPlugInHelp sharedPlugInHelp] showWindow:sender];
}

#pragma mark -
- (void)updatePlugIns {
  /* First, remove all objects */
  [se_plugins removeAllObjects];
  
  /* Then add standards plugins */
  SparkPlugIn *plugin;
  NSEnumerator *plugins = [[SparkActionLoader sharedLoader] plugInEnumerator];
  while (plugin = [plugins nextObject]) {
    if ([plugin isEnabled])
      [se_plugins addObject:plugin];
  }
  /* and sort */
  [se_plugins sortUsingDescriptors:gSortByNameDescriptors];
  
  /* plugins list should contains "Inherit" if:
	 - Application uid != 0.
	 - Edit an existing entry (is updating).
	 - Not a specific action (else global action is nil).
	 */
  BOOL advanced = [[self application] uid] != 0;
  advanced = advanced && (se_entry != nil);
  advanced = advanced && ([se_entry type] != kSparkEntryTypeSpecific);
  
  if (advanced) {
    /* Create Inherits plugin */
    plugin = [[SparkPlugIn alloc] initWithClass:[SEInheritsPlugIn class] identifier:@"org.shadowlab.spark.plugin.inherits"];
    [se_plugins insertObject:plugin atIndex:0];
    [plugin release];
    
    plugin = [[SparkPlugIn alloc] init];
    [plugin setName:SETableSeparator];
    [se_plugins insertObject:plugin atIndex:1];
    [plugin release];
  }
  [uiTypeTable reloadData];
}

- (SparkPlugIn *)actionType {
  NSInteger row = [uiTypeTable selectedRow];
  return row >= 0 ? [se_plugins objectAtIndex:row] : nil;
}

- (SparkEntry *)entry {
  return se_entry;
}
- (void)setEntry:(SparkEntry *)anEntry {
  if (!WBSetterRetain(&se_entry, anEntry))
    return;
  
  /* Update plugins list if needed */
  [self updatePlugIns];
  
  /* Select plugin type */
  SparkPlugIn *type = nil;
  if (se_entry) {
    switch ([se_entry type]) {
      case kSparkEntryTypeDefault:
      case kSparkEntryTypeWeakOverWrite:
        if ([[self application] uid] != 0) {
          type = [se_plugins objectAtIndex:0];
          [se_trap setEnabled:NO];
          break;
        }
        // else fall through
			default:
        // TODO. trap should not be enabled ?
        type = [[SparkActionLoader sharedLoader] plugInForAction:[se_entry action]];
        [se_trap setEnabled:YES];
        break;
    }
    [uiConfirm setTitle:NSLocalizedStringFromTable(@"ENTRY_EDITOR_UPDATE",
                                                   @"SEEditor", @"Entry Editor Update Button")];
  } else {
    // set create
    [se_trap setEnabled:YES];
    [uiConfirm setTitle:NSLocalizedStringFromTable(@"ENTRY_EDITOR_CREATE",
                                                   @"SEEditor", @"Entry Editor Update Button")];
  }
  if (type) {
    [self setActionType:type force:YES];
  }
  
  /* Load trigger value */
  SEHotKey key = {kHKInvalidVirtualKeyCode, 0, kHKNilUnichar};
  if (se_entry) {
    SparkHotKey *hotkey = (SparkHotKey *)[se_entry trigger];
    NSAssert1([hotkey isKindOfClass:[SparkHotKey class]], @"Does not this kind of trigger: %@", [hotkey class]);
    key.keycode = [hotkey keycode];
    key.modifiers = [hotkey nativeModifier];
    key.character = [hotkey character];
  }
  [se_trap setHotKey:key];
}

- (SparkApplication *)application {
  return se_application;
}
- (void)setApplication:(SparkApplication *)anApplication {
  if (se_application != anApplication) {
    [se_application release];
    se_application = [anApplication retain];
    /* Set Application */
    [uiApplication setSparkApplication:anApplication];
    [uiApplication setTitle:[NSString stringWithFormat:
														 NSLocalizedStringFromTable(@"APPLICATION_FIELD",
																												@"SEEditor", @"%@ => Application name"), [anApplication name]]];
    [self updatePlugIns];
  }
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView {
  return [se_plugins count];
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex {
  return [se_plugins objectAtIndex:rowIndex];
}

/* Separator Implementation */
- (CGFloat)tableView:(NSTableView *)tableView heightOfRow:(NSInteger)row {
  return row >= 0 && [[[se_plugins objectAtIndex:row] name] isEqualToString:SETableSeparator] ? 1 : [tableView rowHeight];
}
- (BOOL)tableView:(NSTableView *)aTableView shouldSelectRow:(NSInteger)rowIndex {
  return rowIndex >= 0 ? ![[[se_plugins objectAtIndex:rowIndex] name] isEqualToString:SETableSeparator] : YES;
}

- (void)setActionType:(SparkPlugIn *)aPlugin {
  [self setActionType:aPlugin force:NO];
}

- (void)loadEntry:(Class)cls {
  // Set plugin action
  BOOL edit = NO;
  SparkAction *action = nil;
  if (!cls) { /* Special built-in plugins, do not copy */
    NSAssert(se_entry, @"Invalid entry");
    edit = YES;
    action = [se_entry action];
  } else if (se_entry && [[se_entry action] isKindOfClass:cls]) { /* If is action editor, set a copy */ 
    edit = YES;
    action = [se_entry action];
		if (WBRuntimeObjectImplementsSelector(action, @selector(copyWithZone:))) {
      action = [[action copy] autorelease];
    } else {
      WBLogWarning(@"%@ does not implements NSCopying.", [action class]);
      action = [action duplicate];
    }
		[action setUID:0]; // this copy should be considere as a new action.
  } else { /* Other cases, create new action */
    action = [[[cls alloc] init] autorelease];
    if ([se_entry action])
      [action setPropertiesFromAction:[se_entry action]];
	}
	/* Set plugin's spark action */
	[se_plugin setSparkAction:action edit:edit];
}

- (void)setActionType:(SparkPlugIn *)aPlugin force:(BOOL)force {
  SparkActionPlugIn *previousPlugin = se_plugin;
  se_plugin = NSMapGet(se_instances, aPlugin);
  if (!se_plugin) {
    se_plugin = [aPlugin instantiatePlugIn];
    if (se_plugin) {
      NSMapInsert(se_instances, aPlugin, se_plugin);
      
      /* Become view ownership */
      [se_views addObject:[se_plugin actionView]];
      /* Say se_plugin to no longer retain the view, so we no longer get a retain cycle. */
      [se_plugin releaseViewOwnership];
      
      [self loadEntry:[aPlugin actionClass]];
    }
  } else if (force) {
    [self loadEntry:[aPlugin actionClass]];
  } /* if (!se_plugin) */
  
  /* Configure Help Button */
  BOOL hasHelp = nil != [[se_plugin class] helpFile];
  [uiHelp setHidden:!hasHelp];
  [uiHelp setEnabled:hasHelp];
  
  /* Remove previous view */
  if (se_view != [se_plugin actionView]) {
    [previousPlugin plugInViewWillBecomeHidden];
    [se_view removeFromSuperview];
    [previousPlugin plugInViewDidBecomeHidden];
    
    [previousPlugin setHotKeyTrap:nil];
    if ([se_trap superview])
      [se_trap removeFromSuperview];
    [se_plugin setHotKeyTrap:se_trap];
    
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
        vrect.origin.x = round(AVG(se_min.width, -NSWidth(vrect)));
      }
    }
    if (NSHeight(vrect) < se_min.height) {
      // Adjust height
      if ([se_view autoresizingMask] & NSViewHeightSizable) {
        vrect.size.height = se_min.height;
      } else {
        vrect.origin.y = round(AVG(se_min.height, -NSHeight(vrect)));
      }
    }
    [se_view setFrame:vrect];
    
    /* current size */
    NSSize csize = [uiPlugin frame].size;
    /* destination rect */
    NSRect drect = vrect;
    drect.size.width = MAX(NSWidth(vrect), se_min.width);
    drect.size.height = MAX(NSHeight(vrect), se_min.height);
    /* compute delta between current size and destination size */
    NSSize delta = {NSWidth(drect) - csize.width, NSHeight(drect) - csize.height};
    
    NSWindow *window = [self window];
    /* Resize window frame */
    NSRect wframe = [window frame];
    /* convert frame in point units (delta is expressed in point) */
    wframe = [window contentRectForFrameRect:wframe];
    wframe.size.width += delta.width;
    wframe.size.height += delta.height;
    /* set frame (in pixel units) */
    NSRect pframe = [window frameRectForContentRect:wframe];
    /* Adjust window position using screen factor */
    CGFloat sscale = WBScreenUserSpaceScaleFactor([window screen]);
    pframe.origin.x -= sscale * delta.width / 2;
    pframe.origin.y -= sscale * delta.height;
    [window setFrame:pframe display:YES animate:YES];
    
    /* bug in NSWindow */
		if (WBSystemMinorVersion() == 10 && WBSystemMinorVersion() <= 4)
			wframe.size.height += 22 / WBWindowUserSpaceScaleFactor(window);
    
    /* Adjust window attributes */
    NSSize smax = wframe.size;
    NSUInteger mask = [se_view autoresizingMask];
    if (mask & NSViewWidthSizable) {
      smax.width = CGFLOAT_MAX;
    }
    if (mask & NSViewHeightSizable) {
      smax.height = CGFLOAT_MAX;
    }
    if (MAXFLOAT <= smax.width || MAXFLOAT <= smax.height) {
      [window setShowsResizeIndicator:YES];
      NSSize min;
      NSValue *vmin = NSMapGet(se_sizes, se_plugin);
      if (!vmin) {
        min = wframe.size;
        vmin = [NSValue valueWithSize:min];
        NSMapInsert(se_sizes, se_plugin, vmin);
      } else {
        min = [vmin sizeValue];
      }
      
      [window setContentMinSize:min];
    } else {
      [window setShowsResizeIndicator:NO];
      [window setContentMinSize:smax];
    }
    [window setContentMaxSize:smax];
    
    [se_plugin plugInViewWillBecomeVisible];
    [uiPlugin addSubview:se_view];
    [[self window] recalculateKeyViewLoop];
    [se_plugin plugInViewDidBecomeVisible];
    
    NSUInteger row = [se_plugins indexOfObject:aPlugin];
    if (row != NSNotFound && (NSInteger)row != [uiTypeTable selectedRow])
      [uiTypeTable selectRowIndexes:[NSIndexSet indexSetWithIndex:row] byExtendingSelection:NO];
  }
}

- (void)tableViewSelectionDidChange:(NSNotification *)aNotification {
  NSInteger row = [[aNotification object] selectedRow];
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
  if (kSparkEnableAllSingleKey == SparkGetFilterMode()) {
    return NO;
  } else {
    UInt16 code = [theEvent keyCode];
    NSUInteger mask = [theEvent modifierFlags] & SEValidModifiersFlags;
    /* Shift tab is a navigation shortcut */
    if (NSShiftKeyMask == mask && code == kHKVirtualTabKey)
      return YES;
    
    return mask ? NO : (code == kHKVirtualEnterKey)
		|| (code == kHKVirtualReturnKey)
		|| (code == kHKVirtualEscapeKey)
		|| (code == kHKVirtualTabKey);
  }
}

- (BOOL)trapWindow:(HKTrapWindow *)window isValidHotKey:(HKKeycode)keycode modifier:(HKModifier)modifier {
  return SparkHotKeyFilter(keycode, modifier);
}

@end

#pragma mark -

@implementation SETrapWindow

- (NSTimeInterval)animationResizeTime:(NSRect)newFrame {
  NSEvent *event = [NSApp currentEvent];
  CGFloat factor = WBWindowUserSpaceScaleFactor(self);
  /* Want 150 points per time unit => 150*scale pixels */
  CGFloat delta = ABS(NSHeight([self frame]) - NSHeight(newFrame));
  if (([event modifierFlags] & NSDeviceIndependentModifierFlagsMask) == NSShiftKeyMask) {
    return (1.f * delta / (150. * factor)); //(1.25f * delta / 150.);
  } else {
    return (0.13 * delta / (150. * factor));
  }
}

@end
