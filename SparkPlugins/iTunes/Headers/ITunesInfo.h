/*
 *  ITunesInfo.h
 *  Spark Plugins
 *
 *  Created by Grayfox on 10/09/06.
 *  Copyright 2006 Shadow Lab. All rights reserved.
 */

#import <Cocoa/Cocoa.h>
#import "ITunesAESuite.h"

@interface ITunesInfo : NSWindowController {
  IBOutlet NSTextField *ibName;
  IBOutlet NSTextField *ibAlbum;
  IBOutlet NSTextField *ibArtist;
  
  IBOutlet NSTextField *ibTime;
  IBOutlet NSTextField *ibRate;
}

- (void)setDelay:(float)aDelay;
- (void)setPosition:(NSPoint)aPoint;

- (IBAction)display:(id)sender;

- (void)setTrack:(iTunesTrack *)track;

- (void)setTextColor:(NSColor *)aColor;

- (void)setOrigin:(NSPoint)origin;

- (NSColor *)borderColor;
- (void)setBorderColor:(NSColor *)aColor;

- (NSColor *)backgroundColor;
- (void)setBackgroundColor:(NSColor *)aColor;

- (NSColor *)backgroundTopColor;
- (void)setBackgroundTopColor:(NSColor *)aColor;

- (NSColor *)backgroundBottomColor;
- (void)setBackgroundBottomColor:(NSColor *)aColor;

@end

#import <ShadowKit/SKCGFunctions.h>

@interface ITunesInfoView : NSView {
  @private
  float border[4];
  CGShadingRef shading;
  SKSimpleShadingInfo info;
}

- (NSColor *)borderColor;
- (void)setBorderColor:(NSColor *)aColor;

- (NSColor *)backgroundColor;
- (void)setBackgroundColor:(NSColor *)aColor;

- (NSColor *)backgroundTopColor;
- (void)setBackgroundTopColor:(NSColor *)aColor;

- (NSColor *)backgroundBottomColor;
- (void)setBackgroundBottomColor:(NSColor *)aColor;

@end
