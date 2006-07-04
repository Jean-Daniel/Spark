//
//  SparkActionLoader.m
//  Spark
//
//  Created by Fox on Thu Jan 22 2004.
//  Copyright (c) 2004 Shadow Lab. All rights reserved.
//

#import <SparkKit/SparkActionLoader.h>
#import <SparkKit/SparkPlugIn.h>
//#import <SparkKit/SparkAction.h>

#import "SparkPrivate.h"
#import <SparkKit/SparkActionPlugIn.h>

@implementation SparkActionLoader

+ (id)sharedLoader {
  static id loader = nil;
  if (!loader) {
    loader = [[self alloc] initWithDomains:kSKDefaultDomains subscribe:NO];
  }
  return loader;
}

+ (NSString *)extension {
  return @"spact";
}

+ (NSString *)supportFolderName {
  return kSparkFolderName;
}


- (BOOL)isValidPlugIn:(Class)principalClass {
  if (![principalClass isSubclassOfClass:[SparkActionPlugIn class]]) {
    return NO;
  }
  Class action = [principalClass actionClass];
  return [action isSubclassOfClass:[SparkAction class]];
}

- (id)createPluginForBundle:(NSBundle *)bundle {
  id plug = nil;
  Class principalClass = [bundle principalClass];
  if (principalClass && [self isValidPlugIn:principalClass]) {
    plug = [SparkPlugIn plugInWithBundle:bundle];
  }
  return plug;
}

- (SparkPlugIn *)plugInForAction:(SparkAction *)action {
  id plugins = [[self plugins] objectEnumerator];
  id plugin;
  while (plugin = [plugins nextObject]) {
    if ([action isKindOfClass:[plugin actionClass]]) {
      return plugin;
    }
  }
  return nil;
}

@end
