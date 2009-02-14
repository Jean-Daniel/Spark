/*
 *  SparkAlert.m
 *  SparkKit
 *
 *  Created by Black Moon Team.
 *  Copyright (c) 2004 - 2007 Shadow Lab. All rights reserved.
 */

#import <SparkKit/SparkKit.h>
#import <SparkKit/SparkAlert.h>
#import <SparkKit/SparkFunctions.h>

@implementation SparkAlert

- (id)init {
  if (self = [super init]) {
    [self setHideSparkButton:SparkGetCurrentContext() == kSparkEditorContext];
  }
  return self;
}

- (void)dealloc {
  [sp_message release];
  [sp_informative release];
  [super dealloc];
}

+ (id)alertWithMessageText:(NSString *)message informativeTextWithFormat:(NSString *)format,... {
  SparkAlert *alert;
  
  va_list argList;
  va_start(argList, format);
  alert = [self alertWithMessageText:message informativeTextWithFormat:format args:argList];
  va_end(argList);
  
  return alert;
}

+ (id)alertWithMessageText:(NSString *)message informativeTextWithFormat:(NSString *)format args:(va_list)argList {
  SparkAlert *alert = [[self alloc] init];
  [alert setMessageText:message];
  
  id info = [[NSString alloc] initWithFormat:format arguments:argList];
  [alert setInformativeText:info];
  [info release];
  return [alert autorelease];
}

- (NSString *)messageText {
  return sp_message;
}
- (void)setMessageText:(NSString *)message {
  WBSetterCopy(&sp_message, message);
}

- (NSString *)informativeText {
  return sp_informative;
}
- (void)setInformativeText:(NSString *)string {
  WBSetterCopy(&sp_informative, string);
}

- (BOOL)hideSparkButton {
  return sp_hide;
}
- (void)setHideSparkButton:(BOOL)flag {
  sp_hide = flag;
}

@end
