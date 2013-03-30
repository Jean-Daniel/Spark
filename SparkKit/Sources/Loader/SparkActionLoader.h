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

#import <WonderBox/WBPlugInLoader.h>

@class SparkPlugIn, SparkAction;

SPARK_EXPORT
NSString * const SparkActionLoaderDidRegisterPlugInNotification;

/*!
@abstract Action extension is "spact".
*/
SPARK_OBJC_EXPORT
@interface SparkActionLoader : WBPlugInLoader {
}

+ (SparkActionLoader *)sharedLoader;

- (id)loadPlugIn:(NSBundle *)aBundle;
- (SparkPlugIn *)registerPlugInClass:(Class)aClass;

- (SparkPlugIn *)plugInForAction:(SparkAction *)action;
- (SparkPlugIn *)plugInForActionClass:(Class)cls;

@end
