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
  if (ta_formatter) CFRelease(ta_formatter);
  [super dealloc];
}

- (void)loadSparkAction:(TextAction *)anAction toEdit:(BOOL)isEditing {
  [ibText setString:[anAction string] ? :  @""];
}

- (NSAlert *)sparkEditorShouldConfigureAction {
  return nil;
}

- (void)configureAction {
  /* if text */
  NSString *str = [ibText string];
  [[self sparkAction] setString:str];
}

#pragma mark -
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
    CFDateFormatterSetFormat(ta_formatter, (CFStringRef)format ? : CFSTR(""));
    [self didChangeValueForKey:@"timeFormat"];
    [self didChangeValueForKey:@"dateFormat"];
    [self didChangeValueForKey:@"sampleDate"];
  }
}

@end
