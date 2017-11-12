/*
 *  SparkAppleScriptSuite.h
 *  SparkKit
 *
 *  Created by Black Moon Team.
 *  Copyright (c) 2004 - 2007 Shadow Lab. All rights reserved.
 */

#if !defined(__SPARK_APPLESCRIPT_SUITE_H)
#define __SPARK_APPLESCRIPT_SUITE_H 1

#include <SparkKit/SparkKit.h>

typedef NS_ENUM(OSType, SparkDaemonStatus) {
  kSparkDaemonStatusError = 'sErr',
  kSparkDaemonStatusEnabled = 'sEna',
  kSparkDaemonStatusDisabled = 'sDis',
  kSparkDaemonStatusShutDown = 'sSht',
};

enum {
  kSparkEditorScriptSuite = 'Sprk',
  kSparkEditorOpenHelp = 'Help',
  kSparkEditorHelpPage = 'page',
  kSparkEditorIsTrapping = 'Trap',
  kSparkEditorDaemonStatus = 'srvS'
};

enum {
  kSparkDaemonStatusType = 'dast',
};

#pragma mark Daemon/Editor Constants
SPARK_EXPORT
NSString * const SparkDaemonStatusKey;
SPARK_EXPORT
NSString * const SparkDaemonStatusDidChangeNotification;

@interface NSNotification (SparkDaemonStatus)
@property(readonly) SparkDaemonStatus sparkDaemonStatus;
@end

#endif /* __SPARK_APPLESCRIPT_SUITE_H */
