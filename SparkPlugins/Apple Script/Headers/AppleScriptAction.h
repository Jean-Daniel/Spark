//
//  AppleScriptAction.h
//  Spark
//
//  Created by Fox on Fri Feb 20 2004.
//  Copyright (c) 2004 Shadow Lab. All rights reserved.
//

#import <SparkKit/SparkPluginAPI.h>

SPARK_PRIVATE
NSString * const kASActionBundleIdentifier;

#define AppleScriptActionBundle		[NSBundle bundleWithIdentifier:kASActionBundleIdentifier]

@class SKAlias;
@interface AppleScriptAction : SparkAction <NSCoding, NSCopying> {
  @private
  id as_script;
  SKAlias *as_alias;
}

- (id)script;
- (void)setScript:(id)aScript;

- (NSString *)file;
- (void)setFile:(NSString *)aFile;

- (SKAlias *)scriptAlias;
- (void)setScriptAlias:(SKAlias *)anAlias;

@end

SPARK_PRIVATE
NSString *AppleScriptActionDescription(AppleScriptAction *anAction);
