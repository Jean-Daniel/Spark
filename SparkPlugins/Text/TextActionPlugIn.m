/*
 *  TextActionPlugIn.m
 *  Spark Plugins
 *
 *  Created by Black Moon Team.
 *  Copyright (c) 2004 - 2007, Shadow Lab. All rights reserved.
 */

#import "TextActionPlugIn.h"
#import "TAKeystroke.h"

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

#pragma mark -
- (void)awakeFromNib {
  [uiTokens setTokenizingCharacterSet:[NSCharacterSet whitespaceCharacterSet]];
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
    case kTAKeystrokeAction:
      [uiTokens setObjectValue:[anAction data]];
      break;
  }
  [self setLatency:[anAction latency] / 1e3];
}

- (NSAlert *)sparkEditorShouldConfigureAction {
  switch ([self action]) {
    case kTATextAction:
      if (![[self text] length])
        return [NSAlert alertWithMessageText:@"Empty text" defaultButton:@"OK" alternateButton:nil otherButton:nil informativeTextWithFormat:@"You must enter some text"];
      break;
    case kTADateFormatAction:
      if (![[self rawDateFormat] length]) 
        return [NSAlert alertWithMessageText:@"Empty date" defaultButton:@"OK" alternateButton:nil otherButton:nil informativeTextWithFormat:@"Select a date/time style or type a format string"];
      break;
    case kTAKeystrokeAction:
      if (![[uiTokens objectValue] count])
        return [NSAlert alertWithMessageText:@"No key" defaultButton:@"OK" alternateButton:nil otherButton:nil informativeTextWithFormat:@"You should type at least on key"];
      break;
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
    case kTAKeystrokeAction:
      [action setData:[uiTokens objectValue]];
      break;
  }
  if (ta_latency >= 0)
    [action setLatency:ta_latency * 1e3];
}

#pragma mark -
- (NSInteger)type {
  return ta_idx;
}
- (void)setType:(NSInteger)type {
  ta_idx = type;
  [self stop:nil];
}

- (CGFloat)latency {
  return ta_latency;
}
- (void)setLatency:(CGFloat)latency {
  ta_latency = ABS(latency);
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

#pragma mark Keystroke
- (IBAction)record:(id)sender {
  /* copy current tokens */
  [uiRecTokens setObjectValue:[uiTokens objectValue]];
  
  [uiRecordWindow setTrapping:YES];
  [NSApp runModalForWindow:uiRecordWindow];
}
- (IBAction)stop:(id)sender {
  [NSApp stopModal];
  [uiRecordWindow setTrapping:NO];
  [uiTokens setObjectValue:[uiRecTokens objectValue]];
//  NSArray *tokens = [uiRecTokens objectValue];
//  if ([tokens count] > 0) {
//    NSMutableArray *mtoks = [[uiTokens objectValue] mutableCopy];
//    [mtoks addObjectsFromArray:tokens];
//    [uiTokens setObjectValue:mtoks];
//    [mtoks release];
//  }
  [uiRecordWindow performClose:nil];
}

- (NSString *)tokenField:(NSTokenField *)tokenField displayStringForRepresentedObject:(id)representedObject {
  return [representedObject shortcut];
}

- (NSString *)tokenField:(NSTokenField *)tokenField editingStringForRepresentedObject:(id)representedObject {
  return [representedObject shortcut];
}

- (id)tokenField:(NSTokenField *)tokenField representedObjectForEditingString:(NSString *)editingString {
  return [NSNull null];
}

- (NSArray *)tokenField:(NSTokenField *)tokenField shouldAddObjects:(NSArray *)tokens atIndex:(NSUInteger)anIndex {
  if ([tokens containsObject:[NSNull null]]) {
    NSMutableArray *tks = [NSMutableArray array];
    for (NSUInteger idx = 0; idx < [tokens count]; idx++) {
      id obj = [tokens objectAtIndex:idx];
      if (obj != [NSNull null])
        [tks addObject:obj];
    }
    return tks;
  }
  return tokens;
}

- (BOOL)trapWindow:(HKTrapWindow *)window needPerformKeyEquivalent:(NSEvent *)theEvent {
  /* No modifier and cancel pressed */
  NSUInteger flags = NSShiftKeyMask | NSControlKeyMask | NSAlternateKeyMask | NSCommandKeyMask;
  if (!([theEvent modifierFlags] & flags) && [[theEvent characters] isEqualToString:@"\e"]) {
    CFAbsoluteTime now = CFAbsoluteTimeGetCurrent();
    /* check double escape */
    if (now < ta_escape + 0.5) {
      return YES;
    } else {
      ta_escape = now;
    }
  }
  return NO;
}

- (BOOL)trapWindow:(HKTrapWindow *)window needProceedKeyEvent:(NSEvent *)theEvent {
  UInt16 code = [theEvent keyCode];
  NSUInteger mask = [theEvent modifierFlags] & (NSShiftKeyMask | NSControlKeyMask | NSAlternateKeyMask | NSCommandKeyMask);
  
  return mask ? NO : code == kHKVirtualEscapeKey;
}

- (BOOL)trapWindow:(HKTrapWindow *)window isValidHotKey:(HKKeycode)keycode modifier:(HKModifier)modifier {
  return YES;
}

- (void)trapWindowCatchHotKey:(NSNotification *)aNotification {
  NSDictionary *info = [aNotification userInfo];
  UInt16 nkey = SKIntegerValue([info objectForKey:kHKEventKeyCodeKey]);
  UniChar chr = SKIntegerValue([info objectForKey:kHKEventCharacterKey]);
  HKModifier nmodifier = (HKModifier)SKIntegerValue([info objectForKey:kHKEventModifierKey]);

  TAKeystroke *hkey = [[TAKeystroke alloc] initWithKeycode:nkey character:chr modifier:nmodifier];
  NSMutableArray *objs = [[uiRecTokens objectValue] mutableCopy];
  [objs addObject:hkey];
  [uiRecTokens setObjectValue:objs];
  [objs release];
  [hkey release];
}

@end
