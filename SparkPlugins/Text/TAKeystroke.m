//
//  TAKeystroke.m
//  Spark Plugins
//
//  Created by Jean-Daniel Dupas on 17/10/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "TAKeystroke.h"

@implementation TAKeystroke {
@private
  UniChar ta_char;
  HKKeycode ta_code;
  HKModifier ta_modifier;

  NSString *_shortcut;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
	[aCoder encodeInteger:ta_code forKey:@"keycode"];
  [aCoder encodeInteger:ta_char forKey:@"character"];
  [aCoder encodeInteger:ta_modifier forKey:@"modifier"];
}

- (id)initWithCoder:(NSCoder *)aCoder {
	if (self = [super init]) {
    ta_code = (HKKeycode)[aCoder decodeIntegerForKey:@"keycode"];
    ta_char = (UniChar)[aCoder decodeIntegerForKey:@"character"];
    ta_modifier = (HKModifier)[aCoder decodeIntegerForKey:@"modifier"];
  }
  return self;
}

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

#pragma mark -
- (UInt64)rawKey {
  return HKHotKeyPackKeystoke(ta_code, ta_modifier, ta_char);
}

- (NSString *)shortcut {
  if (!_shortcut) {
    _shortcut = [HKKeyMap stringRepresentationForCharacter:ta_char modifiers:ta_modifier];
  }
  return _shortcut;
}

- (void)sendKeystroke:(CGEventSourceRef)src latency:(useconds_t)latency {
  HKEventPostKeystroke(ta_code, ta_modifier, src, latency);
}

@end
