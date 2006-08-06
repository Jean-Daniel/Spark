/*
 *  SEHotKeyTrap.h
 *  Spark Editor
 *
 *  Created by Grayfox on 09/07/06.
 *  Copyright 2006 Shadow Lab. All rights reserved.
 */

#import <Cocoa/Cocoa.h>

enum {
  SEValidModifiersFlags = NSShiftKeyMask | NSControlKeyMask | NSAlternateKeyMask | NSCommandKeyMask
};

@interface SEHotKeyTrap : NSControl {
  @private
  NSString *se_str;
  /* State */
  UInt16 se_keycode;
  UInt32 se_modifier;
  UniChar se_character;

  /* Backup */
  UInt16 se_bkeycode;
  UInt32 se_bmodifier;
  UniChar se_bcharacter;
  
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
}

@end
