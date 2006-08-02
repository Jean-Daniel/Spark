//
//  main.m
//  Spark
//
//  Created by Fox on Fri Dec 12 2003.
//  Copyright (c) 2004 Shadow Lab. All rights reserved.
//

#import "SparkDaemon.h"

#include <unistd.h>

#import <SparkKit/SparkKit.h>
#import <SparkKit/SparkAlert.h>
#import <SparkKit/SparkActionPlugIn.h>

#import <ShadowKit/SKFunctions.h>
#import <ShadowKit/SKProcessFunctions.h>

#import <HotKeyToolKit/HotKeyToolKit.h>

#import "AEScript.h"

#if defined (DEBUG)
#warning Debug defined in Spark Daemon!
#include <ShadowKit/ShadowAEUtils.h>
#endif

int main(int argc, const char *argv[]) {
#if defined (DEBUG)
  ShadowAEDebug = YES;
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
  [self checkActions];
  [self loadTriggers];
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
          OSType sign = SKGetProcessSignature(&psn);
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
    }
  }
  return self;
}

- (void)dealloc {
  [[NSConnection defaultConnection] invalidate];
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
    DLog(@"Connection OK, Spark Daemon Ready");
  }
  return YES;
}

- (void)checkActions {
  BOOL blockAlert = NO;
  CFBooleanRef blockAlertRef = CFPreferencesCopyAppValue(CFSTR("SDBlockAlertOnLoad"), (CFStringRef)kSparkBundleIdentifier);
  if (blockAlertRef != nil) {
    blockAlert = CFBooleanGetValue(blockAlertRef);
    CFRelease(blockAlertRef);
  }
  if (!blockAlert) {
    id item;
    NSEnumerator *items = [SparkSharedActionSet() objectEnumerator];
    NSMutableArray *errors = [[NSMutableArray alloc] init];
    while (item = [items nextObject]) {
      id alert = ([item check]);
      if (alert != nil) {
        [item setInvalid:YES];
        [alert setHideSparkButton:NO];
        [errors addObject:alert];
      }
    }
    SparkDisplayAlerts(errors);
    [errors release];
  }
}

- (void)loadTriggers {
  SparkTrigger *trigger;
  NSEnumerator *triggers = [SparkSharedTriggerSet() objectEnumerator];
  while (trigger = [triggers nextObject]) {
    @try {
      [trigger setTarget:self];
      [trigger setAction:@selector(executeTrigger:)];
      if ([trigger isEnabled] /* && ![item isInvalid] */) { // Faut-il activer une clé invalide ??
        [trigger setRegistred:YES];
      }
    } @catch (id exception) {
      SKLogException(exception);
    }
  }
}

- (void)didAddTrigger:(SparkTrigger *)aTrigger {
  [aTrigger setTarget:self];
  [aTrigger setAction:@selector(executeTrigger:)];
  if ([aTrigger isEnabled]) {
    [aTrigger setRegistred:YES];
  }
}

- (void)willRemoveTrigger:(SparkTrigger *)aTrigger {
  if ([aTrigger isRegistred]) {
    [aTrigger setRegistred:NO];
  }
}

- (IBAction)executeTrigger:(id)trigger {
  Boolean trapping;
  SparkAlert *alert = nil;
  DLog(@"Start handle event");
  /* If Spark Editor is trapping, forward keystroke */
  if ((noErr == SDGetEditorIsTrapping(&trapping)) && trapping) {
    [trigger sendKeystrokeToApplication:kSparkHFSCreatorType bundle:nil];
    return;
  }
  /* Warning: trigger can be release during it's own invocation, so retain it */
  [trigger retain];
  @try {
    alert = [trigger execute];
  } @catch (id exception) {
    SKLogException(exception);
    NSBeep();
  }
  [trigger release];
  /* If alert not null */
  if (alert) {
    /* Read last change from file system */
    CFPreferencesAppSynchronize((CFStringRef)kSparkBundleIdentifier);
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
  [NSApp run];
  //[[NSRunLoop currentRunLoop] run];
}

- (void)terminate {
  [NSApp terminate:nil];
}

#pragma mark -
#pragma mark Application Delegate

- (void)applicationWillTerminate:(NSNotification *)aNotification {
  SDSendStateToEditor(kSparkDaemonStopped);
}

@end
