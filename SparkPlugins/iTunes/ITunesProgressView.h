//
//  ITunesProgressView.h
//  Spark Plugins
//
//  Created by Jean-Daniel Dupas on 14/09/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface ITunesProgressView : NSView {
  @private
  CGFloat _progress;
  CGFloat _red, _green, _blue, _alpha;
}

- (void)setColor:(NSColor *)aColor;
- (void)setProgress:(CGFloat)progress;


@end
