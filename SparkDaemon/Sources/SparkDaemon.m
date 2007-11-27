/*
 *  SparkDaemon.m
 *  SparkServer
 *
 *  Created by Black Moon Team.
 *  Copyright (c) 2004 - 2006 Shadow Lab. All rights reserved.
 */

#import "SparkDaemon.h"
#import "SDAEHandlers.h"

#include <Carbon/Carbon.h>

#import <SparkKit/SparkKit.h>
#import <SparkKit/SparkPrivate.h>
#import <SparkKit/SparkFunctions.h>
#import <SparkKit/SparkPreferences.h>

#import <SparkKit/SparkPlugIn.h>
#import <SparkKit/SparkLibrary.h>
#import <SparkKit/SparkObjectSet.h>
#import <SparkKit/SparkEntryManager.h>

#import <SparkKit/SparkAlert.h>
#import <SparkKit/SparkAction.h>
#import <SparkKit/SparkTrigger.h>
#import <SparkKit/SparkApplication.h>

#import <ShadowKit/SKProcessFunctions.h>

#if defined (DEBUG)
#import <ShadowKit/SKAEFunctions.h>
#import <HotKeyToolKit/HotKeyToolKit.h>
#import <SparkKit/SparkLibrarySynchronizer.h>
#endif

int main(int argc, const char *argv[]) {
#if defined (DEBUG)
  //SKAEDebug = YES;
  HKTraceHotKeyEvents = YES;
  SparkLogSynchronization = YES;
#endif
  NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
  NSApplicationLoad();
  SparkDaemon *server;
  if (server = [[SparkDaemon alloc] init]) {
    /* Cleanup pool */
    [pool release];
    pool = [[NSAutoreleasePool alloc] init];
    [server run];
  } else {
    // Run Alert panel ?
    SDSendStateToEditor(kSparkDaemonStatusError);
  }
  [server release];
  
  [pool release];
  return 0;
}

/* Main thread variable */
static
BOOL sIsProcessingEvent = NO;

static
OSStatus _SDProcessManagerEvent(EventHandlerCallRef inHandlerCallRef, EventRef inEvent, void *inUserData) {
  if (GetEventClass(inEvent) == kEventClassApplication) {
    UInt32 size;
    EventParamType type;
    ProcessSerialNumber psn;
    SparkDaemon *handler = (SparkDaemon *)inUserData;
    verify_noerr(GetEventParameter(inEvent, kEventParamProcessID, typeProcessSerialNumber, &type, sizeof(psn), &size, &psn));
    switch (GetEventKind(inEvent)) {
      case kEventAppLaunched:
        break;
      case kEventAppTerminated:
        break;
      case kEventAppFrontSwitched:
        [handler frontApplicationDidChange:&psn];
        return noErr;
    }
  }
  return eventNotHandledErr;
}

@implementation SparkDaemon

- (BOOL)application:(NSApplication *)sender delegateHandlesKey:(NSString *)key {
  return [key isEqualToString:@"enabled"];
}

- (void)setActiveLibrary:(SparkLibrary *)aLibrary {
  if (sd_library != aLibrary) {
    /* Release remote library */
    if (sd_rlibrary) {
      [sd_rlibrary release];
      sd_rlibrary = nil;
    }
    if (sd_library) {
      /* Unregister triggers */
      [[sd_library notificationCenter] removeObserver:self];
      [self unregisterTriggers];
      [sd_library unload];
      [sd_library release];
      sd_front = nil;
    }
    sd_library = [aLibrary retain];
    if (sd_library) {
      NSNotificationCenter *center = [sd_library notificationCenter];
      [center addObserver:self
                 selector:@selector(didAddTrigger:)
                     name:SparkObjectSetDidAddObjectNotification
                   object:[sd_library triggerSet]];
      [center addObserver:self
                 selector:@selector(willUpdateTrigger:)
                     name:SparkObjectSetWillUpdateObjectNotification
                   object:[sd_library triggerSet]];
      [center addObserver:self
                 selector:@selector(willRemoveTrigger:)
                     name:SparkObjectSetWillRemoveObjectNotification
                   object:[sd_library triggerSet]];
      
      /* Application observer */
      [center addObserver:self
                 selector:@selector(didChangeApplicationStatus:)
                     name:SparkApplicationDidChangeEnabledNotification
                   object:nil];
      [center addObserver:self
                 selector:@selector(willRemoveApplication:)
                     name:SparkObjectSetWillRemoveObjectNotification
                   object:[sd_library applicationSet]];
      
      /* Entries observer */
      [center addObserver:self
                 selector:@selector(didAddEntry:)
                     name:SparkEntryManagerDidAddEntryNotification 
                   object:[sd_library entryManager]];
      [center addObserver:self
                 selector:@selector(didUpdateEntry:)
                     name:SparkEntryManagerDidUpdateEntryNotification 
                   object:[sd_library entryManager]];
      [center addObserver:self
                 selector:@selector(didRemoveEntry:)
                     name:SparkEntryManagerDidRemoveEntryNotification 
                   object:[sd_library entryManager]];
      [center addObserver:self
                 selector:@selector(didChangeEntryStatus:)
                     name:SparkEntryManagerDidChangeEntryEnabledNotification 
                   object:[sd_library entryManager]];
      
      /* If library not loaded, load library */
      if (![sd_library isLoaded])
        [sd_library load:nil];
      /* register triggers */
      [self checkActions];
      [self loadTriggers];
      
      /* init front process using a valid process */
      ProcessSerialNumber psn;
      if (noErr == GetCurrentProcess(&psn))
        sd_front = [sd_library applicationForProcess:&psn];
    }
  }
}

/* Timer callback */
- (void)finishStartup:(id)sender {
  [self setActiveLibrary:SparkActiveLibrary()];
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(didChangePluginStatus:)
                                               name:SparkPlugInDidChangeStatusNotification
                                             object:nil];
  
  EventTypeSpec eventTypes[] = {
    //      { kEventClassApplication, kEventAppLaunched },
    //      { kEventClassApplication, kEventAppTerminated },
  { kEventClassApplication, kEventAppFrontSwitched },
  };
  InstallApplicationEventHandler(_SDProcessManagerEvent, GetEventTypeCount(eventTypes), eventTypes, self, NULL);
}

- (id)init {
  if (self = [super init]) {
    if (![self openConnection]) {
      [self release];
      self = nil; 
    } else {
#if defined (DEBUG)
      [[NSUserDefaults standardUserDefaults] registerDefaults:[NSDictionary dictionaryWithObjectsAndKeys:
        @"YES", @"NSShowNonLocalizedStrings",
        //@"YES", @"NSShowAllViews",
        //SKFloat(0.15f), @"NSWindowResizeTime",
        //@"6", @"NSDragManagerLogLevel",
        //@"YES", @"NSShowNonLocalizableStrings",
        //@"1", @"NSScriptingDebugLogLevel",
        nil]];
#endif
      [NSApp setDelegate:self];
      /* Init core Apple Event handlers */
      [NSScriptSuiteRegistry sharedScriptSuiteRegistry];
      
      /* Send signal to editor */
      SDSendStateToEditor(kSparkDaemonStatusEnabled);
      
      NSInteger delay = 0;
      /* SparkDaemonDelay */
      ProcessSerialNumber psn = {kNoProcess, kCurrentProcess};
      CFDictionaryRef infos = ProcessInformationCopyDictionary(&psn, kProcessDictionaryIncludeAllInformationMask);
      if (infos) {
        CFNumberRef parent = CFDictionaryGetValue(infos, CFSTR("ParentPSN"));
        if (parent) {
          CFNumberGetValue(parent, kCFNumberLongLongType, &psn);
          
          /* If launch by something that is not Spark Editor */
          OSType sign = SKProcessGetSignature(&psn);
          if (sign != kSparkEditorSignature) {
            delay = SparkPreferencesGetIntegerValue(@"SDDelayStartup", SparkPreferencesDaemon);
          }
        }
        CFRelease(infos);
      }
      if (delay > 0) {
        DLog(@"Delay load: %i", delay);
        [NSTimer scheduledTimerWithTimeInterval:delay
                                         target:self
                                       selector:@selector(finishStartup:)
                                       userInfo:nil
                                        repeats:NO];
      } else {
        [self finishStartup:nil];
      }      
    }
  }
  return self;
}

- (void)dealloc {
  [self closeConnection];
  [self setActiveLibrary:nil];
  [[NSNotificationCenter defaultCenter] removeObserver:self];
  [super dealloc];
}

#pragma mark -
- (BOOL)isEnabled {
  return !sd_disabled;
}

- (void)setEnabled:(BOOL)enabled {
  if (XOR(!enabled, sd_disabled)) {
    sd_disabled = !enabled;
    if (enabled)
      [self registerTriggers];
    else
      [self unregisterVolatileTriggers];
    
    SDSendStateToEditor(sd_disabled ? kSparkDaemonStatusDisabled : kSparkDaemonStatusEnabled);
  }
}

- (void)frontApplicationDidChange:(ProcessSerialNumber *)psn {
  Boolean same = false;
  SparkApplication *front = psn ? [sd_library applicationForProcess:psn] : nil;
  if (!sd_front) {
    same = !front;
  } else {
    same = front && [sd_front isEqual:front];
  }
  if (!same) {
    DLog(@"switch: %@ => %@", sd_front, front);
    /* If status change */
    if ((!sd_front || [sd_front isEnabled]) && (front && ![front isEnabled])) {
      [self unregisterTriggers];
    } else if ((sd_front && ![sd_front isEnabled]) && (!front || [front isEnabled])) {
      [self registerTriggers];
    }
    sd_front = front;
  }
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
  Boolean display = !SparkPreferencesGetBooleanValue(@"SDBlockAlertOnLoad", SparkPreferencesDaemon);
  /* Send actionDidLoad message to all actions */
  SparkAction *action;
  NSEnumerator *actions = [[sd_library actionSet] objectEnumerator];
  NSMutableArray *errors = display ? [[NSMutableArray alloc] init] : nil;
  while (action = [actions nextObject]) {
    SparkAlert *alert = [action actionDidLoad];
    if (alert && display) {
      [alert setHideSparkButton:NO];
      [errors addObject:alert];
    }
  }
  /* Display errors of needed */
  if (display) {
    SparkDisplayAlerts(errors);
    [errors release];
  }
}

- (void)loadTriggers {
  SparkTrigger *trigger;
  NSEnumerator *triggers = [[sd_library triggerSet] objectEnumerator];
  while (trigger = [triggers nextObject]) {
    @try {
      [trigger setTarget:self];
      [trigger setAction:@selector(executeTrigger:)];
    } @catch (id exception) {
      SKLogException(exception);
    }
  }
  [self registerTriggers];
}

- (void)registerTriggers {
  SparkTrigger *trigger;
  SparkEntryManager *manager = [sd_library entryManager];
  NSEnumerator *triggers = [[sd_library triggerSet] objectEnumerator];
  while (trigger = [triggers nextObject]) {
    @try {
      if (![trigger isRegistred]) {
        if ([manager containsActiveEntryForTrigger:[trigger uid]]) {
          [trigger setRegistred:YES];
        }
      } else {
        if (![manager containsActiveEntryForTrigger:[trigger uid]]) {
          [trigger setRegistred:NO];
        }
      }
    } @catch (id exception) {
      SKLogException(exception);
    }
  }
}

- (void)unregisterTriggers {
  SparkTrigger *trigger;
  NSEnumerator *triggers = [[sd_library triggerSet] objectEnumerator];
  while (trigger = [triggers nextObject]) {
    @try {
      if ([trigger isRegistred]) {
        [trigger setRegistred:NO];
      }
    } @catch (id exception) {
      SKLogException(exception);
    }
  }
}
- (void)unregisterVolatileTriggers {
  SparkTrigger *trigger;
  SparkEntryManager *manager = [sd_library entryManager];
  NSEnumerator *triggers = [[sd_library triggerSet] objectEnumerator];
  while (trigger = [triggers nextObject]) {
    @try {
      if ([trigger isRegistred] && ![manager containsPersistentEntryForTrigger:[trigger uid]]) {
        [trigger setRegistred:NO];
      }
    } @catch (id exception) {
      SKLogException(exception);
    }
  }
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
  sIsProcessingEvent = YES;
  /* Warning: trigger can be release during it's own invocation, so retain it */
  [trigger retain];
  @try {
    BOOL status = YES;
    SparkAction *action = nil;
    /* If action depends front application */
    if ([trigger hasManyAction]) {      
      SparkApplication *front = [sd_library frontApplication];
      if (front) {
        /* Get action for front application */
        action = [[sd_library entryManager] actionForTrigger:[trigger uid] application:[front uid] isActive:&status];
      }
    }
    /* No specific action found, use default */
    if (!action) {
      action = [[sd_library entryManager] actionForTrigger:[trigger uid] application:kSparkApplicationSystemUID isActive:&status];
    }
    /* If daemon is disabled, only persistent action are performed */
    if (action) {
      if ([self isEnabled] || [action isPersistent]) {
        [trigger willTriggerAction:status ? action : nil];
        /* Action exists and is enabled */
        if (status) {
          alert = [action performAction];
        } else {
          [trigger bypass];
        }
        [trigger didTriggerAction:status ? action : nil];
      } else {
        // Daemon disabled => bypass
        [trigger bypass];
      }
    } else {
      /* no action found */
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
    Boolean displays = SparkPreferencesGetBooleanValue(@"SDDisplayAlertOnExecute", SparkPreferencesDaemon);
    if (displays) {
      SparkDisplayAlert(alert);
    }
  }
  sIsProcessingEvent = NO;
  DLog(@"Finish handle event");
}

- (void)run {
  /* set front process */
  ProcessSerialNumber psn;
  if (noErr == GetFrontProcess(&psn))
    [self frontApplicationDidChange:&psn];
  [NSApp run];
}

- (void)closeConnection {
  [[NSNotificationCenter defaultCenter] removeObserver:self
                                                  name:NSConnectionDidDieNotification
                                                object:nil];
  [[NSConnection defaultConnection] invalidate];
}

#pragma mark -
#pragma mark Application Delegate
- (void)applicationWillTerminate:(NSNotification *)aNotification {
  /* Invalidate connection. dealloc would probably not be called, so it is not a good candidate for this purpose */
  [self closeConnection];
  [self unregisterTriggers];
  
  SDSendStateToEditor(kSparkDaemonStatusShutDown);
}

@end
