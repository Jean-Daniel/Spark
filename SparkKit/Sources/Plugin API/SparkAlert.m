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

- (instancetype)init {
  if (self = [super init]) {
    [self setHideSparkButton:SparkGetCurrentContext() == kSparkContext_Editor];
  }
  return self;
}

+ (instancetype)alertWithMessageText:(NSString *)message informativeTextWithFormat:(NSString *)format,... {
  SparkAlert *alert;
  
  va_list argList;
  va_start(argList, format);
  alert = [self alertWithMessageText:message informativeTextWithFormat:format args:argList];
  va_end(argList);
  
  return alert;
}

+ (instancetype)alertWithMessageText:(NSString *)message informativeTextWithFormat:(NSString *)format args:(va_list)argList {
  SparkAlert *alert = [[self alloc] init];
  [alert setMessageText:message];
  
  NSString *info = [[NSString alloc] initWithFormat:format arguments:argList];
  [alert setInformativeText:info];
  return alert;
}

@end
