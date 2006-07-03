/*
 *  AEScript.c
 *  Spark Server
 *
 *  Created by Fox on Tue Dec 16 2003.
 *  Copyright (c) 2004 Shadow Lab. All rights reserved.
 *
 */

#include "AEScript.h"

#include <SparkKit/SparkKit.h>
#include "SparkAppleScriptSuite.h"
#include <ApplicationServices/ApplicationServices.h>

OSStatus GetEditorIsTrapping(Boolean *trapping) {
  ProcessSerialNumber psn;
  if (noErr == GetFrontProcess(&psn)) {
    ProcessInfoRec info;
    info.processInfoLength = sizeof(info);
    info.processName = NULL;
    info.processAppSpec = NULL;
    if (noErr == GetProcessInformation(&psn, &info) && kSparkHFSCreatorType != info.processSignature) {
      if (trapping) *trapping = false;
      return noErr;
    }
  }
  OSStatus err = noErr;
  AEDesc theEvent;
  ShadowAENullDesc(&theEvent);
  err = ShadowAECreateEventWithTargetSignature(kSparkHFSCreatorType, kAECoreSuite, kAEGetData, &theEvent);
  if (noErr == err) {
    err = ShadowAEAddPropertyObjectSpecifier(&theEvent, keyDirectObject, typeProperty, kSparkEditorIsTrapping, NULL);
  }
  if (noErr == err) {
    err = ShadowAEAddMagnitude(&theEvent);
  }
  if (noErr == err) {
    err = ShadowAESendEventReturnBoolean(&theEvent, trapping);
    ShadowAEDisposeDesc(&theEvent);
  }
  return err;
}

OSStatus SendStateToEditor(DaemonStatus state) {
  OSStatus err = noErr;
  AEDesc theEvent;
  ShadowAENullDesc(&theEvent);
  
  err = ShadowAECreateEventWithTargetSignature(kSparkHFSCreatorType, kAECoreSuite, kAESetData, &theEvent);
  if (noErr == err) {
    err = ShadowAEAddPropertyObjectSpecifier(&theEvent, keyDirectObject, typeProperty, kSparkEditorDaemonStatus, NULL);
  }
  if (noErr == err) {
    err = ShadowAEAddSInt32(&theEvent, keyAEData, state);
  }
  if (noErr == err) {
    err = ShadowAEAddMagnitude(&theEvent);
  }
  if (noErr == err) {
    err = ShadowAESendEventNoReply(&theEvent);
  }
  ShadowAEDisposeDesc(&theEvent);
  return err;
}
