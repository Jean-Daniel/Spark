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

#pragma mark -
#pragma mark Utilities
SparkContext SparkGetCurrentContext() {
  static SparkContext ctxt = 0xffffffff;
  if (0xffffffff == ctxt) {
    if ([[[NSBundle mainBundle] bundleIdentifier] isEqualToString:kSparkDaemonBundleIdentifier])
      ctxt = kSparkDaemonContext;
    else
      ctxt = kSparkEditorContext;
  }
  return ctxt;
}

void SparkLaunchEditor() {
  switch (SparkGetCurrentContext()) {
    case kSparkEditorContext:
      [NSApp activateIgnoringOtherApps:NO];
      break;
    case kSparkDaemonContext: {
      NSString *sparkPath = [[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:@"../../../"];
      [[NSWorkspace sharedWorkspace] launchApplication:sparkPath];
    }
      break;
  }
}

