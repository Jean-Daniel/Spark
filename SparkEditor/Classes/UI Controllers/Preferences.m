//
//  Preferences.m
//  Spark
//
//  Created by Fox on Wed Jan 21 2004.
//  Copyright (c) 2004 Shadow Lab. All rights reserved.
//

#import <SparkKit/SparkKit.h>
#import <ShadowKit/SKLoginItems.h>

#import "Preferences.h"

CFStringRef const kSparkDaemonExecutable = CFSTR("Spark Daemon.app");

NSString * const kSparkPrefVersion = @"SparkVersion";
NSString * const kSparkPrefAutoStart = @"SparkAutoStart";
NSString * const kSparkPrefSingleKeyMode = @"SparkSingleKeyMode";
NSString * const kSparkPrefDisplayPlugins = @"SparkDisplayPlugins";

/* Optional alerts panels */
NSString * const kSparkPrefConfirmDeleteKey = @"SparkConfirmDeleteKey";
NSString * const kSparkPrefConfirmDeleteList = @"SparkConfirmDeleteList";
NSString * const kSparkPrefConfirmDeleteAction = @"SparkConfirmDeleteAction";
NSString * const kSparkPrefConfirmDeleteApplication = @"SparkConfirmDeleteApplication";

/* Workspace Layout */
NSString * const kSparkPrefMainWindowLibrary = @"SparkMainWindowLibrary";
NSString * const kSparkPrefChoosePanelActionLibrary = @"SparkChoosePanelActionLibrary";
NSString * const kSparkPrefInspectorSelectedTab = @"SparkInspectorSelectedTab";
NSString * const kSparkPrefInspectorActionLibrary = @"SparkInspectorActionLibrary";
NSString * const kSparkPrefInspectorApplicationLibrary = @"SparkInspectorApplicationLibrary";
NSString * const kSparkPrefAppActionSelectedTab = @"SparkAppActionSelectedTab";
NSString * const kSparkPrefAppActionActionLibrary = @"SparkPrefAppActionActionLibrary";
NSString * const kSparkPrefAppActionApplicationLibrary = @"SparkPrefAppActionApplicationLibrary";

@implementation Preferences

- (id)init {
  if (self = [super initWithWindowNibName:@"Preferences"]) {
    
  }
  return self;
}

- (void)awakeFromNib {
  BOOL value = [[NSUserDefaults standardUserDefaults] boolForKey:kSparkPrefAutoStart];
  [self setValue:SKBool(value) forKey:@"runAutomatically"];
  autoStartBak = value;
}

- (IBAction)close:(id)sender {
  [NSApp endSheet:[self window]];
  [self close];
}

- (void)dealloc {
  [[NSUserDefaults standardUserDefaults] synchronize];
  [super dealloc];
}

- (IBAction)resetWarningDialogs:(id)sender {
  NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
  [prefs setBool:NO forKey:kSparkPrefConfirmDeleteKey];
  [prefs setBool:NO forKey:kSparkPrefConfirmDeleteList];
  [prefs setBool:NO forKey:kSparkPrefConfirmDeleteAction];
  [prefs setBool:NO forKey:kSparkPrefConfirmDeleteApplication];
  [prefs synchronize];
}

- (BOOL)runAutomatically {
  return autoStart;
}
- (void)setRunAutomatically:(BOOL)flag {
  autoStart = flag;
}

- (int)singleKeyMode {
  switch (SparkKeyStrokeFilterMode) {
    case kSparkDisableAllSingleKey:
      return 0;
    case kSparkEnableSingleFunctionKey:
      return 1;
    case kSparkEnableAllSingleButNavigation:
      return 2;
    case kSparkEnableAllSingleKey:
      return 3;
  }
  return 0;
}

static void SetSparkKitSingleKeyMode(int mode) {
  switch (mode) {
    case 0:
      SparkKeyStrokeFilterMode = kSparkDisableAllSingleKey;
      break;
    case 1:
      SparkKeyStrokeFilterMode = kSparkEnableSingleFunctionKey;
      break;
    case 2:
      SparkKeyStrokeFilterMode = kSparkEnableAllSingleButNavigation;
      break;  
    case 3:
      SparkKeyStrokeFilterMode = kSparkEnableAllSingleKey;
      break;
  }
}

- (void)setSingleKeyMode:(int)mode {
  SetSparkKitSingleKeyMode(mode);
  [[NSUserDefaults standardUserDefaults] setInteger:mode forKey:kSparkPrefSingleKeyMode];
}

- (void)windowWillClose:(NSNotification *)aNotification {
  if (autoStartBak != autoStart) {
    [Preferences setAutoStart:autoStart];
    autoStartBak = autoStart;
  }
  [[NSUserDefaults standardUserDefaults] setBool:autoStart forKey:kSparkPrefAutoStart];
  [[NSUserDefaults standardUserDefaults] synchronize];
}

+ (BOOL)autoStart {
//  BOOL start = NO;
//  id items = (id)CFPreferencesCopyValue(CFSTR("AutoLaunchedApplicationDictionary"),
//                                        CFSTR("loginwindow"),
//                                        kCFPreferencesCurrentUser,
//                                        kCFPreferencesAnyHost);
//  items = [[items autorelease] mutableCopy];
//  id loginItems = [items objectEnumerator];
//  id item;
//  while ((item = [loginItems nextObject]) && !start) {
//    NSRange range = [[item objectForKey:@"Path"] rangeOfString:kSparkDaemonExecutable options:nil];
//    if (range.location != NSNotFound) {
//      start = YES;
//    }
//  }
//  [items release];
//  return start;
  return [[NSUserDefaults standardUserDefaults] boolForKey:kSparkPrefAutoStart];
}

static __inline__ BOOL __CFFileURLCompare(CFURLRef url1, CFURLRef url2) {
  FSRef r1, r2;
  if (CFURLGetFSRef(url1, &r1) && CFURLGetFSRef(url2, &r2)) {
    return FSCompareFSRefs(&r1, &r2) == noErr;
  }
  return NO;
}

+ (void)setAutoStart:(BOOL)flag {
  CFArrayRef items = SKLoginItemCopyItems();
  if (items) {
    CFBundleRef bundle = CFBundleGetMainBundle();
    CFURLRef sparkd = CFBundleCopyAuxiliaryExecutableURL(bundle, kSparkDaemonExecutable);
    if (sparkd) {
      CFIndex idx;
      BOOL shouldAdd = YES;
      CFIndex count = CFArrayGetCount(items);
      /* Should start from last index else removing an item will change enumeration */
      for (idx = count-1; idx >= 0; idx--) {
        CFDictionaryRef item = CFArrayGetValueAtIndex(items, idx);
        CFURLRef itemURL = CFDictionaryGetValue(item, kSKLoginItemURL);
        if (itemURL) {
          CFStringRef name = CFURLCopyLastPathComponent(itemURL);
          if (name) {
            if (CFEqual(name, kSparkDaemonExecutable)) {
              if (!flag || !__CFFileURLCompare(itemURL, sparkd)) {
                DLog(@"Item no longer valid! %@", itemURL);
#if !defined(DEBUG)
                SKLoginItemRemoveItemAtIndex(idx);
#endif
              } else {
                DLog(@"Current item is ok");
                shouldAdd = NO;
              }
            } 
            CFRelease(name);
          }
        }
      }
      if (flag && shouldAdd) {
#if !defined(DEBUG)
        SKLoginItemAppendItemURL(sparkd, YES);
#else
        DLog(@"Add login item: %@", sparkd);
#endif
      }
      CFRelease(sparkd);
    } else {
      DLog(@"Warning: Spark Daemon cannot be found");
    }
    CFRelease(items);
  }
}

+ (void)verifyAutoStart {
  BOOL state = [[NSUserDefaults standardUserDefaults] boolForKey:kSparkPrefAutoStart];
  [self setAutoStart:state];
}

#pragma mark -
#pragma mark Update Preferences File.
+ (void)setDefaultsValues {
  id values = [NSDictionary dictionaryWithObjectsAndKeys:
    SKBool(YES), kSparkPrefAutoStart,
    SKInt(1), kSparkPrefSingleKeyMode,
    SKBool(YES), kSparkPrefDisplayPlugins,
    SKBool(NO), kSparkPrefConfirmDeleteKey,
    SKBool(NO), kSparkPrefConfirmDeleteList,
    SKBool(NO), kSparkPrefConfirmDeleteAction,
    nil];
  [[NSUserDefaults standardUserDefaults] registerDefaults:values];
  /* Configure Single key mode */
  SetSparkKitSingleKeyMode([[NSUserDefaults standardUserDefaults] integerForKey:kSparkPrefSingleKeyMode]);
}

#pragma mark -
#pragma mark Update Preferences File.
+ (void)checkVersion {
  NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
  int version = [prefs integerForKey:kSparkPrefVersion];
  if (version == 0) {
    BOOL temp = [prefs boolForKey:@"Auto Start"];
    [prefs removeObjectForKey:@"Auto Start"];
    [prefs setBool:temp forKey:kSparkPrefAutoStart];
    
    temp = [prefs boolForKey:@"ConfirmDeleteKey"];
    [prefs removeObjectForKey:@"ConfirmDeleteKey"];
    [prefs setBool:temp forKey:kSparkPrefConfirmDeleteKey];
    
    temp = [prefs boolForKey:@"ConfirmDeleteList"];
    [prefs removeObjectForKey:@"ConfirmDeleteList"];
    [prefs setBool:temp forKey:kSparkPrefConfirmDeleteList];
    
    [prefs removeObjectForKey:@"WarningDeleteKey"];
    
    temp = [prefs boolForKey:@"displayPlugIns"];
    [prefs removeObjectForKey:@"displayPlugIns"];
    [prefs setBool:temp forKey:kSparkPrefDisplayPlugins];
    
    [prefs removeObjectForKey:@"SelectedList"];
    
    /* Remove deprecated items */
    CFArrayRef items = SKLoginItemCopyItems();
    if (items) {
      CFIndex idx;
      CFIndex count = CFArrayGetCount(items);
      /* Should start from last index else removing an item will change enumeration */
      for (idx = count-1; idx >= 0; idx--) {
        CFDictionaryRef item = CFArrayGetValueAtIndex(items, idx);
        CFURLRef itemURL = CFDictionaryGetValue(item, kSKLoginItemURL);
        if (itemURL) {
          CFStringRef name = CFURLCopyLastPathComponent(itemURL);
          if (name) {
            if (CFEqual(name, @"SparkDaemonHelper")) {
              DLog(@"Item no longer valid! %@", itemURL);
#if !defined(DEBUG)
              SKLoginItemRemoveItemAtIndex(idx);
#endif
            } 
            CFRelease(name);
          }
        }
      }
      CFRelease(items);
    }    
    
    [prefs setInteger:kSparkCurrentVersion forKey:@"SparkVersion"];
    [prefs synchronize];
  }
}

@end
