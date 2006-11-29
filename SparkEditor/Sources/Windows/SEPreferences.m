/*
 *  SEPreferences.m
 *  Spark Editor
 *
 *  Created by Grayfox on 07/09/06.
 *  Copyright 2006 Shadow Lab. All rights reserved.
 */

#import "SEPreferences.h"

#import <SparkKit/SparkActionLoader.h>

@implementation SEPreferences

- (id)init {
  if (self = [super init]) {
    se_plugins = [[NSMutableDictionary alloc] init];
  }
  return self;
}

- (void)dealloc {
  [se_plugins release];
  [super dealloc];
}

- (void)awakeFromNib {
  NSMutableArray *uplugs = [NSMutableArray array];
  NSMutableArray *lplugs = [NSMutableArray array];
  NSMutableArray *bplugs = [NSMutableArray array];
  
  NSString *user = [SparkActionLoader pluginPathForDomain:kSKUserDomain];
  NSString *local = [SparkActionLoader pluginPathForDomain:kSKLocalDomain];

  SparkPlugIn *plugin;
  NSEnumerator *plugins = [[SparkActionLoader sharedLoader] objectEnumerator];
  while (plugin = [plugins nextObject]) {
    NSString *path = [plugin path];
    if ([path hasPrefix:user]) {
      [uplugs addObject:plugin];
    } else if ([path hasPrefix:local]) {
      [lplugs addObject:plugin];
    } else {
      [bplugs addObject:plugin];
    }
  }
  [se_plugins setValue:uplugs forKey:@"User"];
  [se_plugins setValue:lplugs forKey:@"Local"];
  [se_plugins setValue:bplugs forKey:@"BuiltIn"];
  
  DLog(@"%@", se_plugins);
}

#pragma mark -
#pragma mark Plugin Manager



@end
