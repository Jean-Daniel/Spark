/*
 *  SparkActionPlugIn_Private.h
 *  Spark
 *
 *  Created by Fox on Sun Feb 29 2004.
 *  Copyright (c) 2004 Shadow Lab. All rights reserved.
 *
 */

#import <SparkKit/SparkAction.h>
#import <SparkKit/SparkActionPlugIn.h>

@interface SparkActionPlugIn (Private)

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

- (BOOL)isCustom;
- (void)setCustom:(BOOL)custom;

@end
