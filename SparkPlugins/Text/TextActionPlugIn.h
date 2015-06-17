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
@private
  IBOutlet NSTokenField *uiTokens;
  IBOutlet NSTokenField *uiRecTokens;
  IBOutlet HKTrapWindow *uiRecordWindow;
}

#pragma mark Type
@property(nonatomic) NSInteger type;

@property(nonatomic) KeyboardActionType action;

@property(nonatomic) CGFloat latency;

#pragma mark Text
@property(nonatomic, copy) NSString *text;

#pragma mark Date
@property(nonatomic, readonly) NSString *sampleDate;

@property(nonatomic)  NSInteger dateFormat;

@property(nonatomic) NSInteger timeFormat;

@property(nonatomic, copy) NSString *rawDateFormat;

#pragma mark Keystrokes
- (IBAction)record:(id)sender;
- (IBAction)stop:(id)sender;

@property(nonatomic) BOOL autorepeat;

@property(nonatomic, readonly) BOOL canAutorepeat;

@end
