/*
 *  ServerProtocol.m
 *  SparkServer
 *
 *  Created by Black Moon Team.
 *  Copyright (c) 2004 - 2006 Shadow Lab. All rights reserved.
 */

#import "SparkDaemon.h"
#import "SDVersion.h"

#import <SparkKit/SparkTrigger.h>
#import <SparkKit/SparkLibrary.h>
#import <SparkKit/SparkObjectSet.h>
#import <SparkKit/SparkActionLoader.h>

SK_INLINE
SparkObjectSet *SDObjectSetForType(OSType type) {
  SparkObjectSet *set = nil;
  switch (type) {
    case kSparkActionType:
      set = SparkSharedActionSet();
      break;
    case kSparkTriggerType:
      set = SparkSharedTriggerSet();
      break;
    case kSparkApplicationType:
      set = SparkSharedApplicationSet();
      break;
  }
  return set;
}

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

- (void)configureTrigger:(SparkTrigger *)aTrigger {
  [aTrigger setTarget:self];
  [aTrigger setAction:@selector(executeTrigger:)]; 
}

- (int)version {
  return kSparkServerVersion;
}

#pragma mark Shutdown
- (void)shutdown {
  ShadowTrace();
  [NSApp terminate:nil];
}

#pragma mark Objects Management
- (void)addObject:(id)plist type:(OSType)type {
  ShadowTrace();
  SparkObjectSet *set = SDObjectSetForType(type);
  if (set) {
    SparkObject *object = [set deserialize:plist error:nil];
    if (object) {
      [set addObject:object];
      if (kSparkTriggerType == type) {
        [self configureTrigger:(SparkTrigger *)object];
      }
    }
  }
}
- (void)updateObject:(id)plist type:(OSType)type {
  ShadowTrace();
  SparkObjectSet *set = SDObjectSetForType(type);
  if (set) {
    SparkObject *object = [set deserialize:plist error:nil];
    if (object) {
      /* Trigger state is handled in notification */
      [set updateObject:object];
      if (kSparkTriggerType == type) {
        [self configureTrigger:(SparkTrigger *)object];
      }
    }
  }
}
- (void)removeObject:(UInt32)uid type:(OSType)type {
  ShadowTrace();
  SparkObjectSet *set = SDObjectSetForType(type);
  if (set) {
    /* Trigger desactivation is handled in notification */
    [set removeObjectWithUID:uid];
  }
}

#pragma mark Entries Management
- (void)addLibraryEntry:(SparkLibraryEntry *)anEntry {
  ShadowTrace();
  SparkEntryManager *manager = SparkSharedManager();
  [manager addLibraryEntry:anEntry];
  if ([self isEnabled]) {
    /* Trigger can have a new active action */
    SparkDaemonCheckTrigger([SparkSharedTriggerSet() objectForUID:anEntry->trigger]);
  }
}
- (void)removeLibraryEntry:(SparkLibraryEntry *)anEntry {
  ShadowTrace();
  SparkEntryManager *manager = SparkSharedManager();
  [manager removeLibraryEntry:anEntry];
  if ([self isEnabled]) {
    /* If trigger was not removed, it can be invalid */
    SparkDaemonCheckTrigger([SparkSharedTriggerSet() objectForUID:anEntry->trigger]);
  }
}
- (void)replaceLibraryEntry:(SparkLibraryEntry *)anEntry withLibraryEntry:(SparkLibraryEntry *)newEntry {
  ShadowTrace();
  SparkEntryManager *manager = SparkSharedManager();
  [manager replaceLibraryEntry:anEntry withLibraryEntry:newEntry];
  if ([self isEnabled]) {
    /* Should check trigger */
    SparkDaemonCheckTrigger([SparkSharedTriggerSet() objectForUID:newEntry->trigger]);
  }
}

- (void)enableLibraryEntry:(SparkLibraryEntry *)anEntry {
  ShadowTrace();
  SparkEntryManager *manager = SparkSharedManager();
  [manager enableLibraryEntry:anEntry];
  /* Should check trigger */
  if ([self isEnabled]) {
    SparkDaemonCheckTrigger([SparkSharedTriggerSet() objectForUID:anEntry->trigger]);
  }
}

- (void)disableLibraryEntry:(SparkLibraryEntry *)anEntry {
  ShadowTrace();
  SparkEntryManager *manager = SparkSharedManager();
  [manager disableLibraryEntry:anEntry];
  /* Should check trigger */
  if ([self isEnabled]) {
    SparkDaemonCheckTrigger([SparkSharedTriggerSet() objectForUID:anEntry->trigger]);
  }
}

#pragma mark Plugins Management
- (void)enablePlugIn:(NSString *)identifier {
  SparkPlugIn *plugin = [[SparkActionLoader sharedLoader] pluginForIdentifier:identifier];
  if (plugin) {
    [plugin setEnabled:YES];
    if ([self isEnabled]) {
      [self registerTriggers];
    }
  } else {
    DLog(@"Cannot find plugin: %@", identifier);
  }
}
- (void)disablePlugIn:(NSString *)identifier {
  SparkPlugIn *plugin = [[SparkActionLoader sharedLoader] pluginForIdentifier:identifier];
  if (plugin) {
    [plugin setEnabled:NO];
    if ([self isEnabled]) {
      [self registerTriggers];
    }
  } else {
    DLog(@"Cannot find plugin: %@", identifier);
  }
}

- (void)registerPlugIn:(NSString *)path {
  SparkPlugIn *plugin = [[SparkActionLoader sharedLoader] loadPlugin:path];
  if (!plugin) {
    DLog(@"Error while loading plugin: %@", path);
  }
}

#pragma mark -
#pragma mark Notifications
- (void)willRemoveTrigger:(NSNotification *)aNotification {
  ShadowTrace();
  if ([self isEnabled]) {
    SparkTrigger *trigger = SparkNotificationObject(aNotification);
    if ([trigger isRegistred])
      [trigger setRegistred:NO];
  }
}

/* Should never append */
- (void)willUpdateTrigger:(NSNotification *)aNotification {
  ShadowTrace();
  if ([self isEnabled]) {
    SparkTrigger *trigger = SparkNotificationObject(aNotification);
    if ([trigger isRegistred]) {
      [trigger setRegistred:NO];
      /* Active new trigger */
      trigger = [[aNotification userInfo] objectForKey:kSparkNotificationUpdatedObject];
      [trigger setRegistred:YES];
    }
  }
}

@end
