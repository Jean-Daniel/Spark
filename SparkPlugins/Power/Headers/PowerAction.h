//
//  PowerAction.h
//  Spark
//
//  Created by Fox on Wed Feb 18 2004.
//  Copyright (c) 2004 Shadow Lab. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <SparkKit/SparkKit.h>

@interface PowerAction : SparkAction <NSCoding, NSCopying> {
  int _powerAction;
}

- (int)powerAction;
- (void)setPowerAction:(int)newPowerAction;

- (void)launchSystemEvent;
- (void)sendAppleEvent:(OSType)eventType;

@end
