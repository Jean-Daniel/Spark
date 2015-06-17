/*
 *  TextAction.h
 *  Spark Plugins
 *
 *  Created by Black Moon Team.
 *  Copyright (c) 2004 - 2007, Shadow Lab. All rights reserved.
 */

#import <SparkKit/SparkPlugInAPI.h>

SPARK_PRIVATE
NSString * const kKeyboardActionBundleIdentifier;

#define kKeyboardActionBundle		[NSBundle bundleWithIdentifier:kKeyboardActionBundleIdentifier]

SPARK_INLINE
bool TADateFormatterCustomFormat(NSInteger format) {
  return (format & 0xffff) == 0;
}

SPARK_INLINE
CFDateFormatterStyle TADateFormatterStyle(NSInteger format) {
  return format & 0xff;
}
SPARK_INLINE
NSInteger TASetDateFormatterStyle(NSInteger format, CFDateFormatterStyle style) {
  format &= ~0xff;
  return format | style;
}

SPARK_INLINE
CFDateFormatterStyle TATimeFormatterStyle(NSInteger format) {
  return (format >> 8) & 0xff;
}
SPARK_INLINE
NSInteger TASetTimeFormatterStyle(NSInteger format, CFDateFormatterStyle style) {
  format &= ~0xff00;
  return format | (style << 8);
}

typedef NS_ENUM(OSType, KeyboardActionType) {
  kTATextAction       = 'Text',
  kTADateStyleAction  = 'DSty',
  kTADateFormatAction = 'DFmt',
  kTAKeystrokeAction  = 'Keys',
};

@interface TextAction : SparkAction

@property(nonatomic, copy) id data;

@property(nonatomic) useconds_t latency;

@property(nonatomic) BOOL autorepeat;

@property(nonatomic) KeyboardActionType action;

@property(nonatomic, retain) id serializedData;

@end

