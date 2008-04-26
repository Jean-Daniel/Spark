//
//  SparkDaemonGrowl.h
//  SparkDaemon
//
//  Created by Jean-Daniel Dupas on 05/04/08.
//  Copyright 2008 Ninsight. All rights reserved.
//

#import "SparkDaemon.h"

#import <Growl/GrowlApplicationBridge.h>

@class SparkActionPlugIn;
@interface SparkDaemon (GrowlSupport) <GrowlApplicationBridgeDelegate>

- (void)registerGrowl;

- (void)registerPlugin:(SparkActionPlugIn *)aPlugin;
- (void)unregisterPlugin:(SparkActionPlugIn *)aPlugin;

@end
