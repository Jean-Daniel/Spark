//
//  MyActionPlugin.m
//  MySparkAction
//
//  Created by Fox on Sat Mar 20 2004.
//  Copyright (c) 2004 ShadowLab. All rights reserved.
//

#import "MyActionPlugin.h"
#import "MyAction.h"

@implementation MyActionPlugin

- (void)dealloc {
  [super dealloc];
}

/* This function is called when the user open MyAction Editor Panel in Spark*/
- (void)loadSparkAction:(id)sparkAction toEdit:(BOOL)flag {
  /* Super loadSparkAction:forEditing: set name and icon of self */
  /* If you want to handle name and icon setting, you don't have to call super method */
  /* In our case, icon is bound to receiver icon field in IB so we used this method to load it */ 
  [super loadSparkAction:sparkAction toEdit:flag];
  
  /* if flag == NO, the user want to create a new Action, else he wants to edit an existing Action */
  if (flag) {
    /* For more information about undo manager, please see SparkActionPlugin.h */
    /* In fact, using undo manager is usefull if you bind you field directly on action fields (for exemple, in InterfaceBuilder
    name was bound to owner "sparkAction.name" keyPath */
    [[self undoManager] registerUndoWithTarget:sparkAction selector:@selector(setName:) object:[sparkAction name]];
    /* Get beep count from action */
    [self setBeepCount:[sparkAction beepCount]];
  } else {
    /* Default beep count */
    [self setBeepCount:5];
  }
}

- (NSAlert *)sparkEditorShouldConfigureAction {
  /* If plugIn configuration require something the user don't set, tell him here by returning a NSAlert */
  // Here we check if user has correctly set MyAction parameters. Icon can be nil and name is checked later, so you can set it on -configureAction.
  if (beepCount < 1 || beepCount > 9) {
    return [NSAlert alertWithMessageText:@"Beep Count is not valid"
                           defaultButton:@"OK"
                         alternateButton:nil
                             otherButton:nil
               informativeTextWithFormat:@"Beep Count must be more than 0 and less than 10."];
  }
  return nil;
}

/* You need configure the new Action or modifie the existing Action here */
- (void)configureAction {
  // [super configureAction] set action Name with [self name] and action icon with [self icon]
  // If you want to use custom name and custom icon, you don't have to invoke it.
  /* As we manage name directly, we don't call super methods */
  
  /* Get the current Action */
  MyAction *myAction = [self sparkAction];
  
  [myAction setIcon:[self icon]];
  // no need to check beepCount value here. -configureAction is called only if -sparkEditorShouldConfigureAction: return nil.
  [myAction setBeepCount:beepCount];
  /* Set Description */
  [myAction setShortDescription:[NSString stringWithFormat:@"Beep %i times", beepCount]];
}

#pragma mark -
#pragma mark Plugin Specifics methods

- (int)beepCount {
  return beepCount;
}
- (void)setBeepCount:(int)newBeepCount {
  beepCount = newBeepCount;
}

@end
