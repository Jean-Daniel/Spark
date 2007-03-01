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
  if ([KeyStrokeAction class] == self) {
    [self setVersion:0x100];
  }
}

- (id)init {
  if (self = [super init]) {
    ks_hotkeys = [[NSMutableArray alloc] init];
  }
  return self;
}

/* initFromPropertyList is called when a Key is loaded. You must call [super initFromPropertyList:plist].
Get all values you set in the -propertyList method et configure your Hot Key */
- (id)initWithSerializedValues:(NSDictionary *)plist {
  if (self = [super initWithSerializedValues:plist]) {
    ks_hotkeys = [[NSMutableArray alloc] init];
    NSNumber *raw;
    NSEnumerator *raws = [[plist objectForKey:@"KSHotKeys"] objectEnumerator];
    while (raw = [raws nextObject]) {
      HKHotKey *key = [HKHotKey hotkey];
      [key setRawkey:[raw unsignedLongLongValue]];
      [ks_hotkeys addObject:key];
    }
  }
  return self;
}

/* Use to transform and record you HotKey in a file. The dictionary returned must contains only PList objects 
See the PropertyList documentation to know more about it */
- (BOOL)serialize:(NSMutableDictionary *)plist {
  if ([super serialize:plist]) {
    NSMutableArray *raws = [NSMutableArray array];
    HKHotKey *key;
    NSEnumerator *keys = [ks_hotkeys objectEnumerator];
    while (key = [keys nextObject]) {
      if ([key isValid])
        [raws addObject:SKLongLong([key rawkey])];
    }
    [plist setObject:raws forKey:@"KSHotKeys"];
    return YES;
  }
  return NO;
}

- (void)dealloc {
  [ks_hotkeys release];
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
    HKHotKey *key;
    NSEnumerator *keys = [ks_hotkeys objectEnumerator];
    while (key = [keys nextObject]) {
      [key sendKeystroke];
    }
  }
  return alert;
}


/****************************************************************************************
*                           Keystroke Hot Key specific Methods							*
****************************************************************************************/
- (NSArray *)hotkeys {
  return ks_hotkeys;
}
- (void)setHotkeys:(NSArray *)keys {
  [ks_hotkeys removeAllObjects];
  [ks_hotkeys addObjectsFromArray:keys];
}

@end
