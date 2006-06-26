//
//  ApplicationAction.h
//  Spark
//
//  Created by Fox on Wed Dec 10 2003.
//  Copyright (c) 2004 Shadow Lab. All rights reserved.
//

#import <SparkKit/SparkKit_API.h>

@class SKBezelItem, SKApplicationAlias;
@interface ApplicationAction : SparkAction <NSCoding, NSCopying> {
  @private
  int sa_flags;
  int sa_appAction;
  SKBezelItem *sa_bezel;
  SKApplicationAlias *sa_alias;
}

- (NSString *)sign;
- (NSString *)bundleId;

- (NSString *)path;
- (void)setPath:(NSString *)path;

- (int)flags;
- (void)setFlags:(int)flags;

- (int)appAction;
- (void)setAppAction:(int)action;

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