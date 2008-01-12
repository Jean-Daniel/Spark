/*
 *  AppleScriptAction.h
 *  Spark Plugins
 *
 *  Created by Black Moon Team.
 *  Copyright (c) 2004 - 2007, Shadow Lab. All rights reserved.
 */

#import <SparkKit/SparkPluginAPI.h>

#define kASActionBundleIdentifier   @"org.shadowlab.spark.action.applescript"
#define AppleScriptActionBundle		[NSBundle bundleWithIdentifier:kASActionBundleIdentifier]

@class WBAlias, OSAScript;
@interface AppleScriptAction : SparkAction <NSCoding, NSCopying> {
  @private
  WBAlias *as_alias;
  OSAScript *as_script;
}

- (NSString *)file;
- (void)setFile:(NSString *)aFile;

- (WBAlias *)scriptAlias;
- (void)setScriptAlias:(WBAlias *)anAlias;

- (NSString *)scriptSource;
- (void)setScriptSource:(NSString *)source;

@end

SPARK_PRIVATE
NSString *AppleScriptActionDescription(AppleScriptAction *anAction);
