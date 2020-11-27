/*
 *  SparkDaemon.m
 *  SparkServer
 *
 *  Created by Black Moon Team.
 *  Copyright (c) 2004 - 2006 Shadow Lab. All rights reserved.
 */

#import "SparkDaemon.h"
#import "SDAEHandlers.h"

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
#import <SparkKit/SparkServerProtocol.h>
#import <SparkKit/SparkLibrarySynchronizer.h>

#if defined (DEBUG)
#import <HotKeyToolKit/HotKeyToolKit.h>
#endif

int main(int argc, const char *argv[]) {
#if defined (DEBUG)
  //WBAEDebug = YES;
  HKTraceHotKeyEvents = YES;
  SparkLogSynchronization = YES;
#endif
  SparkDaemon *server;
  @autoreleasepool {
    NSApplicationLoad();
    server = [[SparkDaemon alloc] init];
  }

  @autoreleasepool {
    if (server) {
      /* Cleanup pool */
      [server run];
    } else {
      spx_log_error("Spark Agent startup failed !");
    }
  }
  return 0;
}

static const int SparkDaemonContext = 0;

@interface SparkDaemon () <NSXPCListenerDelegate, SparkAgent>
@end

@implementation SparkDaemon {
  BOOL sd_disabled;
  NSXPCListener *_connection;
  NSMutableArray<id<SparkEditor>> *_editors; // there should be only one
}

- (BOOL)application:(NSApplication *)sender delegateHandlesKey:(NSString *)key {
  return [key isEqualToString:@"enabled"];
}

- (void)setActiveLibrary:(SparkLibrary *)aLibrary {
  if (sd_library != aLibrary) {
    /* Release remote library */
    sd_rlibrary = nil;
    if (sd_library) {
      /* Unregister triggers */
      [[sd_library notificationCenter] removeObserver:self];
      [self unregisterEntries];
      [sd_library unload];
      sd_front = nil;
    }
    sd_library = aLibrary;
    if (sd_library) {
      NSNotificationCenter *center = sd_library.notificationCenter;
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
      
      /* init front process */
      sd_front = [sd_library frontmostApplication];
    }
    for (id<SparkEditor> editor in _editors) {
      [editor setLibrary:sd_library.libraryProxy uuid:sd_library.uuid];
    }
  }
}

- (id)init {
  if (self = [super init]) {
    [self openConnection];

    _editors = [[NSMutableArray alloc] init];
#if defined (DEBUG)
    [[NSUserDefaults standardUserDefaults] registerDefaults:
     @{
       @"NSShowNonLocalizedStrings": @YES,
       //@"YES", @"NSShowAllViews",
       //WBFloat(0.15f), @"NSWindowResizeTime",
       //@"6", @"NSDragManagerLogLevel",
       //@"YES", @"NSShowNonLocalizableStrings",
       //@"1", @"NSScriptingDebugLogLevel",
     }];
#endif
    [SparkUserDefaults() registerDefaults:
     @{
       @"SDDelayStartup": @(0),
       @"SDBlockAlertOnLoad": @(YES),
       @"SDDisplayAlertOnExecute": @(YES)
     }];

    [NSApp setDelegate:self];
    [SparkEvent setEventHandler:^void(SparkEvent * __nonnull event) {
      @autoreleasepool {
        [self handleSparkEvent:event];
      }
    }];
    /* Init core Apple Event handlers */
    [NSScriptSuiteRegistry sharedScriptSuiteRegistry];

    NSInteger delay = 0;
    /* SparkDaemonDelay (ignored when launch by Spark Editor) */
    if (![[NSProcessInfo processInfo].arguments containsObject:@"-nodelay"])
      delay = [SparkUserDefaults() integerForKey:@"SDDelayStartup"];

    if (delay > 0) {
      spx_debug("Delay load: %ld", (long)delay);
      [self performSelector:@selector(finishStartup:) withObject:nil afterDelay:delay];
    } else {
      [self finishStartup:nil];
    }
  }
  return self;
}

- (void)dealloc {
  [[NSNotificationCenter defaultCenter] removeObserver:self];
  [self setActiveLibrary:nil];
  [self closeConnection];
}

- (void)finishStartup:(id)sender {
  [self setActiveLibrary:SparkActiveLibrary()];
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(didChangePlugInStatus:)
                                               name:SparkPlugInDidChangeStatusNotification
                                             object:nil];

  [NSWorkspace.sharedWorkspace addObserver:self
                                forKeyPath:@"frontmostApplication"
                                   options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew
                                   context:(void *)&SparkDaemonContext];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
  if (context == &SparkDaemonContext) {
    // Frontmost application did change
    [self frontApplicationDidChange:change[NSKeyValueChangeNewKey]];
  } else {
    [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
  }
}

#pragma mark -
- (BOOL)isEnabled {
  return !sd_disabled;
}

- (void)setEnabled:(BOOL)enabled {
  if (spx_xor(!enabled, sd_disabled)) {
    sd_disabled = !enabled;
    if (enabled)
      [self registerEntries];
    else
      [self unregisterVolatileEntries];

    for (id<SparkEditor> editor in _editors) {
      [editor setDaemonEnabled:enabled];
    }
  }
}

- (void)frontApplicationDidChange:(NSRunningApplication *)app {
  Boolean same = false;
  SparkApplication *front = app ? [sd_library applicationWithProcessIdentifier:app.processIdentifier] : nil;
  if (!sd_front) {
    same = !front;
  } else {
    same = front && [sd_front isEqual:front];
  }
  if (!same) {
    SparkApplication *previous = sd_front;
    sd_front = front;
    spx_debug("switch: %@ => %@", previous, front);
    /* If status change */
    if ((!previous || [previous isEnabled]) && (front && ![front isEnabled])) {
      [self unregisterEntries];
    } else if ((previous && ![previous isEnabled]) && (!front || [front isEnabled])) {
      [self registerEntries];
    }
  }
}

- (void)openConnection {
  _connection = [[NSXPCListener alloc] initWithMachServiceName:kSparkDaemonServiceName];
  _connection.delegate = self;
  [_connection resume];
}

- (BOOL)listener:(NSXPCListener *)listener shouldAcceptNewConnection:(NSXPCConnection *)newConnection {
  spx_trace();
  newConnection.exportedInterface = SparkAgentInterface();
  newConnection.exportedObject = self;
  [newConnection resume];
  return YES;
}

- (void)register:(id<SparkEditor>)editor {
  [_editors addObject:editor];

  NSXPCConnection *connection = [NSXPCConnection currentConnection];
  connection.invalidationHandler = ^{
    dispatch_async(dispatch_get_main_queue(), ^{
      [self->_editors removeObject:editor];
    });
  };
  connection.interruptionHandler = ^{
    dispatch_async(dispatch_get_main_queue(), ^{
      [self->_editors removeObject:editor];
    });
  };

  if (sd_library)
    [editor setLibrary:sd_library.libraryProxy uuid:sd_library.uuid];

  [editor setDaemonEnabled:self.enabled];
}


- (void)checkActions {
  BOOL display = ![SparkUserDefaults() boolForKey:@"SDBlockAlertOnLoad"];
  /* Send actionDidLoad message to all actions */
  NSMutableArray *errors = display ? [[NSMutableArray alloc] init] : nil;
  [sd_library.actionSet enumerateObjectsUsingBlock:^(SparkAction *action, BOOL *stop) {
    SparkAlert *alert = [action actionDidLoad];
    if (alert && display) {
      [alert setHideSparkButton:NO];
      [errors addObject:alert];
    }
  }];
  /* Display errors of needed */
  if (display)
    SparkDisplayAlerts(errors);
}

- (void)setEntryStatus:(SparkEntry *)entry {
  if (entry) {
    @try {
      /* register entry if it is active (enabled + plugged), if the daemon is enabled or if the entry is persistent, and if the front application is not disabled */
      if (entry.active && ([self isEnabled] || entry.persistent) && (!sd_front || sd_front.enabled)) {
        entry.registred = YES;
      } else {
        entry.registred = NO;
      }
    } @catch (id exception) {
      spx_log_exception(exception);
    }
  }
}

- (void)registerEntries {
  [sd_library.entryManager enumerateEntriesUsingBlock:^(SparkEntry *entry, BOOL *stop) {
    [self setEntryStatus:entry];
  }];
}

- (void)unregisterEntries {
  [sd_library.entryManager enumerateEntriesUsingBlock:^(SparkEntry *entry, BOOL *stop) {
    @try {
      entry.registred = NO;
    } @catch (id exception) {
      spx_log_exception(exception);
    }
  }];
}

- (void)unregisterVolatileEntries {
  [sd_library.entryManager enumerateEntriesUsingBlock:^(SparkEntry *entry, BOOL *stop) {
    @try {
      if (!entry.persistent) {
        entry.registred = NO;
      }
    } @catch (id exception) {
      spx_log_exception(exception);
    }
  }];
}

- (void)_displayError:(SparkAlert *)anAlert {
  /* Check if need display alert */
  BOOL displays = [SparkUserDefaults() boolForKey:@"SDDisplayAlertOnExecute"];
  if (displays)
    SparkDisplayAlert(anAlert);
}

- (SparkAlert *)_executeEvent:(SparkEvent *)anEvent {
  SparkAlert *alert = nil;
  SparkEntry *entry = [anEvent entry];
  /* Warning: trigger can be release during [action performAction] */
  spx_debug("Start handle event (%@): %@", [NSThread currentThread], anEvent);
  [SparkEvent setCurrentEvent:anEvent];
  @try {
    /* Action exists and is enabled */
    alert = [entry.action performAction];
  } @catch (id exception) {
    // TODO: alert = [SparkAlert alertFromException:exception context:plugin, action, ...];
    spx_log_exception(exception);
    NSBeep();
  }
  [SparkEvent setCurrentEvent:nil];
  spx_debug("End handle event (%@): %@", [NSThread currentThread], anEvent);
  
  return alert;
}

- (void)handleSparkEvent:(SparkEvent *)anEvent {
  Boolean trapping;
  /* If Spark Editor is trapping, forward keystroke */
  if ([anEvent type] == kSparkEventTypeBypass || ((noErr == SDGetEditorIsTrapping(&trapping)) && trapping)) {
    spx_debug("Bypass event or Spark Editor is trapping => bypass");
    [[anEvent trigger] bypass];
    return;
  }

  spx_debug("Start dispatch event: %@", anEvent);

  bool bypass = true;
  /* If daemon is disabled, only persistent action are performed */
  if ([self isEnabled] || [[anEvent entry] isPersistent]) {
    bypass = false;
    /* if does not support concurrency => check if already running for safety */
    SparkAlert *alert = [self _executeEvent:anEvent];
    if (alert)
      [self _displayError:alert];
  }

  if (bypass) [[anEvent trigger] bypass];

  spx_debug("End dispatch event: %@", anEvent);
}

- (void)run {
  [NSApp run];
}

- (void)closeConnection {
  [_connection invalidate];
  _connection = nil;
}

#pragma mark -
#pragma mark Application Delegate
- (void)applicationWillTerminate:(NSNotification *)aNotification {
  /* Invalidate connection. dealloc would probably not be called, so it is not a good candidate for this purpose */
  [self closeConnection];
  [self unregisterEntries];
}

//- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender {
//	WBTrace();
//	return NSTerminateNow;
//}

@end

