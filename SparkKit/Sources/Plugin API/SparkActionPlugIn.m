/* 
 *  SparkActionPlugIn.m
 *  SparkKit
 *
 *  Created by Black Moon Team.
 *  Copyright (c) 2004 - 2007 Shadow Lab. All rights reserved.
 */

#import "SparkPrivate.h"

#import <SparkKit/SparkAction.h>
#import <SparkKit/SparkPluginView.h>
#import <SparkKit/SparkPreferences.h>
#import <SparkKit/SparkActionPlugIn.h>

#import <ShadowKit/SKExtensions.h>
#import <ShadowKit/SKAppKitExtensions.h>

@interface SparkViewPlaceholder : NSObject {
  @private
  NSView *sp_view;
  NSView *sp_placeholder;
}

- (void)setView:(NSView *)aView;
- (void)setPlaceholderView:(NSView *)aView;

@end

@implementation SparkActionPlugIn

- (id)init {
  if (self = [super init]) {
    sp_trap = [[SparkViewPlaceholder alloc] init];
  }
  return self;
}

- (void)dealloc {
  [sp_ctrl release];
  [sp_trap release];
  if (sp_apFlags.ownership)
    [actionView release];
  [sp_action release];
  [super dealloc];
}

- (SparkPluginView *)sp_controller {
  if (!sp_ctrl) {
    sp_ctrl = [[SparkPluginView alloc] init];
    [sp_ctrl setPlugin:self];
    [sp_ctrl setPluginView:actionView];
    [self setHotKeyTrapPlaceholder:[sp_ctrl trapPlaceholder]];
  }
  return sp_ctrl;
}

- (BOOL)hasCustomView {
  return NO;
}

- (NSView *)actionView {
  return [self hasCustomView] ? actionView : [[self sp_controller] view];
}

- (void)setHotKeyTrap:(NSView *)trap {
  [sp_trap setView:trap];
}
- (void)setHotKeyTrapPlaceholder:(NSView *)placeholder {
  [sp_trap setPlaceholderView:placeholder];
}

- (id)sparkAction {
  return sp_action;
}

- (void)loadSparkAction:(SparkAction *)action toEdit:(BOOL)flag {
  // does nothing since name and icon are store in sp_action.
}

- (NSAlert *)sparkEditorShouldConfigureAction {
  // Name should be check after 'configure action' to allow plugin to set it later.
  return nil;
}

- (void)configureAction {
  // does nothing
}

#pragma mark Notifications
- (void)pluginViewWillBecomeVisible {}
- (void)pluginViewDidBecomeVisible {}

- (void)pluginViewWillBecomeHidden {}
- (void)pluginViewDidBecomeHidden {}

#pragma mark Accessors
- (id)valueForUndefinedKey:(NSString *)key {
  static BOOL warn = YES;
  if ([key isEqualToString:@"name"]) {
    if (warn) {
      warn = NO;
      WLog(@"%@ use deprecated KVC getter: name", [self class]);
    }
    return [sp_action name];
  } else if ([key isEqualToString:@"icon"]) {
    if (warn) {
      warn = NO;
      WLog(@"%@ use deprecated KVC getter: icon", [self class]);
    }
    return [sp_action icon];
  }
  return [super valueForUndefinedKey:key];
}

- (void)setValue:(id)value forUndefinedKey:(NSString *)key {
  static BOOL warn = YES;
  if ([key isEqualToString:@"name"]) {
    if (warn) {
      warn = NO;
      WLog(@"%@ use deprecated KVC setter: name", [self class]);
    }
    return [sp_action setName:value];
  } else if ([key isEqualToString:@"icon"]) {
    if (warn) {
      warn = NO;
      WLog(@"%@ use deprecated KVC setter: icon", [self class]);
    }
    return [sp_action setIcon:value];
  }
  return [super setValue:value forUndefinedKey:key];
}

- (BOOL)displaysAdvancedSettings {
  return SparkPreferencesGetBooleanValue(@"SparkAdvancedSettings", SparkPreferencesFramework);
}

#pragma mark -
#pragma mark Private Methods
- (void)setSparkAction:(SparkAction *)action edit:(BOOL)flag {
  [self willChangeValueForKey:@"sparkAction"];
  
  [self willChangeValueForKey:@"name"];
  [self willChangeValueForKey:@"icon"];
  SKSetterRetain(sp_action, action);
  [self didChangeValueForKey:@"icon"];
  [self didChangeValueForKey:@"name"];
  
  /* Send plugin API notification */
  @try {
    [self loadSparkAction:action toEdit:flag];
  } @catch (id exception) {
    SKLogException(exception);
  }
  [self didChangeValueForKey:@"sparkAction"];
}

/* Called by Nib Loader only. Action view is a nib root object, so we should not retain it */
- (void)setActionView:(NSView *)anActionView {
  actionView = anActionView;
  sp_apFlags.ownership = 1;
}

- (void)releaseViewOwnership {
  /* If was owner, release the view */
  if (sp_apFlags.ownership) {
    [actionView release];
    sp_apFlags.ownership = 0;
  }
}

/* Compat */
- (NSUndoManager *)undoManager {
  return nil;
}

#pragma mark -
#pragma mark Plugin Informations
+ (Class)actionClass {
  Class actionClass = nil;
  NSBundle *bundle = SKCurrentBundle();
  NSString *class = [bundle objectForInfoDictionaryKey:@"SparkActionClass"];
  if (class && (actionClass = NSClassFromString(class)) ) {
    return actionClass;
  }
  WLog(@"%@: invalid plugin property list: key \"SparkActionClass\" not found or invalid", [bundle bundlePath]);
  return nil;
}

+ (NSString *)plugInName {
  NSBundle *bundle = SKCurrentBundle();
  NSString *name = [bundle objectForInfoDictionaryKey:@"SparkPluginName"];
  if (!name) {
    name = NSStringFromClass(self);
    WLog(@"%@: invalid plugin property list: key \"SparkPlugInName\" not found", [bundle bundlePath]);
  }
  return name;
}

+ (NSImage *)plugInIcon {
  NSBundle *bundle = SKCurrentBundle();
  NSString *name = [bundle objectForInfoDictionaryKey:@"SparkPluginIcon"];
  NSImage *image = [NSImage imageNamed:name inBundle:bundle];
  if (!image) {
    WLog(@"%@: invalid plugin property list: key \"SparkPluginIcon\" not found", [bundle bundlePath]);
    image = [NSImage imageNamed:@"PluginIcon" inBundle:kSparkKitBundle];
  }
  return image;
}

+ (NSString *)helpFile {
  NSString *path = nil;
  NSBundle *bundle = SKCurrentBundle();
  NSString *help = [bundle objectForInfoDictionaryKey:@"SparkHelpFile"];
  if (help) {
    path = [bundle pathForResource:help ofType:nil];
    if (!path)
      path = [bundle pathForResource:help ofType:@"html"];
    if (!path)
      path = [bundle pathForResource:help ofType:@"htm"];
    if (!path)
      path = [bundle pathForResource:help ofType:@"rtf"];
    if (!path)
      path = [bundle pathForResource:help ofType:@"rtfd"];
  }
  return path;
}

+ (NSString *)nibPath {
  NSBundle *bundle = SKCurrentBundle();
  NSString *name = [bundle objectForInfoDictionaryKey:@"NSMainNibFile"];
  return name ? [bundle pathForResource:name ofType:@"nib"] : nil;
}

+ (NSString *)pluginFullName {
  return [NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"%@ Action", nil, 
                                                                       kSparkKitBundle, @"Plugin fullname (%@ => name)"),
    [self plugInName]];
}

+ (NSImage *)pluginViewIcon {
  return [self plugInIcon];
}

#pragma mark Built-in plugin support

/* Returns default value */
+ (BOOL)isEnabled {
  return YES;
}

+ (NSString *)identifier {
  return NSStringFromClass(self);
}

/* Returns the version string */
+ (NSString *)versionString {
  return nil;
}

@end

#pragma mark -
@implementation SparkViewPlaceholder

- (void)dealloc {
  [sp_view release];
  [sp_placeholder release];
  [super dealloc];
}

SPARK_INLINE
void __SparkViewPlaceholderCopyProperties(NSView *src, NSView *dest) {
  if (src && dest) {
    [dest setFrameOrigin:[src frame].origin];
    [dest setAutoresizingMask:[src autoresizingMask]];
  }
}

SPARK_INLINE
void __SparkViewPlaceholderSwapView(NSView *old, NSView *new) {
  if (!new || [new superview])
    [NSException raise:NSInvalidArgumentException format:@"Target view must bew a valid orphan view."];
  if (!old || ![old superview])
    [NSException raise:NSInvalidArgumentException format:@"Source view must have a valid superview."];
  
  NSView *parent = [old superview];
  if (parent && new) {
    __SparkViewPlaceholderCopyProperties(old, new);
    [old removeFromSuperview];
    [parent addSubview:new];
  }
}

- (void)setView:(NSView *)aView {
  if (sp_view != aView) {
    if (!aView) {
      __SparkViewPlaceholderSwapView(sp_view, sp_placeholder);
    } else if (sp_view) {
      __SparkViewPlaceholderSwapView(sp_view, aView);
    } else {
      __SparkViewPlaceholderSwapView(sp_placeholder, aView);
    }
    [sp_view release];
    sp_view = [aView retain];
  }
}

- (void)setPlaceholderView:(NSView *)aView {
  SKSetterRetain(sp_placeholder, aView);
}

@end
