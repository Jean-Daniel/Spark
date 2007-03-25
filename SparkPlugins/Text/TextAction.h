/*
 *  TextAction.h
 *  Spark Plugins
 *
 *  Created by Black Moon Team.
 *  Copyright (c) 2004 - 2007, Shadow Lab. All rights reserved.
 */

#import <SparkKit/SparkPluginAPI.h>

enum {
  /* Date Formats */
  kTAFormatShortDate  = 1 << 0,
  kTAFormatMediumDate = 1 << 1,
  kTAFormatLongDate   = 1 << 2,
  kTAFormatFullDate   = 1 << 3,
  /* Time Formats */
  kTAFormatShortTime  = 1 << 8,
  kTAFormatMediumTime = 1 << 9,
  kTAFormatLongTime   = 1 << 10,
  kTAFormatFullTime   = 1 << 11,
  /* Custom */
  kTAFormatCustom     = 0xffffffffU,
};

enum TextActionType {
  kTATextAction      = 'Text',
  kTADateAction      = 'Date',
  kTAKeystrokeAction = 'Keys',
};
typedef OSType TextActionType;

@interface TextAction : SparkAction {
  NSString *ta_str;
  TextActionType ta_type;
}

- (NSString *)string;
- (void)setString:(NSString *)aString;

- (TextActionType)action;
- (void)setAction:(TextActionType)action;

@end
