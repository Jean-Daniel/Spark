/*
 *  SparkActionLoader.h
 *  SparkKit
 *
 *  Created by Black Moon Team.
 *  Copyright (c) 2004 - 2007 Shadow Lab. All rights reserved.
 */

/*!
@header SparkActionLoader
 */
#import <SparkKit/SparkKit.h>
#import <ShadowKit/SKPluginLoader.h>

@class SparkPlugIn, SparkAction;

SPARK_EXPORT
NSString * const SparkActionLoaderDidRegisterPlugInNotification;

/*!
@class SparkActionLoader
@abstract Action extension is "spact".
*/
@interface SparkActionLoader : SKPluginLoader {
}

- (id)loadPlugin:(NSString *)path;
- (SparkPlugIn *)registerPlugInClass:(Class)aClass;

- (SparkPlugIn *)plugInForAction:(SparkAction *)action;
- (SparkPlugIn *)plugInForActionClass:(Class)cls;

@end
