/*
 *  SparkActionPlugIn.h
 *  Spark Plugins
 *
 *  Created by Black Moon Team.
 *  Copyright (c) 2004 - 2007, Shadow Lab. All rights reserved.
 */

#import "TextAction.h"

//enum {
//  /* Date Formats */
//  kTAFormatTagNone       = kCFDateFormatterNoStyle, /* 0 */
//  kTAFormatTagShort      = kCFDateFormatterShortStyle, /* 1 */
//  kTAFormatTagMedium     = kCFDateFormatterMediumStyle, /* 2 */
//  kTAFormatTagLong       = kCFDateFormatterLongStyle, /* 3 */
//  kTAFormatTagFull       = kCFDateFormatterFullStyle, /* 4 */
//};

@class HKTrapWindow;
@interface TextActionPlugIn : SparkActionPlugIn {
  IBOutlet NSTokenField *uiTokens;
  IBOutlet NSTokenField *uiRecTokens;
  IBOutlet HKTrapWindow *uiRecordWindow;
  @private
    NSInteger ta_idx;
  CGFloat ta_latency;
  /* Date format */
  CFDateFormatterRef ta_formatter;
  NSString *ta_format;
  NSInteger ta_styles;
  /* Text */
  NSString *ta_text;
  /* keystroke */
  CFAbsoluteTime ta_escape;
}

#pragma mark Type
- (NSInteger)type;
- (void)setType:(NSInteger)type;

- (KeyboardActionType)action;
- (void)setAction:(KeyboardActionType)action;

- (CGFloat)latency;
- (void)setLatency:(CGFloat)latency;

#pragma mark Text
- (NSString *)text;
- (void)setText:(NSString *)text;

#pragma mark Date
- (NSString *)sampleDate;

- (NSInteger)dateFormat;
- (void)setDateFormat:(NSInteger)style;

- (NSInteger)timeFormat;
- (void)setTimeFormat:(NSInteger)style;

- (NSString *)rawDateFormat;
- (void)setRawDateFormat:(NSString *)format;

#pragma mark Keystrokes
- (IBAction)record:(id)sender;
- (IBAction)stop:(id)sender;

@end
