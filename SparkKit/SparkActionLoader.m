//
//  SparkActionLoader.m
//  Spark
//
//  Created by Fox on Thu Jan 22 2004.
//  Copyright (c) 2004 Shadow Lab. All rights reserved.
//

#import <SparkKit/SparkActionLoader.h>
#import <SparkKit/SparkPlugIn.h>
#import <SparkKit/SparkAction.h>
#import <SparkKit/SparkActionPlugIn.h>
#import <SparkKit/Spark_Private.h>

@implementation SparkActionLoader

+ (id)sharedLoader {
  static id loader = nil;
  if (!loader) {
    loader = [[self alloc] init];
  }
  return loader;
}

- (id)loadPlugInBundle:(NSBundle *)bundle {
  id plug = nil;
  Class principalClass = [bundle principalClass];
  if (principalClass) {
    if (![self plugInForClass:principalClass] && [self isValidPlugIn:principalClass]) {
      plug = [SparkPlugIn plugInWithBundle:bundle];
    }
  }
  return plug;
}

- (BOOL)isValidPlugIn:(Class)principalClass {
  if (![principalClass isSubclassOfClass:[SparkActionPlugIn class]]) {
    return NO;
  }
  Class action = [principalClass actionClass];
  return [action isSubclassOfClass:[SparkAction class]];
}

- (SparkPlugIn *)plugInForAction:(SparkAction *)action {
  id plugins = [[self plugIns] objectEnumerator];
  id plugin;
  while (plugin = [plugins nextObject]) {
    if ([action isKindOfClass:[plugin actionClass]]) {
      return plugin;
    }
  }
  return nil;
}

+ (NSString *)extension {
  return @"spact";
}

@end
