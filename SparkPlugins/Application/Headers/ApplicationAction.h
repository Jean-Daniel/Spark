//
//  ApplicationAction.h
//  Spark
//
//  Created by Fox on Wed Dec 10 2003.
//  Copyright (c) 2004 Shadow Lab. All rights reserved.
//

#import <SparkKit/SparkKit_API.h>

@class SKApplicationAlias;
@interface ApplicationAction : SparkAction <NSCoding, NSCopying> {
  SKApplicationAlias *_alias;
  int _appAction;
  int _flags;
}

- (NSString *)sign;
- (NSString *)bundleId;
- (void)setPath:(NSString *)path;
- (NSString *)path;
- (void)setAlias:(SKApplicationAlias *)alias;
- (SKApplicationAlias *)alias;
- (void)setAppAction:(int)action;
- (int)appAction;
- (void)setFlags:(int)flags;
- (int)flags;

- (void)launchApplication;
- (void)quitApplication;
- (void)killApplication;
- (void)relaunchApplication;

- (BOOL)launchAppWithFlag:(int)flag;
@end