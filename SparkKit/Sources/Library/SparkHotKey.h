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

typedef NS_ENUM(NSInteger, SparkFilterMode) {
  kSparkDisableAllSingleKey           = 0,
  kSparkEnableSingleFunctionKey       = 1, /* Default */
  kSparkEnableAllSingleButNavigation  = 2,
  kSparkEnableAllSingleKey            = 3,
};

SPARK_EXPORT 
SparkFilterMode SparkGetFilterMode(void);

SPARK_EXPORT
void SparkSetFilterMode(SparkFilterMode mode);

SPARK_EXPORT
bool SparkHotKeyFilter(HKKeycode code, HKModifier modifier);

#pragma mark -
/*!
@abstract   SparkHotKey is the class that represent hotKeys used in Spark.
*/
@class SparkHKHotKey;

SPARK_OBJC_EXPORT
@interface SparkHotKey : SparkTrigger <NSCoding, NSCopying>

#pragma mark -
#pragma mark Methods from Superclass
- (BOOL)serialize:(NSMutableDictionary *)plist;
- (instancetype)initWithSerializedValues:(NSDictionary *)plist;

@end

#pragma mark -
@interface SparkHotKey (HKHotKeyForwarding)

@property(nonatomic) NSUInteger modifier;
@property(nonatomic) HKModifier nativeModifier;

@property(nonatomic, readonly) HKKeycode keycode;
@property(nonatomic, readonly) UniChar character;

- (void)setKeycode:(HKKeycode)keycode character:(UniChar)character;

//- (BOOL)isValid;
//- (NSString *)shortcut;
//
//- (id)target;
//- (void)setTarget:(id)anObject;
//
//- (SEL)action;
//- (void)setAction:(SEL)aSelector;
//
//- (NSUInteger)modifier;
//- (HKModifier)nativeModifier;
//- (void)setModifier:(NSUInteger)modifier;
//
//- (HKKeycode)keycode;
//- (void)setKeycode:(HKKeycode)keycode;
//
//- (UniChar)character;
//- (void)setCharacter:(UniChar)character;
//
//- (void)setKeycode:(HKKeycode)keycode character:(UniChar)character;

- (BOOL)isRegistred;
- (BOOL)setRegistred:(BOOL)flag;

//- (NSTimeInterval)repeatInterval;
//- (void)setRepeatInterval:(NSTimeInterval)interval;
//
//- (UInt64)rawkey;
//- (void)setRawkey:(UInt64)rawkey;
//
//- (BOOL)sendKeystroke:(useconds_t)latency;
//- (BOOL)sendKeystrokeToApplication:(OSType)signature bundle:(NSString *)bundleId latency:(useconds_t)latency;
//
@end
