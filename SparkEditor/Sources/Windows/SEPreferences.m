/*
 *  SEPreferences.m
 *  Spark Editor
 *
 *  Created by Black Moon Team.
 *  Copyright (c) 2004 - 2007 Shadow Lab. All rights reserved.
 */

#import "SEPreferences.h"

#import "Spark.h"
#import "SEUpdater.h"
#import "SEServerConnection.h"

#import <SparkKit/SparkKit.h>
#import <SparkKit/SparkPlugIn.h>
#import <SparkKit/SparkHotKey.h>
#import <SparkKit/SparkLibrary.h>
#import <SparkKit/SparkPreferences.h>
#import <SparkKit/SparkActionLoader.h>

#import <ShadowKit/SKLoginItems.h>
#import <ShadowKit/SKFSFunctions.h>
#import <ShadowKit/SKAEFunctions.h>

#include <pthread.h>

/* If daemon should delay library loading at startup */
NSString * const kSparkGlobalPrefDelayStartup = @"SDDelayStartup";

NSString * const kSparkVersionKey = @"SparkVersion";

/* Hide entry is plugin is disabled */
NSString * const kSEPreferencesHideDisabled = @"SparkHideDisabled";
/* If daemon should automatically start at login */
NSString * const kSEPreferencesStartAtLogin = @"SparkStartAtLogin";

/* If should check update automatically */
NSString * const kSEPreferencesAutoUpdate = @"SparkAutoUpdate";

/* Define which single key shortcut is allow */
NSString * const kSparkPrefSingleKeyMode = @"SparkSingleKeyMode";

/* Toolbar items */
static NSString * const kSparkPreferencesToolbarGeneralItem = @"SparkPreferencesToolbarGeneralItem";
static NSString * const kSparkPreferencesToolbarPluginsItem = @"SparkPreferencesToolbarPluginsItem";
static NSString * const kSparkPreferencesToolbarUpdateItem = @"SparkPreferencesToolbarUpdateItem";
static NSString * const kSparkPreferencesToolbarAdvancedItem = @"SparkPreferencesToolbarAdvancedItem";

static
void _SEPreferencesUpdateLoginItem(void);

SK_INLINE
BOOL __SEPreferencesLoginItemStatus() {
  return [[NSUserDefaults standardUserDefaults] boolForKey:kSEPreferencesStartAtLogin];
}

void SEPreferencesSetLoginItemStatus(BOOL status) {
  [[NSUserDefaults standardUserDefaults] setBool:status forKey:kSEPreferencesStartAtLogin];
  _SEPreferencesUpdateLoginItem();
}

SK_INLINE
void __SetSparkKitSingleKeyMode(NSInteger mode) {
  SparkSetFilterMode((mode >= 0 && mode <= 3) ? mode : kSparkEnableSingleFunctionKey);
}

@implementation SEPreferences

+ (void)initialize {
  if ([SEPreferences class] == self) {
    SKLoginItemSetTimeout(1200);
  }
}

static
void *_SEPreferencesLoginItemThread(void *arg) {
  long timeout = SKLoginItemTimeout();
  SKLoginItemSetTimeout(5000);
  NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
  _SEPreferencesUpdateLoginItem();
  [pool release];
  SKLoginItemSetTimeout(timeout);
  return NULL;
}

/* Default values initialization */
+ (void)setup {
  NSDictionary *values = [NSDictionary dictionaryWithObjectsAndKeys:
    SKBool(NO), kSEPreferencesAutoUpdate,
    SKBool(NO), kSEPreferencesHideDisabled,
    SKBool(YES), kSEPreferencesStartAtLogin,
    SKInteger(kSparkEnableSingleFunctionKey), kSparkPrefSingleKeyMode,
    nil];
  [[NSUserDefaults standardUserDefaults] registerDefaults:values];
  
  /* Verify login items */
  pthread_t thread;
  pthread_create(&thread, NULL, _SEPreferencesLoginItemThread, NULL);
  //_SEPreferencesUpdateLoginItem();
  
  /* Configure Single key mode */
  __SetSparkKitSingleKeyMode([[NSUserDefaults standardUserDefaults] integerForKey:kSparkPrefSingleKeyMode]);
}

+ (BOOL)synchronize {
  BOOL user = [[NSUserDefaults standardUserDefaults] synchronize];
  BOOL shared = SparkPreferencesSynchronize(SparkPreferencesDaemon);
  shared = shared && SparkPreferencesSynchronize(SparkPreferencesLibrary);
  shared = shared && SparkPreferencesSynchronize(SparkPreferencesFramework);
  return user && shared;
}

- (id)init {
  if (self = [super init]) {
    se_login = __SEPreferencesLoginItemStatus();
    se_status = NSCreateMapTable(NSObjectMapKeyCallBacks, NSIntegerMapValueCallBacks, 0);
    se_plugins = [[NSMutableArray alloc] init];
  }
  return self;
}

- (void)dealloc {
  [se_plugins release];
  if (se_status) NSFreeMapTable(se_status);
  [super dealloc];
}

#pragma mark -
- (void)awakeFromNib {
  /* set toolbar */
  NSToolbar *toolbar = [[NSToolbar alloc] initWithIdentifier:@"SparkPreferencesToolbar"];
  [toolbar setDelegate:self];
  [toolbar setAllowsUserCustomization:NO];
  [toolbar setDisplayMode:NSToolbarDisplayModeIconAndLabel];
  [toolbar setSelectedItemIdentifier:kSparkPreferencesToolbarGeneralItem];
  [[self window] setToolbar:[toolbar autorelease]];
  [[self window] setShowsToolbarButton:NO];
  
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
    NSLocalizedString(@"Built-in", @"Plugin preferences domain - built-in"), @"name",
    bplugs, @"plugins",
    [NSImage imageNamed:@"application"], @"icon", nil];
  [se_plugins addObject:item];
  
  item = [NSDictionary dictionaryWithObjectsAndKeys:
    NSLocalizedString(@"Computer", @"Plugin preferences domain - computer"), @"name",
    lplugs, @"plugins",
    [NSImage imageNamed:@"computer"], @"icon", nil];
  [se_plugins addObject:item];
  
  item = [NSDictionary dictionaryWithObjectsAndKeys:
    NSLocalizedString(@"User", @"Plugin preferences domain - user"), @"name",
    uplugs, @"plugins",
    [NSImage imageNamed:@"user"], @"icon", nil];
  [se_plugins addObject:item];
  
  [uiPlugins reloadData];
  for (NSUInteger idx = 0; idx < [se_plugins count]; idx++) {
    item = [se_plugins objectAtIndex:idx];
    if ([[item objectForKey:@"plugins"] count])
      [uiPlugins expandItem:item];
  }
}

- (IBAction)apply:(id)sender {
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
  /* Check login items */
  if (se_login != __SEPreferencesLoginItemStatus()) {
    se_login = __SEPreferencesLoginItemStatus();
    _SEPreferencesUpdateLoginItem();
  }
  
  /* Unbind to release */
//  [ibController setContent:nil];
}

- (IBAction)close:(id)sender {
  [self apply:sender];
  [super close:sender];
  if (se_update)
    [[SEUpdater sharedUpdater] cancel:nil];
}

#pragma mark -
#pragma mark Preferences
- (float)delay {
  NSNumber *value = SparkPreferencesGetValue(kSparkGlobalPrefDelayStartup, SparkPreferencesDaemon);
  return value ? [value floatValue] : 0;
}
- (void)setDelay:(float)delay {
  SparkPreferencesSetValue(kSparkGlobalPrefDelayStartup, SKFloat(delay), SparkPreferencesDaemon);
}

- (BOOL)advanced {
  return SparkPreferencesGetBooleanValue(@"SparkAdvancedSettings", SparkPreferencesFramework);
}
- (void)setAdvanced:(BOOL)advanced {
  SparkPreferencesSetBooleanValue(@"SparkAdvancedSettings", advanced, SparkPreferencesFramework);
}

- (BOOL)displaysAlert {
  return SparkPreferencesGetBooleanValue(@"SDDisplayAlertOnExecute", SparkPreferencesDaemon);
}
- (void)setDisplaysAlert:(BOOL)flag {
  SparkPreferencesSetBooleanValue(@"SDDisplayAlertOnExecute", flag, SparkPreferencesDaemon);
}

#pragma mark Single Key Mode
- (NSInteger)singleKeyMode {
  NSInteger mode = SparkGetFilterMode();
  return (mode >= 0 && mode <= 3) ? mode : kSparkEnableSingleFunctionKey;
}

- (void)setSingleKeyMode:(NSInteger)mode {
  __SetSparkKitSingleKeyMode(mode);
  [[NSUserDefaults standardUserDefaults] setInteger:mode forKey:kSparkPrefSingleKeyMode];
}

#pragma mark Update
- (IBAction)update:(id)sender {
  if (!se_update) {
    se_update = YES;
    [uiUpdateStatus setHidden:NO];
    [uiUpdateMsg setStringValue:@""];
    [uiProgress setIndeterminate:YES];
    [uiProgress startAnimation:sender];
    [[SEUpdater sharedUpdater] searchWithDelegate:self];
  }
}

- (void)updater:(SEUpdater *)updater didSearchVersion:(BOOL)version error:(NSError *)anError {
  [uiProgress stopAnimation:nil];
  if (!version && !anError) {
    [uiUpdateMsg setStringValue:@"No new version available."];
  } else if (anError) {
    NSString *str = [anError localizedDescription];
    if (str)
      [uiUpdateMsg setStringValue:[NSString stringWithFormat:@"Error: %@.", str]];
    else
      [uiUpdateMsg setStringValue:@"Undefined error occured"];
  }
  [uiUpdateStatus setHidden:YES];
  se_update = NO;
}

#pragma mark -
#pragma mark Plugin Manager
- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item {
  return !item || ![item isKindOfClass:[SparkPlugIn class]];
}
- (NSInteger)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item {
  return item ? [[item objectForKey:@"plugins"] count] : [se_plugins count];
}
- (id)outlineView:(NSOutlineView *)outlineView child:(NSInteger)anIndex ofItem:(id)item {
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
  NSInteger row = [aView selectedRow];
  if (row > 0) {
    id item = [aView itemAtRow:row];
    if (item && [item isKindOfClass:[SparkPlugIn class]]) {
      DLog(@"Delete plugin: %@", item);
    }
  }
}

#pragma mark Toolbar
- (IBAction)changePanel:(id)sender {
  [uiPanels selectTabViewItemAtIndex:[sender tag]];
}

- (NSToolbarItem *)toolbar:(NSToolbar *)toolbar itemForItemIdentifier:(NSString *)itemIdentifier willBeInsertedIntoToolbar:(BOOL)flag {
  NSToolbarItem *toolbarItem = [[[NSToolbarItem alloc] initWithItemIdentifier: itemIdentifier] autorelease];
  if ([kSparkPreferencesToolbarGeneralItem isEqualToString:itemIdentifier]) {
    [toolbarItem setTag:0];
    [toolbarItem setLabel:@"General"];
    [toolbarItem setImage:[NSImage imageNamed:@"generalpref"]];
  } else if ([kSparkPreferencesToolbarPluginsItem isEqualToString:itemIdentifier]) {
    [toolbarItem setTag:1];
    [toolbarItem setLabel:@"Plugins"];
    [toolbarItem setImage:[NSImage imageNamed:@"pluginpref"]];
  } else if ([kSparkPreferencesToolbarUpdateItem isEqualToString:itemIdentifier]) {
    [toolbarItem setTag:2];
    [toolbarItem setLabel:@"Update"];
    [toolbarItem setImage:[NSImage imageNamed:@"updatepref"]];
  } else if ([kSparkPreferencesToolbarAdvancedItem isEqualToString:itemIdentifier]) {
    [toolbarItem setTag:3];
    [toolbarItem setLabel:@"Advanced"];
    [toolbarItem setImage:[NSImage imageNamed:@"advancedpref"]];
  }
  
  // Tell the item what message to send when it is clicked
  [toolbarItem setTarget:self];
  [toolbarItem setAction:@selector(changePanel:)];
  return toolbarItem;
}

- (NSArray *)toolbarDefaultItemIdentifiers:(NSToolbar*)toolbar {
  return [NSArray arrayWithObjects:kSparkPreferencesToolbarGeneralItem, 
    kSparkPreferencesToolbarPluginsItem,
    kSparkPreferencesToolbarUpdateItem,
    kSparkPreferencesToolbarAdvancedItem, nil];
}

- (NSArray *)toolbarAllowedItemIdentifiers:(NSToolbar*)toolbar {
  return [NSArray arrayWithObjects:kSparkPreferencesToolbarGeneralItem, 
    kSparkPreferencesToolbarPluginsItem,
    kSparkPreferencesToolbarUpdateItem,
    kSparkPreferencesToolbarAdvancedItem, nil];
}

- (NSArray *)toolbarSelectableItemIdentifiers:(NSToolbar *)toolbar {
  return [NSArray arrayWithObjects:kSparkPreferencesToolbarGeneralItem, 
    kSparkPreferencesToolbarPluginsItem,
    kSparkPreferencesToolbarUpdateItem,
    kSparkPreferencesToolbarAdvancedItem, nil];
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
