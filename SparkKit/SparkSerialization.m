//
//  SparkSerialization.m
//  SparkKit
//
//  Created by Grayfox on 16/09/04.
//  Copyright 2004 Shadow Lab. All rights reserved.
//

#import <SparkKit/SparkSerialization.h>

static NSString * const kSparkSerializationIsaKey = @"isa";
static NSString * const kSparkSerializationClassKey = @"Class";

NSDictionary *SparkSerializeObject(NSObject<SparkSerialization> *object) {
  NSCParameterAssert([object conformsToProtocol:@protocol(SparkSerialization)]);
  
  id plist = [object propertyList];
  if (plist) {
    [plist setObject:NSStringFromClass([object class]) forKey:kSparkSerializationIsaKey];
  }
  return plist;
}

id SparkDeserializeObject(NSDictionary *plist) {
  id object = nil;
  if (plist) {
    Class class = NSClassFromString([plist objectForKey:kSparkSerializationIsaKey]);
    if (!class) {
      class = NSClassFromString([plist objectForKey:kSparkSerializationClassKey]);
    }
    if (nil != class && [class conformsToProtocol:@protocol(SparkSerialization)]) {
      object = [[class alloc] initFromPropertyList:plist];
      [object autorelease];
    }
  }
  return object;
}
