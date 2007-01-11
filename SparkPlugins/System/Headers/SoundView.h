/*
 *  SoundView.h
 *  Labo Test
 *
 *  Created by Grayfox on 08/01/07.
 *  Copyright 2007 Shadow Lab. All rights reserved.
 */

#import <Cocoa/Cocoa.h>

@interface SoundView : NSView {
  struct _sk_svFlags {
    unsigned int mute:1;
    unsigned int level:5;
    unsigned int reserved:24;
  } sk_svFlags;
}

- (BOOL)isMuted;
- (void)setMuted:(BOOL)flag;

- (UInt32)level;
- (void)setLevel:(UInt32)level;

@end
