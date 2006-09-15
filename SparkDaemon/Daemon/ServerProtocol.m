/*
 *  ServerProtocol.m
 *  SparkServer
 *
 *  Created by Black Moon Team.
 *  Copyright (c) 2004 - 2006 Shadow Lab. All rights reserved.
 */

#import "SparkDaemon.h"

#import <SparkKit/SparkTrigger.h>
#import <SparkKit/SparkLibrary.h>
#import <SparkKit/SparkObjectSet.h>

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

@implementation SparkDaemon (SparkServerProtocol)

- (void)registerTrigger:(SparkTrigger *)aTrigger {
  [aTrigger setTarget:self];
  [aTrigger setAction:@selector(executeTrigger:)]; 
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
        [self registerTrigger:(SparkTrigger *)object];
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
        [self registerTrigger:(SparkTrigger *)object];
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
  /* Trigger can have a new active action */
  SparkTrigger *trigger = [SparkSharedTriggerSet() objectForUID:anEntry->trigger];
  if (![trigger isRegistred] && [manager containsActiveEntryForTrigger:anEntry->trigger]) {
    [trigger setRegistred:YES];
  }
}
- (void)removeLibraryEntry:(SparkLibraryEntry *)anEntry {
  ShadowTrace();
  SparkEntryManager *manager = SparkSharedManager();
  [manager removeLibraryEntry:anEntry];
  /* If trigger was not removed, it can be invalid */
  SparkTrigger *trigger = [SparkSharedTriggerSet() objectForUID:anEntry->trigger];
  if (trigger && [trigger isRegistred] && ![manager containsActiveEntryForTrigger:anEntry->trigger]) {
    [trigger setRegistred:NO];
  }
}
- (void)replaceLibraryEntry:(SparkLibraryEntry *)anEntry withLibraryEntry:(SparkLibraryEntry *)newEntry {
  ShadowTrace();
  SparkEntryManager *manager = SparkSharedManager();
  [manager replaceLibraryEntry:anEntry withLibraryEntry:newEntry];
  /* Should check trigger */
  SparkTrigger *trigger = [SparkSharedTriggerSet() objectForUID:newEntry->trigger];
  if (![trigger isRegistred] && [manager containsActiveEntryForTrigger:newEntry->trigger]) {
    [trigger setRegistred:YES];
  } else if ([trigger isRegistred] && ![manager containsActiveEntryForTrigger:newEntry->trigger]) {
    [trigger setRegistred:NO];
  }
}

- (void)setStatus:(BOOL)status forLibraryEntry:(SparkLibraryEntry *)anEntry {
  ShadowTrace();
  SparkEntryManager *manager = SparkSharedManager();
  [manager setStatus:status forLibraryEntry:anEntry];
  /* Should check trigger */
  SparkTrigger *trigger = [SparkSharedTriggerSet() objectForUID:anEntry->trigger];
  if (status && ![trigger isRegistred] && [manager containsActiveEntryForTrigger:anEntry->trigger]) {
    [trigger setRegistred:YES];
  } else if (!status && [trigger isRegistred] && ![manager containsActiveEntryForTrigger:anEntry->trigger]) {
    [trigger setRegistred:NO];
  }
}

#pragma mark -
#pragma mark Notifications
- (void)willRemoveTrigger:(NSNotification *)aNotification {
  ShadowTrace();
  SparkTrigger *trigger = SparkNotificationObject(aNotification);
  if ([trigger isRegistred])
    [trigger setRegistred:NO];
}

/* Should never append */
- (void)willUpdateTrigger:(NSNotification *)aNotification {
  ShadowTrace();
  SparkTrigger *trigger = SparkNotificationObject(aNotification);
  if ([trigger isRegistred]) {
    [trigger setRegistred:NO];
    /* Active new trigger */
    trigger = [[aNotification userInfo] objectForKey:kSparkNotificationUpdatedObject];
    [trigger setRegistred:YES];
  }
}

@end
