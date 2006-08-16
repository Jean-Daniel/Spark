//
//  MyActionPlugin.h
//  MySparkAction
//
//  Created by Fox on Sat Mar 20 2004.
//  Copyright (c) 2004 ShadowLab. All rights reserved.
//

#import <SparkKit/SparkKit_API.h>

@interface MyActionPlugin : SparkActionPlugIn {

}

- (int)beepCount;
- (void)setBeepCount:(int)newBeepCount;

@end
