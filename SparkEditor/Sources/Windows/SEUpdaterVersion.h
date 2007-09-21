//
//  SEUpdaterVersion.h
//  Spark Editor
//
//  Created by Jean-Daniel Dupas on 21/09/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import <ShadowKit/SKWindowController.h>

@class WebView;
@class SKHeaderView, SKUpdaterVersion;
@interface SEUpdaterVersion : SKWindowController {
  @protected
  IBOutlet NSTextField *ibTitle;
  IBOutlet NSTextField *ibMessage;

  IBOutlet WebView *ibHistory;
  IBOutlet SKHeaderView *ibHeader;
  
  NSPopUpButton *se_versions;
}

- (IBAction)install:(id)sender;
- (IBAction)selectVersion:(id)sender;

- (int)runModal;

- (void)setVersions:(NSArray *)versions;
- (void)setSelectedVersion:(SKUpdaterVersion *)aVersion;


@end
