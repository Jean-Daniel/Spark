/*
 *  EDSparkle.m
 *  Emerald
 *
 *  Created by Jean-Daniel Dupas.
 *  Copyright © 2009 - 2010 Ninsight. All rights reserved.
 */

#import "SparkleDelegate.h"

#import WBHEADER(WBVersionFunctions.h)

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

  WBLogWarning(@"invalid build number: %@ / %@. Try version parser instead", versionA, versionB);

  // maybe this is not build number after all, try to parse them as full version
  UInt64 via = WBVersionGetNumberFromString((CFStringRef)versionA);
  UInt64 vib = WBVersionGetNumberFromString((CFStringRef)versionB);
  if (kWBVersionInvalid != via || kWBVersionInvalid != vib)
    return via > vib ? NSOrderedDescending : via < vib ? NSOrderedAscending : NSOrderedSame;

  WBLogWarning(@"invalid version number: %@ / %@", versionA, versionB);
  return NSOrderedSame;
}

@end


