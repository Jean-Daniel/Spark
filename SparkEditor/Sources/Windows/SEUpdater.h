//
//  SEUpdater.h
//  Spark Editor
//
//  Created by Jean-Daniel Dupas on 18/09/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <ShadowKit/SKSingleton.h>

@class SKUpdater;
@interface SEUpdater : NSObject {
  IBOutlet NSWindow *ibProgressWindow;
  IBOutlet NSTextField *ibName;
  IBOutlet NSTextField *ibProgressText;
  IBOutlet NSProgressIndicator *ibProgress;

  @private
  bool se_search;
  UInt64 se_version;
  NSString *se_size;
  SKUpdater *se_updater;
  CFAbsoluteTime se_refresh;
}

- (void)search;
- (void)runInBackground;

- (void)showProgressPanel;

@end

SKSingletonInterface(SEUpdater, sharedUpdater);
