/*
 *  SparkKit.m
 *  SparkKit
 *
 *  Created by Black Moon Team.
 *  Copyright (c) 2004 - 2006 Shadow Lab. All rights reserved.
 *
 */

#import <SparkKit/SparkKit.h>

#import <ShadowKit/SKFunctions.h>

NSString * const kSparkFolderName = @"Spark";

NSString * const kSparkEditorHFSCreator = @"Sprk";
NSString * const kSparkDaemonHFSCreator = @"SprS";

/* Spark Core preferences */
#if defined(DEBUG)
NSString * const kSparkBundleIdentifier = @"org.shadowlab.Spark-debug";
#else
NSString * const kSparkBundleIdentifier = @"org.shadowlab.Spark";
#endif

NSString * const kSparkKitBundleIdentifier = @"org.shadowlab.SparkKit";
NSString * const kSparkDaemonBundleIdentifier = @"org.shadowlab.SparkDaemon";

OSType kSparkFinderCreatorType;
const OSType kSparkEditorHFSCreatorType = 'Sprk';
const OSType kSparkDaemonHFSCreatorType = 'SprS';

static __attribute__((constructor)) 
void __SparkInitializeLibrary() {
  kSparkFinderCreatorType = 'MACS';
  CFStringRef str = CFPreferencesCopyAppValue(CFSTR("SparkFinderSignature"), (CFStringRef)kSparkBundleIdentifier);
  if (str) {
    if (!CFStringGetTypeID() == CFGetTypeID(str)) {
      CFPreferencesSetAppValue(CFSTR("SparkFinderSignature"), NULL, (CFStringRef)kSparkBundleIdentifier);
    } else {
      OSType type = SKGetOSTypeFromString(str);
      if (type && type != kUnknownType)
        kSparkFinderCreatorType = type;
    }
    CFRelease(str);
  }
}
