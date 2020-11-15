/*
 *  SparkPreferences.h
 *  SparkKit
 *
 *  Created by Grayfox on 14/04/07.
 *  Copyright 2007 Shadow Lab. All rights reserved.
 *
 */

#if !defined(__SPARK_PREFERENCES_H)
#define __SPARK_PREFERENCES_H 1

#if defined(__OBJC__)

#import <SparkKit/SparkDefine.h>

NS_ASSUME_NONNULL_BEGIN

@class SparkLibrary;

// MARK: - Preferences
@interface SparkPreference: NSObject
- (instancetype)initWithLibrary:(SparkLibrary *)library;

- (BOOL)boolForKey:(NSString *)key;
- (void)setBool:(BOOL)value forKey:(NSString *)key;

- (NSInteger)integerForKey:(NSString *)key;
- (void)setInteger:(NSInteger)value forKey:(NSString *)key;

- (__nullable id)objectForKey:(NSString *)key;
- (void)setObject:(__nullable id)value forKey:(NSString *)key;

- (void)synchronize;

- (void)registerObserver:(void(^)(NSString *, __nullable id))observer forKey:(NSString * __nullable)key;
- (void)unregisterObserver:(void(^)(NSString *, __nullable id))observer forKey:(NSString * __nullable)key;

@end

NS_ASSUME_NONNULL_END

#endif /* __OBJC__ */

#endif /* __SPARK_PREFERENCES_H */
