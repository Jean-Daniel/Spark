//
//  SEUpdater.h
//  Spark Editor
//
//  Created by Jean-Daniel Dupas on 18/09/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <ShadowKit/SKSingleton.h>

@class SKUpdater, SKArchive, SKProgressPanel;
@interface SEUpdater : NSObject {
  @private
  bool se_search;
  UInt64 se_version;
  NSString *se_size;
  SKUpdater *se_updater;
  SKArchive *se_archive;
  SKProgressPanel *se_progress;
}

- (void)search;
- (void)runInBackground;

- (void)showProgressPanel;

@end

SKSingletonInterface(SEUpdater, sharedUpdater);
