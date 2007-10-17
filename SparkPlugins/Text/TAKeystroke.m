//
//  TAKeystroke.m
//  Spark Plugins
//
//  Created by Jean-Daniel Dupas on 17/10/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "TAKeystroke.h"

@implementation TAKeystroke

- (id)initWithKeycode:(HKKeycode)keycode character:(UniChar)character modifier:(HKModifier)modifier {
  if (self = [super init]) {
    ta_code = keycode;
    ta_char = character;
    ta_modifier = modifier;
  }
  return self;
}

- (id)initFromRawKey:(UInt64)rawKey {
  if (self = [super init]) {
    HKHotKeyUnpackKeystoke(rawKey, &ta_code, &ta_modifier, &ta_char);
  }
  return self;
}

- (void)dealloc {
  [ta_desc release];
  [super dealloc];
}

#pragma mark -
- (UInt64)rawKey {
  return HKHotKeyPackKeystoke(ta_code, ta_modifier, ta_char);
}

- (NSString *)shortcut {
  if (!ta_desc) {
    ta_desc = [HKMapGetStringRepresentationForCharacterAndModifier(ta_char, ta_modifier) retain];
  }
  return ta_desc;
}

- (void)sendKeystroke:(CGEventSourceRef)src {
  HKEventPostKeystroke(ta_code, ta_modifier, src);
}

@end
