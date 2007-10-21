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

@class SKAlias, OSAScript;
@interface AppleScriptAction : SparkAction <NSCoding, NSCopying> {
  @private
  SKAlias *as_alias;
  OSAScript *as_script;
}

- (NSString *)file;
- (void)setFile:(NSString *)aFile;

- (SKAlias *)scriptAlias;
- (void)setScriptAlias:(SKAlias *)anAlias;

- (NSString *)scriptSource;
- (void)setScriptSource:(NSString *)source;

@end

SPARK_PRIVATE
NSString *AppleScriptActionDescription(AppleScriptAction *anAction);
