/*
 *  SparkDaemon.m
 *  SparkServer
 *
 *  Created by Black Moon Team.
 *  Copyright (c) 2004 - 2006 Shadow Lab. All rights reserved.
 */

#import "SparkDaemon.h"
#import "SDAEHandlers.h"
#import "SparkDaemonGrowl.h"

#include <Carbon/Carbon.h>
#if __LP64__
extern EventTargetRef GetApplicationEventTarget(void);
#endif

#import <SparkKit/SparkEvent.h>
#import <SparkKit/SparkPrivate.h>
#import <SparkKit/SparkFunctions.h>
#import <SparkKit/SparkPreferences.h>

#import <SparkKit/SparkPlugIn.h>
#import <SparkKit/SparkLibrary.h>
#import <SparkKit/SparkObjectSet.h>
#import <SparkKit/SparkEntryManager.h>

#import <SparkKit/SparkAlert.h>
#import <SparkKit/SparkEntry.h>
#import <SparkKit/SparkAction.h>
#import <SparkKit/SparkTrigger.h>
#import <SparkKit/SparkApplication.h>
#import <SparkKit/SparkActionLoader.h>

#import WBHEADER(WBProcessFunctions.h)

#if defined (DEBUG)
#import WBHEADER(WBAEFunctions.h)
#import <HotKeyToolKit/HotKeyToolKit.h>
#import <SparkKit/SparkLibrarySynchronizer.h>
#endif

int main(int argc, const char *argv[]) {
#if defined (DEBUG)
  //WBAEDebug = YES;
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

static
OSStatus _SDProcessManagerEvent(EventHandlerCallRef inHandlerCallRef, EventRef inEvent, void *inUserData) {
  if (GetEventClass(inEvent) == kEventClassApplication) {
    ByteCount size;
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
      [self unregisterEntries];
      [sd_library unload];
      [sd_library release];
      sd_front = nil;
    }
    sd_library = [aLibrary retain];
    if (sd_library) {
      NSNotificationCenter *center = [sd_library notificationCenter];
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
                     name:SparkEntryManagerDidChangeEntryStatusNotification 
                   object:[sd_library entryManager]];
      
      /* If library not loaded, load library */
      if (![sd_library isLoaded])
        [sd_library load:nil];
      /* register triggers */
      [self checkActions];
      [self registerEntries];
      
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
  [self registerGrowl];
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
        //WBFloat(0.15f), @"NSWindowResizeTime",
        //@"6", @"NSDragManagerLogLevel",
        //@"YES", @"NSShowNonLocalizableStrings",
        //@"1", @"NSScriptingDebugLogLevel",
        nil]];
#endif
      [NSApp setDelegate:self];
      [SparkEvent setEventHandler:self andSelector:@selector(handleSparkEvent:)];
      sd_lock = [[NSLock alloc] init];
      sd_locks = NSCreateMapTable(NSObjectMapKeyCallBacks, NSObjectMapValueCallBacks, 0);
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
          OSType sign = WBProcessGetSignature(&psn);
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
  [[NSNotificationCenter defaultCenter] removeObserver:self];
  [self setActiveLibrary:nil];
  [self closeConnection];
  [sd_growl release];
  [sd_lock release];
  if (sd_locks) NSFreeMapTable(sd_locks);
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
      [self registerEntries];
    else
      [self unregisterVolatileEntries];
    
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
    SparkApplication *previous = sd_front;
    sd_front = front;
    DLog(@"switch: %@ => %@", previous, front);
    /* If status change */
    if ((!previous || [previous isEnabled]) && (front && ![front isEnabled])) {
      [self unregisterEntries];
    } else if ((previous && ![previous isEnabled]) && (!front || [front isEnabled])) {
      [self registerEntries];
    }
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
  NSEnumerator *actions = [sd_library actionEnumerator];
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

- (void)setEntryStatus:(SparkEntry *)entry {
  if (entry) {
    @try {
      /* register entry if it is active (enabled + plugged), if the daemon is enabled or if the entry is persistent, and if the front application is not disabled */
      if ([entry isActive] && ([self isEnabled] || [entry isPersistent]) && (!sd_front || [sd_front isEnabled])) {
        [entry setRegistred:YES];
      } else {
        [entry setRegistred:NO];
      }
    } @catch (id exception) {
      WBLogException(exception);
    }
  }
}

- (void)registerEntries {
  SparkEntry *entry;
  NSEnumerator *entries = [sd_library entryEnumerator];
  while (entry = [entries nextObject]) {
    [self setEntryStatus:entry];
  }
}

- (void)unregisterEntries {
  SparkEntry *entry;
  NSEnumerator *entries = [sd_library entryEnumerator];
  while (entry = [entries nextObject]) {
    @try {
      [entry setRegistred:NO];
    } @catch (id exception) {
      WBLogException(exception);
    }
  }
}
- (void)unregisterVolatileEntries {
  SparkEntry *entry;
  NSEnumerator *entries = [sd_library entryEnumerator];
  while (entry = [entries nextObject]) {
    @try {
      if (![entry isPersistent]) {
        [entry setRegistred:NO];
      }
    } @catch (id exception) {
      WBLogException(exception);
    }
  }
}

- (void)_displayError:(SparkAlert *)anAlert {
  /* Check if need display alert */
  Boolean displays = SparkPreferencesGetBooleanValue(@"SDDisplayAlertOnExecute", SparkPreferencesDaemon);
  if (displays) SparkDisplayAlert(anAlert); 
}

- (SparkAlert *)_executeEvent:(SparkEvent *)anEvent {
  SparkAlert *alert = nil;
  SparkEntry *entry = [anEvent entry];
  /* Warning: trigger can be release during [action performAction] */
  DLog(@"Start handle event (%@): %@", [NSThread currentThread], anEvent);
  [SparkEvent setCurrentEvent:anEvent];
  @try {
    /* Action exists and is enabled */
    alert = [[entry action] performAction];
  } @catch (id exception) {
    // TODO: alert = [SparkAlert alertFromException:exception context:plugin, action, ...];
    WBLogException(exception);
    NSBeep();
  }
  [SparkEvent setCurrentEvent:nil];
  DLog(@"End handle event (%@): %@", [NSThread currentThread], anEvent);
  
  return alert;
}

- (void)_executeEventThread:(SparkEvent *)anEvent {
  SparkEvent *event = anEvent;
  do {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    
    SparkAction *action = [[event entry] action];
    SparkAlert *alert = [self _executeEvent:event];
    if (alert) [self performSelectorOnMainThread:@selector(_displayError:) withObject:alert waitUntilDone:NO];
    
    [event release]; // balance retain called before detach thread and on dequeue
    event = nil;
    if (![action supportsConcurrentRequests]) {
      id lock = [action lock];
      SparkPlugIn *plugin = [[SparkActionLoader sharedLoader] plugInForAction:action];
      
      [sd_lock lock];
      NSMutableDictionary *locks = (NSMutableDictionary *)NSMapGet(sd_locks, plugin);
      NSMutableArray *queue = [locks objectForKey:lock];
      // dequeue item and execute next.
      [queue removeLastObject];
      event = [[queue lastObject] retain]; // nil if queue is empty
      [sd_lock unlock];
    }
    [pool release];
  } while (event);
}

- (void)handleSparkEvent:(SparkEvent *)anEvent {
  Boolean trapping;
  /* If Spark Editor is trapping, forward keystroke */
  if ([anEvent type] == kSparkEventTypeBypass || (noErr == SDGetEditorIsTrapping(&trapping)) && trapping) {
    DLog(@"Bypass event or Spark Editor is trapping => bypass");
    [[anEvent trigger] bypass];
    return;
  }
  
  DLog(@"Start dispatch event: %@", anEvent);

  bool bypass = true;
  /* If daemon is disabled, only persistent action are performed */
  if ([self isEnabled] || [[anEvent entry] isPersistent]) {
    SparkAction *action = [[anEvent entry] action];
    /* if does not support concurrency => check if already running for safety */
    if ([action needsToBeRunOnMainThread]) {
      bypass = false;
      SparkAlert *alert = [self _executeEvent:anEvent];
      if (alert) [self _displayError:alert];
    } else {
      if ([action supportsConcurrentRequests]) {
        bypass = false;
        [NSThread detachNewThreadSelector:@selector(_executeEventThread:) toTarget:self withObject:[anEvent retain]];
      } else {
        id lock = [action lock];
        SparkPlugIn *plugin = [[SparkActionLoader sharedLoader] plugInForAction:action];
        
        [sd_lock lock];
        NSMutableDictionary *locks = NSMapGet(sd_locks, plugin);
        if (!locks) { locks = [NSMutableDictionary dictionary]; NSMapInsert(sd_locks, plugin, locks); }
        NSMutableArray *queue = [locks objectForKey:lock];
        if (!queue) { queue = [NSMutableArray array]; [locks setObject:queue forKey:lock]; }
        [queue insertObject:anEvent atIndex:0];
        if (1 == [queue count]) {
          bypass = false;
          [sd_lock unlock];
          [NSThread detachNewThreadSelector:@selector(_executeEventThread:) toTarget:self withObject:[anEvent retain]];
        } else {
          bypass = false;
          [sd_lock unlock];
        }
      }
    }
  }
  
  if (bypass) [[anEvent trigger] bypass];
  
  DLog(@"End dispatch event: %@", anEvent);
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
  [self unregisterEntries];
  
  SDSendStateToEditor(kSparkDaemonStatusShutDown);
}

//- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender {
//	WBTrace();
//	return NSTerminateNow;
//}

@end

