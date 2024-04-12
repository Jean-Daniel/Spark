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

#import <SparkKit/SparkServerProtocol.h>
#import <SparkKit/SparkLibrarySynchronizer.h>

#import <WonderBox/WonderBox.h>

#ifndef DEVELOPMENT_TEAM
#error DEVELOPMENT_TEAM required
#endif

#define xstr(a) str(a)
#define str(a) #a

NSString * const kSparkErrorDomain = @"com.xenonium.SparkErrorDomain";

NSString * const kSparkFolderName = @"Spark";

NSString * const kSparkKitBundleIdentifier = @"com.xenonium.SparkKit";

NSString * const kSparkEditorBundleIdentifier = @"com.xenonium.Spark";

NSString * const kSparkGroupIdentifier = @"" xstr(DEVELOPMENT_TEAM) ".com.xenonium.Spark";

#if defined(DEBUG)
NSString * const kSparkDaemonBundleIdentifier = @"" xstr(DEVELOPMENT_TEAM) ".com.xenonium.Spark.agent.debug";
#else
NSString * const kSparkDaemonBundleIdentifier = @"" xstr(DEVELOPMENT_TEAM) ".com.xenonium.Spark.agent";
#endif

NSXPCInterface *SparkAgentInterface(void) {
  NSXPCInterface *interface = [NSXPCInterface interfaceWithProtocol:@protocol(SparkAgent)];
  [interface setInterface:SparkEditorInterface()
              forSelector:@selector(register:)
            argumentIndex:0
                  ofReply:NO];
  return interface;
}

NSXPCInterface *SparkEditorInterface(void) {
  NSXPCInterface *interface = [NSXPCInterface interfaceWithProtocol:@protocol(SparkEditor)];
  [interface setInterface:[SparkLibrarySynchronizer sparkLibraryInterface]
              forSelector:@selector(setLibrary:uuid:)
            argumentIndex:0
                  ofReply:NO];
  return interface;
}

// MARK: -
const OSType kSparkEditorSignature = 'Sprk';
const OSType kSparkDaemonSignature = 'SprS';

NSString * const kSparkFinderBundleIdentifier = @"com.apple.finder";

NSBundle *SparkKitBundle(void) {
  return [NSBundle bundleWithIdentifier:kSparkKitBundleIdentifier];
}

NSUserDefaults *SparkUserDefaults(void) {
  static NSUserDefaults *sparkUserDefaults = nil;
  if (!sparkUserDefaults)
    sparkUserDefaults = [[NSUserDefaults alloc] initWithSuiteName:kSparkGroupIdentifier];
  return sparkUserDefaults;
}

