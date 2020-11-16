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
#import <SparkKit/SparkLibrary.h>

// MARK: -

static NSString * const kSparkPreferencesWildcard = @"__****__";

typedef void(^_SparkPreferencesObserver)(NSString *, __nullable id);

@interface SparkPreference ()
@property (nonatomic,unsafe_unretained) SparkLibrary *library;
- (void)notifyObservers:(NSString *)key value:(__nullable id)value;
@end

// FIXME: move this in a header
@interface SparkLibrary (SparkPreferencesPrivate)
- (BOOL)synchronizePreferences;
- (id)preferenceValueForKey:(NSString *)key;
- (void)setPreferenceValue:(id)value forKey:(NSString *)key;
@end

@implementation SparkPreference {
  NSMutableDictionary<NSString *, NSHashTable<_SparkPreferencesObserver> *> *_observers;
}

- (instancetype)initWithLibrary:(SparkLibrary *)library {
  if (self = [super init]) {
    _library = library;
  }
  return self;
}

// MARK: Implementation

// MARK: API
- (BOOL)boolForKey:(NSString *)key {
  return [[self objectForKey:key] boolValue];
}
- (void)setBool:(BOOL)value forKey:(NSString *)key {
  [self setObject:@(value) forKey:key];
}

- (NSInteger)integerForKey:(NSString *)key {
  return [[self objectForKey:key] integerValue];
}
- (void)setInteger:(NSInteger)value forKey:(NSString *)key {
  [self setObject:@(value) forKey:key];
}

- (__nullable id)objectForKey:(NSString *)key {
  return [_library preferenceValueForKey:key];
}
- (void)setObject:(__nullable id)value forKey:(NSString *)key {
  [_library setPreferenceValue:value forKey:key];

  [self notifyObservers:key value:value];
  [self notifyObservers:kSparkPreferencesWildcard value:value];
}

- (void)synchronize {
  [_library synchronizePreferences];
}

- (void)registerObserver:(void(^)(NSString *, __nullable id))block forKey:(NSString *)key {
  if (!_observers)
    _observers = [NSMutableDictionary new];

  if (!key)
    key = kSparkPreferencesWildcard;

  NSHashTable *observers = _observers[key];
  if (!observers) {
    observers = [NSHashTable weakObjectsHashTable];
    [_observers setObject:observers forKey:key];
  }
  [observers addObject:block];
}

- (void)unregisterObserver:(void(^)(NSString *, id))observer forKey:(NSString *)key {
  if (_observers) {
    /* If key is null, remove observer for all entries */
    if (!key) {
      for (NSHashTable<_SparkPreferencesObserver> *observers in [_observers allValues]) {
        [observers removeObject:observer];
      }
    } else {
      [_observers[key] removeObject:observer];
    }
  }
}

- (void)notifyObservers:(NSString *)key value:(id)value {
  for (_SparkPreferencesObserver observer in [_observers[key] copy]) {
    @try {
      if (observer)
        observer(key, value);
    } @catch (id exception) {
      spx_log_exception(exception);
    }
  }
}

@end
