//
//  MyHotKey.h
//  MySparkHotKey
//
//  Created by JD on Sat Mar 20 2004.
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//

#import <SparkKit/SparkKit_PlugIn.h>

@interface MyHotKey : SparkHotKey {
  int beepCount;
}

- (int)beepCount;
- (void)setBeepCount:(int)newBeepCount;

@end
