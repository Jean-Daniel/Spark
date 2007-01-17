/*
 *  SEHotKeyTrap.h
 *  Spark Editor
 *
 *  Created by Black Moon Team.
 *  Copyright (c) 2004 - 2007 Shadow Lab. All rights reserved.
 */

#import <Cocoa/Cocoa.h>

enum {
  SEValidModifiersFlags = NSShiftKeyMask | NSControlKeyMask | NSAlternateKeyMask | NSCommandKeyMask
};

typedef struct _SEHotKey {
  UInt16 keycode;
  UInt32 modifiers;
  UniChar character;
} SEHotKey;

@interface SEHotKeyTrap : NSView {
  @private
  NSString *se_str;
  /* State */
  SEHotKey se_hotkey;
  /* Backup */
  SEHotKey se_bhotkey;
  
  struct _se_htFlags {
    unsigned int trap:1;
    unsigned int hint:1;
    unsigned int cancel:1;
    unsigned int traponce:1;
    unsigned int disabled:1;
    unsigned int inbutton:1;
    unsigned int highlight:1;
    unsigned int reserved:25;
  } se_htFlags;

  NSTrackingRectTag se_tracker;
  id se_target;
  SEL se_action;
}

- (id)target;
- (void)setTarget:(id)aTarget;

- (SEL)action;
- (void)setAction:(SEL)anAction;

- (SEHotKey)hotkey;
- (void)setHotKey:(SEHotKey)anHotkey;

- (BOOL)isEnabled;
- (void)setEnabled:(BOOL)flag;

- (IBAction)validate:(id)sender;
- (IBAction)delete:(id)sender;
- (IBAction)cancel:(id)sender;

@end
