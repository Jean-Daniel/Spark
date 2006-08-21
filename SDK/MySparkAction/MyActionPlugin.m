/*
 *  MyActionPlugin.m
 *  MySparkAction
 *
 *  Created by Black Moon Team.
 *  Copyright (c) ShadowLab. 2004 - 2006.
 */

#import "MyActionPlugin.h"
#import "MyAction.h"

@implementation MyActionPlugin

/* This function is called when the user open MyAction Editor Panel in Spark. Default implementation does nothing. */
- (void)loadSparkAction:(id)sparkAction toEdit:(BOOL)flag {
  /* if flag == NO, the user want to create a new Action, else he wants to edit an existing Action */
  if (!flag) {
    /* Configure default beep count for new actions */
    [self setBeepCount:5];
  }
}

/* Default implementation does nothing */
/* The action icon is not required and the action name will be checked later, so you can safely ignore them. */
- (NSAlert *)sparkEditorShouldConfigureAction {
  /* You can verify action settings and tell the user if he did someting wrong. 
  In this example, we check the beep count, and return an error if it is less than 1 or more than 9 */
  if ([self beepCount] < 1 || [self beepCount] > 9) {
    return [NSAlert alertWithMessageText:@"Beep Count is not valid"
                           defaultButton:@"OK"
                         alternateButton:nil
                             otherButton:nil
               informativeTextWithFormat:@"Beep Count must be more than 0 and less than 10."];
  }
  return nil;
}

/* You need configure the new Action or modify the existing Action here */
/* If you use [self setName:] and [self setIcon:] (directly or with binding), 
action's icon and action's name are already setted, else you have to set them here */
- (void)configureAction {
  /* Get the current Action */
  MyAction *myAction = [self sparkAction];
  
  /* In this sample, we bind name, so don't have to set it, but icon should updated */
  [myAction setIcon:[self icon]];
  
  /* Set ActionDescription */
  [myAction setActionDescription:[NSString stringWithFormat:@"Beep %i times", [self beepCount]]];
}

#pragma mark -
#pragma mark Plugin Specifics methods
- (int)beepCount {
  return [[self sparkAction] beepCount];
}
- (void)setBeepCount:(int)newBeepCount {
  [[self sparkAction] setBeepCount:newBeepCount];
}

@end
