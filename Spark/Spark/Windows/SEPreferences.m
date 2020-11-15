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
#import <SparkKit/SparkPreferences.h>
#import <SparkKit/SparkActionLoader.h>

#import <WonderBox/WonderBox.h>

/* If daemon should delay library loading at startup */
NSString * const kSparkGlobalPrefDelayStartup = @"SDDelayStartup";

NSString * const kSparkVersionKey = @"SparkVersion";

/* Hide entry is plugin is disabled */
NSString * const kSEPreferencesHideDisabled = @"SparkHideDisabled";
/* If YES, do not daemon (and don't register it as a login item) */
NSString * const kSEPreferencesSparkDaemonDisabled = @"SparkDaemonDisabled";

/* If should check update automatically */
NSString * const kSEPreferencesAutoUpdate = @"SparkAutoUpdate";

/* Define which single key shortcut is allow */
NSString * const kSparkPrefSingleKeyMode = @"SparkSingleKeyMode";

/* Toolbar items */
static NSString * const kSparkPreferencesToolbarGeneralItem = @"SparkPreferencesToolbarGeneralItem";
static NSString * const kSparkPreferencesToolbarPlugInsItem = @"SparkPreferencesToolbarPlugInsItem";
static NSString * const kSparkPreferencesToolbarUpdateItem = @"SparkPreferencesToolbarUpdateItem";
static NSString * const kSparkPreferencesToolbarAdvancedItem = @"SparkPreferencesToolbarAdvancedItem";


WB_INLINE
void __SetSparkKitSingleKeyMode(NSInteger mode) {
  SparkSetFilterMode((mode >= 0 && mode <= 3) ? mode : kSparkEnableSingleFunctionKey);
}

@implementation SEPreferences {
  BOOL se_update;
  NSMapTable *_status;
  NSMutableArray<NSDictionary *> *_plugins;
}

/* Default values initialization */
+ (void)setup {
  NSDictionary *values = @{
                           kSEPreferencesAutoUpdate: @(NO),
                           kSEPreferencesHideDisabled: @(NO),
                           kSEPreferencesSparkDaemonDisabled: @(NO),
                           kSparkPrefSingleKeyMode: @(kSparkEnableSingleFunctionKey),
                          };
  [[NSUserDefaults standardUserDefaults] registerDefaults:values];

  /* Configure Single key mode */
  __SetSparkKitSingleKeyMode([[NSUserDefaults standardUserDefaults] integerForKey:kSparkPrefSingleKeyMode]);
}

- (id)init {
  if (self = [super init]) {
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
    [_status setObject:@(plugin.enabled) forKey:plugin];
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
  NSDictionary *item = @{
                         @"name": NSLocalizedStringFromTable(@"Built-in", @"SEPreferences", @"Plugin preferences domain - built-in"),
                         @"plugins": plugs,
                         @"icon": [NSImage imageNamed:NSImageNameApplicationIcon]};
  [_plugins addObject:item];

  plugs = [[[SparkActionLoader sharedLoader] plugInsForDomain:kWBPlugInDomainLocal] sortedArrayUsingDescriptors:gSortByNameDescriptors];
  item = @{
           @"name": NSLocalizedStringFromTable(@"Computer", @"SEPreferences", @"Plugin preferences domain - computer"),
           @"plugins": plugs,
           @"icon": [NSImage imageNamed:NSImageNameComputer]};
  [_plugins addObject:item];
  
  plugs = [[[SparkActionLoader sharedLoader] plugInsForDomain:kWBPlugInDomainUser] sortedArrayUsingDescriptors:gSortByNameDescriptors];
  item = @{
           @"name": NSLocalizedStringFromTable(@"User", @"SEPreferences", @"Plugin preferences domain - user"),
           @"plugins": plugs,
           @"icon": [NSImage imageNamed:NSImageNameUser]};
  [_plugins addObject:item];
  
  [uiPlugins reloadData];
  for (item in _plugins) {
    NSArray *plugins = item[@"plugins"];
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
    [NSNotificationCenter.defaultCenter postNotificationName:SESparkEditorDidChangePlugInStatusNotification
                                                      object:nil];
  
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
  NSNumber *value = [SparkUserDefaults() objectForKey:kSparkGlobalPrefDelayStartup];
  return value ? [value floatValue] : 0;
}
- (void)setDelay:(float)delay {
  [SparkUserDefaults() setFloat:delay forKey:kSparkGlobalPrefDelayStartup];
}

- (BOOL)advanced {
  return [SparkUserDefaults() boolForKey:@"SparkAdvancedSettings"];
}
- (void)setAdvanced:(BOOL)advanced {
  [SparkUserDefaults() setBool:advanced forKey:@"SparkAdvancedSettings"];
}

- (BOOL)displaysAlert {
  return [SparkUserDefaults() boolForKey:@"SDDisplayAlertOnExecute"];
}
- (void)setDisplaysAlert:(BOOL)flag {
  [SparkUserDefaults() setBool:flag forKey:@"SDDisplayAlertOnExecute"];
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
  // [[Spark sharedSpark] checkForUpdates:sender];
}

- (void)windowDidLoad {
  [super windowDidLoad];
#if MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_6
  if ([ibDateFormat respondsToSelector:@selector(setDoesRelativeDateFormatting:)])
    [ibDateFormat setDoesRelativeDateFormatting:YES];
#endif

  //[uiFeedURL setHidden:![EDPreferences sharedPreferences].showUpdateFeedChooser];
//  [uiFeedURL addItemWithObjectValue:[[[Spark sharedSpark] releaseFeedURL] absoluteString]];
//  [uiFeedURL addItemWithObjectValue:[[[Spark sharedSpark] betaFeedURL] absoluteString]];
}

- (NSString *)feedURL {
  // return [[[Spark sharedSpark] feedURL] absoluteString];
  return @"";
}

- (void)setFeedURL:(NSString *)anURL {
  // [[Spark sharedSpark] setFeedURL:anURL ? [NSURL URLWithString:anURL] : nil];
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
  return item ? [item[@"plugins"] count] : _plugins.count;
}
- (id)outlineView:(NSOutlineView *)outlineView child:(NSInteger)anIndex ofItem:(id)item {
  return item ? item[@"plugins"][anIndex] : _plugins[anIndex];
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
      spx_debug("Delete plugin: %@", item);
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
    [toolbarItem setImage:[NSImage imageNamed:NSImageNamePreferencesGeneral]];
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
    [toolbarItem setImage:[NSImage imageNamed:NSImageNameAdvanced]];
  }
  
  // Tell the item what message to send when it is clicked
  toolbarItem.target = self;
  toolbarItem.action = @selector(changePanel:);
  return toolbarItem;
}

- (NSArray *)toolbarDefaultItemIdentifiers:(NSToolbar*)toolbar {
  return @[kSparkPreferencesToolbarGeneralItem,
					kSparkPreferencesToolbarPlugInsItem,
					kSparkPreferencesToolbarUpdateItem,
					kSparkPreferencesToolbarAdvancedItem];
}

- (NSArray *)toolbarAllowedItemIdentifiers:(NSToolbar*)toolbar {
  return @[kSparkPreferencesToolbarGeneralItem,
					kSparkPreferencesToolbarPlugInsItem,
					kSparkPreferencesToolbarUpdateItem,
					kSparkPreferencesToolbarAdvancedItem];
}

- (NSArray *)toolbarSelectableItemIdentifiers:(NSToolbar *)toolbar {
  return @[kSparkPreferencesToolbarGeneralItem,
					kSparkPreferencesToolbarPlugInsItem,
					kSparkPreferencesToolbarUpdateItem,
					kSparkPreferencesToolbarAdvancedItem];
}

@end
