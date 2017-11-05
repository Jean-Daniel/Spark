/*
 *  AppleScriptAction.h
 *  Spark Plugins
 *
 *  Created by Black Moon Team.
 *  Copyright (c) 2004 - 2007, Shadow Lab. All rights reserved.
 */

#import <SparkKit/SparkKit.h>

SPARK_PRIVATE NSBundle *AppleScriptActionBundle(void);

@class WBAlias;

@interface AppleScriptAction : SparkAction <NSCoding, NSCopying>

@property(nonatomic, copy) NSURL *URL;

@property(nonatomic, retain) WBAlias *scriptBookmark;

@property(nonatomic, copy) NSString *scriptSource;

@end

SPARK_PRIVATE
NSString *AppleScriptActionDescription(AppleScriptAction *anAction);
