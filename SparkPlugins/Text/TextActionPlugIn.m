/*
 *  TextActionPlugIn.m
 *  Spark Plugins
 *
 *  Created by Black Moon Team.
 *  Copyright (c) 2004 - 2007, Shadow Lab. All rights reserved.
 */

#import "TextActionPlugIn.h"

@implementation TextActionPlugIn

- (id)init {
  if (self = [super init]) {
    ta_styles = TASetDateFormatterStyle(ta_styles, kCFDateFormatterLongStyle);
  }
  return self;
}

- (void)dealloc {
  [ta_text release];
  [ta_format release];
  if (ta_formatter) CFRelease(ta_formatter);
  [super dealloc];
}

- (void)loadSparkAction:(TextAction *)anAction toEdit:(BOOL)isEditing {
  [self setAction:[anAction action]];
  switch ([anAction action]) {
    case kTATextAction:
      [self setText:[anAction data]];
      break;
    case kTADateStyleAction: {
      NSInteger styles = SKIntegerValue([anAction data]);
      [self setDateFormat:TADateFormatterStyle(styles)];
      [self setTimeFormat:TATimeFormatterStyle(styles)];
    }
      break;
    case kTADateFormatAction:
      [self setRawDateFormat:[anAction data]];
      break;
  }
}

- (NSAlert *)sparkEditorShouldConfigureAction {
  //TextAction *action = [self sparkAction];
  switch ([self action]) {
    
  }
  return nil;
}

- (void)configureAction {
  TextAction *action = [self sparkAction];
  [action setAction:[self action]];
  switch ([action action]) {
    case kTATextAction:
      [action setData:ta_text];
      break;
    case kTADateFormatAction:
      [action setData:ta_format];
      break;
    case kTADateStyleAction:
      [action setData:SKInteger(ta_styles)];
      break;
  }
}

#pragma mark -
- (NSInteger)type {
  return ta_idx;
}
- (void)setType:(NSInteger)type {
  ta_idx = type;
}

- (KeyboardActionType)action {
  switch (ta_idx) {
    case 0:
      return kTATextAction;
    case 1:
      return TADateFormatterCustomFormat(ta_styles) ? kTADateFormatAction : kTADateStyleAction;
    case 2:
      return kTAKeystrokeAction;
  }
  return 0;
}

- (void)setAction:(KeyboardActionType)action {
  switch (action) {
    case kTATextAction:
      [self setType:0];
      break;
    case kTADateStyleAction:
    case kTADateFormatAction:
      [self setType:1];
      break;
    case kTAKeystrokeAction:
      [self setType:2];
      break;      
  }
}

#pragma mark Text
- (NSString *)text {
  return ta_text;
}
- (void)setText:(NSString *)text {
  SKSetterCopy(ta_text, text);
}

#pragma mark Date
- (void)resetFormatter {
  [self willChangeValueForKey:@"sampleDate"];
  [self willChangeValueForKey:@"rawDateFormat"];
  if (ta_formatter)
    CFRelease(ta_formatter);
  
  /* Create date formatter */
  CFLocaleRef locale = CFLocaleCopyCurrent();
  ta_formatter = CFDateFormatterCreate(kCFAllocatorDefault, locale, 
                                       TADateFormatterStyle(ta_styles), TATimeFormatterStyle(ta_styles));
  if (locale) CFRelease(locale);
  
  [ta_format release];
  ta_format = [(id)CFDateFormatterGetFormat(ta_formatter) retain];
  [self didChangeValueForKey:@"rawDateFormat"];
  [self didChangeValueForKey:@"sampleDate"];
}

/* date format */
- (NSString *)sampleDate {
  if (!ta_formatter)
    [self resetFormatter];
  NSString *str = (id)CFDateFormatterCreateStringWithAbsoluteTime(kCFAllocatorDefault, ta_formatter, CFAbsoluteTimeGetCurrent());
  return [str autorelease];
}

- (NSInteger)dateFormat {
  return TADateFormatterStyle(ta_styles);
}
- (void)setDateFormat:(NSInteger)style {
  ta_styles = TASetDateFormatterStyle(ta_styles, style);
  [self resetFormatter];
}

- (NSInteger)timeFormat {
  return TATimeFormatterStyle(ta_styles);
}
- (void)setTimeFormat:(NSInteger)style {
  ta_styles = TASetTimeFormatterStyle(ta_styles, style);
  [self resetFormatter];
}

- (NSString *)rawDateFormat {
  return ta_format;
}
- (void)setRawDateFormat:(NSString *)format {
  if (format != ta_format && ![format isEqualToString:ta_format]) {
    [self willChangeValueForKey:@"sampleDate"];
    [self willChangeValueForKey:@"dateFormat"];
    [self willChangeValueForKey:@"timeFormat"];
    [ta_format release];
    ta_format = [format copy];
    ta_styles = TASetDateFormatterStyle(ta_styles, kCFDateFormatterNoStyle);
    ta_styles = TASetTimeFormatterStyle(ta_styles, kCFDateFormatterNoStyle);
    CFDateFormatterSetFormat(ta_formatter, (CFStringRef)format ? : CFSTR(""));
    [self didChangeValueForKey:@"timeFormat"];
    [self didChangeValueForKey:@"dateFormat"];
    [self didChangeValueForKey:@"sampleDate"];
  }
}

@end
