/*
 *  SparkDaemon.m
 *  SparkServer
 *
 *  Created by Black Moon Team.
 *  Copyright (c) 2004 - 2006 Shadow Lab. All rights reserved.
 */

#import "SparkDaemon.h"

#include <unistd.h>

#import <SparkKit/SparkKit.h>

#import <SparkKit/SparkLibrary.h>
#import <SparkKit/SparkObjectSet.h>
#import <SparkKit/SparkEntryManager.h>
/* Display alert */
#import <SparkKit/SparkActionPlugIn.h>

#import <SparkKit/SparkAlert.h>
#import <SparkKit/SparkAction.h>
#import <SparkKit/SparkTrigger.h>
#import <SparkKit/SparkApplication.h>

#import <ShadowKit/SKFunctions.h>
#import <ShadowKit/SKProcessFunctions.h>

#import <HotKeyToolKit/HotKeyToolKit.h>

#import "AEScript.h"

#if defined (DEBUG)
#warning Debug defined in Spark Daemon!
#include <ShadowKit/SKAEFunctions.h>
#endif

int main(int argc, const char *argv[]) {
#if defined (DEBUG)
  SKAEDebug = YES;
  HKTraceHotKeyEvents = YES;
#endif
  NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
  NSApplicationLoad();
  SparkDaemon *server;
  if (server = [[SparkDaemon alloc] init]) {
    SDSendStateToEditor(kSparkDaemonStarted);
    /* Cleanup pool */
    [pool release];
    pool = [[NSAutoreleasePool alloc] init];
    [server run];
  } else {
    // Run Alert panel ?
    SDSendStateToEditor(kSparkDaemonError);
  }
  [server release];
  
  [pool release];
  return 0;
}

@implementation SparkDaemon

/* Timer callback */
- (void)checkAndLoad:(id)sender {
  [SparkSharedLibrary() readLibrary:nil];
  DLog(@"Library loaded");
//  [self checkActions];
  [self loadTriggers];
  DLog(@"Trigger registred");
}

- (id)init {
  if (self = [super init]) {
    if (![self openConnection]) {
      [self release];
      self = nil; 
    } else {
#if defined (DEBUG)
      [[NSUserDefaults standardUserDefaults] registerDefaults:[NSDictionary dictionaryWithObjectsAndKeys:
        @"1", @"NSScriptingDebugLogLevel",
        nil]];
#endif
      [NSApp setDelegate:self];
      
      int delay = 0;
      /* SparkDaemonDelay */
      ProcessSerialNumber psn = {kNoProcess, kCurrentProcess};
      CFDictionaryRef infos = ProcessInformationCopyDictionary(&psn, kProcessDictionaryIncludeAllInformationMask);
      if (infos) {
        CFNumberRef parent = CFDictionaryGetValue(infos, CFSTR("ParentPSN"));
        if (parent) {
          CFNumberGetValue(parent, kCFNumberLongLongType, &psn);
          
          /* If launch by something that is not Spark Editor */
          OSType sign = SKProcessGetSignature(&psn);
          if (sign != kSparkHFSCreatorType) {
            CFNumberRef value = CFPreferencesCopyAppValue(CFSTR("SparkDaemonDelay"), (CFStringRef)kSparkBundleIdentifier);
            if (value) {
              CFNumberGetValue(value, kCFNumberIntType, &delay);
              CFRelease(value);
            }
          }
        }
        CFRelease(infos);
      }
      if (delay > 0) {
        DLog(@"Delay load: %i", delay);
        [NSTimer scheduledTimerWithTimeInterval:delay
                                         target:self
                                       selector:@selector(checkAndLoad:)
                                       userInfo:nil
                                        repeats:NO];
      } else {
        [self checkAndLoad:nil];
      }
      [[NSNotificationCenter defaultCenter] addObserver:self
                                               selector:@selector(willUpdateTrigger:)
                                                   name:kSparkLibraryWillUpdateObjectNotification
                                                 object:SparkSharedTriggerSet()];
      [[NSNotificationCenter defaultCenter] addObserver:self
                                               selector:@selector(willRemoveTrigger:)
                                                   name:kSparkLibraryWillRemoveObjectNotification
                                                 object:SparkSharedTriggerSet()];
    }
  }
  return self;
}

- (void)dealloc {
  [[NSConnection defaultConnection] invalidate];
  [[NSNotificationCenter defaultCenter] removeObserver:self];
  [super dealloc];
}

- (BOOL)openConnection {
  NSProtocolChecker *checker = [[NSProtocolChecker alloc] initWithTarget:self
                                                                protocol:@protocol(SparkServer)]; 
  NSConnection *connection = [NSConnection defaultConnection];
  [connection setRootObject:checker];
  [checker release];
  if (![connection registerName:kSparkConnectionName]) {
    DLog(@"Error While opening Connection");
    return NO;
  } else {
    DLog(@"Connection OK");
  }
  return YES;
}

- (void)checkActions {
//  BOOL blockAlert = NO;
//  CFBooleanRef blockAlertRef = CFPreferencesCopyAppValue(CFSTR("SDBlockAlertOnLoad"), (CFStringRef)kSparkBundleIdentifier);
//  if (blockAlertRef != nil) {
//    blockAlert = CFBooleanGetValue(blockAlertRef);
//    CFRelease(blockAlertRef);
//  }
//  if (!blockAlert) {
//    id item;
//    NSEnumerator *items = [SparkSharedActionSet() objectEnumerator];
//    NSMutableArray *errors = [[NSMutableArray alloc] init];
//    while (item = [items nextObject]) {
//      id alert = ([item check]);
//      if (alert != nil) {
//        [item setInvalid:YES];
//        [alert setHideSparkButton:NO];
//        [errors addObject:alert];
//      }
//    }
//    SparkDisplayAlerts(errors);
//    [errors release];
//  }
}

- (void)loadTriggers {
  SparkTrigger *trigger;
  SparkEntryManager *manager = SparkSharedManager();
  NSEnumerator *triggers = [SparkSharedTriggerSet() objectEnumerator];
  while (trigger = [triggers nextObject]) {
    @try {
      [trigger setTarget:self];
      [trigger setAction:@selector(executeTrigger:)];
      if ([manager containsActiveEntryForTrigger:[trigger uid]]) {
        [trigger setRegistred:YES];
      }
    } @catch (id exception) {
      SKLogException(exception);
    }
  }
}

- (SparkApplication *)frontApplication {
  SparkApplication *front = nil;
  /* Try signature */
  OSType sign = SKProcessGetFrontProcessSignature();
  if (sign && kUnknownType != sign) {
    SparkApplication *app;
    NSEnumerator *apps = [SparkSharedApplicationSet() objectEnumerator];
    while (app = [apps nextObject]) {
      if ([app signature] == sign) {
        front = app;
        break;
      }
    }
  }
  /* Try bundle identifier */
  if (!front) {
    NSString *bundle = SKProcessGetFrontProcessBundleIdentifier();
    if (bundle) {
      SparkApplication *app;
      NSEnumerator *apps = [SparkSharedApplicationSet() objectEnumerator];
      while (app = [apps nextObject]) {
        if ([[app bundleIdentifier] isEqualToString:bundle]) {
          front = app;
          break;
        }
      }
    }
  }
  return front;
}

- (IBAction)executeTrigger:(SparkTrigger *)trigger {
  Boolean trapping;
  SparkAlert *alert = nil;
  DLog(@"Start handle event");
  /* If Spark Editor is trapping, forward keystroke */
  if ((noErr == SDGetEditorIsTrapping(&trapping)) && trapping) {
    [trigger bypass];
    return;
  }
  /* Warning: trigger can be release during it's own invocation, so retain it */
  [trigger retain];
  @try {
    BOOL status = YES;
    SparkAction *action = nil;
    /* If action depends front application */
    if ([trigger hasManyAction]) {      
      SparkApplication *front = [self frontApplication];
      if (front) {
        /* Get action for front application */
        action = [SparkSharedManager() actionForTrigger:[trigger uid] application:[front uid] status:&status];
      }
    }
    /* No action found, use default */
    if (!action) {
      action = [SparkSharedManager() actionForTrigger:[trigger uid] application:0 status:&status];
    }
    /* Action exists and is enabled */
    if (status && action) {
      alert = [action execute];
    } else {
      [trigger bypass];
    }
  } @catch (id exception) {
    SKLogException(exception);
    NSBeep();
  }
  [trigger release];
  
  /* If alert not null */
  if (alert) {
    /* Check if need display alert */
    CFBooleanRef displayAlertRef = CFPreferencesCopyAppValue(CFSTR("SDDisplayAlertOnExecute"), (CFStringRef)kSparkBundleIdentifier);
    if (displayAlertRef) {
      if (CFBooleanGetValue(displayAlertRef))
        SparkDisplayAlert(alert);
      CFRelease(displayAlertRef);
    }
  }
  DLog(@"Finish handle event");
}

- (void)run {
  DLog(@"Waiting events");
  [NSApp run];
}

#pragma mark -
#pragma mark Application Delegate
- (void)applicationWillTerminate:(NSNotification *)aNotification {
  SDSendStateToEditor(kSparkDaemonStopped);
  /* Invalidate connection. dealloc would probably not be called, so it is not a good candidate for this purpose */
  [[NSConnection defaultConnection] invalidate];
  [[HKHotKeyManager sharedManager] unregisterAll];
}

@end
