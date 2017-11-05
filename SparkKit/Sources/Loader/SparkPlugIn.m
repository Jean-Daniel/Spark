/*
 *  SparkPlugIn.m
 *  SparkKit
 *
 *  Created by Black Moon Team.
 *  Copyright (c) 2004 - 2007 Shadow Lab. All rights reserved.
 */

#import <SparkKit/SparkPlugIn.h>

#import <SparkKit/SparkFunctions.h>
#import <SparkKit/SparkPreferences.h>
#import <SparkKit/SparkActionLoader.h>

#import "SparkPrivate.h"

NSString * const SparkPlugInDidChangeStatusNotification = @"SparkPlugInDidChangeStatus";

@implementation SparkPlugIn

/* Check status */
static 
BOOL SparkPlugInIsEnabled(NSString *identifier, BOOL *exists) {
  BOOL enabled = YES;
  if (exists)
    *exists = NO;
  NSDictionary *plugins = SparkPreferencesGetValue(@"SparkPlugIns", SparkPreferencesFramework);
  if (plugins) {
    NSNumber *status = plugins[identifier];
    if (status) {
      if (exists)
        *exists = YES;
      enabled = [status boolValue];
    }
  }
  return enabled;
}

static 
void SparkPlugInSetEnabled(NSString *identifier, BOOL enabled) {
  if (SparkGetCurrentContext() == kSparkContext_Editor) {
    NSMutableDictionary *plugins = NULL;
    NSDictionary *prefs = SparkPreferencesGetValue(@"SparkPlugIns", SparkPreferencesFramework);
    if (!prefs) {
      plugins = [[NSMutableDictionary alloc] init];
    } else {
      plugins = [prefs mutableCopy];
    }
    [plugins setObject:@(enabled) forKey:identifier];
    SparkPreferencesSetValue(@"SparkPlugIns", plugins, SparkPreferencesFramework);
  }
}

/* Synchronize daemon */
+ (void)setFrameworkValue:(NSDictionary *)plugins forKey:(NSString *)key {
  NSString *identifier;
  SparkActionLoader *loader = [SparkActionLoader sharedLoader];
  for (identifier in plugins) {
    SparkPlugIn *plugin = [loader plugInForIdentifier:identifier];
    if (plugin) {
      NSNumber *value = plugins[identifier];
      if (value && [value respondsToSelector:@selector(boolValue)])
        [plugin setEnabled:[value boolValue]];
    }
  }
}

+ (void)initialize {
  if ([SparkPlugIn class] == self) {
    if (SparkGetCurrentContext() == kSparkContext_Daemon) {
      SparkPreferencesRegisterObserver(@"SparkPlugIns", SparkPreferencesFramework, ^(NSString *key, id value) {
        if ([value isKindOfClass:[NSDictionary class]]) {
          NSDictionary *plugins = value;
          SparkActionLoader *loader = [SparkActionLoader sharedLoader];
          for (NSString *identifier in plugins) {
            SparkPlugIn *plugin = [loader plugInForIdentifier:identifier];
            if (plugin) {
              NSNumber *enabled = plugins[identifier];
              if (enabled && [enabled respondsToSelector:@selector(boolValue)])
                [plugin setEnabled:[enabled boolValue]];
            }
          }
        }
      });
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
    SPXThrowException(NSInvalidArgumentException, @"Invalid action plugin class.");
  } 
  
  if (self = [super init]) {
    _plugInClass = cls;
    _identifier = [identifier copy];
    
    [self setVersion:[cls versionString]];
    
    /* Set status */
    BOOL exists;
    BOOL status = SparkPlugInIsEnabled(identifier, &exists);
    if (exists)
      _enabled = status;
    else
      _enabled = [_plugInClass isEnabled];
  }
  return self;
}

- (id)initWithBundle:(NSBundle *)bundle {
  if (self = [self initWithClass:[bundle principalClass]
                      identifier:[bundle bundleIdentifier]]) {
    _URL = bundle.bundleURL;
    /* Extend applescript support */
//    if (SparkGetCurrentContext() == kSparkContext_Editor)
//      [[NSScriptSuiteRegistry sharedScriptSuiteRegistry] loadSuitesFromBundle:bundle];
  }
  return self;
}

- (NSUInteger)hash {
  return [_identifier hash];
}

- (BOOL)isEqual:(id)object {
  if (!object || ![object isKindOfClass:[SparkPlugIn class]])
    return NO;
  
  return [_identifier isEqual:[object identifier]];
}

- (NSString *)description {
  return [NSString stringWithFormat:@"<%@ %p> {Name: %@, Class: %@, Status: %@}",
    [self class], self,
    [self name], _plugInClass,
    ([self isEnabled] ? @"On" : @"Off")];
}

#pragma mark -
- (NSString *)name {
  if (_name == nil) {
    self.name = [_plugInClass plugInName];
  }
  return _name;
}

- (NSImage *)icon {
  if (_icon == nil) {
    self.icon = [_plugInClass plugInIcon];
  }
  return _icon;
}

- (void)setEnabled:(BOOL)flag {
  /* If status change */
  if (spx_xor(flag, _enabled)) {
    _enabled = flag;
    /* Update preferences */
    SparkPlugInSetEnabled([self identifier], flag);
    [[NSNotificationCenter defaultCenter] postNotificationName:SparkPlugInDidChangeStatusNotification
                                                        object:self];
    
  }
}

- (NSBundle *)bundle {
  NSBundle *bundle = nil;
  if (self.URL)
    bundle = [NSBundle bundleWithURL:self.URL];
  if (!bundle)
    bundle = [NSBundle bundleForClass:_plugInClass];
  // FIXME: Why is this needed ?
  if (bundle != [NSBundle mainBundle])
    return bundle;
  return nil;
}

- (NSString *)version {
  if (!_version) {
    // Try to init version
    _version = [[self bundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
  }
  return _version;
}

- (NSURL *)helpURL {
  return [_plugInClass helpURL];
}

- (NSURL *)sdefURL {
  NSBundle *bundle = [self bundle];
  if (bundle) {
    NSString *sdef = [bundle objectForInfoDictionaryKey:@"OSAScriptingDefinition"];
    if (sdef) {
      return [bundle URLForResource:[sdef stringByDeletingPathExtension] withExtension:[sdef pathExtension]];
    }
  }
  return nil;
}

- (id)instantiatePlugIn {
  NSString *nib = [_plugInClass nibName];
  NSBundle *bundle = SPXBundleForClass(_plugInClass);
  SparkActionPlugIn *plugin = [[_plugInClass alloc] initWithNibName:nib bundle:bundle];
  // Make sure the plugin is loaded
  [plugin view];
  return plugin;
}

- (Class)actionClass {
  return [_plugInClass actionClass];
}

@end
