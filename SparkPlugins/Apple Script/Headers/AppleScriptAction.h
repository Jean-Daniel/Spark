//
//  AppleScriptAction.h
//  Spark
//
//  Created by Fox on Fri Feb 20 2004.
//  Copyright (c) 2004 Shadow Lab. All rights reserved.
//

#import <SparkKit/SparkPluginAPI.h>

@class SKAlias;
@interface AppleScriptAction : SparkAction <NSCoding, NSCopying> {
  NSAppleScript *_script;
  SKAlias *_scriptAlias;
}

- (SKAlias *)scriptAlias;
- (void)setScriptAlias:(SKAlias *)newScriptAlias;

- (NSAppleScript *)script;
- (void)setScript:(NSAppleScript *)newScript;
- (NSString *)scriptFile;
- (void)setScriptFile:(NSString *)newScriptFile;

@end
