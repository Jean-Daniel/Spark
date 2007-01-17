/*
 *  SparkKit.m
 *  SparkKit
 *
 *  Created by Black Moon Team.
 *  Copyright (c) 2004 - 2007 Shadow Lab. All rights reserved.
 */

#import <SparkKit/SparkKit.h>

#import <ShadowKit/SKFunctions.h>

NSString * const kSparkFolderName = @"Spark";

NSString * const kSparkEditorHFSCreator = @"Sprk";
NSString * const kSparkDaemonHFSCreator = @"SprS";

NSString * const kSparkKitBundleIdentifier = @"org.shadowlab.SparkKit";
NSString * const kSparkDaemonBundleIdentifier = @"org.shadowlab.SparkDaemon";

/* Spark Core preferences */
#if defined(DEBUG)
NSString * const kSparkPreferencesIdentifier = @"org.shadowlab.Spark-debug";
#else
NSString * const kSparkPreferencesIdentifier = @"org.shadowlab.Spark";
#endif

OSType kSparkFinderCreatorType;
const OSType kSparkEditorHFSCreatorType = 'Sprk';
const OSType kSparkDaemonHFSCreatorType = 'SprS';

static __attribute__((constructor)) 
void __SparkInitializeLibrary() {
  kSparkFinderCreatorType = 'MACS';
  CFStringRef str = CFPreferencesCopyAppValue(CFSTR("SparkFinderSignature"), (CFStringRef)kSparkPreferencesIdentifier);
  if (str) {
    if (!CFStringGetTypeID() == CFGetTypeID(str)) {
      CFPreferencesSetAppValue(CFSTR("SparkFinderSignature"), NULL, (CFStringRef)kSparkPreferencesIdentifier);
    } else {
      OSType type = SKGetOSTypeFromString(str);
      if (type && type != kUnknownType)
        kSparkFinderCreatorType = type;
    }
    CFRelease(str);
  }
}
