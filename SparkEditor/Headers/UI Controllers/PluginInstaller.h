//
//  PluginInstaller.h
//  Spark Editor
//
//  Created by Grayfox on 15/12/2004.
//  Copyright 2004 Shadow Lab. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class SFAuthorization;
@interface PluginInstaller : NSWindowController {
  IBOutlet id form;
  IBOutlet id explain;
  IBOutlet id adminInfo;
  IBOutlet id installButton;
  @private
  CFBundleRef _src;
  CFBundleRef _dest;
  SFAuthorization *_auth;
}

- (IBAction)update:(id)sender;
- (IBAction)cancel:(id)sender;
- (IBAction)install:(id)sender;

- (CFBundleRef)source;
- (void)setSource:(CFBundleRef)source;

- (CFBundleRef)destination;
- (void)setDestination:(CFBundleRef)dest;

- (BOOL)copyPluginForUser;
- (BOOL)copyPluginForComputer;

@end
