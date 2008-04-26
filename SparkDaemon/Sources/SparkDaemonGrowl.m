//
//  SparkDaemonGrowl.m
//  SparkDaemon
//
//  Created by Jean-Daniel Dupas on 05/04/08.
//  Copyright 2008 Ninsight. All rights reserved.
//

#import "SparkDaemonGrowl.h"

#import <SparkKit/SparkPlugIn.h>
#import <SparkKit/SparkActionLoader.h>

@implementation SparkDaemon (GrowlSupport)

//+ (BOOL)isGrowlRunning;
//+ (BOOL)isGrowlInstalled;

- (void)registerGrowl {
  if ([GrowlApplicationBridge isGrowlInstalled])
    [GrowlApplicationBridge setGrowlDelegate:self];
}

- (void)registerPlugin:(SparkActionPlugIn *)aPlugin {
  
}
- (void)unregisterPlugin:(SparkActionPlugIn *)aPlugin {
  
}

- (void)registerGrowlDelegate:(id)delegate {
  if (!sd_growl) sd_growl = [[NSMutableArray alloc] init];
  [sd_growl addObject:delegate];
}

#pragma mark -
- (NSDictionary *)registrationDictionaryForGrowl {
  NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                               [NSMutableArray array], GROWL_NOTIFICATIONS_ALL,
                               [NSMutableArray array], GROWL_NOTIFICATIONS_DEFAULT,
                               [NSMutableDictionary dictionary], GROWL_NOTIFICATIONS_DESCRIPTIONS, 
                               [NSMutableDictionary dictionary], GROWL_NOTIFICATIONS_HUMAN_READABLE_NAMES, nil];
  
  SparkActionLoader *loader = [SparkActionLoader sharedLoader];
  NSArray *plugins = [loader plugins];
  for (NSUInteger idx = 0; idx < [plugins count]; idx++) {
    SparkPlugIn *plugin = [plugins objectAtIndex:idx];
    NSDictionary *subdict = [plugin growlNotifications];
    if (subdict) {
      /* merge dictionaries */
      NSArray *array = [subdict objectForKey:GROWL_NOTIFICATIONS_ALL];
      if (array) [[dict objectForKey:GROWL_NOTIFICATIONS_ALL] addObjectsFromArray:array];
      
      array = [subdict objectForKey:GROWL_NOTIFICATIONS_DEFAULT];
      if (array) [[dict objectForKey:GROWL_NOTIFICATIONS_DEFAULT] addObjectsFromArray:array];
      
      NSDictionary *dictionary = [subdict objectForKey:GROWL_NOTIFICATIONS_DESCRIPTIONS];
      if (dictionary) [[dict objectForKey:GROWL_NOTIFICATIONS_DESCRIPTIONS] addEntriesFromDictionary:dictionary];
      
      dictionary = [subdict objectForKey:GROWL_NOTIFICATIONS_HUMAN_READABLE_NAMES];
      if (dictionary) [[dict objectForKey:GROWL_NOTIFICATIONS_HUMAN_READABLE_NAMES] addEntriesFromDictionary:dictionary];
    }
  }
  return dict;
}

- (NSString *)applicationNameForGrowl {
  return @"Spark";
}

//- (NSImage *)applicationIconForGrowl {
//  return nil;
//}
//
//- (NSData *)applicationIconDataForGrowl {
//  return nil;
//}

- (void)growlIsReady {
  NSUInteger idx = [sd_growl count];
  while (idx-- > 0) {
    id delegate = [sd_growl objectAtIndex:idx];
    if ([delegate respondsToSelector:_cmd]) [delegate performSelector:_cmd];
  }  
}

- (void)growlNotificationWasClicked:(id)clickContext {
  NSUInteger idx = [sd_growl count];
  while (idx-- > 0) {
    id delegate = [sd_growl objectAtIndex:idx];
    if ([delegate respondsToSelector:_cmd]) [delegate performSelector:_cmd withObject:clickContext];
  }
}

- (void)growlNotificationTimedOut:(id)clickContext {
  NSUInteger idx = [sd_growl count];
  while (idx-- > 0) {
    id delegate = [sd_growl objectAtIndex:idx];
    if ([delegate respondsToSelector:_cmd]) [delegate performSelector:_cmd withObject:clickContext];
  }  
}


@end
