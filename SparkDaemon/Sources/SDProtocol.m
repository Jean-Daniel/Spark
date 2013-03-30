/*
 *  ServerProtocol.m
 *  SparkServer
 *
 *  Created by Black Moon Team.
 *  Copyright (c) 2004 - 2006 Shadow Lab. All rights reserved.
 */

#import "SparkDaemon.h"
#import "SDVersion.h"

#import <SparkKit/SparkEntry.h>
#import <SparkKit/SparkTrigger.h>
#import <SparkKit/SparkObjectSet.h>
#import <SparkKit/SparkFunctions.h>
#import <SparkKit/SparkEntryManager.h>
#import <SparkKit/SparkLibrarySynchronizer.h>

@implementation SparkDaemon (SparkServerProtocol)

- (UInt32)version {
  SPXTrace();
  return kSparkServerVersion;
}

- (void)shutdown {
  SPXTrace();
  [NSApp terminate:nil];
}

- (id<SparkLibrary>)library {
  SPXTrace();
  if (!sd_rlibrary)
    sd_rlibrary = [[sd_library distantLibrary] retain];
  return [sd_rlibrary distantLibrary];
}

#pragma mark Entries Management
- (void)didAddEntry:(NSNotification *)aNotification {
  SPXTrace();
  SparkEntry *entry = SparkNotificationObject(aNotification);
  /* Trigger can have a new active action */
  if ([self isEnabled] || [entry isPersistent])
    [self setEntryStatus:entry];
}

- (void)didUpdateEntry:(NSNotification *)aNotification {
  SPXTrace();
  SparkEntry *new = SparkNotificationObject(aNotification);
  SparkEntry *previous = SparkNotificationUpdatedObject(aNotification);
  if ([self isEnabled] || [new isPersistent] || [previous isPersistent]) {
    [self setEntryStatus:previous];
    
    if (![[new trigger] isEqual:[previous trigger]])
      [self setEntryStatus:new];
  }
}

- (void)didRemoveEntry:(NSNotification *)aNotification {
  SPXTrace();
  SparkEntry *entry = SparkNotificationObject(aNotification);
  /* If trigger was not removed, we should check it */
  if ([self isEnabled] || [entry isPersistent])
    [self setEntryStatus:entry];
}

- (void)didChangeEntryStatus:(NSNotification *)aNotification {
  SPXTrace();
  SparkEntry *entry = SparkNotificationObject(aNotification);
  if ([self isEnabled] || [entry isPersistent]) {
    /* Should check triggers */
    [self setEntryStatus:entry];
  }  
}

#pragma mark -
#pragma mark Notifications
- (void)willRemoveTrigger:(NSNotification *)aNotification {
  SPXTrace();
  if ([self isEnabled]) {
    SparkTrigger *trigger = SparkNotificationObject(aNotification);
    if ([trigger isRegistred])
      [trigger setRegistred:NO];
  }
}

/* Should never append since a trigger is not editable */
//- (void)willUpdateTrigger:(NSNotification *)aNotification {
//  SPXTrace();
//  /* Configure new trigger */
//  SparkTrigger *new = SparkNotificationObject(aNotification);
//  [self configureTrigger:new];
//  if ([self isEnabled]) {
//    SparkTrigger *previous = SparkNotificationUpdatedObject(aNotification);
//    if ([previous isRegistred]) {
//      [previous setRegistred:NO];
//      /* Active new trigger */
//      [new setRegistred:YES];
//    }
//  }
//}

#pragma mark Application
- (void)willRemoveApplication:(NSNotification *)aNotification {
  SPXTrace();
  /* handle special case: remove the front application and application is disabled */
  SparkApplication *app = SparkNotificationObject(aNotification);
  if ([app isEqual:sd_front] && ![app isEnabled]) {
    /* restore triggers status */
    [self registerEntries];
    sd_front = nil;
  }
}
- (void)didChangeApplicationStatus:(NSNotification *)aNotification {
  SPXTrace();
  SparkApplication *app = [aNotification object];
  if ([app isEqual:sd_front]) {
    if ([app isEnabled])
      [self registerEntries];
    else 
      [self unregisterEntries];
  }
}

#pragma mark Plugins Management
- (void)didChangePlugInStatus:(NSNotification *)aNotification {
  SPXTrace();
  if ([self isEnabled])
    [self registerEntries];
}

@end

void SDSendStateToEditor(SparkDaemonStatus state) {
  NSNumber *value = @(state);
  CFDictionaryRef info = CFDictionaryCreate(kCFAllocatorDefault, 
                                            (const void **)&SparkDaemonStatusKey,
                                            (const void **)&value, 1, 
                                            &kCFCopyStringDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
  
  if (info) {
    CFNotificationCenterPostNotification(CFNotificationCenterGetDistributedCenter(),
                                         SparkDaemonStatusDidChangeNotification,
                                         kSparkConnectionName, info, false);
    CFRelease(info);
  }
}

