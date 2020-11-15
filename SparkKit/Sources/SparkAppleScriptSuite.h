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
  kSparkDaemonStatusStopped = 'sSht',
  // Started bu either enabled or disabled
  kSparkDaemonStatusEnabled = 'sEna',
  kSparkDaemonStatusDisabled = 'sDis',
  kSparkDaemonStatusError = 'sErr',
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

#endif /* __SPARK_APPLESCRIPT_SUITE_H */
