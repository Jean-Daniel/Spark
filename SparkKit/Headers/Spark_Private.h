/*
 *  SparkActionPlugIn_Private.h
 *  Spark
 *
 *  Created by Fox on Sun Feb 29 2004.
 *  Copyright (c) 2004 Shadow Lab. All rights reserved.
 *
 */

#import <Foundation/Foundation.h>
#import <SparkKit/SparkShadow.h>

#import <SparkKit/SparkAction.h>
#import <SparkKit/SparkActionPlugIn.h>
#import <SparkKit/SparkLibraryObject.h>
#import <HotKeyToolKit/HotKeyToolKit.h>

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
- (void)setUndoManager:(NSUndoManager *)manager;

@end

@class SparkObjectsLibrary;
@interface SparkLibraryObject (Private)
- (SparkObjectsLibrary *)objectsLibrary;
@end

@class SparkHotKey;
@interface SparkAction (Private)

- (SparkAlert *)hotKeyShouldExecuteAction:(SparkHotKey *)hotkey;

- (BOOL)isInvalid;
- (void)setInvalid:(BOOL)flag;

- (BOOL)isCustom;
- (void)setCustom:(BOOL)custom;

@end

@interface _SparkIgnoreAction : SparkAction {
  
}
+ (id)action;

@end

@interface SparkHotKeyManager : HKHotKeyManager {
}
@end
