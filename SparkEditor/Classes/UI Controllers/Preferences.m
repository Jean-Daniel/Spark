//
//  Preferences.m
//  Spark
//
//  Created by Fox on Wed Jan 21 2004.
//  Copyright (c) 2004 Shadow Lab. All rights reserved.
//

#import <SparkKit/SparkKit.h>
#import "Preferences.h"

#define SPARK_LAUNCHER		@"Spark Daemon"

NSString * const kSparkPrefVersion = @"SparkVersion";
NSString * const kSparkPrefAutoStart = @"SparkAutoStart";
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
  autoStartBak = autoStart;
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

- (void)windowWillClose:(NSNotification *)aNotification {
  if (autoStartBak != autoStart) {
    [Preferences setAutoStart:autoStart];
    autoStartBak = autoStart;
  }
  [[NSUserDefaults standardUserDefaults] setBool:autoStart forKey:kSparkPrefAutoStart];
  [[NSUserDefaults standardUserDefaults] synchronize];
}

+ (BOOL)autoStart {
  BOOL start = NO;
  id items = (id)CFPreferencesCopyValue(CFSTR("AutoLaunchedApplicationDictionary"),
                                        CFSTR("loginwindow"),
                                        kCFPreferencesCurrentUser,
                                        kCFPreferencesAnyHost);
  items = [[items autorelease] mutableCopy];
  id loginItems = [items objectEnumerator];
  id item;
  while ((item = [loginItems nextObject]) && !start) {
    NSRange range = [[item objectForKey:@"Path"] rangeOfString:SPARK_LAUNCHER options:nil];
    if (range.location != NSNotFound) {
      start = YES;
    }
  }
  [items release];
  return start;
}

+ (void)setAutoStart:(BOOL)flag {
  id items = (id)CFPreferencesCopyValue(CFSTR("AutoLaunchedApplicationDictionary"),
                                        CFSTR("loginwindow"),
                                        kCFPreferencesCurrentUser,
                                        kCFPreferencesAnyHost);
  items = (items != nil) ? [[items autorelease] mutableCopy] : [[NSMutableArray alloc] init];
  id path = [[NSBundle mainBundle] pathForAuxiliaryExecutable:[SPARK_LAUNCHER stringByAppendingPathExtension:@"app"]];
  if (flag) {
    DLog(@"Auto Start On");
    if (![self autoStart]) {
      SKAlias *alias = [SKAlias aliasWithPath:path];
      id data = [alias data];
      if (!data) {
        NSLog(@"Error unable to find Daemon at path: %@", path);
        return;
      }
      id dico = [NSMutableDictionary dictionary];
      [dico setObject:[path stringByAbbreviatingWithTildeInPath] forKey:@"Path"];
      [dico setObject:data forKey:@"AliasData"];
      [dico setObject:SKBool(YES) forKey:@"Hide"];
      [items insertObject:dico atIndex:0];
    }
  }
  else {
    DLog(@"AutoStart Off");
    id loginItems = [items objectEnumerator];
    id item;
    while (item = [loginItems nextObject]) {
      NSRange range = [[item objectForKey:@"Path"] rangeOfString:SPARK_LAUNCHER options:nil];
      if (range.location != NSNotFound) {
        [items removeObject:item];
      }
    }
  }
  CFPreferencesSetValue(CFSTR("AutoLaunchedApplicationDictionary"),
                        (CFPropertyListRef)items,
                        CFSTR("loginwindow"),
                        kCFPreferencesCurrentUser,
                        kCFPreferencesAnyHost);
  CFPreferencesSynchronize(CFSTR("loginwindow"), kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
  [items release];
}

+ (void)verifyAutoStart {
#ifndef DEBUG
  BOOL state = [[NSUserDefaults standardUserDefaults] boolForKey:kSparkPrefAutoStart];

  // Si Auto start activé dans les prefs
  if (state) {
    /* Dans tout les cas on vérifie */
    id items = (id)CFPreferencesCopyValue(CFSTR("AutoLaunchedApplicationDictionary"),
                                          CFSTR("loginwindow"),
                                          kCFPreferencesCurrentUser,
                                          kCFPreferencesAnyHost);
    [items autorelease];
    // On regarde s'il est dans les login items.
    id loginItems = [items objectEnumerator];
    id item;
    while (item = [loginItems nextObject]) {
      NSRange range = [[item objectForKey:@"Path"] rangeOfString:SPARK_LAUNCHER options:nil];
      /* 
       * Si on le trouve, on vérifie que l'alias est valide, et qu'il pointe bien sur le daemon contenu dans l'appli.
       * S'il n'est pas bon, on le supprime.
       */
      if (range.location != NSNotFound) {
        SKAlias *alias = [SKAlias aliasWithData:[item objectForKey:@"AliasData"]];
        if (![alias path] || [[[NSBundle mainBundle] bundlePath] rangeOfString:[alias path] options:nil].location == NSNotFound) {
          [self setAutoStart:NO];
          break;
        }
        else return;
      }
    }
  }
  [self setAutoStart:state];
#else
#warning Disable Verify Autostart.
#endif
}

#pragma mark -
#pragma mark Update Preferences File.
+ (void)setDefaultsValues {
  id values = [NSDictionary dictionaryWithObjectsAndKeys:
    SKBool(YES), kSparkPrefAutoStart,
    SKBool(YES), kSparkPrefDisplayPlugins,
    SKBool(NO), kSparkPrefConfirmDeleteKey,
    SKBool(NO), kSparkPrefConfirmDeleteList,
    SKBool(NO), kSparkPrefConfirmDeleteAction,
    nil];
  [[NSUserDefaults standardUserDefaults] registerDefaults:values];
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
    
    id items = (id)CFPreferencesCopyValue(CFSTR("AutoLaunchedApplicationDictionary"),
                                          CFSTR("loginwindow"),
                                          kCFPreferencesCurrentUser,
                                          kCFPreferencesAnyHost);
    // On regarde s'il est dans les login items.
    id loginItems = [items objectEnumerator];
    id item;
    while (item = [loginItems nextObject]) {
      NSRange range = [[item objectForKey:@"Path"] rangeOfString:@"SparkDaemonHelper" options:nil];
      // Si on le trouve, on vérifie que l'alias est valide, s'il ne l'est pas, on le supprime.
      if (range.location != NSNotFound) {
        [items removeObject:item];
      }
    }
    CFPreferencesSetValue(CFSTR("AutoLaunchedApplicationDictionary"),
                          (CFPropertyListRef)items,
                          CFSTR("loginwindow"),
                          kCFPreferencesCurrentUser,
                          kCFPreferencesAnyHost);
    CFPreferencesSynchronize(CFSTR("loginwindow"), kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
    [items release];
    [prefs setInteger:kSparkCurrentVersion forKey:@"SparkVersion"];
    [prefs synchronize];
  }
}

@end
