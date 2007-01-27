/*
 *  MyAction.m
 *  MySparkAction
 *
 *  Created by Black Moon Team.
 *  Copyright (c) ShadowLab. 2004 - 2006.
 */

#import "MyAction.h"

@implementation MyAction

static 
NSString * const kMyActionMessageKey = @"MyActionMessage";

- (id)copyWithZone:(NSZone *)aZone {
  MyAction *copy = [super copyWithZone:aZone];
  copy->my_message = [my_message copy];
  return copy;
}

- (void)dealloc {
  [my_message release];
  [super dealloc];
}

/* initWithSerializedValues: is called when a Action is loaded. You must call [super initWithSerializedValues:plist].
Get all values you set in the -serialize: method and configure your Action */
- (id)initWithSerializedValues:(NSDictionary *)plist {
  if (self = [super initWithSerializedValues:plist]) {
    [self setMessage:[plist objectForKey:kMyActionMessageKey]];
  }
  return self;
}

/* Use to transform and record you Action in a file. The dictionary returned must contains only PList objects 
See the PropertyList documentation to know more about it */
- (BOOL)serialize:(NSMutableDictionary *)plist {
  if ([super serialize:plist]) {
    if (my_message)
      [plist setObject:my_message forKey:kMyActionMessageKey];
    return YES;
  }
  return NO;
}

/* This function is call after loading. It permit to signal if the action is valid or not.
In our case, beepCount is always right exept if an user edit the library file manually */
- (SparkAlert *)actionDidLoad {
  if ([[self message] length] < 5 || [[self message] length] > 128) {
    return [SparkAlert alertWithMessageText:[NSString stringWithFormat:@"The MyAction \"%@\" isn't valid.", [self name]]
                  informativeTextWithFormat:@"Your message MUST be at least 5 characters and contains less than 128 characters. Use Spark to correct this Problem."];
  }
  return nil;
}

- (SparkAlert *)performAction {
  NSAlert *dialog = [NSAlert alertWithMessageText:@"Hello, you call me?"
                                    defaultButton:@"OK"
                                  alternateButton:nil
                                      otherButton:nil
                        informativeTextWithFormat:@"You message is : %@", my_message];
  [dialog runModal];
  return nil;
}

#pragma mark -
#pragma mark Accessor methods
- (NSString *)message {
  return my_message;
}
- (void)setMessage:(NSString *)aMessage {
  if (my_message != aMessage) {
    [my_message release];
    my_message = [aMessage retain];
    [self setActionDescription:[NSString stringWithFormat:@"Dislay message: %@", my_message]];
  }
}

@end
