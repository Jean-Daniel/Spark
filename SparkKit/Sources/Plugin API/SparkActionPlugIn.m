/* 
 *  SparkActionPlugIn.m
 *  SparkKit
 *
 *  Created by Black Moon Team.
 *  Copyright (c) 2004 - 2006 Shadow Lab. All rights reserved.
 *
 */

#import "SparkPrivate.h"

#import <SparkKit/SparkAction.h>
#import <SparkKit/SparkActionPlugIn.h>
#import <ShadowKit/SKAppKitExtensions.h>

@implementation SparkActionPlugIn

- (void)dealloc {
  [sp_action release];
  [super dealloc];
}

- (void)setActionView:(NSView *)actionView {
  sp_view = actionView;
}

- (NSView *)actionView {
  if (!sp_view) {
    NSBundle * bundle = SKCurrentBundle();
    [NSBundle loadNibNamed:[bundle objectForInfoDictionaryKey:@"NSMainNibFile"] owner:self];
    [sp_view autorelease];
  }
  return sp_view;
}

- (void)loadSparkAction:(SparkAction *)action toEdit:(BOOL)flag {
  // does nothing
}

- (id)sparkAction {
  return sp_action;
}

- (NSAlert *)sparkEditorShouldConfigureAction {
  // Does nothing
  return nil;
}

- (void)configureAction {
  [sp_action setName:[self name]];
  [sp_action setIcon:[self icon]];
}

- (NSString *)name {
  return [sp_action name];
}

- (void)setName:(NSString *)name {
  [sp_action setName:name];
}

- (NSImage *)icon {
  return [sp_action icon];
}

- (void)setIcon:(NSImage *)icon {
  [sp_action setIcon:icon];
}

/* Compat */
- (NSUndoManager *)undoManager {
  return nil;
}

#pragma mark -
#pragma mark Private Methods
- (void)setSparkAction:(SparkAction *)action {
  SKSetterRetain(sp_action, action);
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
  [NSException raise:@"InvalidClassKeyException" format:@"Unable to find a valid class for key \"SparkActionClass\" in bundle \"%@\" propertylist", [bundle bundlePath]];
  return nil;
}

+ (NSString *)plugInName {
  NSBundle *bundle = SKCurrentBundle();
  NSString *name = [bundle objectForInfoDictionaryKey:@"SparkPluginName"];
  if (name) {
    return name;
  }
  [NSException raise:@"InvalidPlugInNameException" format:@"Unable to find a valid name for key \"SparkPlugInName\" in bundle \"%@\" propertylist", [bundle bundlePath]];
  return nil;
}

+ (NSImage *)plugInIcon {
  NSBundle *bundle = SKCurrentBundle();
  NSString *name = [bundle objectForInfoDictionaryKey:@"SparkPluginIcon"];
  NSImage *image = [NSImage imageNamed:name inBundle:bundle];
  if (!image) {
    image = [NSImage imageNamed:@"PluginIcon" inBundle:[NSBundle bundleWithIdentifier:kSparkKitBundleIdentifier]];
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

@end
