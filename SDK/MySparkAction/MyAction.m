//
//  MyAction.m
//  MySparkAction
//
//  Created by Fox on Sat Mar 20 2004.
//  Copyright (c) 2004 shadowlab. All rights reserved.
//

#import "MyAction.h"

@implementation MyAction

static NSString * const kMyBeepCountKey = @"MyBeepCount";

/* initFromPropertyList is called when a Action is loaded. You must call [super initFromPropertyList:plist].
Get all values you set in the -propertyList method and configure your Action */
- (id)initFromPropertyList:(NSDictionary *)plist {
  if (self = [super initFromPropertyList:plist]) {
    [self setBeepCount:[[plist objectForKey:kMyBeepCountKey] intValue]];
  }
  return self;
}

/* Use to transform and record you Action in a file. The dictionary returned must contains only PList objects 
See the PropertyList documentation to know more about it */
- (id)propertyList {
  id plist = [super propertyList];
  [plist setObject:[NSNumber numberWithInt:beepCount] forKey:kMyBeepCountKey];
  return plist;
}

/* This function is call on loading. It permit to signal if the action is valid or not.
In our case, beepCount is always right exept if an user edit the library file manually */
- (SparkAlert *)check {
  if (beepCount < 1 || beepCount > 9) {
    return [SparkAlert alertWithMessageText:[NSString stringWithFormat:@"The MyAction \"%@\" isn't valid.", [self name]]
                  informativeTextWithFormat:@"Beep count must be more than 0 and less than 10! Launch Spark to correct this Problem."]; 
  }
  return nil;
}

- (SparkAlert *)execute {
  id alert = [self check]; // It is better to check the hot key before execution.
  if (alert == nil) {
    NSAlert *dialog = [NSAlert alertWithMessageText:@"Hello, you call me?"
                                      defaultButton:@"OK"
                                    alternateButton:nil
                                        otherButton:nil
                          informativeTextWithFormat:@"You set beep Count to : %i", beepCount];
    [dialog runModal];
  }
  return alert;
}

#pragma mark -
#pragma mark Accessor methods
- (int)beepCount {
  return beepCount;
}
- (void)setBeepCount:(int)newBeepCount {
  beepCount = newBeepCount;
}

@end
