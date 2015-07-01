/*
 *  SEPreferences.m
 *  Spark Editor
 *
 *  Created by Black Moon Team.
 *  Copyright (c) 2004 - 2007 Shadow Lab. All rights reserved.
 */

#import "SEPreferences.h"

#import "Spark.h"
#import "SparkleDelegate.h"
#import "SEServerConnection.h"

#import <SparkKit/SparkKit.h>
#import <SparkKit/SparkPlugIn.h>
#import <SparkKit/SparkHotKey.h>
#import <SparkKit/SparkLibrary.h>
#import <SparkKit/SparkPreferences.h>
#import <SparkKit/SparkActionLoader.h>

#import <WonderBox/WBFSFunctions.h>
#import <WonderBox/WBAEFunctions.h>

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
static NSString * const kSparkPreferencesToolbarPlugInsItem = @"SparkPreferencesToolbarPlugInsItem";
static NSString * const kSparkPreferencesToolbarUpdateItem = @"SparkPreferencesToolbarUpdateItem";
static NSString * const kSparkPreferencesToolbarAdvancedItem = @"SparkPreferencesToolbarAdvancedItem";

static
void _SEPreferencesUpdateLoginItem(void);

WB_INLINE
BOOL __SEPreferencesLoginItemStatus(void) {
  return [[NSUserDefaults standardUserDefaults] boolForKey:kSEPreferencesStartAtLogin];
}

void SEPreferencesSetLoginItemStatus(BOOL status) {
  [[NSUserDefaults standardUserDefaults] setBool:status forKey:kSEPreferencesStartAtLogin];
  _SEPreferencesUpdateLoginItem();
}

WB_INLINE
void __SetSparkKitSingleKeyMode(NSInteger mode) {
  SparkSetFilterMode((mode >= 0 && mode <= 3) ? mode : kSparkEnableSingleFunctionKey);
}

@implementation SEPreferences {
  BOOL se_login;
  BOOL se_update;
  NSMapTable *_status;
  NSMutableArray *_plugins;
}

/* Default values initialization */
+ (void)setup {
  NSDictionary *values = [NSDictionary dictionaryWithObjectsAndKeys:
													@(NO), kSEPreferencesAutoUpdate,
													@(NO), kSEPreferencesHideDisabled,
													@(YES), kSEPreferencesStartAtLogin,
													@(kSparkEnableSingleFunctionKey), kSparkPrefSingleKeyMode,
													nil];
  [[NSUserDefaults standardUserDefaults] registerDefaults:values];
  
  /* Verify login items */
  _SEPreferencesUpdateLoginItem();
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
    _status = [[NSMapTable alloc] initWithKeyOptions:NSPointerFunctionsStrongMemory | NSPointerFunctionsObjectPersonality
                                        valueOptions:NSPointerFunctionsStrongMemory | NSPointerFunctionsObjectPersonality
                                            capacity:0];
    _plugins = [[NSMutableArray alloc] init];
  }
  return self;
}

#pragma mark -
- (void)se_initPlugInStatus:(NSArray *)plugins {
  for (SparkPlugIn *plugin in plugins)
    [_status setObject:@(plugin.enabled) forKey:plugin.identifier];
}

- (void)awakeFromNib {
  /* set toolbar */
  NSToolbar *toolbar = [[NSToolbar alloc] initWithIdentifier:@"SparkPreferencesToolbar"];
  [toolbar setDelegate:self];
  [toolbar setAllowsUserCustomization:NO];
  [toolbar setDisplayMode:NSToolbarDisplayModeIconAndLabel];
  [toolbar setSelectedItemIdentifier:kSparkPreferencesToolbarGeneralItem];
  [[self window] setToolbar:toolbar];
  [[self window] setShowsToolbarButton:NO];
  
  /* Load PlugIns */
  NSArray *plugs;
  plugs = [[[SparkActionLoader sharedLoader] plugInsForDomain:kWBPlugInDomainBuiltIn] sortedArrayUsingDescriptors:gSortByNameDescriptors];
  NSDictionary *item = [NSDictionary dictionaryWithObjectsAndKeys:
												NSLocalizedStringFromTable(@"Built-in", @"SEPreferences", @"Plugin preferences domain - built-in"), @"name",
												plugs, @"plugins",
												[NSImage imageNamed:@"application"], @"icon", nil];
  [_plugins addObject:item];

  plugs = [[[SparkActionLoader sharedLoader] plugInsForDomain:kWBPlugInDomainLocal] sortedArrayUsingDescriptors:gSortByNameDescriptors];
  item = [NSDictionary dictionaryWithObjectsAndKeys:
					NSLocalizedStringFromTable(@"Computer", @"SEPreferences", @"Plugin preferences domain - computer"), @"name",
					plugs, @"plugins",
					[NSImage imageNamed:@"computer"], @"icon", nil];
  [_plugins addObject:item];
  
  plugs = [[[SparkActionLoader sharedLoader] plugInsForDomain:kWBPlugInDomainUser] sortedArrayUsingDescriptors:gSortByNameDescriptors];
  item = [NSDictionary dictionaryWithObjectsAndKeys:
					NSLocalizedStringFromTable(@"User", @"SEPreferences", @"Plugin preferences domain - user"), @"name",
					plugs, @"plugins",
					[NSImage imageNamed:@"user"], @"icon", nil];
  [_plugins addObject:item];
  
  [uiPlugins reloadData];
  for (item in _plugins) {
    NSArray *plugins = [item objectForKey:@"plugins"];
    if ([plugins count]) {
      [self se_initPlugInStatus:plugins];
      [uiPlugins expandItem:item];
    }
  }
}

- (IBAction)apply:(id)sender {
  BOOL change = NO;
  for (SparkPlugIn *plugin in _status) {
    BOOL status = [[_status objectForKey:plugin] boolValue];
    if (spx_xor(status, plugin.enabled)) {
      plugin.enabled = status;
      change = YES;
    }
  }
  if (change)
    [[NSNotificationCenter defaultCenter] postNotificationName:SESparkEditorDidChangePlugInStatusNotification
                                                        object:nil];
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
//  if (se_update)
//    [[SEUpdater sharedUpdater] cancel:nil];
}

#pragma mark -
#pragma mark Preferences
- (float)delay {
  NSNumber *value = SparkPreferencesGetValue(kSparkGlobalPrefDelayStartup, SparkPreferencesDaemon);
  return value ? [value floatValue] : 0;
}
- (void)setDelay:(float)delay {
  SparkPreferencesSetValue(kSparkGlobalPrefDelayStartup, @(delay), SparkPreferencesDaemon);
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
- (IBAction)checkForUpdates:(id)sender {
  [[Spark sharedSpark] checkForUpdates:sender];
}

- (void)windowDidLoad {
  [super windowDidLoad];
#if MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_6
  if ([ibDateFormat respondsToSelector:@selector(setDoesRelativeDateFormatting:)])
    [ibDateFormat setDoesRelativeDateFormatting:YES];
#endif

  //[uiFeedURL setHidden:![EDPreferences sharedPreferences].showUpdateFeedChooser];
  [uiFeedURL addItemWithObjectValue:[[[Spark sharedSpark] releaseFeedURL] absoluteString]];
  [uiFeedURL addItemWithObjectValue:[[[Spark sharedSpark] betaFeedURL] absoluteString]];
}

- (NSString *)feedURL {
  return [[[Spark sharedSpark] feedURL] absoluteString];
}
- (void)setFeedURL:(NSString *)anURL {
  [[Spark sharedSpark] setFeedURL:anURL ? [NSURL URLWithString:anURL] : nil];
}

//- (IBAction)update:(id)sender {
//  if (!se_update) {
//    se_update = YES;
//    [uiUpdateStatus setHidden:NO];
//    [uiUpdateMsg setStringValue:@""];
//    [uiProgress setIndeterminate:YES];
//    [uiProgress startAnimation:sender];
//    [[SEUpdater sharedUpdater] searchWithDelegate:self];
//  }
//}
//
//- (void)updater:(SEUpdater *)updater didSearchVersion:(BOOL)version error:(NSError *)anError {
//  [uiProgress stopAnimation:nil];
//  if (!version && !anError) {
//    [uiUpdateMsg setStringValue:
//		 NSLocalizedStringFromTable(@"No new version available.", @"SEPreferences", @"Check Update: version up to date")];
//  } else if (anError) {
//    NSString *str = [anError localizedDescription];
//    if (str)
//      [uiUpdateMsg setStringValue:[NSString stringWithFormat:
//																	 NSLocalizedStringFromTable(@"Error: %@.", @"SEPreferences", @"Check Update: error (%@)"), str]];
//    else
//      [uiUpdateMsg setStringValue:
//			 NSLocalizedStringFromTable(@"Undefined error occured.", @"SEPreferences", @"Check Update: undefined error")];
//  }
//  [uiUpdateStatus setHidden:YES];
//  se_update = NO;
//}

#pragma mark -
#pragma mark Plugin Manager
- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item {
  return !item || ![item isKindOfClass:[SparkPlugIn class]];
}
- (NSInteger)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item {
  return item ? [[item objectForKey:@"plugins"] count] : _plugins.count;
}
- (id)outlineView:(NSOutlineView *)outlineView child:(NSInteger)anIndex ofItem:(id)item {
  return item ? [[item objectForKey:@"plugins"] objectAtIndex:anIndex] : _plugins[anIndex];
}
- (id)outlineView:(NSOutlineView *)outlineView objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(id)item {
  if ([item isKindOfClass:[SparkPlugIn class]]) {
    if ([[tableColumn identifier] isEqualToString:@"__item__"])
      return item;
    else if ([[tableColumn identifier] isEqualToString:@"enabled"])
      return [_status objectForKey:item];
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
    if ([_status objectForKey:item])
      [_status setObject:object forKey:item];
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
      SPXDebug(@"Delete plugin: %@", item);
    }
  }
}

#pragma mark Toolbar
- (IBAction)changePanel:(id)sender {
  [uiPanels selectTabViewItemAtIndex:[sender tag]];
}

- (NSToolbarItem *)toolbar:(NSToolbar *)toolbar itemForItemIdentifier:(NSString *)itemIdentifier willBeInsertedIntoToolbar:(BOOL)flag {
  NSToolbarItem *toolbarItem = [[NSToolbarItem alloc] initWithItemIdentifier: itemIdentifier];
  if ([kSparkPreferencesToolbarGeneralItem isEqualToString:itemIdentifier]) {
    [toolbarItem setTag:0];
    [toolbarItem setLabel:NSLocalizedStringFromTable(@"General", @"SEPreferences", @"Toolar item: General")];
    [toolbarItem setImage:[NSImage imageNamed:@"generalpref"]];
  } else if ([kSparkPreferencesToolbarPlugInsItem isEqualToString:itemIdentifier]) {
    [toolbarItem setTag:1];
    [toolbarItem setLabel:NSLocalizedStringFromTable(@"Plugins", @"SEPreferences", @"Toolar item: Plugins")];
    [toolbarItem setImage:[NSImage imageNamed:@"pluginpref"]];
  } else if ([kSparkPreferencesToolbarUpdateItem isEqualToString:itemIdentifier]) {
    [toolbarItem setTag:2];
    [toolbarItem setLabel:NSLocalizedStringFromTable(@"Update", @"SEPreferences", @"Toolar item: Update")];
    [toolbarItem setImage:[NSImage imageNamed:@"updatepref"]];
  } else if ([kSparkPreferencesToolbarAdvancedItem isEqualToString:itemIdentifier]) {
    [toolbarItem setTag:3];
    [toolbarItem setLabel:NSLocalizedStringFromTable(@"Advanced", @"SEPreferences", @"Toolar item: Advanced")];
    [toolbarItem setImage:[NSImage imageNamed:@"advancedpref"]];
  }
  
  // Tell the item what message to send when it is clicked
  toolbarItem.target = self;
  toolbarItem.action = @selector(changePanel:);
  return toolbarItem;
}

- (NSArray *)toolbarDefaultItemIdentifiers:(NSToolbar*)toolbar {
  return [NSArray arrayWithObjects:kSparkPreferencesToolbarGeneralItem, 
					kSparkPreferencesToolbarPlugInsItem,
					kSparkPreferencesToolbarUpdateItem,
					kSparkPreferencesToolbarAdvancedItem, nil];
}

- (NSArray *)toolbarAllowedItemIdentifiers:(NSToolbar*)toolbar {
  return [NSArray arrayWithObjects:kSparkPreferencesToolbarGeneralItem, 
					kSparkPreferencesToolbarPlugInsItem,
					kSparkPreferencesToolbarUpdateItem,
					kSparkPreferencesToolbarAdvancedItem, nil];
}

- (NSArray *)toolbarSelectableItemIdentifiers:(NSToolbar *)toolbar {
  return [NSArray arrayWithObjects:kSparkPreferencesToolbarGeneralItem, 
					kSparkPreferencesToolbarPlugInsItem,
					kSparkPreferencesToolbarUpdateItem,
					kSparkPreferencesToolbarAdvancedItem, nil];
}

@end

#pragma mark -
void _SEPreferencesUpdateLoginItem(void) {
	NSURL *sparkd = SESparkDaemonURL();
  BOOL status = __SEPreferencesLoginItemStatus();
  /* do it the new way */
  LSSharedFileListRef list = LSSharedFileListCreate(kCFAllocatorDefault, kLSSharedFileListSessionLoginItems, NULL);
  if (list) {
    UInt32 seed = 0;
    BOOL shouldAdd = status;
    CFArrayRef items = LSSharedFileListCopySnapshot(list, &seed);
    if (items) {
      CFIndex count = CFArrayGetCount(items);
      while (count-- > 0) {
        CFURLRef itemURL = NULL;
        LSSharedFileListItemRef item = (LSSharedFileListItemRef)CFArrayGetValueAtIndex(items, count);
        if (noErr == LSSharedFileListItemResolve(item, kLSSharedFileListNoUserInteraction | kLSSharedFileListDoNotMountVolumes,
                                                 &itemURL, NULL) && itemURL) {
          CFStringRef name = CFURLCopyLastPathComponent(itemURL);
          if (name) {
            if (CFEqual(name, SPXNSToCFString(kSparkDaemonExecutableName))) {
              if (!status || !WBFSCompareURLs(itemURL, SPXNSToCFURL(sparkd))) {
                SPXDebug(@"Remove login item: %@", itemURL);
#if !defined(DEBUG)
                LSSharedFileListItemRemove(list, item);
#endif
              } else {
                SPXDebug(@"Valid login item found");
                shouldAdd = NO;
              }
            }
            CFRelease(name);
          }
          CFRelease(itemURL);
        }
      }
      /* Append login item if needed */
      if (shouldAdd) {
#if !defined(DEBUG)
        CFDictionaryRef properties = CFDictionaryCreate(kCFAllocatorDefault, (const void **)&kLSSharedFileListItemHidden,
                                                        (const void **)&kCFBooleanTrue, 1, &kCFCopyStringDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
        LSSharedFileListInsertItemURL(list, kLSSharedFileListItemLast, NULL, NULL, (CFURLRef)sparkd, properties, NULL);
        CFRelease(properties);
#else
        SPXDebug(@"Add login item: %@", sparkd);
#endif
      }
      CFRelease(items);
    }
    CFRelease(list);
  }
}
