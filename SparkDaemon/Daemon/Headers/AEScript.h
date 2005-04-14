/*
 *  AEScript.h
 *  Spark Server
 *
 *  Created by Fox on Tue Dec 16 2003.
 *  Copyright (c) 2004 Shadow Lab. All rights reserved.
 *
 */

#include <Carbon/Carbon.h>
#include "SparkServerProtocol.h"

OSStatus GetEditorIsTrapping(Boolean *trapping);
OSStatus SendStateToEditor(DaemonStatus state);
