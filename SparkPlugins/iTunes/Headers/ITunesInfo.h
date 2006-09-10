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

- (IBAction)display:(id)sender;

- (void)setTrack:(iTunesTrack *)track;

@end

#import <ShadowKit/SKCGFunctions.h>

@interface ITunesInfoView : NSView {
  @private
  CGShadingRef shading;
  SKSimpleShadingInfo info;
}

@end
