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

enum {
  kSparkDaemonStatusError = 'sErr',
  kSparkDaemonStatusEnabled = 'sEna',
  kSparkDaemonStatusDisabled = 'sDis',
  kSparkDaemonStatusShutDown = 'sSht',
};
typedef OSType SparkDaemonStatus;

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
CFStringRef const SparkDaemonStatusKey;
SPARK_EXPORT
CFStringRef const SparkDaemonStatusDidChangeNotification;

#if defined(__OBJC__)
SK_INLINE
SparkDaemonStatus SparkDaemonGetStatus(NSNotification *notification) {
  return [[[notification userInfo] objectForKey:(id)SparkDaemonStatusKey] unsignedIntValue];
}
#endif

#endif /* __SPARK_APPLESCRIPT_SUITE_H */
