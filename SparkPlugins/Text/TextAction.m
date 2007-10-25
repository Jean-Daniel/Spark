/*
 *  TextAction.m
 *  Spark Plugins
 *
 *  Created by Black Moon Team.
 *  Copyright (c) 2004 - 2007, Shadow Lab. All rights reserved.
 */

#import "TextAction.h"
#import "TAKeystroke.h"

#include <unistd.h>
#import <ShadowKit/SKFunctions.h>
#import <HotKeyToolKit/HotKeyToolKit.h>

NSString * const kKeyboardActionBundleIdentifier = @"org.shadowlab.spark.action.keyboard";

/* 500 ms */
#define kTextActionMaxLatency 500000U

@implementation TextAction

- (id)copyWithZone:(NSZone *)aZone {
  TextAction *copy = [super copyWithZone:aZone];
  copy->ta_type = ta_type;
  copy->ta_data = [ta_data copy];
  return copy;
}

- (BOOL)serialize:(NSMutableDictionary *)plist {
  if ([super serialize:plist]) {
    id data = [self serializedData];
    if (data)
      [plist setObject:data forKey:@"TAData"];
    if (ta_latency > 0)
      [plist setObject:SKUInteger(ta_latency) forKey:@"TALatency"];  
    [plist setObject:SKStringForOSType(ta_type) forKey:@"TAAction"];
    return YES;
  }
  return NO;
}

- (id)initWithSerializedValues:(NSDictionary *)plist {
  if (self = [super initWithSerializedValues:plist]) {
    [self setAction:SKOSTypeFromString([plist objectForKey:@"TAAction"])];
    [self setLatency:SKUIntegerValue([plist objectForKey:@"TALatency"])];
    [self setSerializedData:[plist objectForKey:@"TAData"]];
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
      HKEventPostCharacterKeystrokesToTarget([text characterAtIndex:idx], target, kHKEventTargetProcess, src, [self latency]);
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

- (SparkAlert *)simulateKeystroke {
  useconds_t latency = [self latency];
  CGEventSourceRef src = HKEventCreatePrivateSource();
  for (NSUInteger idx = 0; idx < [ta_data count]; idx++) {
    if (idx > 0)
      [[ta_data objectAtIndex:idx] sendKeystroke:src latency:latency];
  }
  if (src) CFRelease(src);
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
      error = [self simulateDateFormat];
      break;
    case kTAKeystrokeAction:
      error = [self simulateKeystroke];
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

- (id)serializedData {
  switch ([self action]) {
    case kTAKeystrokeAction: {
      NSArray *keys = [self data];
      NSMutableArray *strokes = [NSMutableArray array];
      for (NSUInteger idx = 0; idx < [keys count]; idx++) {
        UInt64 raw = [[keys objectAtIndex:idx] rawKey];
        [strokes addObject:SKULongLong(raw)];
      }
      return strokes;
    }
    default:
      return [self data];
  }
}
- (void)setSerializedData:(id)data {
  switch ([self action]) {
    case kTAKeystrokeAction: {
      NSMutableArray *keys = [NSMutableArray array];
      for (NSUInteger idx = 0; idx < [data count]; idx++) {
        UInt64 raw = [[data objectAtIndex:idx] unsignedLongLongValue];
        TAKeystroke *stroke = [[TAKeystroke alloc] initFromRawKey:raw];
        [keys addObject:stroke];
        [stroke release];
      }
      [self setData:keys];
    }
      break;
    default:
      return [self setData:data];
  }
}

- (KeyboardActionType)action {
  return ta_type;
}
- (void)setAction:(KeyboardActionType)action {
  if (action != ta_type) {
    [self setData:nil];
    ta_type = action;
  }
}

- (useconds_t)latency {
  return ta_latency > 0 ? ta_latency : kHKEventDefaultLatency;
}
- (void)setLatency:(useconds_t)latency {
  ta_latency = MIN(latency, kTextActionMaxLatency);
}

@end
