//
//  SparkActionLoader.h
//  Spark
//
//  Created by Fox on Thu Jan 22 2004.
//  Copyright (c) 2004 Shadow Lab. All rights reserved.
//

/*!
    @header SparkActionLoader
*/
#import <ShadowKit/SKPluginLoader.h>

@class SparkPlugIn, SparkAction;

/*!
    @class		SparkActionLoader
    @abstract   Action extension is "spact".
*/
@interface SparkActionLoader : SKPluginLoader {

}

+ (NSString *)buildInPath;
+ (void)setBuildInPath:(NSString *)newPath;

- (SparkPlugIn *)plugInForAction:(SparkAction *)action;

@end
