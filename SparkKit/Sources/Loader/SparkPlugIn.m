/*
 *  SparkPlugIn.m
 *  SparkKit
 *
 *  Created by Black Moon Team.
 *  Copyright (c) 2004 - 2007 Shadow Lab. All rights reserved.
 */

#import "SparkPrivate.h"

#import <SparkKit/SparkPlugIn.h>
#import <SparkKit/SparkFunctions.h>
#import <SparkKit/SparkPreferences.h>
#import <SparkKit/SparkActionLoader.h>

NSString * const SparkPlugInDidChangeStatusNotification = @"SparkPlugInDidChangeStatus";

@implementation SparkPlugIn

/* Check status */
static 
BOOL SparkPlugInIsEnabled(NSString *identifier, BOOL *exists) {
  BOOL enabled = YES;
  if (exists) *exists = NO;
  NSDictionary *plugins = SparkPreferencesGetValue(@"SparkPlugins", SparkPreferencesFramework);
  if (plugins) {
    NSNumber *status = [plugins objectForKey:identifier];
    if (status) {
      if (exists) *exists = YES;
      enabled = [status boolValue];
    }
  }
  return enabled;
}

static 
void SparkPlugInSetEnabled(NSString *identifier, BOOL enabled) {
  if (SparkGetCurrentContext() == kSparkEditorContext) {
    NSMutableDictionary *plugins = NULL;
    NSDictionary *prefs = SparkPreferencesGetValue(@"SparkPlugins", SparkPreferencesFramework);
    if (!prefs) {
      plugins = [[NSMutableDictionary alloc] init];
    } else {
      plugins = [prefs mutableCopy];
    }
    [plugins setObject:WBBool(enabled) forKey:identifier];
    SparkPreferencesSetValue(@"SparkPlugins", plugins, SparkPreferencesFramework);
    [plugins release];
  }
}

/* Synchronize daemon */
+ (void)setFrameworkValue:(NSDictionary *)plugins forKey:(NSString *)key {
  NSString *identifier;
  NSEnumerator *keys = [plugins keyEnumerator];
  SparkActionLoader *loader = [SparkActionLoader sharedLoader];
  while (identifier = [keys nextObject]) {
    SparkPlugIn *plugin = [loader pluginForIdentifier:identifier];
    if (plugin) {
      NSNumber *value = [plugins objectForKey:identifier];
      if (value && [value respondsToSelector:@selector(boolValue)])
        [plugin setEnabled:[value boolValue]];
    }
  }
}

+ (void)initialize {
  if ([SparkPlugIn class] == self) {
    if (SparkGetCurrentContext() == kSparkDaemonContext) {
      SparkPreferencesRegisterObserver(self, @selector(setFrameworkValue:forKey:), @"SparkPlugins", SparkPreferencesFramework);
    }
  }
}

- (id)init {
  if (self = [super init]) {
    // Should not create valid plugin with this method.
  }
  return self;
}

- (id)initWithClass:(Class)cls identifier:(NSString *)identifier {
  if (![cls isSubclassOfClass:[SparkActionPlugIn class]]) {
    [self release];
    [NSException raise:NSInvalidArgumentException format:@"Invalid action plugin class."];  
    return nil;
  } 
  
  if (self = [super init]) {
    sp_class = cls;
    [self setIdentifier:identifier];
    
    [self setVersion:[cls versionString]];
    
    /* Set status */
    BOOL exists;
    BOOL status = SparkPlugInIsEnabled(identifier, &exists);
    if (exists)
      WBFlagSet(sp_spFlags.disabled, !status);
    else
      WBFlagSet(sp_spFlags.disabled, ![sp_class isEnabled]);
  }
  return self;
}

- (id)initWithBundle:(NSBundle *)bundle {
  if (self = [self initWithClass:[bundle principalClass]
                      identifier:[bundle bundleIdentifier]]) {
    [self setPath:[bundle bundlePath]];
    
    /* Extend applescript support */
    //[[NSScriptSuiteRegistry sharedScriptSuiteRegistry] loadSuitesFromBundle:bundle];
  }
  return self;
}

- (void)dealloc {
  [sp_nib release];
  [sp_name release];
  [sp_path release];
  [sp_icon release];
  [sp_version release];
  [sp_identifier release];
  [super dealloc];
}

- (NSUInteger)hash {
  return [sp_identifier hash];
}

- (BOOL)isEqual:(id)object {
  if (!object || ![object isKindOfClass:[SparkPlugIn class]])
    return NO;
  
  return [sp_identifier isEqual:[object identifier]];
}

- (NSString *)description {
  return [NSString stringWithFormat:@"<%@ %p> {Name: %@, Class: %@, Status: %@}",
    [self class], self,
    [self name], sp_class,
    ([self isEnabled] ? @"On" : @"Off")];
}

#pragma mark -
- (NSString *)name {
  if (sp_name == nil) {
    [self setName:[sp_class plugInName]];
  }
  return sp_name;
}
- (void)setName:(NSString *)newName {
  WBSetterRetain(sp_name, newName);
}

- (NSString *)path {
  return sp_path;
}

- (void)setPath:(NSString *)newPath {
  WBSetterRetain(sp_path, newPath);
}

- (NSImage *)icon {
  if (sp_icon == nil) {
    [self setIcon:[sp_class plugInIcon]];
  }
  return sp_icon;
}
- (void)setIcon:(NSImage *)icon {
  WBSetterRetain(sp_icon, icon);
}

- (BOOL)isEnabled {
  return !sp_spFlags.disabled;
}
- (void)setEnabled:(BOOL)flag {
  bool disabled = WBFlagTestAndSet(sp_spFlags.disabled, !flag);
  /* If status change */
  if (disabled != sp_spFlags.disabled) {
    /* Update preferences */
    SparkPlugInSetEnabled([self identifier], flag);
    [[NSNotificationCenter defaultCenter] postNotificationName:SparkPlugInDidChangeStatusNotification
                                                        object:self];
    
  }
}

- (NSString *)version {
  if (!sp_version && [self path]) {
    // Try to init version
    NSBundle *bundle = [NSBundle bundleWithPath:[self path]];
    if (bundle != [NSBundle mainBundle])
      sp_version = [[bundle objectForInfoDictionaryKey:@"CFBundleShortVersionString"] retain];
  }
  return sp_version;
}
- (void)setVersion:(NSString *)version {
  WBSetterCopy(sp_version, version);
}

- (NSString *)identifier {
  return sp_identifier;
}
- (void)setIdentifier:(NSString *)identifier {
  WBSetterRetain(sp_identifier, identifier);
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
      sp_nib = [NSNull null];
      DLog(@"Plugin does not have nib path");
    }
  }
  SparkActionPlugIn *plugin = [[sp_class alloc] init];
  if (sp_nib != [NSNull null]) 
    [sp_nib instantiateNibWithOwner:plugin topLevelObjects:nil];
  return [plugin autorelease];
}

- (Class)actionClass {
  return [sp_class actionClass];
}

@end

