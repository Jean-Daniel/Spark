/*
 *  SparkFunctions.m
 *  SparkKit
 *
 *  Created by Black Moon Team.
 *  Copyright (c) 2004 - 2007 Shadow Lab. All rights reserved.
 */

#import <SparkKit/SparkFunctions.h>

#import <SparkKit/SparkAlert.h>
#import <SparkKit/SparkPrivate.h>
#import <SparkKit/SparkMultipleAlerts.h>

#import <ShadowKit/SKIconView.h>
#import <ShadowKit/SKImageView.h>
#import <ShadowKit/SKBezelItem.h>
#import <ShadowKit/SKAEFunctions.h>
#import <ShadowKit/SKProcessFunctions.h>

#pragma mark Utilities
void SparkLaunchEditor() {
  switch (SparkGetCurrentContext()) {
    case kSparkEditorContext:
      [NSApp activateIgnoringOtherApps:NO];
      break;
    case kSparkDaemonContext: {
      ProcessSerialNumber psn = SKProcessGetProcessWithSignature(kSparkEditorHFSCreatorType);
      if (psn.lowLongOfPSN != kNoProcess) {
        SetFrontProcess(&psn);
        SKAESendSimpleEvent(kSparkEditorHFSCreatorType, kCoreEventClass, kAEReopenApplication);
      } else {
#if defined(DEBUG)
        NSString *sparkPath = @"./Spark.app";
        [[NSWorkspace sharedWorkspace] openFile:sparkPath];
#else
        NSString *sparkPath = [[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:@"../../../"];
        [[NSWorkspace sharedWorkspace] launchApplication:sparkPath];
#endif   
      }
    }
      break;
  }
}

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

#pragma mark Alerts
void SparkDisplayAlerts(NSArray *items) {
  if ([items count] == 1) {
    SparkAlert *alert = [items objectAtIndex:0];
    NSString *ok = NSLocalizedStringFromTableInBundle(@"OK", nil, [NSBundle bundleWithIdentifier:kSparkKitBundleIdentifier] , @"OK");
    
    NSString *other = [alert hideSparkButton] ? nil : NSLocalizedStringFromTableInBundle(@"LAUNCH_SPARK_BUTTON", nil,
                                                                                  [NSBundle bundleWithIdentifier:kSparkKitBundleIdentifier],
                                                                                  @"Open Spark Alert Button");
    [NSApp activateIgnoringOtherApps:YES];
    if (NSRunAlertPanel([alert messageText],[alert informativeText], ok, nil, other) == NSAlertOtherReturn) {
      SparkLaunchEditor();
    }
  }
  else if ([items count] > 1) {
    id alerts = [[SparkMultipleAlerts alloc] initWithAlerts:items];
    [alerts showAlerts];
    [alerts autorelease];
  }  
}

#pragma mark Notifications

static 
SKBezelItem *_SparkNotifiationSharedItem() {
  static SKBezelItem *_shared = nil;
  if (!_shared) {
    _shared = [[SKBezelItem alloc] initWithContent:nil];
    [_shared setAdjustSize:NO];
  }
  return _shared;
}

static 
SKIconView *_SparkNotificationSharedIconView() {
  static SKIconView *_shared = nil;
  if (!_shared) {
    _shared = [[SKIconView alloc] initWithFrame:NSMakeRect(0, 0, 128, 128)];
  }
  return _shared;
}

static 
NSImageView *_SparkNotificationSharedImageView() {
  static SKImageView *_shared = nil;
  if (!_shared) {
    _shared = [[SKImageView alloc] initWithFrame:NSMakeRect(0, 0, 128, 128)];
    [_shared setEditable:NO];
    [_shared setImageFrameStyle:NSImageFrameNone];
    [_shared setImageAlignment:NSImageAlignCenter];
    [_shared setImageScaling:NSScaleProportionally];
    [_shared setImageInterpolation:NSImageInterpolationHigh];
  }
  return _shared;
}

void SparkNotificationDisplay(NSView *view, float delay) {
  SKBezelItem *item = _SparkNotifiationSharedItem();
  [item setContent:view];
  [item setDelay:delay];
  [item display:nil];
}

void SparkNotificationDisplayIcon(IconRef icon, float delay) {
  SKIconView *view = _SparkNotificationSharedIconView();
  [view setIconRef:icon];
  SparkNotificationDisplay(view, delay);
}

void SparkNotificationDisplayImage(NSImage *anImage, float delay) {
  NSImageView *view = _SparkNotificationSharedImageView();
  [view setImage:anImage];
  SparkNotificationDisplay(view, delay);
}

void SparkNotificationDisplaySystemIcon(OSType icon, float delay) {
  SKIconView *view = _SparkNotificationSharedIconView();
  [view setSystemIcon:icon];
  SparkNotificationDisplay(view, delay);
}
