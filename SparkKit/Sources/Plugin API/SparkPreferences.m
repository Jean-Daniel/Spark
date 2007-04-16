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

#pragma mark Observers
@interface _SparkPreferencesObserver : NSObject {
  id sp_target;
  SEL sp_action;
}

- (id)initWithTarget:(id)target action:(SEL)action;

- (id)target;

- (void)notifyValueChange:(id)value forKey:(NSString *)key;

@end

static NSMapTable *sDaemonObservers = NULL;
static NSMapTable *sLibraryObservers = NULL;
static NSMapTable *sFrameworkObservers = NULL;

static NSString * const kSparkPreferencesWildcard = @"__****__";

static
NSMapTable *_SparkPreferencesGetObservers(SparkPreferencesDomain domain) {
  switch (domain) {
    case SparkPreferencesDaemon:
      return sDaemonObservers;
    case SparkPreferencesLibrary:
      return sLibraryObservers;
    case SparkPreferencesFramework:
      return sFrameworkObservers;
  }
  [NSException raise:NSInvalidArgumentException format:@"Unsupported preference domain: %li", domain];
  return NULL;
}

static
void _SparkPreferencesSetObservers(NSMapTable *observers, SparkPreferencesDomain domain) {
  switch (domain) {
    case SparkPreferencesDaemon:
      sDaemonObservers = observers;
      break;
    case SparkPreferencesLibrary:
      sLibraryObservers = observers;
      break;
    case SparkPreferencesFramework:
      sFrameworkObservers = observers;
      break;
    default:
      [NSException raise:NSInvalidArgumentException format:@"Unsupported preference domain: %li", domain];
  }
}

SK_INLINE
void __SparkPreferencesNotifyObservers(NSHashTable *observers, NSString *key, id value) {
  if (observers) {
    _SparkPreferencesObserver *observer;
    NSHashTable *copy = NSCopyHashTableWithZone(observers, NULL);
    NSHashEnumerator items = NSEnumerateHashTable(copy);
    while (observer = NSNextHashEnumeratorItem(&items)) {
      if ([observer target]) {
        [observer notifyValueChange:value forKey:key];
      } else {
        NSHashRemove(observers, observer);
      }
    }
    NSEndHashTableEnumeration(&items);
  }  
}

static
void SparkPreferencesNotifyObservers(NSString *key, id value, SparkPreferencesDomain domain) {
  NSCParameterAssert(key);
  NSMapTable *table = _SparkPreferencesGetObservers(domain);
  if (table) {
    __SparkPreferencesNotifyObservers(NSMapGet(table, key), key, value);
    __SparkPreferencesNotifyObservers(NSMapGet(table, kSparkPreferencesWildcard), key, value);
  }
}

void SparkPreferencesRegisterObserver(id object, SEL callback, NSString *key, SparkPreferencesDomain domain) {
  NSMapTable *table = _SparkPreferencesGetObservers(domain);
  if (!table) {
    table = NSCreateMapTable(NSObjectMapKeyCallBacks, NSNonOwnedPointerMapValueCallBacks, 0);
    _SparkPreferencesSetObservers(table, domain);
  }
  if (!key) key = kSparkPreferencesWildcard;
  NSHashTable *observers = NSMapGet(table, key);
  if (!observers) {
    observers = NSCreateHashTable(NSObjectHashCallBacks, 0);
    NSMapInsert(table, key, observers);
  }
  _SparkPreferencesObserver *observer = [[_SparkPreferencesObserver alloc] initWithTarget:object action:callback];
  NSHashInsert(observers, observer);
  [observer release];
}

SK_INLINE
void __SparkPreferencesRemoveObserver(NSMapTable *table, NSHashTable *observers, id observer, NSString *key) {
  if (observers) {
    NSHashRemove(observers, observer);
    /* Cleanup */
    if (!NSCountHashTable(observers)) {
      NSMapRemove(table, key);
      NSFreeHashTable(observers);
    }
  }
}

void SparkPreferencesUnregisterObserver(id observer, NSString *key, SparkPreferencesDomain domain) {
  NSMapTable *table = _SparkPreferencesGetObservers(domain);
  if (table) {
    /* If key is null, remove observer for all entries */
    if (!key) {
      NSHashTable *observers;
      NSMapTable *copy = NSCopyMapTableWithZone(table, NULL);
      NSMapEnumerator iter = NSEnumerateMapTable(copy);
      while (NSNextMapEnumeratorPair(&iter, (void **)&key, (void **)&observers)) {
        __SparkPreferencesRemoveObserver(table, observers, observer, key);
      }
      NSEndMapTableEnumeration(&iter);
      NSFreeMapTable(copy);
    } else {
      __SparkPreferencesRemoveObserver(table, NSMapGet(table, key), observer, key);
    }
    /* Cleanup */
    if (!NSCountMapTable(table)) {
      NSFreeMapTable(table);
      _SparkPreferencesSetObservers(NULL, domain);
    }
  }
}

@implementation _SparkPreferencesObserver

- (id)initWithTarget:(id)target action:(SEL)action {
  if (self = [super init]) {
    sp_target = target;
    sp_action = action;
  }
  return self;
}

- (NSUInteger)hash {
  return [sp_target hash];
}

- (BOOL)isEqual:(id)object {
  return [sp_target isEqual:object];
}

- (id)target {
  return sp_target;
}

- (void)notifyValueChange:(id)value forKey:(NSString *)key {
  [sp_target performSelector:sp_action withObject:value withObject:key];
}

@end

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
  /* Notify Observers */
  SparkPreferencesNotifyObservers(key, value, SparkPreferencesLibrary);
}

@end

