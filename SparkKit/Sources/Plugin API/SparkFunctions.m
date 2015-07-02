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

#import <WonderBox/WBIconView.h>
#import <WonderBox/WBImageView.h>
#import <WonderBox/WBBezelItem.h>
#import <WonderBox/WBAEFunctions.h>

#pragma mark Utilities
bool SparkEditorIsRunning(void) {
  NSRunningApplication *app = [NSRunningApplication runningApplicationsWithBundleIdentifier:kSparkEditorBundleIdentifier].firstObject;
  return app != nil;
}

bool SparkDaemonIsRunning(void) {
  NSRunningApplication *app = [NSRunningApplication runningApplicationsWithBundleIdentifier:kSparkDaemonBundleIdentifier].firstObject;
  return app != nil;
}

void SparkLaunchEditor(void) {
  switch (SparkGetCurrentContext()) {
    default:
      spx_abort("undefined context");
    case kSparkContext_Editor:
      [NSApp activateIgnoringOtherApps:NO];
      break;
    case kSparkContext_Daemon: {
      NSRunningApplication *editor = [NSRunningApplication runningApplicationsWithBundleIdentifier:kSparkEditorBundleIdentifier].firstObject;
      if (editor) {
        [editor activateWithOptions:NSApplicationActivateIgnoringOtherApps];
        WBAESendSimpleEventToBundle(SPXNSToCFString(kSparkEditorBundleIdentifier), kCoreEventClass, kAEReopenApplication);
      } else {
#if defined(DEBUG)
        NSURL *spark = [NSURL fileURLWithPath:@"./Spark.app"];
#else
        NSURL *spark = [[[NSBundle mainBundle] bundleURL] URLByAppendingPathComponent:@"../../../"];
#endif
        if ([NSThread isMainThread]) {
          [[NSWorkspace sharedWorkspace] launchApplicationAtURL:spark options:NSWorkspaceLaunchDefault configuration:nil error:NULL];
        } else {
          dispatch_async(dispatch_get_main_queue(), ^{
            [[NSWorkspace sharedWorkspace] launchApplicationAtURL:spark options:NSWorkspaceLaunchDefault configuration:nil error:NULL];
          });
        }
      }
    }
      break;
  }
}

SparkContext SparkGetCurrentContext(void) {
  static SparkContext ctxt = kSparkContext_Undefined;
  if (ctxt != kSparkContext_Undefined)
    return ctxt;

  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    if (kSparkContext_Undefined == ctxt) {
      CFBundleRef bundle = CFBundleGetMainBundle();
      if (bundle) {
        CFStringRef ident = CFBundleGetIdentifier(bundle);
        if (ident) {
          if (CFEqual(SPXNSToCFString(kSparkDaemonBundleIdentifier), ident)) {
            ctxt = kSparkContext_Daemon;
          } else {
            ctxt = kSparkContext_Editor;
          }
        }
      }
    }
  });
  return ctxt;
}

#pragma mark Alerts
void SparkDisplayAlerts(NSArray *items) {
  if ([items count] == 1) {
    SparkAlert *alert = [items objectAtIndex:0];
    NSString *ok = NSLocalizedStringFromTableInBundle(@"OK", nil, kSparkKitBundle , @"OK");
    
    NSString *other = [alert hideSparkButton] ? nil : NSLocalizedStringFromTableInBundle(@"LAUNCH_SPARK_BUTTON", nil,
                                                                                         kSparkKitBundle, @"Open Spark Alert Button");
    [NSApp activateIgnoringOtherApps:YES];
    if (NSRunAlertPanel([alert messageText], @"%@", ok, nil, other, [alert informativeText]) == NSAlertOtherReturn) {
      SparkLaunchEditor();
    }
  } else if ([items count] > 1) {
    // FIXME: should we retain the Multiple Alert Controller ?
    SparkMultipleAlerts *alerts = [[SparkMultipleAlerts alloc] initWithAlerts:items];
    [alerts showAlerts];
  }  
}

#pragma mark Notifications

static 
WBBezelItem *_SparkNotifiationSharedItem(void) {
  static WBBezelItem *_shared = nil;
  if (!_shared) {
    _shared = [[WBBezelItem alloc] initWithContent:nil];
    [_shared setAdjustSize:NO];
  }
  return _shared;
}

static 
WBIconView *_SparkNotificationSharedIconView(void) {
  static WBIconView *_shared = nil;
  if (!_shared) {
    _shared = [[WBIconView alloc] initWithFrame:NSMakeRect(0, 0, 128, 128)];
  }
  return _shared;
}

static 
NSImageView *_SparkNotificationSharedImageView(void) {
  static WBImageView *_shared = nil;
  if (!_shared) {
    _shared = [[WBImageView alloc] initWithFrame:NSMakeRect(0, 0, 128, 128)];
    [_shared setEditable:NO];
    [_shared setImageFrameStyle:NSImageFrameNone];
    [_shared setImageAlignment:NSImageAlignCenter];
    [_shared setImageScaling:NSScaleProportionally];
    [_shared setImageInterpolation:NSImageInterpolationHigh];
  }
  return _shared;
}

void SparkNotificationDisplay(NSView *view, CGFloat delay) {
  WBBezelItem *item = _SparkNotifiationSharedItem();
  [item setContent:view];
  [item setDelay:delay];
  [item display:nil];
}

void SparkNotificationDisplayIcon(IconRef icon, CGFloat delay) {
  NSImage *image = [[NSImage alloc] initWithIconRef:icon];
  if (image)
    SparkNotificationDisplayImage(image, delay);
}

void SparkNotificationDisplayImage(NSImage *anImage, CGFloat delay) {
  NSImageView *view = _SparkNotificationSharedImageView();
  [view setImage:anImage];
  SparkNotificationDisplay(view, delay);
}

//void SparkNotificationDisplaySystemIcon(OSType icon, CGFloat delay) {
//  WBIconView *view = _SparkNotificationSharedIconView();
//  [view setSystemIcon:icon];
//  SparkNotificationDisplay(view, delay);
//}
