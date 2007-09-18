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

@interface TextActionPlugIn : SparkActionPlugIn {
  IBOutlet NSTextView *ibText;
  IBOutlet NSTabView *ibTypeView;
  @private
    NSInteger ta_idx;
  /* Date format */
  CFDateFormatterRef ta_formatter;
  NSString *ta_format;
  NSInteger ta_styles;
  /* Text */
  NSString *ta_text;
}

#pragma mark Type
- (NSInteger)type;
- (void)setType:(NSInteger)type;

- (KeyboardActionType)action;
- (void)setAction:(KeyboardActionType)action;

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

@end
