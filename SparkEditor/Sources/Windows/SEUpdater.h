//
//  SEUpdater.h
//  Spark Editor
//
//  Created by Jean-Daniel Dupas on 18/09/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class SKUpdater;
@interface SEUpdater : NSObject {
  @private
  SKUpdater *se_updater;
}

+ (SEUpdater *)sharedUpdater;

- (void)check;
- (void)runInBackground;

@end
