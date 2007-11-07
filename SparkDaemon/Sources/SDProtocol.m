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

#import <ShadowKit/SKApplication.h>

static
void SparkDaemonCheckTrigger(SparkLibrary *library, SparkTrigger *trigger) {
  if (trigger) {
    if ([trigger isRegistred]) {
      if (![[library entryManager] containsActiveEntryForTrigger:[trigger uid]]) {
        [trigger setRegistred:NO];
      }
    } else {
      if ([[library entryManager] containsActiveEntryForTrigger:[trigger uid]]) {
        [trigger setRegistred:YES];
      }
    }
  }
}

@implementation SparkDaemon (SparkServerProtocol)

- (UInt32)version {
  ShadowTrace();
  return kSparkServerVersion;
}

#pragma mark Shutdown
- (void)shutdown {
  ShadowTrace();
  [NSApp terminate:nil];
}

- (id<SparkLibrary>)library {
  ShadowTrace();
  if (!sd_rlibrary) {
    sd_rlibrary = [[sd_library distantLibrary] retain];
    [sd_rlibrary setDelegate:self];
  }
  return [sd_rlibrary distantLibrary];
}

#pragma mark Entries Management
- (void)distantLibrary:(SparkDistantLibrary *)library didAddEntry:(SparkEntry *)anEntry {
  ShadowTrace();
  if ([self isEnabled]) {
    /* Trigger can have a new active action */
    SparkDaemonCheckTrigger([library library], [anEntry trigger]);
  }
}
- (void)distantLibrary:(SparkDistantLibrary *)library didRemoveEntry:(SparkEntry *)anEntry {
  ShadowTrace();
  if ([self isEnabled]) {
    /* If trigger was not removed, it can be invalid */
    SparkDaemonCheckTrigger([library library], [anEntry trigger]);
  }
}
- (void)distantLibrary:(SparkDistantLibrary *)library didChangeEntryStatus:(SparkEntry *)anEntry {
  ShadowTrace();
  if ([self isEnabled]) {
    /* Should check triggers */
    SparkDaemonCheckTrigger([library library], [anEntry trigger]);
  }  
}
- (void)distantLibrary:(SparkDistantLibrary *)library didReplaceEntry:(SparkEntry *)anEntry withEntry:(SparkEntry *)otherEntry {
  ShadowTrace();
  if ([self isEnabled]) {
    /* Should check triggers */
    SparkDaemonCheckTrigger([library library], [anEntry trigger]);
    if (![[anEntry trigger] isEqual:[otherEntry trigger]])
      SparkDaemonCheckTrigger([library library], [otherEntry trigger]);
  }
}

#pragma mark -
#pragma mark Notifications
- (void)configureTrigger:(SparkTrigger *)aTrigger {
  [aTrigger setTarget:self];
  [aTrigger setAction:@selector(executeTrigger:)]; 
}

- (void)willAddTrigger:(NSNotification *)aNotification {
  ShadowTrace();
  SparkTrigger *trigger = SparkNotificationObject(aNotification);
  [self configureTrigger:trigger];
}

- (void)willRemoveTrigger:(NSNotification *)aNotification {
  ShadowTrace();
  if ([self isEnabled]) {
    SparkTrigger *trigger = SparkNotificationObject(aNotification);
    if ([trigger isRegistred])
      [trigger setRegistred:NO];
  }
}

/* Should never append since a trigger is not editable */
- (void)willUpdateTrigger:(NSNotification *)aNotification {
  ShadowTrace();
  /* Configure new trigger */
  SparkTrigger *new = SparkNotificationUpdatedObject(aNotification);
  NSAssert(new != nil, @"Invalid notification");
  [self configureTrigger:new];
  if ([self isEnabled]) {
    SparkTrigger *previous = SparkNotificationObject(aNotification);
    if ([previous isRegistred]) {
      [previous setRegistred:NO];
      /* Active new trigger */
      [new setRegistred:YES];
    }
  }
}

#pragma mark Application
- (void)willRemoveApplication:(NSNotification *)aNotification {
  ShadowTrace();
  /* handle special case: remove the front application and application is disabled */
  SparkApplication *app = SparkNotificationObject(aNotification);
  if ([[app application] isFront] && ![app isEnabled]) {
    /* restore triggers status */
    [self registerTriggers];
  }
}
- (void)didChangeApplicationStatus:(NSNotification *)aNotification {
  ShadowTrace();
  SparkApplication *app = [aNotification object];
  if ([[app application] isFront]) {
    if ([app isEnabled])
      [self registerTriggers];
    else 
      [self unregisterTriggers];
  }
}

#pragma mark Plugins Management
- (void)didChangePluginStatus:(NSNotification *)aNotification {
  if ([self isEnabled]) {
    [self registerTriggers];
  }
}

@end

void SDSendStateToEditor(SparkDaemonStatus state) {
  NSNumber *value = SKUInt(state);
  CFDictionaryRef info = CFDictionaryCreate(kCFAllocatorDefault, 
                                            (const void **)&SparkDaemonStatusKey,
                                            (const void **)&value, 1, 
                                            &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
  
  if (info) {
    CFNotificationCenterPostNotification(CFNotificationCenterGetDistributedCenter(),
                                         SparkDaemonStatusDidChangeNotification,
                                         kSparkConnectionName, info, false);
    CFRelease(info);
  }
}

