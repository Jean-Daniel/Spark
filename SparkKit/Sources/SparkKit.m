/*
 *  SparkKit.m
 *  SparkKit
 *
 *  Created by Black Moon Team.
 *  Copyright (c) 2004 - 2007 Shadow Lab. All rights reserved.
 */

#import <SparkKit/SparkKit.h>
/* MUST be include for SparkDaemonStatusKey */
#import <SparkKit/SparkAppleScriptSuite.h>

#import <SparkKit/SparkPreferences.h>

#import <ShadowKit/SKFunctions.h>
#import <ShadowKit/SKLSFunctions.h>

NSString * const kSparkErrorDomain = @"org.shadowlab.SparkErrorDomain";

NSString * const kSparkFolderName = @"Spark";

NSString * const kSparkEditorHFSCreator = @"Sprk";
NSString * const kSparkDaemonHFSCreator = @"SprS";

NSString * const kSparkKitBundleIdentifier = @"org.shadowlab.SparkKit";
NSString * const kSparkDaemonBundleIdentifier = @"org.shadowlab.SparkDaemon";

#pragma mark Distributed Notifications
CFStringRef const SparkDaemonStatusKey = CFSTR("SparkDaemonStatusKey");
CFStringRef const SparkDaemonStatusDidChangeNotification = CFSTR("SparkDaemonStatusDidChange");

OSType kSparkFinderSignature;
const OSType kSparkEditorSignature = 'Sprk';
const OSType kSparkDaemonSignature = 'SprS';

static __attribute__((constructor)) 
void __SparkInitializeLibrary() {
  kSparkFinderSignature = 'MACS';
  NSString *str = SparkPreferencesGetValue(@"SparkFinderSignature", SparkPreferencesFramework);
  if (str) {
    if (![str isKindOfClass:[NSString class]]) {
      SparkPreferencesSetValue(@"SparkFinderSignature", NULL, SparkPreferencesFramework);
    } else {
      OSType sign = SKOSTypeFromString(str);
      if (sign && sign != kUnknownType && SKLSFindApplicationForSignature(sign))
        kSparkFinderSignature = sign;
    }
  }
}
