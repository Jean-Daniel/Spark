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
#import <ShadowKit/SKFunctions.h>

#import "AEScript.h"

#if defined (DEBUG)
#warning Debug defined in Spark Daemon!
#import <HotKeyToolKit/HotKeyToolKit.h>
#endif

int main(int argc, const char *argv[]) {
#if defined (DEBUG)
  ShadowAEDebug = YES;
  HKTraceHotKeyEvents = YES;
#endif
  id pool = [[NSAutoreleasePool alloc] init];
  NSApplicationLoad();
  id server = nil;
  if (server = [[SparkDaemon alloc] init]) {
    SendStateToEditor(kSparkDaemonStarted);
    [pool release];
    pool = [[NSAutoreleasePool alloc] init];
    [server run];
  }
  else {
    NSBeep();
    SendStateToEditor(kSparkDaemonError);
  }
  [server release];
  
  [pool release];
  return 0;
}

@implementation SparkDaemon

- (void)checkAndLoad:(id)sender {
  ShadowTrace();
  [self checkActions];
  [self loadKeys];
}

- (id)init {
  if (self = [super init]) {
    if (![self setPlugInPath] || ![self connect]) {
      [self release];
      self = nil;
    } else {
#if defined (DEBUG)
      [[NSUserDefaults standardUserDefaults] registerDefaults:[NSDictionary dictionaryWithObjectsAndKeys:
        @"1", @"NSScriptingDebugLogLevel",
        nil]];
#endif
      [SparkLibraryObject setLoadUI:NO];
      [NSApp setDelegate:self];
      
      int delay = 0;
      /* SparkDaemonDelay */
      ProcessSerialNumber psn = {kNoProcess, kCurrentProcess};
      CFDictionaryRef infos = ProcessInformationCopyDictionary(&psn, kProcessDictionaryIncludeAllInformationMask);
      if (infos) {
        CFNumberRef parent = CFDictionaryGetValue(infos, CFSTR("ParentPSN"));
        if (parent) {
          CFNumberGetValue(parent, kCFNumberLongLongType, &psn);
          CFRelease(infos);
          infos = ProcessInformationCopyDictionary(&psn, kProcessDictionaryIncludeAllInformationMask);
          if (infos) {
            CFStringRef creator = CFDictionaryGetValue(infos, CFSTR("FileCreator"));
            if (creator) {
              OSType sign = SKGetOSTypeFromString(creator);
              if (sign != kSparkHFSCreatorType) {
                CFNumberRef value = CFPreferencesCopyAppValue(CFSTR("SparkDaemonDelay"), (CFStringRef)kSparkBundleIdentifier);
                if (value) {
                  delay = [(id)value intValue];
                  CFRelease(value);
                }
              }
            }
            CFRelease(infos);
          }
        }
      }
      if (delay) {
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

- (BOOL)setPlugInPath {
  BOOL result = NO;
  CFBundleRef spark = nil;
  id path = [[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:@"../../../"];
  CFURLRef sparkUrl = CFURLCreateWithFileSystemPath(kCFAllocatorDefault,(CFStringRef)path, kCFURLPOSIXPathStyle, YES);
  if (sparkUrl) {
    spark = CFBundleCreate(kCFAllocatorDefault, sparkUrl);
    if (spark) {
      CFStringRef identifier = CFBundleGetIdentifier(spark);
      if (identifier && CFEqual(identifier, kSparkBundleIdentifier)) {
        CFStringRef plugPath = nil;
        CFURLRef plugUrl = CFBundleCopyBuiltInPlugInsURL(spark);
        if (plugUrl) {
          plugPath = CFURLCopyFileSystemPath(plugUrl, kCFURLPOSIXPathStyle);
          CFRelease(plugUrl);
          plugUrl = nil;
        }
        if (plugPath) {
          plugUrl = CFURLCreateCopyAppendingPathComponent(kCFAllocatorDefault, sparkUrl, plugPath, YES);
          CFRelease(plugPath);
          plugPath = nil;
        }
        if (plugUrl) {
          plugPath = CFURLCopyFileSystemPath(plugUrl, kCFURLPOSIXPathStyle);
          CFRelease(plugUrl);
          plugUrl = nil;
        }
        if (plugPath) {
          result = YES;
          [SparkActionLoader setBuildInPath:(id)plugPath];
          CFRelease(plugPath);
          plugPath = nil;
        }
      }
      CFRelease(spark);
    }
    CFRelease(sparkUrl);
  }
  return result;
}

- (void)checkActions {
  CFBooleanRef blockAlertRef = CFPreferencesCopyAppValue((CFStringRef)@"SDBlockAlertOnLoad", (CFStringRef)kSparkBundleIdentifier);
  BOOL blockAlert = NO;
  if (blockAlertRef != nil) {
    blockAlert = CFBooleanGetValue(blockAlertRef);
    CFRelease(blockAlertRef);
  }
  if (!blockAlert) {
    id items = [SparkDefaultActionLibrary() objectEnumerator];
    id item;
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

- (void)loadKeys {
  id items = [SparkDefaultKeyLibrary() objectEnumerator];
  SparkHotKey *item;
  while (item = [items nextObject]) {
    @try {
      [item setTarget:self];
      [item setAction:@selector(executeHotKey:)];
      if ([item isActive] /* && ![item isInvalid] */) { // Faut-il activer une clé invalide ??
        [item setRegistred:YES];
      }
    }
    @catch (id exception) {
      SKLogException(exception);
    }
  }
}

- (BOOL)connect {
  NSConnection *theConnection;
  id checker = [[NSProtocolChecker alloc] initWithTarget:self protocol:@protocol(SparkServer)]; 
  theConnection = [NSConnection defaultConnection];
  [theConnection setRootObject:checker];
  [checker release];
  if ([theConnection registerName:kSparkConnectionName] == NO) {
    NSLog(@"Error While opening Connection");
    return NO;
  }
#if defined(DEBUG)
  else {
    NSLog(@"Connection OK, Spark Daemon Ready");
  }
#endif
  return YES;
}

- (void)addKey:(SparkHotKey *)key {
  [key setTarget:self];
  [key setAction:@selector(executeHotKey:)];
  [SparkDefaultKeyLibrary() addObject:key];
  if ([key isActive]) {
    [key setRegistred:YES];
  }
}
- (void)updateKey:(SparkHotKey *)key {
  id old = [SparkDefaultKeyLibrary() objectWithId:[key uid]];
  [old setRegistred:NO];
  [key setTarget:self];
  [key setAction:@selector(executeHotKey:)];
  [SparkDefaultKeyLibrary() updateObject:key];
  if ([key isActive]) {
    [key setRegistred:YES];
  }
}
- (void)removeKey:(SparkHotKey *)key {
  if ([key isRegistred]) {
    [key setRegistred:NO];
  }
  [SparkDefaultKeyLibrary() removeObject:key];
}

- (IBAction)executeHotKey:(id)sender {
  id alert = nil;
  Boolean trapping;
  DLog(@"Processing event");
  if ((noErr == GetEditorIsTrapping(&trapping)) && trapping) {
    [sender sendHotKeyToApplicationWithSignature:kSparkHFSCreatorType bundleId:nil];
    return;
  }
  // Recursive loop are avoid by low level lock (-[HKHotKey invoke]).
//  BOOL ok = [sender isRegistred];
//  if (ok) [sender setRegistred:NO];
  [sender retain];
  @try {
    alert = [sender execute];
  } @catch (id exception) {
    SKLogException(exception);
    NSBeep();
  }
  [sender release];
//  if (ok) [sender setRegistred:YES];
  if (alert != nil) {
    CFPreferencesAppSynchronize((CFStringRef)kSparkBundleIdentifier);
    CFBooleanRef blockAlertRef = CFPreferencesCopyAppValue((CFStringRef)@"SDBlockAlertOnExecute", (CFStringRef)kSparkBundleIdentifier);
    if (blockAlertRef == nil || !CFBooleanGetValue(blockAlertRef)) {
      SparkDisplayAlert(alert);
    }
    [(id)blockAlertRef release];
  }
  DLog(@"End Processing event.");
}

- (void)run {
  [NSApp run];
}

- (void)terminate {
  [NSApp terminate:nil];
}

#pragma mark -
#pragma mark Application Delegate

- (void)applicationWillTerminate:(NSNotification *)aNotification {
  SendStateToEditor(kSparkDaemonStopped);
}

@end
