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
  NSString *str = [ibText string];
  [[self sparkAction] setString:str];
}

/* date format */
- (NSString *)sampleDate {
  if (!ta_formatter) {
    /* Create date formatter */
    CFLocaleRef locale = CFLocaleCopyCurrent();
    ta_formatter = CFDateFormatterCreate(kCFAllocatorDefault, locale, 
                                         TADateFormatterStyle(ta_styles), TATimeFormatterStyle(ta_styles));
    if (locale) CFRelease(locale);
    
    if (ta_format)
      CFDateFormatterSetFormat(ta_formatter, (CFStringRef)ta_format);
  }
  
  NSString *str = (id)CFDateFormatterCreateStringWithAbsoluteTime(kCFAllocatorDefault, ta_formatter, CFAbsoluteTimeGetCurrent());
  return [str autorelease];
}

- (NSInteger)dateFormat {
  return TADateFormatterStyle(ta_styles);
}
- (void)setDateFormat:(NSInteger)style {
  [self willChangeValueForKey:@"sampleDate"];
  ta_styles = TASetDateFormatterStyle(ta_styles, style);
  if (ta_formatter) {
    CFRelease(ta_formatter);
    ta_formatter = NULL;
  }
  [self didChangeValueForKey:@"sampleDate"];
}

- (NSInteger)timeFormat {
  return TATimeFormatterStyle(ta_styles);
}
- (void)setTimeFormat:(NSInteger)style {
  [self willChangeValueForKey:@"sampleDate"];
  ta_styles = TASetTimeFormatterStyle(ta_styles, style);
  if (ta_formatter) {
    CFRelease(ta_formatter);
    ta_formatter = NULL;
  }
  [self didChangeValueForKey:@"sampleDate"];
}

- (NSString *)rawDateFormat {
  return ta_format;
}
- (void)setRawDateFormat:(NSString *)format {
  [self willChangeValueForKey:@"sampleDate"];
  SKSetterCopy(ta_format, format);
  if (ta_formatter) {
    if (format && [format length]) {
      CFDateFormatterSetFormat(ta_formatter,(CFStringRef)format);
    } else {
      CFRelease(ta_formatter);
      ta_formatter = NULL;
    }
  }
  [self didChangeValueForKey:@"sampleDate"];
}

@end
