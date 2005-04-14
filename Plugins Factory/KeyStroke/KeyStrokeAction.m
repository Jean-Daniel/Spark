//
//  KeyStrokeAction.m
//  Spark
//
//  Created by Fox on Sun Feb 15 2004.
//  Copyright (c) 2004 Shadow Lab. All rights reserved.
//

#import "KeyStrokeAction.h"
#import "KeyStrokeActionPlugin.h"

@implementation KeyStrokeAction

+ (void)initialize {
  static BOOL tooLate = NO;
  if (!tooLate) {
    [self setVersion:0x100];
    tooLate = YES;
  }
}

/* initFromPropertyList is called when a Key is loaded. You must call [super initFromPropertyList:plist].
Get all values you set in the -propertyList method et configure your Hot Key */
- (id)initFromPropertyList:(id)plist {
  if (self = [super initFromPropertyList:plist]) {
    [self setKeystroke:[plist objectForKey:@"Stroke"]];
    [self setKeyModifier:[[plist objectForKey:@"KeyModifier"] intValue]];
  }
  return self;
}

/* Use to transform and record you HotKey in a file. The dictionary returned must contains only PList objects 
See the PropertyList documentation to know more about it */
- (NSMutableDictionary *)propertyList {
  NSMutableDictionary *dico = [super propertyList];
  [dico setObject:SKInt([self keyModifier]) forKey:@"KeyModifier"];
  [dico setObject:[self keystroke] forKey:@"Stroke"];
  return dico;
}

- (SparkAlert *)check {
  return nil;
}

/* This is the main method (the entry point) of a Hot Key. Actually, the alert returned isn't display but maybe in a next version 
so you can return one */
- (SparkAlert *)execute {
  NSLog(@"Execute");
  SparkAlert *alert = [self check];
  if (alert == nil) {
    [self launchSystemEvent];
    AppleEvent theEvent;
    ShadowAECreateEventWithTargetSignature('sevs', 'prcs', 'kprs', &theEvent);
    OSType sign;
    switch (modifier) {
      case 1:
        sign = kSShiftModifier;
        break;
      case 2:
        sign = kSOptionModifier;
        break;
      case 3:
        sign = kSControlModifier;
        break;
      case 4:
        sign = kSCommandModifier;
        break;
      default:
        sign = 0;
        break;
    }
    AEPutParamPtr(&theEvent, 'faal', typeType, &sign, sizeof(int));
    AEPutParamPtr(&theEvent, keyDirectObject, typeText, [[self keystroke] cString], [[self keystroke] cStringLength]);
    ShadowAEAddMagnitude(&theEvent);
    ShadowAEAddSubject(&theEvent);
    ShadowAESendEventNoReturnValue(&theEvent);
    ShadowAEPrintDesc(&theEvent);
    ShadowAEDisposeDesc(&theEvent);
  }
  return alert;
}


/****************************************************************************************
*                           Keystroke Hot Key specific Methods							*
****************************************************************************************/

- (id)keystroke {
  return [[keystroke retain] autorelease];
}

- (void)setKeystroke:(id)newKeystroke {
  if (keystroke != newKeystroke) {
    [keystroke release];
    keystroke = [newKeystroke copy];
  }
}

- (int)keyModifier {
  return modifier;
}

- (void)setKeyModifier:(int)newModifier {
  if (modifier != newModifier) {
    modifier = newModifier;
  }
}

#define SYSTEM_EVENT		@"/System/Library/CoreServices/System Events.app"
- (void)launchSystemEvent {
  ProcessSerialNumber p = SKGetProcessWithSignature('sevs');
  if ( (p.highLongOfPSN == kNoProcess) && (p.lowLongOfPSN == kNoProcess)) {
    [[NSWorkspace sharedWorkspace] launchApplication:SYSTEM_EVENT showIcon:NO autolaunch:NO];
  }
}

@end
