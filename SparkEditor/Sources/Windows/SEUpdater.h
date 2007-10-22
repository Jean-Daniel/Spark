//
//  SEUpdater.h
//  Spark Editor
//
//  Created by Jean-Daniel Dupas on 18/09/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import <SUpdaterKit/SUpdater.h>
#import <ShadowKit/SKSingleton.h>

@interface SEUpdater : SUpdater {
  @private
  IBOutlet NSProgressIndicator *uiProgress;
}


@end

SKSingletonInterface(SEUpdater, sharedUpdater);
