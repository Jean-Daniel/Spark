/*
 *  AppleScriptAction.h
 *  Spark Plugins
 *
 *  Created by Black Moon Team.
 *  Copyright (c) 2004 - 2006, Shadow Lab. All rights reserved.
 */

#import <SparkKit/SparkPluginAPI.h>

SPARK_PRIVATE
NSString * const kASActionBundleIdentifier;

#define AppleScriptActionBundle		[NSBundle bundleWithIdentifier:kASActionBundleIdentifier]

@class SKAlias;
@interface AppleScriptAction : SparkAction <NSCoding, NSCopying> {
  @private
  SKAlias *as_alias;
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
