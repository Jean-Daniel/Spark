/*
 *  SEEntryEditor.m
 *  Spark Editor
 *
 *  Created by Black Moon Team.
 *  Copyright (c) 2004 - 2007 Shadow Lab. All rights reserved.
 */

#import "SEEntryEditor.h"

#import "Spark.h"
#import "SEPlugInHelp.h"
#import "SEHotKeyTrap.h"
#import "SEBuiltInPlugIn.h"
#import "SEApplicationView.h"
#import "SESeparatorCellView.h"

#import <SparkKit/SparkPlugIn.h>
#import <SparkKit/SparkHotKey.h>
#import <SparkKit/SparkEntry.h>
#import <SparkKit/SparkPrivate.h>
#import <SparkKit/SparkApplication.h>
#import <SparkKit/SparkActionLoader.h>
#import <SparkKit/SparkActionPlugIn.h>

#import <HotKeyToolKit/HotKeyToolKit.h>

#import <WonderBox/WBGeometry.h>
#import <WonderBox/WBFunctions.h>
#import <WonderBox/WBTableView.h>
#import <WonderBox/WBObjCRuntime.h>
#import <WonderBox/NSString+WonderBox.h>

/* Custom resize animation time */
@interface SETrapWindow : HKTrapWindow {
}
- (NSTimeInterval)animationResizeTime:(NSRect)newFrame;
@end

#pragma mark -
@implementation SEEntryEditor {
@private
  NSSize se_min;
  NSView *se_view; /* current view __weak */
  SEHotKeyTrap *se_trap; /* trap field */

  NSMutableArray *se_plugins; /* plugins list */
  SparkActionPlugIn *se_plugin; /* current action plugin __weak */

  NSMapTable *_sizes; /* plugin min sizes */
  NSMutableDictionary *_instances; /* plugin instances */
}

- (id)init {
  if (self = [super init]) {
    se_plugins = [[NSMutableArray alloc] init];
    _sizes = [[NSMapTable alloc] initWithKeyOptions:NSPointerFunctionsStrongMemory | NSPointerFunctionsObjectPersonality
                                       valueOptions:NSPointerFunctionsStrongMemory | NSPointerFunctionsObjectPersonality
                                           capacity:0];
    _instances = [[NSMutableDictionary alloc] init];
    
    se_trap = [[SEHotKeyTrap alloc] initWithFrame:NSMakeRect(0, 0, 114, 22)];
  }
  return self;
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

- (IBAction)close:(id)sender {
  [super close:sender];
  /* Cleanup */
  [se_plugin plugInViewWillBecomeHidden];
  [se_view removeFromSuperview];
  [se_plugin plugInViewDidBecomeHidden];
  se_view = nil;
  se_plugin = nil;
  /* Remove plugins instances */
  [_instances removeAllObjects];
  /* Release entry and reset view */
  self.entry = nil;
}

- (void)createEntryWithAction:(SparkAction *)action trigger:(SparkTrigger *)trigger application:(SparkApplication *)application {
  if (!SPXDelegateHandle(_delegate, editor:shouldCreateEntryWithAction:trigger:application:) ||
			[_delegate editor:self shouldCreateEntryWithAction:action trigger:trigger application:application])
    [self close:nil];
}
- (void)updateEntryWithAction:(SparkAction *)action trigger:(SparkTrigger *)trigger application:(SparkApplication *)application {
  if (!SPXDelegateHandle(_delegate, editor:shouldUpdateEntry:setAction:trigger:application:) ||
			[_delegate editor:self shouldUpdateEntry:_entry setAction:action trigger:trigger application:application])
    [self close:nil];
}

- (IBAction)ok:(id)sender {
  [[self window] endEditingFor:nil]; // commit editing
  
  /* Check trigger */
  NSAlert *alert = nil;
  /* End editing if needed */
  [se_trap validate:sender];
  SEHotKey key = se_trap.hotKey;
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
      SPXLogException(exception);
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
      SPXLogException(exception);
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
      hkey = [[SparkHotKey alloc] init];
      [hkey setKeycode:key.keycode character:key.character];
      [hkey setModifier:key.modifiers];
    }
    if (_entry) {
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
  for (SparkPlugIn *plugin in [SparkActionLoader sharedLoader].plugIns) {
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
  advanced = advanced && (_entry != nil);
  advanced = advanced && (_entry.type != kSparkEntryTypeSpecific);
  
  if (advanced) {
    /* Create Inherits plugin */
    SparkPlugIn *plugin = [[SparkPlugIn alloc] initWithClass:[SEInheritsPlugIn class] identifier:@"org.shadowlab.spark.plugin.inherits"];
    [se_plugins insertObject:plugin atIndex:0];
    
    plugin = [[SparkPlugIn alloc] init];
    [plugin setName:SETableSeparator];
    [se_plugins insertObject:plugin atIndex:1];
  }
  [uiTypeTable reloadData];
}

- (SparkPlugIn *)actionType {
  NSInteger row = [uiTypeTable selectedRow];
  return row >= 0 ? se_plugins[row] : nil;
}

- (void)setEntry:(SparkEntry *)anEntry {
  if (anEntry == _entry)
    return;

  SPXSetterRetain(_entry, anEntry);

  /* Select plugin type */
  SparkPlugIn *type = nil;
  if (_entry) {
    /* Update plugins list if needed */
    [self updatePlugIns];

    switch ([_entry type]) {
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
        type = [[SparkActionLoader sharedLoader] plugInForAction:_entry.action];
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
  if (_entry) {
    SparkHotKey *hotkey = (SparkHotKey *)_entry.trigger;
    NSAssert1([hotkey isKindOfClass:[SparkHotKey class]], @"Does not this kind of trigger: %@", [hotkey class]);
    key.keycode = [hotkey keycode];
    key.modifiers = [hotkey nativeModifier];
    key.character = [hotkey character];
  }
  [se_trap setHotKey:key];
}

- (void)setApplication:(SparkApplication *)anApplication {
  if (_application != anApplication) {
    _application = anApplication;
    /* Set Application */
    [uiApplication setSparkApplication:anApplication];
    [uiApplication setTitle:[NSString stringWithFormat:
														 NSLocalizedStringFromTable(@"APPLICATION_FIELD",
																												@"SEEditor", @"%@ => Application name"), [anApplication name]]];
    [self updatePlugIns];
  }
}

// MARK: -
// MARK: Data Source and Delegate
- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView {
  return [se_plugins count];
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex {
  return [se_plugins objectAtIndex:rowIndex];
}

/* Separator Implementation */
- (CGFloat)tableView:(NSTableView *)tableView heightOfRow:(NSInteger)row {
  return row >= 0 && (NSUInteger)row < se_plugins.count && [[se_plugins[row] name] isEqualToString:SETableSeparator] ? 1 : [tableView rowHeight];
}

- (BOOL)tableView:(NSTableView *)aTableView shouldSelectRow:(NSInteger)rowIndex {
  return rowIndex >= 0 && (NSUInteger)rowIndex < se_plugins.count ? ![[se_plugins[rowIndex] name] isEqualToString:SETableSeparator] : YES;
}

- (nullable NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(nullable NSTableColumn *)tableColumn row:(NSInteger)row {
  if (row >= 0 && (NSUInteger)row < se_plugins.count && [[se_plugins[row] name] isEqualToString:SETableSeparator]) {
    return [tableView makeViewWithIdentifier:@"separator" owner:self];
  }
  return [tableView makeViewWithIdentifier:@"default" owner:self];
}

- (void)setActionType:(SparkPlugIn *)aPlugin {
  [self setActionType:aPlugin force:NO];
}

- (void)loadEntry:(Class)cls {
  // Set plugin action
  BOOL edit = NO;
  SparkAction *action = nil;
  if (!cls) { /* Special built-in plugins, do not copy */
    NSAssert(_entry, @"Invalid entry");
    edit = YES;
    action = _entry.action;
  } else if ([_entry.action isKindOfClass:cls]) { /* If is action editor, set a copy */
    edit = YES;
    action = _entry.action;
		if (WBRuntimeObjectImplementsSelector(action, @selector(copyWithZone:))) {
      action = [action copy];
    } else {
      SPXLogWarning(@"%@ does not implements NSCopying.", [action class]);
      action = [action duplicate];
    }
		[action setUID:0]; // this copy should be considere as a new action.
  } else { /* Other cases, create new action */
    action = [[cls alloc] init];
    if (_entry.action)
      [action setPropertiesFromAction:_entry.action];
	}
	/* Set plugin's spark action */
	[se_plugin setSparkAction:action edit:edit];
}

- (void)setActionType:(SparkPlugIn *)aPlugin force:(BOOL)force {
  SparkActionPlugIn *previousPlugin = se_plugin;
  se_plugin = _instances[aPlugin.identifier];
  if (!se_plugin) {
    se_plugin = [aPlugin instantiatePlugIn];
    if (se_plugin) {
      _instances[aPlugin.identifier] = se_plugin;
      [self loadEntry:[aPlugin actionClass]];
    }
  } else if (force) {
    [self loadEntry:[aPlugin actionClass]];
  } /* if (!se_plugin) */
  
  /* Configure Help Button */
  BOOL hasHelp = nil != [[se_plugin class] helpURL];
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
        vrect.origin.x = round((se_min.width - NSWidth(vrect)) / 2);
      }
    }
    if (NSHeight(vrect) < se_min.height) {
      // Adjust height
      if ([se_view autoresizingMask] & NSViewHeightSizable) {
        vrect.size.height = se_min.height;
      } else {
        vrect.origin.y = round((se_min.height - NSHeight(vrect)) / 2);
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
    pframe.origin.x -= delta.width / 2;
    pframe.origin.y -= delta.height;
    [window setFrame:pframe display:YES animate:YES];
    
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
      NSValue *vmin = [_sizes objectForKey:se_plugin];
      if (!vmin) {
        min = wframe.size;
        vmin = [NSValue valueWithSize:min];
        [_sizes setObject:vmin forKey:se_plugin];
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
