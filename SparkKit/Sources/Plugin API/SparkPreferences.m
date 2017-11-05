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
  static
  CFStringRef const kSparkPreferencesService = CFSTR("org.shadowlab.spark.preferences.debug");
#else
	static
	CFStringRef const kSparkPreferencesIdentifier = CFSTR("org.shadowlab.Spark");
  static
  CFStringRef const kSparkPreferencesService = CFSTR("org.shadowlab.spark.preferences");
#endif

enum {
  kSparkPreferencesMessageID = 'SpPr',
};

static 
CFMutableDictionaryRef sSparkDaemonPreferences = NULL;
static 
CFMutableDictionaryRef sSparkFrameworkPreferences = NULL;

static
void SparkPreferencesNotifyObservers(NSString *key, id value, SparkPreferencesDomain domain);

@interface SparkLibrary (SparkPreferencesPrivate)
- (BOOL)synchronizePreferences;
- (id)preferenceValueForKey:(NSString *)key;
- (void)setPreferenceValue:(id)value forKey:(NSString *)key;
@end

#pragma mark -
static
CFDataRef _SparkPreferencesHandleMessage(CFMessagePortRef local, SInt32 msgid, CFDataRef data, void *info) {
  if (kSparkPreferencesMessageID == msgid) {
    NSDictionary *request = [NSPropertyListSerialization propertyListWithData:SPXCFToNSData(data)
                                                                      options:NSPropertyListImmutable
                                                                       format:NULL error:NULL];
    if (request) {
      NSString *key = request[@"key"];
      SparkPreferencesDomain domain = [request[@"domain"] integerValue];
      id value = request[@"value"];
      SparkPreferencesSetValue(key, value, domain);
    }
  }
  return NULL;
}

static 
void _SparkPreferencesStartServer(void) {
  static
  CFMessagePortRef sMachPort = NULL;
  if (!sMachPort) {
    sMachPort = CFMessagePortCreateLocal(kCFAllocatorDefault, kSparkPreferencesService,
                                         _SparkPreferencesHandleMessage, NULL, NULL);
    if (sMachPort) {
      CFRunLoopSourceRef source = CFMessagePortCreateRunLoopSource(kCFAllocatorDefault, sMachPort, 0);
      if (source) {
        CFRunLoopRef rl = CFRunLoopGetCurrent();
        if (rl) {
          CFRunLoopAddSource(rl, source, kCFRunLoopCommonModes);
        } else {
          SPXLogWarning(@"Undefined error while getting current run loop");
        }
        CFRelease(source);
      }
    } else {
      SPXLogWarning(@"Undefined error while creating preference port");
      /* we do not want to retry on next call */
      sMachPort = (CFMessagePortRef)kCFNull;
    }
  }
}

static
void _SparkPreferencesSetDaemonValue(NSString *key, __nullable id value, SparkPreferencesDomain domain) {
  if (SparkDaemonIsRunning()) {
    spx_trace();
    NSDictionary *request = value ? @{ @"key": key, @"domain": @(domain), @"value": (id)value } : @{ @"key": key, @"domain": @(domain) };
    NSData *data = [NSPropertyListSerialization dataWithPropertyList:request
                                                              format:NSPropertyListBinaryFormat_v1_0
                                                             options:0 error:NULL];
    if (data) {
      CFMessagePortRef port = CFMessagePortCreateRemote(kCFAllocatorDefault, kSparkPreferencesService);
      if (port) {
        if (kCFMessagePortSuccess != CFMessagePortSendRequest(port, kSparkPreferencesMessageID, SPXNSToCFData(data),
                                                              5, 0, NULL, NULL)) {
          SPXLogWarning(@"Error while sending preference message");
        }
        CFMessagePortInvalidate(port);
        CFRelease(port);
      }
    }
  }
}

#pragma mark -
#pragma mark API
static
CFMutableDictionaryRef _SparkPreferencesGetDictionary(SparkPreferencesDomain domain) {
  switch (domain) {
    case SparkPreferencesDaemon:
      if (!sSparkDaemonPreferences)
        sSparkDaemonPreferences = CFDictionaryCreateMutable(kCFAllocatorDefault, 0,
                                                            &kCFTypeDictionaryKeyCallBacks,
                                                            &kCFTypeDictionaryValueCallBacks);
      return sSparkDaemonPreferences;
    case SparkPreferencesFramework:
      if (!sSparkFrameworkPreferences)
        sSparkFrameworkPreferences = CFDictionaryCreateMutable(kCFAllocatorDefault, 0,
                                                               &kCFTypeDictionaryKeyCallBacks,
                                                               &kCFTypeDictionaryValueCallBacks);
      return sSparkFrameworkPreferences;
    default:
      SPXThrowException(NSInvalidArgumentException, @"Unsupported preference domain: %ti", domain);
  }
}

#pragma mark Getter
id SparkPreferencesGetValue(NSString *key, SparkPreferencesDomain domain) {
  /* If daemon context, register preferences port */
  if (SparkGetCurrentContext() != kSparkContext_Editor) {
    _SparkPreferencesStartServer();
  }
  
  switch (domain) {
    case SparkPreferencesDaemon:
    case SparkPreferencesFramework: {
      id value = nil;
      /* If daemon context, try to get value from memory cache*/
      if (SparkGetCurrentContext() != kSparkContext_Editor) {
        CFMutableDictionaryRef dict = _SparkPreferencesGetDictionary(domain);
        NSCAssert(dict != NULL, @"Invalid preferences dictionary");
        value = (id)CFDictionaryGetValue(dict, SPXNSToCFString(key));
      }
      /* If editor context or memory cache return NULL, get system preference */
      if (!value) {
        value = SPXCFToNSType(CFPreferencesCopyValue(SPXNSToCFString(key), kSparkPreferencesIdentifier,
                                                     kCFPreferencesCurrentUser, kCFPreferencesAnyHost));
      }
      return value;
    }
    case SparkPreferencesLibrary:
      return [SparkActiveLibrary() preferenceValueForKey:key];
  }
  SPXThrowException(NSInvalidArgumentException, @"Unsupported preference domain: %ti", domain);
}

BOOL SparkPreferencesGetBooleanValue(NSString *key, SparkPreferencesDomain domain) {
  return [SparkPreferencesGetValue(key, domain) boolValue];
}

NSInteger SparkPreferencesGetIntegerValue(NSString *key, SparkPreferencesDomain domain) {
  return [SparkPreferencesGetValue(key, domain) integerValue];
}

#pragma mark Setter
static
void _SparkPreferencesSetValue(NSString *key, __nullable id value, SparkPreferencesDomain domain, BOOL synchronize) {
  SPXDebug(@"SparkPreferencesSetValue(%@, %@, %ld)", key, value, (long)domain);
  /* If daemon context, register preferences port */
  if (SparkGetCurrentContext() != kSparkContext_Editor) {
    _SparkPreferencesStartServer();
  }
  
  switch (domain) {
    case SparkPreferencesDaemon:
    case SparkPreferencesFramework: {
      if (SparkGetCurrentContext() == kSparkContext_Editor) {
        CFPreferencesSetValue(SPXNSToCFString(key), (CFPropertyListRef)value,
                              kSparkPreferencesIdentifier,
                              kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
      } else {
        CFMutableDictionaryRef dict = _SparkPreferencesGetDictionary(domain);
        NSCAssert(dict != NULL, @"Invalid preferences dictionary");
        if (value) {
          CFDictionarySetValue(dict, SPXNSToCFString(key), SPXNSToCFType(value));
        } else {
          CFDictionaryRemoveValue(dict, SPXNSToCFString(key));
        }
      }
    }
      break;
    case SparkPreferencesLibrary:
      [SparkActiveLibrary() setPreferenceValue:value forKey:key];
      break;
    default:
      SPXThrowException(NSInvalidArgumentException, @"Unsupported preference domain: %ti", domain);
  }
  SparkPreferencesNotifyObservers(key, value, domain);
  if (synchronize && SparkGetCurrentContext() == kSparkContext_Editor) {
    /* Sync daemon */
    _SparkPreferencesSetDaemonValue(key, value, domain);
  }
}

void SparkPreferencesSetValue(NSString *key, __nullable id value, SparkPreferencesDomain domain) {
  _SparkPreferencesSetValue(key, value, domain, YES);
}

void SparkPreferencesSetBooleanValue(NSString *key, BOOL value, SparkPreferencesDomain domain) {
  SparkPreferencesSetValue(key, @(value), domain);
}
void SparkPreferencesSetIntegerValue(NSString *key, NSInteger value, SparkPreferencesDomain domain) {
  SparkPreferencesSetValue(key, @(value), domain);
}

#pragma mark Synchronize
bool SparkPreferencesSynchronize(SparkPreferencesDomain domain) {
  if (SparkGetCurrentContext() != kSparkContext_Editor) {
    SPXLogWarning(@"Try to synchronize preferences but not in editor context");
    return false;
  }
  switch (domain) {
    case SparkPreferencesDaemon:
      return CFPreferencesSynchronize(kSparkPreferencesIdentifier,
                                      kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
    case SparkPreferencesLibrary:
      return [SparkActiveLibrary() synchronizePreferences]; /* synchronization is done when the library is saved */ // SparkLibraryPreferencesSynchronize();
    case SparkPreferencesFramework:
      return CFPreferencesSynchronize(kSparkPreferencesIdentifier,
                                      kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
  }
  SPXThrowException(NSInvalidArgumentException, @"Unsupported preference domain: %ti", domain);
}

#pragma mark -
#pragma mark Observers
@interface _SparkPreferencesObserver : NSObject {
  void(^_block)(NSString *, id);
}

- (instancetype)initWithBlock:(void(^)(NSString *, id))block;

- (void)notifyValueChange:(id)value forKey:(NSString *)key;

@end

static NSMutableDictionary *sDaemonObservers = NULL;
static NSMutableDictionary *sLibraryObservers = NULL;
static NSMutableDictionary *sFrameworkObservers = NULL;

static NSString * const kSparkPreferencesWildcard = @"__****__";

static
NSMutableDictionary *_SparkPreferencesGetObservers(SparkPreferencesDomain domain) {
  switch (domain) {
    case SparkPreferencesDaemon:
      return sDaemonObservers;
    case SparkPreferencesLibrary:
      return sLibraryObservers;
    case SparkPreferencesFramework:
      return sFrameworkObservers;
  }
  SPXThrowException(NSInvalidArgumentException, @"Unsupported preference domain: %ld", (long)domain);
}

static
void _SparkPreferencesSetObservers(NSMutableDictionary *observers, SparkPreferencesDomain domain) {
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
      SPXThrowException(NSInvalidArgumentException, @"Unsupported preference domain: %ld", (long)domain);
  }
}

WB_INLINE
void __SparkPreferencesNotifyObservers(NSMutableSet *observers, NSString *key, id value) {
  for (_SparkPreferencesObserver *observer in [observers copy]) {
    [observer notifyValueChange:value forKey:key];
  }
}

static
void SparkPreferencesNotifyObservers(NSString *key, id value, SparkPreferencesDomain domain) {
  NSCParameterAssert(key);
  NSMutableDictionary *table = _SparkPreferencesGetObservers(domain);
  if (table) {
    __SparkPreferencesNotifyObservers(table[key], key, value);
    __SparkPreferencesNotifyObservers(table[kSparkPreferencesWildcard], key, value);
  }
}

void SparkPreferencesRegisterObserver(NSString *key, SparkPreferencesDomain domain, void(^block)(NSString *, id)) {
  NSMutableDictionary *table = _SparkPreferencesGetObservers(domain);
  if (!table) {
    table = [NSMutableDictionary new];
    _SparkPreferencesSetObservers(table, domain);
  }

  if (!key)
    key = kSparkPreferencesWildcard;

  NSMutableSet *observers = table[key];
  if (!observers) {
    observers = [NSMutableSet new];
    [table setObject:observers forKey:key];
  }
  _SparkPreferencesObserver *observer = [[_SparkPreferencesObserver alloc] initWithBlock:block];
  [observers addObject:observer];
}

WB_INLINE
void __SparkPreferencesRemoveObserver(NSMutableDictionary *table, NSMutableSet *observers, id observer, NSString *key) {
  if (observers) {
    [observers removeObject:observer];
    /* Cleanup */
    if (![observers count]) {
      [table removeObjectForKey:key];
    }
  }
}

void SparkPreferencesUnregisterObserver(NSString *key, SparkPreferencesDomain domain, void(^observer)(NSString *, id)) {
  NSMutableDictionary *table = _SparkPreferencesGetObservers(domain);
  if (table) {
    /* If key is null, remove observer for all entries */
    if (!key) {
      for (NSMutableSet *observers in [table copy]) {
        __SparkPreferencesRemoveObserver(table, observers, observer, key);
      }
    } else {
      __SparkPreferencesRemoveObserver(table, table[key], observer, key);
    }
    /* Cleanup */
    if (![table count])
      _SparkPreferencesSetObservers(NULL, domain);
  }
}

@implementation _SparkPreferencesObserver

- (instancetype)initWithBlock:(void(^)(NSString *, id))block {
  if (self = [super init]) {
    _block = block;
  }
  return self;
}

- (NSUInteger)hash {
  return [_block hash];
}

- (BOOL)isEqual:(id)object {
  return [_block isEqual:object];
}

- (void)notifyValueChange:(id)value forKey:(NSString *)key {
  @try {
    _block(key, value);
  } @catch (id exception) {
    SPXLogException(exception);
  }
}

@end

