//
//  KeyStrokeAction.h
//  Spark
//
//  Created by Fox on Sun Feb 15 2004.
//  Copyright (c) 2004 Shadow Lab. All rights reserved.
//
#import <Cocoa/Cocoa.h>
#import <SparkKit/SparkKit.h>
#import "KeyStrokeActionPlugin.h"

@interface KeyStrokeAction : SparkHotKey {
  id keystroke;
  int modifier;
}

- (id)keystroke;
- (void)setKeystroke:(id)newKeystroke;
- (int)keyModifier;
- (void)setKeyModifier:(int)newModifier;

- (void)launchSystemEvent;

@end
