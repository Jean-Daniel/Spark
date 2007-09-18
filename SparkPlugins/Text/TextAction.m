/*
 *  TextAction.m
 *  Spark Plugins
 *
 *  Created by Black Moon Team.
 *  Copyright (c) 2004 - 2007, Shadow Lab. All rights reserved.
 */

#import "TextAction.h"

#import <ShadowKit/SKFunctions.h>
#import <HotKeyToolKit/HotKeyToolKit.h>

NSString * const kKeyboardActionBundleIdentifier = @"org.shadowlab.spark.action.keyboard";

@implementation TextAction

- (id)copyWithZone:(NSZone *)aZone {
  TextAction *copy = [super copyWithZone:aZone];
  copy->ta_type = ta_type;
  copy->ta_data = [ta_data copy];
  return copy;
}

- (BOOL)serialize:(NSMutableDictionary *)plist {
  if ([super serialize:plist]) {
    if (ta_data)
      [plist setObject:ta_data forKey:@"TAData"];
    [plist setObject:SKStringForOSType(ta_type) forKey:@"TAAction"];
    return YES;
  }
  return NO;
}

- (id)initWithSerializedValues:(NSDictionary *)plist {
  if (self = [super initWithSerializedValues:plist]) {
    [self setData:[plist objectForKey:@"TAData"]];
    [self setAction:SKOSTypeFromString([plist objectForKey:@"TAAction"])];
  }
  return self;
}

- (void)dealloc {
  [ta_data release];
  [super dealloc];
}

#pragma mark -
- (SparkAlert *)actionDidLoad {
  switch ([self action]) {
    case kTATextAction:
    case kTADateStyleAction:
    case kTADateFormatAction:
    case kTAKeystrokeAction:
      return nil;
    default:
      return [SparkAlert alertWithMessageText:NSLocalizedStringFromTableInBundle(@"INVALID_ACTION_ALERT",
                                                                                 nil,
                                                                                 kKeyboardActionBundle,
                                                                                 @"Error When trying to execute but Action unknown ** Title **")
                    informativeTextWithFormat:NSLocalizedStringFromTableInBundle(@"INVALID_ACTION_ALERT_MSG",
                                                                                 nil,
                                                                                 kKeyboardActionBundle,
                                                                                 @"Error When trying to execute but Action unknown ** Msg **"), [self name]];
  }
}

- (SparkAlert *)simulateText:(NSString *)text {
  if (text && [text length] > 0) {
    CGEventSourceRef src = HKEventCreatePrivateSource();
    NSAssert(src != nil, @"Invalid event source");
    /* Use new event API */
    ProcessSerialNumber psn;
    GetFrontProcess(&psn);
    HKEventTarget target = { psn: &psn };
    for (NSUInteger idx = 0; idx < [text length]; idx++) {
      HKEventPostCharacterKeystrokesToTarget([text characterAtIndex:idx], target, kHKEventTargetProcess, src);
    }
    CFRelease(src);
  }
  return nil;
}

- (SparkAlert *)simulateDateStyle {
  NSInteger style = SKIntegerValue([self data]);
  CFLocaleRef locale = CFLocaleCopyCurrent();
  CFDateFormatterRef formatter = CFDateFormatterCreate(kCFAllocatorDefault, locale, 
                                                       TADateFormatterStyle(style), TATimeFormatterStyle(style));
  if (locale) CFRelease(locale);
  NSAssert(formatter, @"error while creating date formatter");
  if (formatter) {
    CFStringRef str = CFDateFormatterCreateStringWithAbsoluteTime(kCFAllocatorDefault, formatter, CFAbsoluteTimeGetCurrent());
    NSAssert(str, @"error while formatting date");
    if (str) {
      [self simulateText:(id)str];
      CFRelease(str);
    }
    CFRelease(formatter);
  }
  return nil;
}

- (SparkAlert *)simulateDateFormat {
  NSString *format = [self data];
  if (format) {
    CFLocaleRef locale = CFLocaleCopyCurrent();
    CFDateFormatterRef formatter = CFDateFormatterCreate(kCFAllocatorDefault, locale, 
                                                         kCFDateFormatterNoStyle, kCFDateFormatterNoStyle);
    if (locale) CFRelease(locale);
    NSAssert(formatter, @"error while creating date formatter");
    if (formatter) {
      CFDateFormatterSetFormat(formatter, (CFStringRef)format);
      CFStringRef str = CFDateFormatterCreateStringWithAbsoluteTime(kCFAllocatorDefault, formatter, CFAbsoluteTimeGetCurrent());
      NSAssert(str, @"error while formatting date");
      if (str) {
        [self simulateText:(id)str];
        CFRelease(str);
      }
      CFRelease(formatter);
    }
  }
  return nil;
}

- (SparkAlert *)performAction {
  SparkAlert *error = nil;
  switch (ta_type) {
    case kTATextAction:
      error = [self simulateText:[self data]];
      break;
    case kTADateStyleAction:
      error = [self simulateDateStyle];
      break;
    case kTADateFormatAction:
      [self simulateDateFormat];
      break;
    case kTAKeystrokeAction:
      break;
    default:
      /* invalid type */
      NSBeep();
      break;
  }

  return error;
}

- (BOOL)shouldSaveIcon {
  return NO;
}

#pragma mark -
- (id)data {
  return ta_data;
}
- (void)setData:(id)anObject {
  SKSetterCopy(ta_data, anObject);
}

- (KeyboardActionType)action {
  return ta_type;
}
- (void)setAction:(KeyboardActionType)action {
  ta_type = action;
}

@end
