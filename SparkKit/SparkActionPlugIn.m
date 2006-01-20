//
//  HotKeyConfig.m
//  Short-Cut
//
//  Created by Fox on Mon Dec 08 2003.
//  Copyright (c) 2004 Shadow Lab. All rights reserved.
//

#import <SparkKit/SparkActionPlugIn.h>

#import <ShadowKit/ShadowMacros.h>
#import <SparkKit/SparkAlert.h>
#import <SparkKit/SparkAction.h>
#import <SparkKit/Spark_Private.h>
#import <SparkKit/SparkConstantes.h>

@implementation SparkActionPlugIn

- (void)dealloc {
  [_name release];
  [_icon release];
  [_undo release];
  [_action release];
  [super dealloc];
}

- (void)setActionView:(NSView *)actionView {
  _actionView = actionView;
}

- (NSView *)actionView {
  if (!_actionView) {
    id bundle = SKCurrentBundle();
    [NSBundle loadNibNamed:[bundle objectForInfoDictionaryKey:@"NSMainNibFile"] owner:self];
    [_actionView autorelease];
  }
  return _actionView;
}

- (void)loadSparkAction:(SparkAction *)action toEdit:(BOOL)flag {
  if (flag) {
    [self setName:[action name]];
    [self setIcon:[action icon]];
  }
}

- (id)sparkAction {
  return _action;
}

- (NSAlert *)sparkEditorShouldConfigureAction {
  return nil;
}

- (void)configureAction {
  [_action setName:[self name]];
  [_action setIcon:[self icon]];
}

- (void)revertEditing {
}

- (NSString *)name {
  return _name;
}

- (void)setName:(NSString *)newName {
  if (_name != newName) {
    [_name release];
    _name = [newName copy];
  }
}

- (NSImage *)icon {
  return _icon;
}

- (void)setIcon:(NSImage *)newIcon {
  if (_icon != newIcon) {
    [_icon release];
    _icon = [newIcon copy];
  }
}

- (NSUndoManager *)undoManager {
  return _undo;
}

#pragma mark -
#pragma mark Private Methods
- (void)setSparkAction:(SparkAction *)action {
  if (_action != action) {
    [_action release];
    _action = [action retain];
  }
}

- (void)setUndoManager:(NSUndoManager *)manager {
  if (_undo != manager) {
    [_undo release];
    _undo = [manager retain];
  }
}

#pragma mark -
#pragma mark Plugin Informations
+ (Class)actionClass {
  id bundle = SKCurrentBundle();
  id class = [bundle objectForInfoDictionaryKey:@"SparkActionClass"];
  id actionClass;
  if (class && (actionClass = NSClassFromString(class)) ) {
    return actionClass;
  }
  [NSException raise:@"InvalidClassKeyException" format:@"Unable to find a valid class for key \"SparkActionClass\" in bundle \"%@\" propertylist", [bundle bundlePath]];
  return nil;
}

+ (NSString *)plugInName {
  id bundle = SKCurrentBundle();
  id name = [bundle objectForInfoDictionaryKey:@"SparkPluginName"];
  if (name) {
    return name;
  }
  [NSException raise:@"InvalidPlugInNameException" format:@"Unable to find a valid name for key \"SparkPlugInName\" in bundle \"%@\" propertylist", [bundle bundlePath]];
  return nil;
}

+ (NSImage *)plugInIcon {
  id image = nil;
  if ([SparkLibraryObject loadUI]) {
    id bundle = SKCurrentBundle();
    id name = [bundle objectForInfoDictionaryKey:@"SparkPluginIcon"];
    image = [NSImage imageNamed:name inBundle:bundle];
    if (!image) {
      image = [NSImage imageNamed:@"PluginIcon" inBundle:[NSBundle bundleWithIdentifier:kSparkKitBundleIdentifier]];
    }
  }
  return image;
}

+ (NSString *)helpFile {
  id bundle = SKCurrentBundle();
  id help = [bundle objectForInfoDictionaryKey:@"SparkHelpFile"];
  id path = nil;
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