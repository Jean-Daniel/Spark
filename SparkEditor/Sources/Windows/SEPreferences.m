/*
 *  SEPreferences.m
 *  Spark Editor
 *
 *  Created by Black Moon Team.
 *  Copyright (c) 2004 - 2007 Shadow Lab. All rights reserved.
 */

#import "SEPreferences.h"

#import "Spark.h"
#import "SEServerConnection.h"

#import <SparkKit/SparkKit.h>
#import <SparkKit/SparkPlugIn.h>
#import <SparkKit/SparkHotKey.h>
#import <SparkKit/SparkLibrary.h>
#import <SparkKit/SparkActionLoader.h>

#import <ShadowKit/SKLoginItems.h>
#import <ShadowKit/SKFSFunctions.h>

/* If daemon should delay library loading at startup */
CFStringRef kSparkGlobalPrefDelayStartup = CFSTR("SDDelayStartup");

NSString * const kSparkPrefVersion = @"SparkVersion";

/* Hide entry is plugin is disabled */
NSString * const kSparkPrefHideDisabled = @"SparkHideDisabled";
/* If daemon should automatically start at login */
NSString * const kSparkPrefStartAtLogin = @"SparkStartAtLogin";
/* Define which single key shortcut is allow */
NSString * const kSparkPrefSingleKeyMode = @"SparkSingleKeyMode";

static
void _SEPreferencesUpdateLoginItem(void);

SK_INLINE
BOOL __SEPreferencesLoginItemStatus() {
  return [[NSUserDefaults standardUserDefaults] boolForKey:kSparkPrefStartAtLogin];
}

void SEPreferencesSetLoginItemStatus(BOOL status) {
  [[NSUserDefaults standardUserDefaults] setBool:status forKey:kSparkPrefStartAtLogin];
  _SEPreferencesUpdateLoginItem();
}

SK_INLINE
void __SetSparkKitSingleKeyMode(int mode) {
  SparkKeyStrokeFilterMode = (mode >= 0 && mode <= 3) ? mode : kSparkEnableSingleFunctionKey;
}

@implementation SEPreferences

+ (void)setup {
  NSDictionary *values = [NSDictionary dictionaryWithObjectsAndKeys:
    SKBool(NO), kSparkPrefHideDisabled,
    SKBool(YES), kSparkPrefStartAtLogin,
    SKInt(kSparkEnableSingleFunctionKey), kSparkPrefSingleKeyMode,
    nil];
  [[NSUserDefaults standardUserDefaults] registerDefaults:values];
  
  /* Verify login items */
  _SEPreferencesUpdateLoginItem();
  
  /* Configure Single key mode */
  __SetSparkKitSingleKeyMode([[NSUserDefaults standardUserDefaults] integerForKey:kSparkPrefSingleKeyMode]);
}

+ (BOOL)synchronize {
  return [[NSUserDefaults standardUserDefaults] synchronize] && CFPreferencesAppSynchronize((CFStringRef)kSparkPreferencesIdentifier);
}

- (id)init {
  if (self = [super init]) {
    se_login = __SEPreferencesLoginItemStatus();
    se_status = NSCreateMapTable(NSObjectMapKeyCallBacks, NSIntMapValueCallBacks, 0);
    se_plugins = [[NSMutableArray alloc] init];
  }
  return self;
}

- (void)dealloc {
  [se_plugins release];
  if (se_status) NSFreeMapTable(se_status);
  [super dealloc];
}

- (void)awakeFromNib {
  /* Set outline column */
  [ibPlugins setOutlineTableColumn:[ibPlugins tableColumnWithIdentifier:@"__item__"]];
  
  /* Load plugins */
  NSMutableArray *uplugs = [NSMutableArray array];
  NSMutableArray *lplugs = [NSMutableArray array];
  NSMutableArray *bplugs = [NSMutableArray array];
  
  FSRef uref, lref;
  BOOL user = NO, local = NO;
  if ([[SparkActionLoader pluginPathForDomain:kSKUserDomain] getFSRef:&uref]) {
    user = YES;
  }
  if ([[SparkActionLoader pluginPathForDomain:kSKLocalDomain] getFSRef:&lref]) {
    local = YES;
  }
  
  SparkPlugIn *plugin;
  NSEnumerator *plugins = [[[[SparkActionLoader sharedLoader] plugins] sortedArrayUsingDescriptors:gSortByNameDescriptors] objectEnumerator];
  while (plugin = [plugins nextObject]) {
    FSRef path;
    BOOL done = NO;
    if ([[[plugin path] stringByDeletingLastPathComponent] getFSRef:&path]) {
      if (user && noErr == FSCompareFSRefs(&path, &uref)) {
        done = YES;
        [uplugs addObject:plugin];
      } else if (local  && noErr == FSCompareFSRefs(&path, &lref)) {
        done = YES;
        [lplugs addObject:plugin];
      }
    } 
    if (!done) {
      [bplugs addObject:plugin];
    }
    /* Save status */
    long status = [plugin isEnabled];
    NSMapInsert(se_status, plugin, (void *)status);
  }
  NSDictionary *item = [NSDictionary dictionaryWithObjectsAndKeys:
    @"Built-in", @"name",
    bplugs, @"plugins",
    [NSImage imageNamed:@"application"], @"icon", nil];
  [se_plugins addObject:item];
  
  item = [NSDictionary dictionaryWithObjectsAndKeys:
    @"Computer", @"name",
    lplugs, @"plugins",
    [NSImage imageNamed:@"computer"], @"icon", nil];
  [se_plugins addObject:item];
  
  item = [NSDictionary dictionaryWithObjectsAndKeys:
    @"User", @"name",
    uplugs, @"plugins",
    [NSImage imageNamed:@"user"], @"icon", nil];
  [se_plugins addObject:item];
  
  [ibPlugins reloadData];
  for (unsigned idx = 0; idx < [se_plugins count]; idx++) {
    item = [se_plugins objectAtIndex:idx];
    if ([[item objectForKey:@"plugins"] count])
      [ibPlugins expandItem:item];
  }
}

- (IBAction)close:(id)sender {
  BOOL change = NO;
  long status = status;
  SparkPlugIn *plugin = nil;
  NSMapEnumerator plugins = NSEnumerateMapTable(se_status);
  while (NSNextMapEnumeratorPair(&plugins, (void **)&plugin, (void **)&status)) {
    if (XOR(status, [plugin isEnabled])) {
      [plugin setEnabled:status];
      change = YES;
    }
  }
  if (change) {
    [[NSNotificationCenter defaultCenter] postNotificationName:SESparkEditorDidChangePluginStatusNotification
                                                        object:nil];
  }
//    /* Invalidate entries cache */
//    [[SEEntriesManager sharedManager] reload];
//  } else {
//    [[SEEntriesManager sharedManager] refresh];
//  }
  /* Check login items */
  if (se_login != __SEPreferencesLoginItemStatus())
    _SEPreferencesUpdateLoginItem();
  
  /* Unbind to release */
  [ibController setContent:nil];
  
  [super close:sender];
}

#pragma mark -
#pragma mark Preferences
- (float)delay {
  float value = 0;
  CFNumberRef ref = CFPreferencesCopyAppValue(kSparkGlobalPrefDelayStartup, (CFStringRef)kSparkPreferencesIdentifier);
  if (ref) {
    CFNumberGetValue(ref, kCFNumberFloatType, &value);
    CFRelease(ref);
  }
  return value;
}
- (void)setDelay:(float)delay {
  CFNumberRef ref = CFNumberCreate(kCFAllocatorDefault, kCFNumberFloatType, &delay);
  if (ref) {
    CFPreferencesSetAppValue(kSparkGlobalPrefDelayStartup, ref, (CFStringRef)kSparkPreferencesIdentifier);
    CFRelease(ref);
  }
}

#pragma mark Single Key Mode
- (int)singleKeyMode {
  int mode = SparkKeyStrokeFilterMode;
  return (mode >= 0 && mode <= 3) ? mode : kSparkEnableSingleFunctionKey;
}

- (void)setSingleKeyMode:(int)mode {
  __SetSparkKitSingleKeyMode(mode);
  [[NSUserDefaults standardUserDefaults] setInteger:mode forKey:kSparkPrefSingleKeyMode];
}

#pragma mark -
#pragma mark Plugin Manager
- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item {
  return !item || ![item isKindOfClass:[SparkPlugIn class]];
}
- (int)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item {
  return item ? [[item objectForKey:@"plugins"] count] : [se_plugins count];
}
- (id)outlineView:(NSOutlineView *)outlineView child:(int)anIndex ofItem:(id)item {
  return item ? [[item objectForKey:@"plugins"] objectAtIndex:anIndex] : [se_plugins objectAtIndex:anIndex];
}
- (id)outlineView:(NSOutlineView *)outlineView objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(id)item {
  if ([item isKindOfClass:[SparkPlugIn class]]) {
    if ([[tableColumn identifier] isEqualToString:@"__item__"])
      return item;
    else if ([[tableColumn identifier] isEqualToString:@"enabled"])
      return SKBool(NSMapGet(se_status, item) != 0); 
    else
      return [item valueForKey:[tableColumn identifier]];
  } else if ([item isKindOfClass:[NSDictionary class]]) {
    if ([[tableColumn identifier] isEqualToString:@"__item__"])
      return item;
  }
  return nil;
}

- (void)outlineView:(NSOutlineView *)outlineView setObjectValue:(id)object forTableColumn:(NSTableColumn *)tableColumn byItem:(id)item {
  if ([item isKindOfClass:[SparkPlugIn class]] && [[tableColumn identifier] isEqualToString:@"enabled"]) {
    if (NSMapMember(se_status, item, NULL, NULL)) {
      NSMapInsert(se_status, item, (void *)[object longValue]);
    }
  }
}

- (void)outlineView:(NSOutlineView *)outlineView willDisplayCell:(id)cell forTableColumn:(NSTableColumn *)tableColumn item:(id)item {
  if ([item isKindOfClass:[SparkPlugIn class]]) {
    if ([[tableColumn identifier] isEqualToString:@"enabled"]) {
      [cell setEnabled:YES];
      [cell setTransparent:NO];
    }
  } else {
    if ([[tableColumn identifier] isEqualToString:@"enabled"]) {
      [cell setEnabled:NO];
      [cell setTransparent:YES];
    }
  }
}

- (void)deleteSelectionInOutlineView:(NSOutlineView *)aView {
  int row = [aView selectedRow];
  if (row > 0) {
    id item = [aView itemAtRow:row];
    if (item && [item isKindOfClass:[SparkPlugIn class]]) {
      DLog(@"Delete plugin: %@", item);
    }
  }
}

@end

#pragma mark -
SK_INLINE
BOOL __CFFileURLCompare(CFURLRef url1, CFURLRef url2) {
  FSRef r1, r2;
  if (CFURLGetFSRef(url1, &r1) && CFURLGetFSRef(url2, &r2)) {
    return FSCompareFSRefs(&r1, &r2) == noErr;
  }
  return NO;
}

void _SEPreferencesUpdateLoginItem() {
  BOOL status = __SEPreferencesLoginItemStatus();
  
  CFArrayRef items = SKLoginItemCopyItems();
  if (items) {
    NSString *sparkd = SESparkDaemonPath();
    NSURL *durl = sparkd ? [NSURL fileURLWithPath:sparkd] : NULL;
    
    if (durl) {
      BOOL shouldAdd = status;
      CFIndex idx = CFArrayGetCount(items);
      while (idx-- > 0) {
        CFDictionaryRef item = CFArrayGetValueAtIndex(items, idx);
        CFURLRef itemURL = CFDictionaryGetValue(item, kSKLoginItemURL);
        if (itemURL) {
          CFStringRef name = CFURLCopyLastPathComponent(itemURL);
          if (name) {
            if (CFEqual(name, kSparkDaemonExecutableName)) {
              if (!status || !__CFFileURLCompare(itemURL, (CFURLRef)durl)) {
                DLog(@"Remove login item: %@", itemURL);
#if !defined(DEBUG)
                SKLoginItemRemoveItemAtIndex(idx);
#endif
              } else {
                DLog(@"Valid login item found");
                shouldAdd = NO;
              }
            } 
            CFRelease(name);
          }
        }
      }
      /* Append login item if needed */
      if (shouldAdd) {
#if !defined(DEBUG)
        SKLoginItemAppendItemURL((CFURLRef)durl, YES);
#else
        DLog(@"Add login item: %@", durl);
#endif
      }
    }
    CFRelease(items);
  }
}
