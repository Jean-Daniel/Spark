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

+ (id)sharedLoader {
  static SparkActionLoader *loader = nil;
  if (!loader) {
    loader = [[self alloc] initWithDomains:kWBDefaultDomains subscribe:NO];
  }
  return loader;
}

+ (NSString *)extension {
  return @"spact";
}

+ (NSString *)supportFolderName {
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
    WBLogException(exception);
  }
  return NO;
}

- (id)createPluginForBundle:(NSBundle *)bundle {
  SparkPlugIn *plug = nil;
  Class principalClass = [bundle principalClass];
  if (principalClass && [self isValidPlugIn:principalClass]) {
    plug = [[SparkPlugIn alloc] initWithBundle:bundle];
  }
  return [plug autorelease];
}

#pragma mark -
- (SparkPlugIn *)plugInForActionClass:(Class)cls {
  NSArray *plugins = [self plugins];
  NSUInteger count = [plugins count];
  while (count-- > 0) {
    SparkPlugIn *plugin = [plugins objectAtIndex:count];
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
    if (plugin) {
      [self registerPlugin:plugin withIdentifier:[plugin identifier]];
    }
    return plugin;
  }
  return nil;
}

- (id)loadPlugin:(NSString *)path {
  SparkPlugIn *plugin = [super loadPlugin:path];
  if (plugin) {
    [[NSNotificationCenter defaultCenter] postNotificationName:SparkActionLoaderDidRegisterPlugInNotification
                                                        object:plugin];
  }
  return plugin;
}

@end
