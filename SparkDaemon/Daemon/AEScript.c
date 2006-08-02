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

#include <ShadowKit/ShadowAEUtils.h>

OSStatus SDGetEditorIsTrapping(Boolean *trapping) {
  check(trapping);
  *trapping = FALSE;
  ProcessSerialNumber psn;
  OSStatus err = GetFrontProcess(&psn);
  require_noerr(err, bail);
  
  /* Check front process */
  ProcessInfoRec info;
  info.processInfoLength = sizeof(info);
  info.processName = NULL;
  info.processAppSpec = NULL;
  err = GetProcessInformation(&psn, &info);
  require_noerr(err, bail);
  
  /* If Spark Editor is the front process, send apple event */
  if (kSparkHFSCreatorType == info.processSignature) {
    AEDesc theEvent;
    ShadowAENullDesc(&theEvent);
    err = ShadowAECreateEventWithTargetProcess(&psn, kAECoreSuite, kAEGetData, &theEvent);
    require_noerr(err, bail);
    
    err = ShadowAEAddPropertyObjectSpecifier(&theEvent, keyDirectObject, typeProperty, kSparkEditorIsTrapping, NULL);
    require_noerr(err, fevent);
    
    err = ShadowAEAddMagnitude(&theEvent);
    require_noerr(err, fevent);
    
    
    err = ShadowAESendEventReturnBoolean(&theEvent, trapping);
    /* Release Apple event descriptor */
fevent:
      ShadowAEDisposeDesc(&theEvent);
  }
  
bail:
  return err;
}

OSStatus SDSendStateToEditor(DaemonStatus state) {
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
