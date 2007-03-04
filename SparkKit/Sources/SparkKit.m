/*
 *  SparkKit.m
 *  SparkKit
 *
 *  Created by Black Moon Team.
 *  Copyright (c) 2004 - 2007 Shadow Lab. All rights reserved.
 */

#import <SparkKit/SparkKit.h>

#import <SparkKit/SparkAppleScriptSuite.h>

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

/* Spark Core preferences */
#if defined(DEBUG)
NSString * const kSparkPreferencesIdentifier = @"org.shadowlab.Spark-debug";
#else
NSString * const kSparkPreferencesIdentifier = @"org.shadowlab.Spark";
#endif

OSType kSparkFinderSignature;
const OSType kSparkEditorSignature = 'Sprk';
const OSType kSparkDaemonSignature = 'SprS';

static __attribute__((constructor)) 
void __SparkInitializeLibrary() {
  kSparkFinderSignature = 'MACS';
  CFStringRef str = CFPreferencesCopyAppValue(CFSTR("SparkFinderSignature"), (CFStringRef)kSparkPreferencesIdentifier);
  if (str) {
    if (!CFStringGetTypeID() == CFGetTypeID(str)) {
      CFPreferencesSetAppValue(CFSTR("SparkFinderSignature"), NULL, (CFStringRef)kSparkPreferencesIdentifier);
    } else {
      OSType sign = SKGetOSTypeFromString(str);
      if (sign && sign != kUnknownType && SKLSFindApplicationForSignature(sign))
        kSparkFinderSignature = sign;
    }
    CFRelease(str);
  }
}
