/*
 *  SEHotKeyTrap.h
 *  Spark Editor
 *
 *  Created by Black Moon Team.
 *  Copyright (c) 2004 - 2007 Shadow Lab. All rights reserved.
 */

#import <Cocoa/Cocoa.h>

enum {
  SEValidModifiersFlags = NSEventModifierFlagShift | NSEventModifierFlagControl | NSEventModifierFlagOption | NSEventModifierFlagCommand
};

typedef struct _SEHotKey {
  UInt16 keycode;
  UInt32 modifiers;
  UniChar character;
} SEHotKey;

@interface SEHotKeyTrap : NSView

@property(nonatomic) SEL action;
@property(nonatomic, assign) id target;

@property(nonatomic) SEHotKey hotKey;

@property(nonatomic, getter=isEnabled) BOOL enabled;

- (IBAction)validate:(id)sender;
- (IBAction)delete:(id)sender;
- (IBAction)cancel:(id)sender;

@end
