/*
 *  ITunesStarView.h
 *  Spark Plugins
 *
 *  Created by Grayfox on 13/01/07.
 *  Copyright 2007 Shadow Lab. All rights reserved.
 */

#import <Cocoa/Cocoa.h>

@interface ITunesStarView : NSView {
  UInt8 ia_rate;
  NSColor *ia_color;
}

- (UInt8)rate;
- (void)setRate:(UInt8)rate;

- (void)setStarsColor:(NSColor *)aColor;

@end
