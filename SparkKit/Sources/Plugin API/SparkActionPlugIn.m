/* 
 *  SparkActionPlugIn.m
 *  SparkKit
 *
 *  Created by Black Moon Team.
 *  Copyright (c) 2004 - 2007 Shadow Lab. All rights reserved.
 */

#import "SparkPrivate.h"

#import <SparkKit/SparkAction.h>
#import <SparkKit/SparkPlugInView.h>
#import <SparkKit/SparkPreferences.h>
#import <SparkKit/SparkActionPlugIn.h>

#import <WonderBox/WonderBox.h>

@interface SparkViewPlaceholder : NSObject

- (void)setView:(NSView *)aView;
- (void)setPlaceholderView:(NSView *)aView;

@end

@interface SparkActionPlugIn ()
@property(nonatomic, retain) id sparkAction;
@end

@implementation SparkActionPlugIn {
@private
  SparkPlugInView *sp_ctrl;
  SparkViewPlaceholder *sp_trap;
}

- (instancetype)initWithNibName:(nullable NSNibName)nibNameOrNil bundle:(nullable NSBundle *)nibBundleOrNil {
  if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
    sp_trap = [[SparkViewPlaceholder alloc] init];
  }
  return self;
}

- (SparkPlugInView *)sp_controller {
  if (!sp_ctrl) {
    sp_ctrl = [[SparkPlugInView alloc] init];
    [sp_ctrl setPlugIn:self];
    [sp_ctrl setPlugInViewController:self];
    [self setHotKeyTrapPlaceholder:[sp_ctrl trapPlaceholder]];
  }
  return sp_ctrl;
}

- (BOOL)hasCustomView {
  return NO;
}

- (NSView *)actionView {
  return self.viewController.view;
}

- (NSViewController *)viewController {
  return [self hasCustomView] ? self : [self sp_controller];
}

- (void)setHotKeyTrap:(NSView *)trap {
  [sp_trap setView:trap];
}
- (void)setHotKeyTrapPlaceholder:(NSView *)placeholder {
  [sp_trap setPlaceholderView:placeholder];
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
- (void)plugInViewWillBecomeVisible {}
- (void)plugInViewDidBecomeVisible {}

- (void)plugInViewWillBecomeHidden {}
- (void)plugInViewDidBecomeHidden {}

#pragma mark Accessors
- (id)valueForUndefinedKey:(NSString *)key {
  static BOOL warn = YES;
  if ([key isEqualToString:@"name"]) {
    if (warn) {
      warn = NO;
      spx_log("%@ use deprecated KVC getter: name", [self class]);
    }
    return [_sparkAction name];
  } else if ([key isEqualToString:@"icon"]) {
    if (warn) {
      warn = NO;
      spx_log("%@ use deprecated KVC getter: icon", [self class]);
    }
    return [_sparkAction icon];
  }
  return [super valueForUndefinedKey:key];
}

- (void)setValue:(id)value forUndefinedKey:(NSString *)key {
  static BOOL warn = YES;
  if ([key isEqualToString:@"name"]) {
    if (warn) {
      warn = NO;
      spx_log("%@ use deprecated KVC setter: name", [self class]);
    }
    return [(SparkAction *)_sparkAction setName:value];
  } else if ([key isEqualToString:@"icon"]) {
    if (warn) {
      warn = NO;
      spx_log("%@ use deprecated KVC setter: icon", [self class]);
    }
    return [_sparkAction setIcon:value];
  }
  return [super setValue:value forUndefinedKey:key];
}

- (SparkPreference *)preferences {
  return SparkActiveLibrary().preferences;
}

- (BOOL)displaysAdvancedSettings {
  return [SparkUserDefaults() boolForKey:@"SparkAdvancedSettings"];
}

#pragma mark -
#pragma mark Private Methods
+ (NSSet *)keyPathsForValuesAffectingValueForKey:(NSString *)key {
  if ([@"name" isEqualToString:key] || [@"icon" isEqualToString:key])
    return [NSSet setWithObject:@"sparkAction"];
  return [super keyPathsForValuesAffectingValueForKey:key];
}

- (void)setSparkAction:(SparkAction *)action edit:(BOOL)flag {
  self.sparkAction = action;
  
  /* Send plugin API notification */
  @try {
    [self loadSparkAction:action toEdit:flag];
  } @catch (id exception) {
    spx_log_exception(exception);
  }
}

/* Compat */
- (NSUndoManager *)undoManager {
  return nil;
}

#pragma mark -
#pragma mark PlugIn Informations
+ (Class)actionClass {
  Class actionClass = nil;
  NSBundle *bundle = SPXCurrentBundle();
  NSString *class = [bundle objectForInfoDictionaryKey:@"SparkActionClass"];
  if (class && (actionClass = NSClassFromString(class)) ) {
    return actionClass;
  }
  spx_log("%@: invalid plugin property list: key \"SparkActionClass\" not found or invalid", [bundle bundlePath]);
  return nil;
}

+ (NSString *)plugInName {
  NSBundle *bundle = SPXCurrentBundle();
  NSString *name = [bundle objectForInfoDictionaryKey:@"SparkPluginName"];
  if (!name) {
    name = NSStringFromClass(self);
    spx_log("%@: invalid plugin property list: key \"SparkPlugInName\" not found", [bundle bundlePath]);
  }
  return name;
}

+ (NSImage *)plugInIcon {
  NSBundle *bundle = SPXCurrentBundle();
  NSString *name = [bundle objectForInfoDictionaryKey:@"SparkPluginIcon"];
  NSImage *image = [NSImage imageNamed:name inBundle:bundle];
  if (!image) {
    spx_log("%@: invalid plugin property list: key \"SparkPluginIcon\" not found", [bundle bundlePath]);
    image = [NSImage imageNamed:@"PluginIcon" inBundle:SparkKitBundle()];
  }
  return image;
}

+ (NSURL *)helpURL {
  NSURL *path = nil;
  NSBundle *bundle = SPXCurrentBundle();
  NSString *help = [bundle objectForInfoDictionaryKey:@"SparkHelpFile"];
  if (help) {
    path = [bundle URLForResource:help withExtension:nil];
    if (!path)
      path = [bundle URLForResource:help withExtension:@"html"];
    if (!path)
      path = [bundle URLForResource:help withExtension:@"htm"];
    if (!path)
      path = [bundle URLForResource:help withExtension:@"rtf"];
    if (!path)
      path = [bundle URLForResource:help withExtension:@"rtfd"];
  }
  return path;
}

+ (NSString *)nibName {
  NSBundle *bundle = SPXCurrentBundle();
  return [bundle objectForInfoDictionaryKey:@"NSMainNibFile"];
}

+ (NSString *)plugInFullName {
  return [NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"%@ Action", nil, 
                                                                       SparkKitBundle(), @"Plugin fullname (%@ => name)"),
    [self plugInName]];
}

+ (NSImage *)plugInViewIcon {
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
@implementation SparkViewPlaceholder {
@private
  NSView *sp_view;
  NSView *sp_placeholder;
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
    SPXThrowException(NSInvalidArgumentException, @"Target view must bew a valid orphan view.");
  if (!old || ![old superview])
    SPXThrowException(NSInvalidArgumentException, @"Source view must have a valid superview.");

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
    sp_view = aView;
  }
}

- (void)setPlaceholderView:(NSView *)aView {
  sp_placeholder = aView;
}

@end
