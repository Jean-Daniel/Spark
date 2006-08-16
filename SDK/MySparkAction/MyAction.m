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

/* initWithSerializedValues: is called when a Action is loaded. You must call [super initWithSerializedValues:plist].
Get all values you set in the -serialize: method and configure your Action */
- (id)initWithSerializedValues:(NSDictionary *)plist {
  if (self = [super initWithSerializedValues:plist]) {
    [self setBeepCount:[[plist objectForKey:kMyBeepCountKey] unsignedIntValue]];
  }
  return self;
}

/* Use to transform and record you Action in a file. The dictionary returned must contains only PList objects 
See the PropertyList documentation to know more about it */
- (BOOL)serialize:(NSDictionary *)plist {
  if ([super serialize:plist]) {
    [plist setObject:[NSNumber numberWithUnsignedInt:my_count] forKey:kMyBeepCountKey];
    return YES;
  }
  return NO;
}

/* This function is call on loading. It permit to signal if the action is valid or not.
In our case, beepCount is always right exept if an user edit the library file manually */
- (SparkAlert *)check {
  if (my_count < 1 || my_count > 9) {
    return [SparkAlert alertWithMessageText:[NSString stringWithFormat:@"The MyAction \"%@\" isn't valid.", [self name]]
                  informativeTextWithFormat:@"Beep count must be more than 0 and less than 10! Launch Spark to correct this Problem."]; 
  }
  return nil;
}

- (SparkAlert *)execute {
  NSAlert *dialog = [NSAlert alertWithMessageText:@"Hello, you call me?"
                                    defaultButton:@"OK"
                                  alternateButton:nil
                                      otherButton:nil
                        informativeTextWithFormat:@"You set beep Count to : %i", my_count];
  [dialog runModal];
}

#pragma mark -
#pragma mark Accessor methods
- (int)beepCount {
  return my_count;
}
- (void)setBeepCount:(int)aBeepCount {
  my_count = aBeepCount;
}

@end
