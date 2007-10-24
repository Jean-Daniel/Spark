/*
 *  TextAction.h
 *  Spark Plugins
 *
 *  Created by Black Moon Team.
 *  Copyright (c) 2004 - 2007, Shadow Lab. All rights reserved.
 */

#import <SparkKit/SparkPluginAPI.h>

SK_PRIVATE
NSString * const kKeyboardActionBundleIdentifier;

#define kKeyboardActionBundle		[NSBundle bundleWithIdentifier:kKeyboardActionBundleIdentifier]

SK_INLINE
bool TADateFormatterCustomFormat(NSInteger format) {
  return (format & 0xffff) == 0;
}

SK_INLINE
CFDateFormatterStyle TADateFormatterStyle(NSInteger format) {
  return format & 0xff;
}
SK_INLINE 
NSInteger TASetDateFormatterStyle(NSInteger format, CFDateFormatterStyle style) {
  format &= ~0xff;
  return format | style;
}

SK_INLINE
CFDateFormatterStyle TATimeFormatterStyle(NSInteger format) {
  return (format >> 8) & 0xff;
}
SK_INLINE 
NSInteger TASetTimeFormatterStyle(NSInteger format, CFDateFormatterStyle style) {
  format &= ~0xff00;
  return format | (style << 8);
}

enum KeyboardActionType {
  kTATextAction      = 'Text',
  kTADateStyleAction = 'DSty',
  kTADateFormatAction = 'DFmt',
  kTAKeystrokeAction = 'Keys',
};
typedef OSType KeyboardActionType;

@interface TextAction : SparkAction {
  id ta_data;
  useconds_t ta_latency;
  KeyboardActionType ta_type;
}

- (id)data;
- (void)setData:(id)anObject;

- (KeyboardActionType)action;
- (void)setAction:(KeyboardActionType)action;

- (id)serializedData;
- (void)setSerializedData:(id)data;

@end

