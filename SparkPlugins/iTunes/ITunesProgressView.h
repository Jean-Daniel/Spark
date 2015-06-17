//
//  ITunesProgressView.h
//  Spark Plugins
//
//  Created by Jean-Daniel Dupas on 14/09/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface ITunesProgressView : NSView

- (void)setColor:(NSColor *)aColor;

@property(nonatomic) CGFloat progress;

@end
