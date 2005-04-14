//
//  SparkAlert.m
//  SparkKit
//
//  Created by Fox on Wed Mar 17 2004.
//  Copyright (c) 2004 Shadow Lab. All rights reserved.
//

#import "SparkAlert.h"
#import "SparkConstantes.h"

@implementation SparkAlert

- (id)init {
  if (self = [super init]) {
    [self setHideSparkButton:[[[NSBundle mainBundle] bundleIdentifier] isEqualToString:kSparkBundleIdentifier]];
  }
  return self;
}

- (void)dealloc {
  [_messageText release];
  [_informativeText release];
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
  return _messageText;
}
- (void)setMessageText:(NSString *)newMessageText {
  if (_messageText != newMessageText) {
    [_messageText release];
    _messageText = [newMessageText copy];
  }
}

- (NSString *)informativeText {
  return _informativeText;
}
- (void)setInformativeText:(NSString *)newInformativeText {
  if (_informativeText != newInformativeText) {
    [_informativeText release];
    _informativeText = [newInformativeText copy];
  }
}

- (BOOL)hideSparkButton {
  return _hideSparkButton;
}
- (void)setHideSparkButton:(BOOL)flag {
  _hideSparkButton = flag;
}

@end
