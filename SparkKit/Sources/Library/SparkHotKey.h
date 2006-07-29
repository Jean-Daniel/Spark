/*
 *  SparkHotKey.h
 *  SparkKit
 *
 *  Created by Black Moon Team.
 *  Copyright © 2004 - 2006 Shadow Lab. All rights reserved.
 *
 */
/*!
@header SparkHotKey
 @abstract Define a SparkHotKey.
 */

#import <SparkKit/SparkKit.h>
#import <SparkKit/SparkTrigger.h>

typedef enum {
  kSparkDisableAllSingleKey,
  kSparkEnableSingleFunctionKey,
  kSparkEnableAllSingleButNavigation,
  kSparkEnableAllSingleKey,
} SparkFilterMode;

SPARK_EXPORT
SparkFilterMode SparkKeyStrokeFilterMode;

#pragma mark -
/*!
@class 		SparkHotKey
@abstract   SparkHotKey is the class that represent hotKeys used in Spark.
*/
@class HKHotKey;
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

- (id)target;
- (void)setTarget:(id)anObject;

- (SEL)action;
- (void)setAction:(SEL)aSelector;

- (UInt32)modifier;
- (void)setModifier:(UInt32)modifier;

- (UInt32)keycode; 
- (void)setKeycode:(UInt32)keycode;

- (UniChar)character;
- (void)setCharacter:(UniChar)character;

- (BOOL)isRegistred;
- (BOOL)setRegistred:(BOOL)flag;

- (NSTimeInterval)keyRepeat;
- (void)setKeyRepeat:(NSTimeInterval)interval;

- (NSString *)shortCut;

- (BOOL)sendKeystroke;
- (BOOL)sendKeystrokeToApplication:(OSType)signature bundle:(NSString *)bundleId;

- (UInt64)rawkey;
- (void)setRawkey:(UInt64)rawkey;

@end

