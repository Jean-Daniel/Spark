/*
 *  AppleScriptAction.h
 *  Spark Plugins
 *
 *  Created by Black Moon Team.
 *  Copyright (c) 2004 - 2007, Shadow Lab. All rights reserved.
 */

#import <SparkKit/SparkPlugInAPI.h>

#define kASActionBundleIdentifier   @"org.shadowlab.spark.action.applescript"
#define AppleScriptActionBundle		[NSBundle bundleWithIdentifier:kASActionBundleIdentifier]

@class WBAlias;
@interface AppleScriptAction : SparkAction <NSCoding, NSCopying>

@property(nonatomic, copy) NSString *file;

@property(nonatomic, retain) WBAlias *scriptAlias;

@property(nonatomic, copy) NSString *scriptSource;

@end

SPARK_PRIVATE
NSString *AppleScriptActionDescription(AppleScriptAction *anAction);
