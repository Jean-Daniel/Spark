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
    ks_hotkey = [[HKHotKey alloc] init];
    unsigned hotkey = [[plist objectForKey:@"KSHotKey"] unsignedIntValue];
    SparkDecodeHotKey(ks_hotkey, hotkey);
  }
  return self;
}

/* Use to transform and record you HotKey in a file. The dictionary returned must contains only PList objects 
See the PropertyList documentation to know more about it */
- (NSMutableDictionary *)propertyList {
  NSMutableDictionary *dico = [super propertyList];
  unsigned hotkey = SparkEncodeHotKey(ks_hotkey);
  [dico setValue:SKUInt(hotkey) forKey:@"KSHotKey"];
  return dico;
}

- (void)dealloc {
  [ks_hotkey release];
  [super dealloc];
}

- (SparkAlert *)check {
  return nil;
}

/* This is the main method (the entry point) of a Hot Key. Actually, the alert returned isn't display but maybe in a next version 
so you can return one */
- (SparkAlert *)execute {
  SparkAlert *alert = [self check];
  if (alert == nil) {
    [ks_hotkey sendHotKey];
  }
  return alert;
}


/****************************************************************************************
*                           Keystroke Hot Key specific Methods							*
****************************************************************************************/

- (HKHotKey *)hotkey {
  return ks_hotkey;
}

- (void)setHotkey:(HKHotKey *)aKey {
  if (ks_hotkey != aKey) {
    [ks_hotkey release];
    ks_hotkey = [aKey retain];
  }
}

@end
