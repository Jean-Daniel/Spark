//
//  ActionEditorView.m
//  Spark Editor
//
//  Created by Grayfox on 18/09/04.
//  Copyright 2004 Shadow Lab. All rights reserved.
//

#import "ActionEditor.h"
#import "ServerController.h"
#import <SparkKit/SparkKit.h>

NSString * const kActionEditorWillChangePluginNotification = @"ActionEditorWillChangePluginNotification";
NSString * const kActionEditorDidChangePluginNotification = @"ActionEditorDidChangePluginNotification";

@interface ActionEditorView : ActionEditor {
  IBOutlet id categorieView;
  IBOutlet NSView *pluginView;
  
  IBOutlet NSTabView *titleTabView;
  IBOutlet NSPopUpButton *categoriePopup;
  IBOutlet NSImageView *pluginIcon;
  IBOutlet NSTextField *pluginName;
@private
  id _delegate;
  NSSize defaultMinSize;
  
  NSMutableSet *_actionViews;
  NSMutableDictionary *_plugins;
  
  SparkActionPlugIn *_plugin; /* Weak Ref */
}

- (BOOL)helpAvailable;

- (BOOL)allowsChangeActionType;
- (void)setAllowsChangeActionType:(BOOL)canChange;

- (SparkPlugIn *)selectedPlugin;
- (void)selectActionPlugin:(SparkPlugIn *)plugin;

- (IBAction)selectPlugin:(id)sender;
- (IBAction)showPluginHelp:(id)sender;

- (NSAlert *)checkAction;
- (NSAlert *)configureAction;

- (void)setActionPlugin:(Class)pluginClass;
- (BOOL)loadActionPlugin:(Class)plugin;
- (void)setPlugInView:(NSView *)view;

- (void)buildPlugInMenu;

@end

#pragma mark -
@interface ActionEditorNibLoader : NSObject {
  IBOutlet ActionEditorView *editorView;
}

- (id)editorView;

@end

#pragma mark -
@implementation ActionEditorView

- (void)awakeFromNib {
  [self buildPlugInMenu];
  defaultMinSize = [pluginView frame].size;
  [titleTabView selectTabViewItemAtIndex:0];
}

- (id)initWithFrame:(NSRect)frame {
  if (self = [super initWithFrame:frame]) {
    _actionViews = [[NSMutableSet alloc] init];
    _plugins = [[NSMutableDictionary alloc] init];
  }
  return self;
}

- (void)dealloc {
  [self setDelegate:nil];
  [_plugins release];
  [_actionViews release];
  [super dealloc];
}

- (id)delegate {
  return _delegate;
}

- (void)setDelegate:(id)delegate {
  if (_delegate != delegate) {
    if (_delegate) {
      [[NSNotificationCenter defaultCenter] removeObserver:_delegate
                                                      name:nil
                                                    object:self];
    }
    _delegate = delegate;
    if (_delegate) {
      SKRegisterDelegateForNotification(_delegate, @selector(actionEditorWillChangePlugin:), kActionEditorWillChangePluginNotification);
      SKRegisterDelegateForNotification(_delegate, @selector(actionEditorDidChangePlugin:), kActionEditorDidChangePluginNotification);
    }
  }
}

#pragma mark -
#pragma mark UI Elements accessor.
- (NSMenu *)pluginMenu {
  return [categoriePopup menu];
}

#pragma mark -
#pragma mark IBActions
- (NSAlert *)create {
  id alert = [self checkAction];
  if (nil == alert)
    alert = [self configureAction];
  return alert;
}

- (NSAlert *)update {
  id alert = [self checkAction];
  if (nil == alert)
    alert = [self configureAction];
  if (nil == alert) {
    [[_plugin sparkAction] setInvalid:NO];
    [[NSNotificationCenter defaultCenter] postNotificationName:kSparkActionDidChangeNotification object:[_plugin sparkAction]];
  }
  return alert;
}

- (void)revert {
  [_plugin revertEditing];
}

- (IBAction)selectPlugin:(id)sender {
  [self setActionPlugin:[sender representedObject]];
}

- (IBAction)showPluginHelp:(id)sender {
  if (_plugin)
    [[NSApp delegate] showPlugInHelpPage:[[_plugin class] plugInName]];
}

#pragma mark -
#pragma mark Action Manipulation
- (id)sparkAction {
  return [_plugin sparkAction];
}
- (void)setSparkAction:(id)sparkAction {
  NSParameterAssert(nil != sparkAction);
  if ([_plugin sparkAction] != sparkAction) { 
    /* Configure Editor */
    //[self setAllowsChangeActionType:NO];
    
    id plugin = [[SparkActionLoader sharedLoader] plugInForAction:sparkAction];
    [self selectActionPlugin:plugin];
    /* Set Privates _plugin ivar */
    if ([_delegate respondsToSelector:@selector(undoManagerForActionEditor:)]) {
      [_plugin setUndoManager:[_delegate undoManagerForActionEditor:self]];
    }
#ifdef DEBUG
    else {
      NSLog(@"Unable to obtains UndoManager from delegate");
    }
#endif
    [_plugin setSparkAction:sparkAction];
    
    /* Call public method */
    [_plugin loadSparkAction:sparkAction toEdit:YES];
  }
}

- (NSAlert *)checkAction {
  return [_plugin sparkEditorShouldConfigureAction];
}

- (NSAlert *)configureAction {
  [_plugin configureAction];
  if ([[[[_plugin sparkAction] name] stringByTrimmingWhitespaceAndNewline] length] == 0) {
    return [NSAlert alertWithMessageText:NSLocalizedStringFromTable(@"CREATE_ACTION_WITHOUT_NAME_ALERT",
                                                                    @"Editors", @"Create Action without Name")
                           defaultButton:NSLocalizedStringFromTable(@"OK",
                                                                    @"Editors", @"Alert default button")
                         alternateButton:nil
                             otherButton:nil
               informativeTextWithFormat:NSLocalizedStringFromTable(@"CREATE_ACTION_WITHOUT_NAME_ALERT_MSG",
                                                                    @"Editors", @"Create Action without Name")];
  }
  return nil;
}

#pragma mark -
#pragma mark Plugin Manipulation
- (SparkPlugIn *)selectedPlugin {
  return (_plugin) ? [[SparkActionLoader sharedLoader] pluginForClass:[_plugin class]] : nil;
}

- (void)selectActionPlugin:(SparkPlugIn *)plugin {
  if (nil == plugin) {
    [categoriePopup selectItemAtIndex:0]; 
  } else { /* Select Menu Item */
    Class pluginClass = [plugin principalClass];
    id items = [[categoriePopup itemArray] objectEnumerator];
    id item;
    while (item = [items nextObject]) {
      if ([[item representedObject] isEqual:pluginClass]) {
        [categoriePopup selectItem:item];
        break;
      }
    }
  }
  [self selectPlugin:[categoriePopup selectedItem]];
}

- (void)setActionPlugin:(Class)pluginClass {
  if ([_plugin class] == pluginClass)
    return;
  [[NSNotificationCenter defaultCenter] postNotificationName:kActionEditorWillChangePluginNotification object:self];
  [[pluginView subviews] makeObjectsPerformSelector:@selector(removeFromSuperview)];
  _plugin = nil;
  if (pluginClass && [self loadActionPlugin:pluginClass]) {
    Class actionClass = [pluginClass actionClass];
    if (nil == [_plugin sparkAction]) {
      id action = [[actionClass alloc] init];
      [_plugin setSparkAction:action];
      [_plugin loadSparkAction:action toEdit:NO];        
      [action release];
    }
    [pluginIcon setImage:[pluginClass plugInIcon]];
    [pluginName setStringValue:[pluginClass plugInName]];
    [pluginName sizeToFit];
    float titleW = NSWidth([pluginIcon frame]) + 8 + NSWidth([pluginName frame]);
    float x = (NSWidth([titleTabView frame]) - titleW) / 2;
    NSPoint origin = [pluginIcon frame].origin;
    origin.x = x;
    [pluginIcon setFrameOrigin:origin];
    origin = [pluginName frame].origin;
    origin.x = x + 8 + 16;
    [pluginName setFrameOrigin:origin];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:kActionEditorDidChangePluginNotification object:self];
  }
}

- (BOOL)loadActionPlugin:(Class)pluginClass {
  NSAssert(nil != pluginClass, @"Invalid pluginClass Parameter. Cannot be nil.");
  _plugin = [_plugins objectForKey:pluginClass];
  if (nil == _plugin) {
    _plugin = [[pluginClass alloc] init];
    [_plugins setObject:_plugin forKey:pluginClass];
    [_plugin release];
  }
  if (_plugin) {
    id view = [_plugin actionView];
    if (view) {
      if (![_actionViews containsObject:view]) {
        [_actionViews addObject:view];
      }
      [self setPlugInView:view];
      return YES;
    }
  }
  return NO;
}

- (void)setPlugInView:(NSView *)view {
  float deltaW, deltaH;
  NSSize minSize = ([self allowsChangeActionType]) ? defaultMinSize : NSZeroSize;
  
  /* On centre la vue si elle est plus petite */
  NSPoint origin = NSZeroPoint;
  if (minSize.width > NSWidth([view frame])) {
    deltaW = minSize.width - NSWidth([pluginView frame]);
    origin.x = (minSize.width - NSWidth([view frame])) / 2;
    origin.x = roundf(origin.x); /* If doesn't round, can produce distorded view */
  } else {
    deltaW = NSWidth([view frame]) - NSWidth([pluginView frame]);
  }
  if (minSize.height > NSHeight([view frame])) {
    deltaH = minSize.height - NSHeight([pluginView frame]);
    origin.y = (minSize.height - NSHeight([view frame])) / 2;
    origin.y = roundf(origin.y); /* If doesn't round, can produce distorded view */
  } else {
    deltaH = NSHeight([view frame]) - NSHeight([pluginView frame]);
  }
  [view setFrameOrigin:origin];
  
  NSRect winFrame = [[self window] frame];
  if (deltaW != 0 || deltaH != 0) {
    winFrame.size.width += deltaW;
    winFrame.size.height += deltaH;
    winFrame.origin.x -= deltaW/2;
    winFrame.origin.y -= deltaH;
  }
  if ([[self delegate] respondsToSelector:@selector(actionEditor:willResize:forView:)]) {
    NSSize newSize = [[self delegate] actionEditor:self willResize:winFrame.size forView:view]; 
    if (newSize.width != NSWidth(winFrame) || newSize.height != NSHeight(winFrame)) {
      winFrame.origin.x -= (newSize.width - NSWidth(winFrame)) / 2;
      winFrame.origin.y -= (newSize.height - NSHeight(winFrame)) / 2;
    }
    winFrame.size = newSize;
  }
  [[self window] setFrame:winFrame display:YES animate:YES];
  minSize = [[[self window] contentView] frame].size;
  [[self window] setMinSize:minSize];
  [pluginView addSubview:view];
  
  NSSize maxWinSize = minSize;
  int mask = [view autoresizingMask];
  if (mask & NSViewWidthSizable) {
    maxWinSize.width = FLT_MAX;
  }
  if (mask & NSViewHeightSizable) {
    maxWinSize.height = FLT_MAX;
  }
  [[self window] setShowsResizeIndicator:(FLT_MAX == maxWinSize.width) || (FLT_MAX == maxWinSize.height)];
  [[self window] setMaxSize:maxWinSize];
}

#pragma mark -
- (BOOL)helpAvailable {
  return nil != [[_plugin class] helpFile];
}

- (BOOL)allowsChangeActionType {
  return [titleTabView indexOfTabViewItem:[titleTabView selectedTabViewItem]] == 0;
}

- (void)setAllowsChangeActionType:(BOOL)flag {
  [titleTabView selectTabViewItemAtIndex:(flag) ? 0 : 1];
}

#pragma mark -
- (void)buildPlugInMenu {
  [categoriePopup removeAllItems];
  
  id menu = [categoriePopup menu];
  
  id desc = [[NSSortDescriptor alloc] initWithKey:@"name" ascending:YES selector:@selector(caseInsensitiveCompare:)];
  id plugIns = [[[SparkActionLoader sharedLoader] plugins] sortedArrayUsingDescriptors:[NSArray arrayWithObject:desc]];
  [desc release];
  plugIns = [plugIns objectEnumerator];
  id plugIn;
  while (plugIn = [plugIns nextObject]) {
    id menuItem = [[NSMenuItem alloc] initWithTitle:[plugIn name] action:nil keyEquivalent:@""];
    [menuItem setImage:[plugIn icon]];
    [menuItem setRepresentedObject:[plugIn principalClass]];
    [menuItem setAction:@selector(selectPlugin:)];
    [menuItem setTarget:self];
    [menu addItem:menuItem];
    [menuItem release];
  }
}

@end

#pragma mark -
@implementation ActionEditorNibLoader

- (id)init {
  if (self = [super init]) {
    [NSBundle loadNibNamed:@"ActionEditorView" owner:self];
  }
  return self;
}

- (void)dealloc {
  [editorView release];
  [super dealloc];
}

- (id)editorView {
  return editorView;
}

@end

#pragma mark -
@implementation ActionEditor

- (id)initWithFrame:(NSRect)frame {
  if ([self isMemberOfClass:[ActionEditor class]]) {
    [self release];
    self = nil;
    ActionEditorNibLoader *loader = [[ActionEditorNibLoader alloc] init];
    if (self = [loader editorView]) {
      [self retain];
      [self setFrame:frame];
    }
    [loader release];
  } else {
    self = [super initWithFrame:frame];
  }
  return self;
}

- (NSAlert *)create { return nil; }
- (void)cancel {}

- (NSAlert *)update { return nil; }
- (void)revert {}

@end
