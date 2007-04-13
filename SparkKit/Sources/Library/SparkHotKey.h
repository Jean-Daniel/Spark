/*
 *  SparkHotKey.h
 *  SparkKit
 *
 *  Created by Black Moon Team.
 *  Copyright (c) 2004 - 2007 Shadow Lab. All rights reserved.
 */
/*!
@header SparkHotKey
 @abstract Define a SparkHotKey.
 */

#import <SparkKit/SparkKit.h>
#import <SparkKit/SparkTrigger.h>

#import <HotKeyToolKit/HotKeyToolKit.h>

enum {
  kSparkDisableAllSingleKey           = 0,
  kSparkEnableSingleFunctionKey       = 1, /* Default */
  kSparkEnableAllSingleButNavigation  = 2,
  kSparkEnableAllSingleKey            = 3,
};
typedef NSInteger SparkFilterMode;

SPARK_EXPORT
SparkFilterMode SparkKeyStrokeFilterMode;

#pragma mark -
/*!
@class 		SparkHotKey
@abstract   SparkHotKey is the class that represent hotKeys used in Spark.
*/
@class HKHotKey;
SK_CLASS_EXPORT
@interface SparkHotKey : SparkTrigger <NSCoding, NSCopying> {
  @private
  HKHotKey *sp_hotkey;
}

#pragma mark -
#pragma mark Methods from Superclass
- (BOOL)serialize:(NSMutableDictionary *)plist;
- (id)initWithSerializedValues:(NSDictionary *)plist;

@end

#pragma mark -
@interface SparkHotKey (HKHotKeyForwarding)

- (BOOL)isValid;
- (NSString *)shortcut;

- (id)target;
- (void)setTarget:(id)anObject;

- (SEL)action;
- (void)setAction:(SEL)aSelector;

- (NSUInteger)modifier;
- (HKModifier)nativeModifier;
- (void)setModifier:(NSUInteger)modifier;

- (HKKeycode)keycode;
- (void)setKeycode:(HKKeycode)keycode;

- (UniChar)character;
- (void)setCharacter:(UniChar)character;

- (BOOL)isRegistred;
- (BOOL)setRegistred:(BOOL)flag;

- (NSTimeInterval)repeatInterval;
- (void)setRepeatInterval:(NSTimeInterval)interval;

- (UInt64)rawkey;
- (void)setRawkey:(UInt64)rawkey;

- (BOOL)sendKeystroke;
- (BOOL)sendKeystrokeToApplication:(OSType)signature bundle:(NSString *)bundleId;

@end
