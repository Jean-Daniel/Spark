/*
 *  SparkPreferences.m
 *  SparkKit
 *
 *  Created by Grayfox on 14/04/07.
 *  Copyright 2007 Shadow Lab. All rights reserved.
 */

#import <SparkKit/SparkPreferences.h>
#import <SparkKit/SparkFunctions.h>
#import <SparkKit/SparkPrivate.h>

/* Spark Core preferences */
#if defined(DEBUG)
static
CFStringRef const kSparkPreferencesIdentifier = CFSTR("org.shadowlab.Spark-debug");
#else
static
CFStringRef const kSparkPreferencesIdentifier = CFSTR("org.shadowlab.Spark");
#endif

id SparkPreferencesGetValue(NSString *key, SparkPreferencesDomain domain) {
  switch (domain) {
    case SparkPreferencesDaemon: {
      id value = (id)CFPreferencesCopyValue((CFStringRef)key, kSparkPreferencesIdentifier, 
                                            kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
      return [value autorelease];
    }
    case SparkPreferencesLibrary:
      return [SparkActiveLibrary() preferenceValueForKey:key];
    case SparkPreferencesFramework: {
      id value = (id)CFPreferencesCopyValue((CFStringRef)key, kSparkPreferencesIdentifier, 
                                            kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
      return [value autorelease];
    }
  }
  [NSException raise:NSInvalidArgumentException format:@"Unsupported preference domain: %ti", domain];
  return nil;
}

BOOL SparkPreferencesGetBooleanValue(NSString *key, SparkPreferencesDomain domain) {
  return [SparkPreferencesGetValue(key, domain) boolValue];
}
NSInteger SparkPreferencesGetIntegerValue(NSString *key, SparkPreferencesDomain domain) {
  return SKIntegerValue(SparkPreferencesGetValue(key, domain));
}

Boolean SparkPreferencesSynchronize(SparkPreferencesDomain domain) {
  switch (domain) {
    case SparkPreferencesDaemon:
      return CFPreferencesSynchronize(kSparkPreferencesIdentifier,
                                      kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
    case SparkPreferencesLibrary:
      return SparkLibraryPreferencesSynchronize();
    case SparkPreferencesFramework:
      return CFPreferencesSynchronize(kSparkPreferencesIdentifier,
                                      kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
  }
  [NSException raise:NSInvalidArgumentException format:@"Unsupported preference domain: %ti", domain];
  return false;
}

void SparkPreferencesSetValue(NSString *key, id value, SparkPreferencesDomain domain) {
  if (SparkGetCurrentContext() != kSparkEditorContext) {
    WLog(@"Try to set preferences (%@) but not in editor context", key);
    return;
  }
  switch (domain) {
    case SparkPreferencesDaemon: 
      CFPreferencesSetValue((CFStringRef)key, (CFPropertyListRef)value, 
                            kSparkPreferencesIdentifier,
                            kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
      break;
    case SparkPreferencesLibrary:
      [SparkActiveLibrary() setPreferenceValue:value forKey:key];
      break;
    case SparkPreferencesFramework:
      CFPreferencesSetValue((CFStringRef)key, (CFPropertyListRef)value, 
                            kSparkPreferencesIdentifier,
                            kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
      break;
    default:
      [NSException raise:NSInvalidArgumentException format:@"Unsupported preference domain: %ti", domain];
      break;
  }
}
void SparkPreferencesSetBooleanValue(NSString *key, BOOL value, SparkPreferencesDomain domain) {
  SparkPreferencesSetValue(key, SKBool(value), domain);
}
void SparkPreferencesSetIntegerValue(NSString *key, NSInteger value, SparkPreferencesDomain domain) {
  SparkPreferencesSetValue(key, SKInteger(value), domain);
}

static NSMapTable *sObservers = NULL;

void SparkPreferencesRegisterObserver(id object, NSString *key) {
  if (!sObservers) {
    sObservers = NSCreateMapTable(NSObjectMapKeyCallBacks, NSNonOwnedPointerMapValueCallBacks, 0);
  }
  NSHashTable *observers = NSMapGet(sObservers, key);
  if (!observers) {
    observers = NSCreateHashTable(NSNonRetainedObjectHashCallBacks, 0);
    NSMapInsert(sObservers, key, observers);
  }
  NSHashInsert(observers, object);
}

void SparkPreferencesUnregisterObserver(id object, NSString *key) {
  if (sObservers) {
    NSHashTable *observers = NSMapGet(sObservers, key);
    if (observers) {
      NSHashRemove(observers, object);
      /* Cleanup */
      if (!NSCountHashTable(observers)) {
        NSMapRemove(sObservers, key);
        NSFreeHashTable(observers);
      }
    }
    /* Cleanup */
    if (!NSCountMapTable(sObservers)) {
      NSFreeMapTable(sObservers);
      sObservers = NULL;
    }
  }
}

static
void SparkPreferencesNotifyObservers(NSString *key, id value) {
  if (sObservers) {
    NSHashTable *observers = NSMapGet(sObservers, key);
    if (observers) {
      id observer;
      NSHashEnumerator items = NSEnumerateHashTable(observers);
      while (observer = NSNextHashEnumeratorItem(&items)) {
        [observer didSetPreferenceValue:value forKey:key];
      }
      NSEndHashTableEnumeration(&items);
    }
  }
}

#pragma mark -
@implementation SparkLibrary (SparkPreferences)

- (NSMutableDictionary *)preferences {
  return sp_prefs ? : SparkLibraryGetPreferences(self);
}
- (void)setPreferences:(NSDictionary *)preferences {
  SKSetterMutableCopy(sp_prefs, preferences);
}

- (id)preferenceValueForKey:(NSString *)key {
  return [[self preferences] objectForKey:key];
}

- (void)setPreferenceValue:(id)value forKey:(NSString *)key {
  if (value) {
    [[self preferences] setObject:value forKey:key];
  } else {
    [[self preferences] removeObjectForKey:key];
  }
  /* Notify */
  NSDictionary *info = [NSDictionary dictionaryWithObjectsAndKeys:
    key, SparkNotificationPreferenceNameKey,
    value, SparkNotificationPreferenceValueKey, nil];
  [[self notificationCenter] postNotificationName:SparkLibraryDidSetPreferenceNotification
                                           object:self
                                         userInfo:info];
  /* Public notify */
  SparkPreferencesNotifyObservers(key, value);
}

@end

