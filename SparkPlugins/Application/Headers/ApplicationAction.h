//
//  ApplicationAction.h
//  Spark
//
//  Created by Fox on Wed Dec 10 2003.
//  Copyright (c) 2004 Shadow Lab. All rights reserved.
//

#import <SparkKit/SparkPluginAPI.h>

@class SKBezelItem, SKApplicationAlias;
@interface ApplicationAction : SparkAction <NSCoding, NSCopying> {
  @private
  int sa_flags;
  int sa_action;
  SKBezelItem *sa_bezel;
  SKApplicationAlias *sa_alias;
}

- (OSType)signature;
- (NSString *)bundleIdentifier;

- (NSString *)path;
- (void)setPath:(NSString *)path;

- (int)flags;
- (void)setFlags:(int)flags;

- (int)action;
- (void)setAction:(int)action;

- (SKApplicationAlias *)alias;
- (void)setAlias:(SKApplicationAlias *)alias;

- (void)hideFront;
- (void)hideOthers;
- (void)launchApplication;
- (void)quitApplication;
- (void)toggleApplicationState;
- (void)killApplication;
- (void)relaunchApplication;

- (BOOL)launchAppWithFlag:(int)flag;

@end
