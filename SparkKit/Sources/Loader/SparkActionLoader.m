/*
 *  SparkActionLoader.m
 *  SparkKit
 *
 *  Created by Black Moon Team.
 *  Copyright (c) 2004 - 2007 Shadow Lab. All rights reserved.
 */

#import <SparkKit/SparkActionLoader.h>

#import "SparkPrivate.h"

#import <SparkKit/SparkPlugIn.h>
#import <SparkKit/SparkActionPlugIn.h>

NSString * const SparkActionLoaderDidRegisterPlugInNotification = @"SparkActionLoaderDidRegisterPlugIn";

@implementation SparkActionLoader

+ (SparkActionLoader *)sharedLoader {
  static SparkActionLoader *loader = nil;
  if (!loader) 
    loader = [[self alloc] init];
  return loader;
}

- (NSString *)extension {
  return @"spact";
}

- (NSString *)supportFolderName {
  return kSparkFolderName;
}

#pragma mark Instance Methods Override
- (BOOL)isValidPlugIn:(Class)principalClass {
  @try {
    if (![principalClass isSubclassOfClass:[SparkActionPlugIn class]])
      return NO;
    /* check required values */
    if (![principalClass plugInName])
      return NO;
    
    Class action = [principalClass actionClass];
    if (![action isSubclassOfClass:[SparkAction class]])
      return NO;
    
    return YES;
  } @catch (id exception) {
    SPXLogException(exception);
  }
  return NO;
}

- (id)createPlugInForBundle:(NSBundle *)bundle {
  SparkPlugIn *plug = nil;
  Class principalClass = [bundle principalClass];
  if (principalClass && [self isValidPlugIn:principalClass]) {
    plug = [[SparkPlugIn alloc] initWithBundle:bundle];
  }
  return plug;
}

- (WBPlugInBundle *)resolveConflict:(NSArray *)plugins {
  for (WBPlugInBundle *entry in plugins) {
    /* prefere built in version, else don't care */
    if ([entry domain] == kWBPlugInDomainBuiltIn)
      return entry;
  }
  // use first found
  return nil;
}

#pragma mark -
- (SparkPlugIn *)plugInForActionClass:(Class)cls {
  for (SparkPlugIn *plugin in [self plugIns]) {
    if ([cls isSubclassOfClass:[plugin actionClass]]) {
      return plugin;
    }
  }
  return nil;
}

- (SparkPlugIn *)plugInForAction:(SparkAction *)action {
  return [self plugInForActionClass:[action class]];
}

- (SparkPlugIn *)registerPlugInClass:(Class)aClass {
  if ([self isValidPlugIn:aClass]) {
    SparkPlugIn *plugin = [[SparkPlugIn alloc] initWithClass:aClass identifier:[aClass identifier]];
    if (plugin)
      [self registerPlugIn:plugin withIdentifier:[plugin identifier]];
    return plugin;
  }
  return nil;
}

- (id)loadPlugIn:(NSBundle *)aBundle {
  SparkPlugIn *plugin = [super loadPlugIn:aBundle];
  if (plugin) {
    [[NSNotificationCenter defaultCenter] postNotificationName:SparkActionLoaderDidRegisterPlugInNotification
                                                        object:plugin];
  }
  return plugin;
}

@end
