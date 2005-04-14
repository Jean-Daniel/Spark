//
//  MyHotKey.m
//  MySparkHotKey
//
//  Created by JD on Sat Mar 20 2004.
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//

#import "MyHotKey.h"

@implementation MyHotKey

static NSString * const kMyBeepCountKey = @"MyBeepCount";

- (id)initFromPropertyList:(NSDictionary *)plist {
  if (self = [super initFromPropertyList:plist]) {
    [self setBeepCount:[[plist objectForKey:kMyBeepCountKey] intValue]];
  }
  return self;
}
- (id)propertyList {
  id plist = [super propertyList];
  [plist setObject:[NSNumber numberWithInt:beepCount] forKey:kMyBeepCountKey];
  return plist;
}

/* This function is call on loading. It permit to signal if the hot key is valid or not.
In our case, beepCount is always right exept if an user edit the key file manually */
- (SparkAlert *)check {
  if (beepCount < 1 || beepCount > 9) {
    return [SparkAlert alertWithMessageText:[NSString stringWithFormat:@"The MyHotKey «%@» isn't valid.", [self name]]
                  informativeTextWithFormat:@"Beep count must be more than 0 and less than 10! Launch Spark to correct this Problem."]; 
  }
  return nil;
}

- (SparkAlert *)execute {
  id alert = [self check]; // It is better to check the hot key before execution.
  if (alert == nil) {
    id alert = [SparkAlert alertWithMessageText:@"Hello, you calle me ?" informativeTextWithFormat:@"You set beep Count to : %i", beepCount];
    [alert setHideSparkButton:YES];
    SparkDisplayAlert(alert);
  }
  return alert;
}


- (int)beepCount {
  return beepCount;
}
- (void)setBeepCount:(int)newBeepCount {
  beepCount = newBeepCount;
}


@end
