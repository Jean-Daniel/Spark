/*
 *  SparkPlugIn.m
 *  SparkKit
 *
 *  Created by Black Moon Team.
 *  Copyright (c) 2004 - 2006 Shadow Lab. All rights reserved.
 *
 */

#import "SparkPrivate.h"

#import <SparkKit/SparkPlugIn.h>

#import <ShadowKit/SKImageUtils.h>
#import <ShadowKit/SKCGFunctions.h>

NSString * const SparkPlugInDidChangeEnabledNotification = @"SparkPlugInDidChangeEnabled";

@implementation SparkPlugIn

/* Check status */
static 
BOOL SparkPlugInIsEnabled(NSString *identifier) {
  BOOL enabled = YES;
  CFDictionaryRef plugins = CFPreferencesCopyAppValue(CFSTR("SparkPlugins"), (CFStringRef)kSparkBundleIdentifier);
  if (plugins) {
    CFBooleanRef status = CFDictionaryGetValue(plugins, identifier);
    if (status)
      enabled = CFBooleanGetValue(status);
    
    CFRelease(plugins);
  }
  return enabled;
}
static 
void SparkPlugInSetEnabled(NSString *identifier, BOOL enabled) {
  CFMutableDictionaryRef plugins = NULL;
  CFDictionaryRef prefs = CFPreferencesCopyAppValue(CFSTR("SparkPlugins"), (CFStringRef)kSparkBundleIdentifier);
  if (!prefs) {
    plugins = CFDictionaryCreateMutable(kCFAllocatorDefault, 0, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
  } else {
    plugins = CFDictionaryCreateMutableCopy(kCFAllocatorDefault, 0, prefs);
    CFRelease(prefs);
  }
  CFDictionarySetValue(plugins, identifier, enabled ? kCFBooleanTrue : kCFBooleanFalse);
  CFPreferencesSetAppValue(CFSTR("SparkPlugins"), plugins, (CFStringRef)kSparkBundleIdentifier);
  CFRelease(plugins);
}

- (id)initWithBundle:(NSBundle *)bundle {
  if (self = [super init]) {
    sp_class = [bundle principalClass];
    [self setPath:[bundle bundlePath]];
    [self setBundleIdentifier:[bundle bundleIdentifier]];
    
    /* Set status */
    SKSetFlag(sp_spFlags.disabled, !SparkPlugInIsEnabled([bundle bundleIdentifier]));
    
    /* Extend applescript support */
    //[[NSScriptSuiteRegistry sharedScriptSuiteRegistry] loadSuitesFromBundle:bundle];
  }
  return self;
}

+ (id)plugInWithBundle:(NSBundle *)bundle {
  return [[[self alloc] initWithBundle:bundle] autorelease]; 
}

- (void)dealloc {
  [sp_nib release];
  [sp_name release];
  [sp_path release];
  [sp_icon release];
  [sp_bundle release];
  [super dealloc];
}

- (unsigned)hash {
  return [sp_bundle hash];
}

- (BOOL)isEqual:(id)object {
  if (!object || ![object isKindOfClass:[SparkPlugIn class]])
    return NO;
  
  return [sp_bundle isEqual:[object bundleIdentifier]];
}

- (NSString *)description {
  return [NSString stringWithFormat:@"<%@ %p> {Name: %@, Class: %@}",
    [self class], self,
    [self name], sp_class];
}

#pragma mark -
- (NSString *)name {
  if (sp_name == nil) {
    [self setName:[sp_class plugInName]];
  }
  return sp_name;
}
- (void)setName:(NSString *)newName {
  SKSetterRetain(sp_name, newName);
}

- (NSString *)path {
  return sp_path;
}

- (void)setPath:(NSString *)newPath {
  SKSetterRetain(sp_path, newPath);
}

- (NSImage *)icon {
  if (sp_icon == nil) {
    [self setIcon:[sp_class plugInIcon]];
  }
  return sp_icon;
}
- (void)setIcon:(NSImage *)icon {
  SKSetterRetain(sp_icon, icon);
}

- (BOOL)isEnabled {
  return !sp_spFlags.disabled;
}
- (void)setEnabled:(BOOL)flag {
  BOOL enabled = [self isEnabled];
  /* If status change */
  if (XOR(enabled, flag)) {
    SKSetFlag(sp_spFlags.disabled, !flag);
    /* Update preferences */
    SparkPlugInSetEnabled([self bundleIdentifier] ? : NSStringFromClass(sp_class), flag);
    [[NSNotificationCenter defaultCenter] postNotificationName:SparkPlugInDidChangeEnabledNotification
                                                        object:self];
    
  }
}

- (NSString *)bundleIdentifier {
  return sp_bundle;
}
- (void)setBundleIdentifier:(NSString *)identifier {
  SKSetterRetain(sp_bundle, identifier);
}

- (NSURL *)helpURL {
  NSString *help = [sp_class helpFile];
  if (help)
    return [NSURL fileURLWithPath:help];
  return nil;
}

- (id)instantiatePlugin {
  if (!sp_nib) {
    NSString *path = [sp_class nibPath];
    if (path) {
      NSURL *url = [NSURL fileURLWithPath:path];
      sp_nib = [[NSNib alloc] initWithContentsOfURL:url];
    } else {
      DLog(@"Invalid plugin nib path");
    }
  }
  SparkActionPlugIn *plugin = [[sp_class alloc] init];
  [sp_nib instantiateNibWithOwner:plugin topLevelObjects:nil];
  return [plugin autorelease];
}

- (Class)actionClass {
  return [sp_class actionClass];
}

@end

@implementation SparkPlugIn (SparkBuiltInPlugIn)

- (id)initWithClass:(Class)cls {
  if (self = [self init]) {
    sp_class = cls;
    
    SKSetFlag(sp_spFlags.disabled, !SparkPlugInIsEnabled(NSStringFromClass(cls)));
  }
  return self;
}


@end

