/*
 *  SparkActionPlugIn.h
 *  Spark Plugins
 *
 *  Created by Black Moon Team.
 *  Copyright (c) 2004 - 2007, Shadow Lab. All rights reserved.
 */

#import "TextAction.h"

enum {
  /* Date Formats */
  kTAFormatTagNone       = kCFDateFormatterNoStyle, /* 0 */
  kTAFormatTagShort      = kCFDateFormatterShortStyle, /* 1 */
  kTAFormatTagMedium     = kCFDateFormatterMediumStyle, /* 2 */
  kTAFormatTagLong       = kCFDateFormatterLongStyle, /* 3 */
  kTAFormatTagFull       = kCFDateFormatterFullStyle, /* 4 */
};

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

@interface TextActionPlugIn : SparkActionPlugIn {
  IBOutlet NSTextView *ibText;
  @private
    /* Date format */
    CFDateFormatterRef ta_formatter;
  NSString *ta_format;
  NSInteger ta_styles;
  /* */
}

- (NSString *)sampleDate;

- (NSString *)rawDateFormat;
- (void)setRawDateFormat:(NSString *)format;

@end
