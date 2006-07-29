/*
 *  SparkActionLoader.h
 *  SparkKit
 *
 *  Created by Black Moon Team.
 *  Copyright © 2004 - 2006 Shadow Lab. All rights reserved.
 *
 */

/*!
@header SparkActionLoader
 */
#import <ShadowKit/SKPluginLoader.h>

@class SparkPlugIn, SparkAction;

/*!
@class SparkActionLoader
@abstract Action extension is "spact".
*/
@interface SparkActionLoader : SKPluginLoader {
  
}

- (SparkPlugIn *)plugInForAction:(SparkAction *)action;

@end
