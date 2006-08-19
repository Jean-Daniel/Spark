/*
 *  SparkActionLoader.m
 *  SparkKit
 *
 *  Created by Black Moon Team.
 *  Copyright (c) 2004 - 2006 Shadow Lab. All rights reserved.
 *
 */

#import <SparkKit/SparkActionLoader.h>
#import <SparkKit/SparkPlugIn.h>

#import "SparkPrivate.h"
#import <SparkKit/SparkActionPlugIn.h>

@implementation SparkActionLoader

+ (id)sharedLoader {
  static SparkActionLoader *loader = nil;
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
  SparkPlugIn *plug = nil;
  Class principalClass = [bundle principalClass];
  if (principalClass && [self isValidPlugIn:principalClass]) {
    plug = [SparkPlugIn plugInWithBundle:bundle];
  }
  return plug;
}

- (SparkPlugIn *)plugInForActionClass:(Class)cls {
  SInt32 count = [[self plugins] count];
  while (count-- > 0) {
    SparkPlugIn *plugin = [[self plugins] objectAtIndex:count];
    if ([cls isSubclassOfClass:[plugin actionClass]]) {
      return plugin;
    }
  }
  return nil;
}

- (SparkPlugIn *)plugInForAction:(SparkAction *)action {
  return [self plugInForActionClass:[action class]];
}

@end
