/*
 *  SparkAppleScriptSuite.h
 *  Spark Editor
 *
 *  Created by Grayfox on 07/10/04.
 *  Copyright 2004 Shadow Lab. All rights reserved.
 *
 */

typedef enum {
  kSparkDaemonStarted = 'strt',
  kSparkDaemonStopped = 'stop',
  kSparkDaemonError = 'erro'
} DaemonStatus;

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

