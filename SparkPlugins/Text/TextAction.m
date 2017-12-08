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

#import <WonderBox/WonderBox.h>

#import <HotKeyToolKit/HotKeyToolKit.h>

NSString * const kKeyboardActionBundleIdentifier = @"org.shadowlab.spark.action.keyboard";

/* 500 ms */
#define kTextActionMaxLatency 500000U

@implementation TextAction {
@private
  BOOL _locked;
  useconds_t _latency;
}

- (id)copyWithZone:(NSZone *)aZone {
  TextAction *copy = [super copyWithZone:aZone];
  copy->_action = _action;
	copy->_autorepeat = _autorepeat;
	copy->_latency = _latency;
  copy->_data = [_data copy];
  return copy;
}

- (BOOL)serialize:(NSMutableDictionary *)plist {
  if ([super serialize:plist]) {
    id data = [self serializedData];
    if (data)
      [plist setObject:data forKey:@"TAData"];
		if (_autorepeat)
			[plist setObject:@(_autorepeat) forKey:@"TARepeat"];
    if (_latency > 0)
      [plist setObject:@(_latency) forKey:@"TALatency"];
    [plist setObject:WBStringForOSType(_action) forKey:@"TAAction"];
    return YES;
  }
  return NO;
}

- (id)initWithSerializedValues:(NSDictionary *)plist {
  if (self = [super initWithSerializedValues:plist]) {
		[self setAutorepeat:[[plist objectForKey:@"TARepeat"] boolValue]];
    [self setAction:WBOSTypeFromString([plist objectForKey:@"TAAction"])];
    [self setLatency:(useconds_t)[[plist objectForKey:@"TALatency"] integerValue]];
    [self setSerializedData:[plist objectForKey:@"TAData"]];
  }
  return self;
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
    HKEventTarget target = { .pid = [NSWorkspace.sharedWorkspace frontmostApplication].processIdentifier };
    for (NSUInteger idx = 0; idx < [text length]; idx++) {
      HKEventPostCharacterKeystrokesToTarget([text characterAtIndex:idx], target, kHKEventTargetProcess, src, [self latency]);
    }
    if (src) CFRelease(src);
  }
  return nil;
}

- (SparkAlert *)simulateDateStyle {
  NSInteger style = [[self data] integerValue];

  CFLocaleRef locale = CFLocaleCopyCurrent();
  CFDateFormatterRef formatter = CFDateFormatterCreate(kCFAllocatorDefault, locale,
                                                       TADateFormatterStyle(style), TATimeFormatterStyle(style));
  SPXCFRelease(locale);

  NSAssert(formatter, @"error while creating date formatter");
  if (formatter) {
    CFStringRef str = CFDateFormatterCreateStringWithAbsoluteTime(kCFAllocatorDefault, formatter, CFAbsoluteTimeGetCurrent());
    NSAssert(str, @"error while formatting date");
    if (str)
      [self simulateText:SPXCFStringBridgingRelease(str)];
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
    SPXCFRelease(locale);

    NSAssert(formatter, @"error while creating date formatter");
    if (formatter) {
      CFDateFormatterSetFormat(formatter, (CFStringRef)format);
      CFStringRef str = CFDateFormatterCreateStringWithAbsoluteTime(kCFAllocatorDefault, formatter, CFAbsoluteTimeGetCurrent());
      NSAssert(str, @"error while formatting date");
      if (str)
        [self simulateText:SPXCFStringBridgingRelease(str)];
      CFRelease(formatter);
    }
  }
  return nil;
}

- (SparkAlert *)simulateKeystroke {
  useconds_t latency = [self latency];
  CGEventSourceRef src = HKEventCreatePrivateSource();
  for (NSUInteger idx = 0; idx < [_data count]; idx++) {
		[[_data objectAtIndex:idx] sendKeystroke:src latency:latency];
  }
  SPXCFRelease(src);
  return nil;
}

- (SparkAlert *)performAction {
  SparkAlert *error = nil;
  if (!_locked) {
    _locked = YES; // prevent recursive calls
    switch (_action) {
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
    _locked = NO;
  }
  return error;
}

- (BOOL)shouldSaveIcon {
  return NO;
}

- (NSTimeInterval)repeatInterval {
	if (_autorepeat)
		return SparkGetDefaultKeyRepeatInterval();
	return 0;
}

- (BOOL)needsToBeRunOnMainThread {
  return NO;
}
- (BOOL)supportsConcurrentRequests {
  return NO;
}

#pragma mark -
- (id)serializedData {
  switch ([self action]) {
    case kTAKeystrokeAction: {
      NSArray *keys = [self data];
      NSMutableArray *strokes = [NSMutableArray array];
      for (NSUInteger idx = 0; idx < [keys count]; idx++) {
        UInt64 raw = [[keys objectAtIndex:idx] rawKey];
        [strokes addObject:@(raw)];
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
      }
      [self setData:keys];
    }
      break;
    default:
      return [self setData:data];
  }
}

- (void)setAction:(KeyboardActionType)action {
  if (action != _action) {
    [self setData:nil];
    _action = action;
  }
}

- (useconds_t)latency {
  return _latency > 0 ? _latency : kHKEventDefaultLatency;
}
- (void)setLatency:(useconds_t)latency {
  _latency = MIN(latency, kTextActionMaxLatency);
}

@end
