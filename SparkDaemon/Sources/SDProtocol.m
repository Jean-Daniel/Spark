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
#import <SparkKit/SparkEntryManager.h>
#import <SparkKit/SparkLibrarySynchronizer.h>

static
void SparkDaemonCheckTrigger(SparkTrigger *trigger) {
  if (trigger) {
    if ([trigger isRegistred]) {
      if (![SparkSharedManager() containsActiveEntryForTrigger:[trigger uid]]) {
        [trigger setRegistred:NO];
      }
    } else {
      if ([SparkSharedManager() containsActiveEntryForTrigger:[trigger uid]]) {
        [trigger setRegistred:YES];
      }
    }
  }
}

@implementation SparkDaemon (SparkServerProtocol)

- (int)version {
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
  if (!sd_library) {
    sd_library = [[SparkSharedLibrary() distantLibrary] retain];
    [sd_library setDelegate:self];
  }
  return [sd_library distantLibrary];
}

#pragma mark Entries Management
- (void)distantLibrary:(SparkDistantLibrary *)library didAddEntry:(SparkEntry *)anEntry {
  ShadowTrace();
  if ([self isEnabled]) {
    /* Trigger can have a new active action */
    SparkDaemonCheckTrigger([anEntry trigger]);
  }
}
- (void)distantLibrary:(SparkDistantLibrary *)library didRemoveEntry:(SparkEntry *)anEntry {
  ShadowTrace();
  if ([self isEnabled]) {
    /* If trigger was not removed, it can be invalid */
    SparkDaemonCheckTrigger([anEntry trigger]);
  }
}
- (void)distantLibrary:(SparkDistantLibrary *)library didChangeEntryStatus:(SparkEntry *)anEntry {
  ShadowTrace();
  if ([self isEnabled]) {
    /* Should check triggers */
    SparkDaemonCheckTrigger([anEntry trigger]);
  }  
}
- (void)distantLibrary:(SparkDistantLibrary *)library didReplaceEntry:(SparkEntry *)anEntry withEntry:(SparkEntry *)otherEntry {
  ShadowTrace();
  if ([self isEnabled]) {
    /* Should check triggers */
    SparkDaemonCheckTrigger([anEntry trigger]);
    if (![[anEntry trigger] isEqualToLibraryObject:[otherEntry trigger]])
      SparkDaemonCheckTrigger([otherEntry trigger]);
  }
}

- (void)configureTrigger:(SparkTrigger *)aTrigger {
  [aTrigger setTarget:self];
  [aTrigger setAction:@selector(executeTrigger:)]; 
}

#pragma mark -
#pragma mark Notifications
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
  SparkTrigger *new = [[aNotification userInfo] objectForKey:kSparkNotificationUpdatedObject];
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

#pragma mark Plugins Management
- (void)didChangePluginStatus:(NSNotification *)aNotification {
  if ([self isEnabled]) {
    [self registerTriggers];
  }
}

@end
