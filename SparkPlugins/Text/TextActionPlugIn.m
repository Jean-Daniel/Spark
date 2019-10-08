/*
 *  TextActionPlugIn.m
 *  Spark Plugins
 *
 *  Created by Black Moon Team.
 *  Copyright (c) 2004 - 2007, Shadow Lab. All rights reserved.
 */

#import "TextActionPlugIn.h"
#import "TAKeystroke.h"

@implementation TextActionPlugIn {
@private
  /* keystroke */
  CFAbsoluteTime _escape;
  /* Date format */
  NSInteger _styles;
  CFDateFormatterRef _formatter;
}

- (id)init {
  if (self = [super init]) {
    _styles = TASetDateFormatterStyle(_styles, kCFDateFormatterLongStyle);
  }
  return self;
}

- (void)dealloc {
  if (_formatter)
    CFRelease(_formatter);
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
      NSInteger styles = [[anAction data] integerValue];
      [self setDateFormat:TADateFormatterStyle(styles)];
      [self setTimeFormat:TATimeFormatterStyle(styles)];
    }
      break;
    case kTADateFormatAction:
      [self setRawDateFormat:[anAction data]];
      break;
    case kTAKeystrokeAction:
      [uiTokens setObjectValue:[anAction data]];
			[self setAutorepeat:[anAction autorepeat]];
      break;
  }
  [self setLatency:[anAction latency] / 1e3];
}

static inline
NSAlert *SimpleAlert(NSString *title, NSString *message) {
  NSAlert *alert = [[NSAlert alloc] init];
  alert.messageText = title;
  alert.informativeText = message;
  return alert;
}

- (NSAlert *)sparkEditorShouldConfigureAction {
  switch ([self action]) {
    case kTATextAction:
      if (![[self text] length])
        return SimpleAlert(@"Empty text", @"You must enter some text");
      break;
    case kTADateFormatAction:
      if (![[self rawDateFormat] length]) 
        return SimpleAlert(@"Empty date", @"Select a date/time style or type a format string");
      break;
    case kTAKeystrokeAction:
      if (![[uiTokens objectValue] count])
        return SimpleAlert(@"No key", @"You should type at least on key");
      break;
    case kTADateStyleAction:
      break;
  }
  return nil;
}

- (void)configureAction {
  TextAction *action = [self sparkAction];
  [action setAction:[self action]];
  switch ([action action]) {
    case kTATextAction:
      [action setData:_text];
      break;
    case kTADateFormatAction:
      [action setData:_rawDateFormat];
      break;
    case kTADateStyleAction:
      [action setData:@(_styles)];
      break;
    case kTAKeystrokeAction:
      [action setData:[uiTokens objectValue]];
			[action setAutorepeat:[self canAutorepeat] && [self autorepeat]];
      break;
  }
  if (_latency >= 0)
    [action setLatency:(useconds_t)(_latency * 1e3)];
}

#pragma mark -
- (void)setType:(NSInteger)type {
  _type = type;
  [self stop:nil];
}

- (void)setLatency:(CGFloat)latency {
  _latency = ABS(latency);
}

- (KeyboardActionType)action {
  switch (_type) {
    case 0:
      return kTATextAction;
    case 1:
      return TADateFormatterCustomFormat(_styles) ? kTADateFormatAction : kTADateStyleAction;
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

#pragma mark Date
- (void)resetFormatter {
  [self willChangeValueForKey:@"sampleDate"];
  [self willChangeValueForKey:@"rawDateFormat"];
  if (_formatter)
    CFRelease(_formatter);
  
  /* Create date formatter */
  CFLocaleRef locale = CFLocaleCopyCurrent();
  _formatter = CFDateFormatterCreate(kCFAllocatorDefault, locale,
                                       TADateFormatterStyle(_styles), TATimeFormatterStyle(_styles));
  if (locale) CFRelease(locale);
  
  _rawDateFormat = SPXCFToNSString(CFDateFormatterGetFormat(_formatter));
  [self didChangeValueForKey:@"rawDateFormat"];
  [self didChangeValueForKey:@"sampleDate"];
}

/* date format */
- (NSString *)sampleDate {
  if (!_formatter)
    [self resetFormatter];
  return SPXCFStringBridgingRelease(CFDateFormatterCreateStringWithAbsoluteTime(kCFAllocatorDefault, _formatter, CFAbsoluteTimeGetCurrent()));
}

- (NSInteger)dateFormat {
  return TADateFormatterStyle(_styles);
}
- (void)setDateFormat:(NSInteger)style {
  _styles = TASetDateFormatterStyle(_styles, style);
  [self resetFormatter];
}

- (NSInteger)timeFormat {
  return TATimeFormatterStyle(_styles);
}
- (void)setTimeFormat:(NSInteger)style {
  _styles = TASetTimeFormatterStyle(_styles, style);
  [self resetFormatter];
}

- (void)setRawDateFormat:(NSString *)format {
  if (format != _rawDateFormat && ![format isEqualToString:_rawDateFormat]) {
    [self willChangeValueForKey:@"sampleDate"];
    [self willChangeValueForKey:@"dateFormat"];
    [self willChangeValueForKey:@"timeFormat"];
    _rawDateFormat = [format copy];
    _styles = TASetDateFormatterStyle(_styles, kCFDateFormatterNoStyle);
    _styles = TASetTimeFormatterStyle(_styles, kCFDateFormatterNoStyle);
    CFDateFormatterSetFormat(_formatter, SPXNSToCFString(format) ? : CFSTR(""));
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
	[self willChangeValueForKey:@"canAutorepeat"];
  [uiTokens setObjectValue:[uiRecTokens objectValue]];
	[self didChangeValueForKey:@"canAutorepeat"];
//  NSArray *tokens = [uiRecTokens objectValue];
//  if ([tokens count] > 0) {
//    NSMutableArray *mtoks = [[uiTokens objectValue] mutableCopy];
//    [mtoks addObjectsFromArray:tokens];
//    [uiTokens setObjectValue:mtoks];
//    [mtoks release];
//  }
  [uiRecordWindow performClose:nil];
}

- (BOOL)canAutorepeat {
	return [[uiTokens objectValue] count] <= 1;
}

- (void)controlTextDidChange:(NSNotification *)aNotification {
	[self willChangeValueForKey:@"canAutorepeat"];
	
	[self didChangeValueForKey:@"canAutorepeat"];	
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
      if (![obj isEqual:[NSNull null]])
        [tks addObject:obj];
    }
    return tks;
  }
  return tokens;
}

- (BOOL)trapWindow:(HKTrapWindow *)window needPerformKeyEquivalent:(NSEvent *)theEvent {
  /* No modifier and cancel pressed */
  NSUInteger flags = NSEventModifierFlagShift | NSEventModifierFlagControl | NSEventModifierFlagOption | NSEventModifierFlagCommand;
  if (!([theEvent modifierFlags] & flags) && [[theEvent characters] isEqualToString:@"\e"]) {
    CFAbsoluteTime now = CFAbsoluteTimeGetCurrent();
    /* check double escape */
    if (now < _escape + 0.5) {
      return YES;
    } else {
      _escape = now;
    }
  }
  return NO;
}

- (BOOL)trapWindow:(HKTrapWindow *)window needProceedKeyEvent:(NSEvent *)theEvent {
  UInt16 code = [theEvent keyCode];
  NSUInteger mask = [theEvent modifierFlags] & (NSEventModifierFlagShift | NSEventModifierFlagControl | NSEventModifierFlagOption | NSEventModifierFlagCommand);
  
  return mask ? NO : code == kHKVirtualEscapeKey;
}

- (BOOL)trapWindow:(HKTrapWindow *)window isValidHotKey:(HKKeycode)keycode modifier:(HKModifier)modifier {
  return YES;
}

- (void)trapWindowDidCatchHotKey:(NSNotification *)aNotification {
  NSDictionary *info = [aNotification userInfo];
  UInt16 nkey = (UInt16)[info[kHKEventKeyCodeKey] integerValue];
  UniChar chr = (UniChar)[info[kHKEventCharacterKey] integerValue];
  HKModifier nmodifier = (HKModifier)[info[kHKEventModifierKey] integerValue];

  TAKeystroke *hkey = [[TAKeystroke alloc] initWithKeycode:nkey character:chr modifier:nmodifier];
  NSMutableArray *objs = [[uiRecTokens objectValue] mutableCopy];
  [objs addObject:hkey];
  [uiRecTokens setObjectValue:objs];
}

@end
