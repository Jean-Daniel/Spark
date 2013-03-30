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

@class WBAlias, OSAScript;
@interface AppleScriptAction : SparkAction <NSCoding, NSCopying> {
  @private
  WBAlias *as_alias;
  OSAScript *as_script;
  NSTimeInterval as_repeat;
}

- (NSString *)file;
- (void)setFile:(NSString *)aFile;

@property(nonatomic, retain) WBAlias *scriptAlias;

- (NSString *)scriptSource;
- (void)setScriptSource:(NSString *)source;

@end

SPARK_PRIVATE
NSString *AppleScriptActionDescription(AppleScriptAction *anAction);
