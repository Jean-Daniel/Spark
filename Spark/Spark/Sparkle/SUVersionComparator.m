/*
 *  EDSparkle.m
 *  Emerald
 *
 *  Created by Jean-Daniel Dupas.
 *  Copyright © 2009 - 2010 Ninsight. All rights reserved.
 */

#import "SparkleDelegate.h"

#import <WonderBox/WonderBox.h>

@implementation Spark (SparkleSupport)

- (NSComparisonResult)compareVersion:(NSString *)versionA toVersion:(NSString *)versionB {
  if (!versionA)
    return !versionB ? NSOrderedSame : NSOrderedAscending;
  if (!versionB)
    return NSOrderedDescending;

  // BB-TV uses build number for update, not marketing version, so use doubleValue
  double va = [versionA doubleValue];
  double vb = [versionB doubleValue];

  if (fnonzero(va) && fnonzero(vb))
    return va > vb ? NSOrderedDescending : va < vb ? NSOrderedAscending : NSOrderedSame;

  spx_log("invalid build number: %@ / %@. Try version parser instead", versionA, versionB);

  // maybe this is not build number after all, try to parse them as full version
  UInt64 via = WBVersionGetNumberFromString(SPXNSToCFString(versionA));
  UInt64 vib = WBVersionGetNumberFromString(SPXNSToCFString(versionB));
  if (kWBVersionInvalid != via || kWBVersionInvalid != vib)
    return via > vib ? NSOrderedDescending : via < vib ? NSOrderedAscending : NSOrderedSame;

  spx_log("invalid version number: %@ / %@", versionA, versionB);
  return NSOrderedSame;
}

@end


