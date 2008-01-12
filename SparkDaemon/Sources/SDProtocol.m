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

static
void SparkDaemonCheckTrigger(SparkLibrary *library, SparkTrigger *trigger, BOOL isEnabled) {
  if (trigger) {
    if (isEnabled) {
      /* Spark daemon is enabled, si check on all actions */
      if ([trigger isRegistred]) {
        if (![[library entryManager] containsActiveEntryForTrigger:trigger]) {
          [trigger setRegistred:NO];
        }
      } else {
        if ([[library entryManager] containsActiveEntryForTrigger:trigger]) {
          [trigger setRegistred:YES];
        }
      }
    } else {
      /* Spark Daemon is disabled, so check only persistents actions */
      if ([trigger isRegistred]) {
        if (![[library entryManager] containsPersistentActiveEntryForTrigger:trigger]) {
          [trigger setRegistred:NO];
        }
      } else {
        if ([[library entryManager] containsPersistentActiveEntryForTrigger:trigger]) {
          [trigger setRegistred:YES];
        }
      }
    }
  }
}

@implementation SparkDaemon (SparkServerProtocol)

- (UInt32)version {
  WBTrace();
  return kSparkServerVersion;
}

#pragma mark Shutdown
- (void)shutdown {
  WBTrace();
  [NSApp terminate:nil];
}

- (id<SparkLibrary>)library {
  WBTrace();
  if (!sd_rlibrary) {
    sd_rlibrary = [[sd_library distantLibrary] retain];
  }
  return [sd_rlibrary distantLibrary];
}

#pragma mark Entries Management
- (void)didAddEntry:(NSNotification *)aNotification {
  WBTrace();
  SparkEntry *entry = SparkNotificationObject(aNotification);
  if ([self isEnabled] || [entry isPersistent]) {
    /* Trigger can have a new active action */
    SparkDaemonCheckTrigger(sd_library, [entry trigger], [self isEnabled]);
  }
}

- (void)didUpdateEntry:(NSNotification *)aNotification {
  WBTrace();
  SparkEntry *new = SparkNotificationObject(aNotification);
  SparkEntry *previous = SparkNotificationUpdatedObject(aNotification);
  if ([self isEnabled] || [new isPersistent] || [previous isPersistent]) {
    SparkDaemonCheckTrigger(sd_library, [previous trigger], [self isEnabled]);
    
    if (![[new trigger] isEqual:[previous trigger]])
      SparkDaemonCheckTrigger(sd_library, [new trigger], [self isEnabled]);
  }
}

- (void)didRemoveEntry:(NSNotification *)aNotification {
  WBTrace();
  SparkEntry *entry = SparkNotificationObject(aNotification);
  if ([self isEnabled] || [entry isPersistent]) {
    /* If trigger was not removed, we should check it */
    SparkDaemonCheckTrigger(sd_library, [entry trigger], [self isEnabled]);
  }
}

- (void)didChangeEntryStatus:(NSNotification *)aNotification {
  WBTrace();
  SparkEntry *entry = SparkNotificationObject(aNotification);
  if ([self isEnabled] || [entry isPersistent]) {
    /* Should check triggers */
    SparkDaemonCheckTrigger(sd_library, [entry trigger], [self isEnabled]);
  }  
}

#pragma mark -
#pragma mark Notifications
- (void)configureTrigger:(SparkTrigger *)aTrigger {
  [aTrigger setTarget:self];
  [aTrigger setAction:@selector(executeTrigger:)]; 
}

- (void)didAddTrigger:(NSNotification *)aNotification {
  WBTrace();
  SparkTrigger *trigger = SparkNotificationObject(aNotification);
  [self configureTrigger:trigger];
}

- (void)willRemoveTrigger:(NSNotification *)aNotification {
  WBTrace();
  if ([self isEnabled]) {
    SparkTrigger *trigger = SparkNotificationObject(aNotification);
    if ([trigger isRegistred])
      [trigger setRegistred:NO];
  }
}

/* Should never append since a trigger is not editable */
//- (void)willUpdateTrigger:(NSNotification *)aNotification {
//  WBTrace();
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
  WBTrace();
  /* handle special case: remove the front application and application is disabled */
  SparkApplication *app = SparkNotificationObject(aNotification);
  if ([app isEqual:sd_front] && ![app isEnabled]) {
    /* restore triggers status */
    [self registerTriggers];
    sd_front = nil;
  }
}
- (void)didChangeApplicationStatus:(NSNotification *)aNotification {
  WBTrace();
  SparkApplication *app = [aNotification object];
  if ([app isEqual:sd_front]) {
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
  NSNumber *value = WBUInteger(state);
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

