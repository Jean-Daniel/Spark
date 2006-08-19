/*
 *  SparkPrivate.h
 *  SparkKit
 *
 *  Created by Black Moon Team.
 *  Copyright (c) 2004 - 2006 Shadow Lab. All rights reserved.
 *
 */

#import <SparkKit/SparkAction.h>
#import <SparkKit/SparkActionPlugIn.h>

@interface SparkActionPlugIn (Private)

+ (NSString *)nibPath;

/* SparkActionClass */
+ (Class)actionClass;

/* SparkPluginName */
+ (NSString *)plugInName;

/* SparkPluginIcon */
+ (NSImage *)plugInIcon;

/* SparkHelpFile */
+ (NSString *)helpFile;

- (void)setSparkAction:(SparkAction *)anAction;

@end

@class SparkHotKey;
@interface SparkAction (Private)

- (SparkAlert *)hotKeyShouldExecuteAction:(SparkHotKey *)hotkey;

- (BOOL)isInvalid;
- (void)setInvalid:(BOOL)flag;

@end
