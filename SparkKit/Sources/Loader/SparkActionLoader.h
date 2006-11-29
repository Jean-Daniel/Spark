/*
 *  SparkActionLoader.h
 *  SparkKit
 *
 *  Created by Black Moon Team.
 *  Copyright (c) 2004 - 2006 Shadow Lab. All rights reserved.
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

- (SparkPlugIn *)registerPlugInClass:(Class)aClass;

- (SparkPlugIn *)plugInForAction:(SparkAction *)action;
- (SparkPlugIn *)plugInForActionClass:(Class)cls;

@end
