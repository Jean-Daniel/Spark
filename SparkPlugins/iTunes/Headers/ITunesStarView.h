/*
 *  ITunesStarView.h
 *  Spark Plugins
 *
 *  Created by Grayfox on 13/01/07.
 *  Copyright 2007 Shadow Lab. All rights reserved.
 */

#import <Cocoa/Cocoa.h>

@interface ITunesStarView : NSView

@property(nonatomic) uint8_t rate;

@property(nonatomic, retain) NSColor *starsColor;

@end
