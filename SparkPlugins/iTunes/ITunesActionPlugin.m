/*
 *  ITunesActionPlugin.m
 *  Spark Plugins
 *
 *  Created by Black Moon Team.
 *  Copyright (c) 2004 - 2007, Shadow Lab. All rights reserved.
 */

#import "ITunesActionPlugin.h"

#import "ITunesAction.h"
#import "ITunesAESuite.h"
#import "ITunesVisualSetting.h"

#import <WonderBox/WonderBox.h>

@interface ITunesActionPlugin () <ITunesVisualSettingDelegate>

@end

static 
NSImage *ITunesGetApplicationIcon(void) {
  NSImage *icon = nil;
  NSURL *itunes = [NSWorkspace.sharedWorkspace URLForApplicationWithBundleIdentifier:SPXCFToNSString(iTunesBundleIdentifier())];
  if (itunes)
    [itunes getResourceValue:&icon forKey:NSURLEffectiveIconKey error:NULL];

  return icon;
}

@implementation ITunesActionPlugin {
@private
  struct _ia_apFlags {
    unsigned int play:1;
    unsigned int loaded:1;
    unsigned int background:1;
    unsigned int reserved:29;
  } ia_apFlags;
  NSArray *_playlists;
  NSDictionary *it_playlists;
}

+ (NSSet *)keyPathsForValuesAffectingValueForKey:(NSString *)key {
  if ([key isEqualToString:@"lsPlay"] || [key isEqualToString:@"rating"] || [key isEqualToString:@"showInfo"])
    return [NSSet setWithObject:@"sparkAction"];
  return [super keyPathsForValuesAffectingValueForKey:key];
}

#pragma mark -
- (void)awakeFromNib {
  NSImage *icon = ITunesGetApplicationIcon();
  if (icon) {
    [ibIcon setImage:icon];
  }
  [[uiPlaylists menu] setDelegate:self];
}

/* This function is called when the user open the iTunes Action Editor Panel */
- (void)loadSparkAction:(ITunesAction *)sparkAction toEdit:(BOOL)flag {
  [ibName setStringValue:[sparkAction name] ? : @""];
  /* if flag == NO, the user want to create a new Action, else he wants to edit an existing Action */
  if (flag) {
    [self setLsHide:[sparkAction launchHide]];
    /* Set Action menu on the Action action */
    [self setITunesAction:[sparkAction iTunesAction]];
    if ([sparkAction iTunesAction] == kiTunesPlayPlaylist) {
      [self loadPlaylists];
      if ([sparkAction playlist])
        [self setPlaylist:[sparkAction playlist]];
    }
    switch ([sparkAction visualMode]) {
      case kiTunesSettingCustom: {
        const ITunesVisual *visual = [sparkAction visual];
        if (visual) {
          [ibVisual setVisual:visual];
        }
      }
        break;
      case kiTunesSettingDefault:
        [ibVisual setVisual:[ITunesAction defaultVisual]];
        break;
    }
    [ibVisual setConfiguration:[sparkAction visualMode]];
  } else {
    /* Default action for the iTunes Action Menu */
    [self setITunesAction:kiTunesPlayPause];
    [ibVisual setVisual:[ITunesAction defaultVisual]];
  }
  [ibVisual setDelegate:self];
}

- (NSAlert *)sparkEditorShouldConfigureAction {
  
  return nil;
}

/* You need configure the new Action or modifie the existing Action here */
- (void)configureAction {
  /* Get the current Action */
  ITunesAction *iAction = [self sparkAction];
  /* Set Name */
  [iAction setName:[ibName stringValue]];
  if ([[[iAction name] stringByTrimmingWhitespaceAndNewline] length] == 0)
    [iAction setName:[self defaultName]];
  
  if ([self iTunesAction] == kiTunesPlayPlaylist) {
    NSString *list = [self playlist];
    NSNumber *number = list ? [[it_playlists objectForKey:list] objectForKey:@"uid"] : nil;
    UInt64 uid = number ? [number unsignedLongLongValue] : 0;
    [iAction setPlaylist:list uid:uid];
  } else {
    [iAction setPlaylist:nil uid:0];
  }
  
  /* Set Icon */
  [iAction setIcon:ITunesActionIcon(iAction)];
  
  /* Set Description */
  [iAction setActionDescription:ITunesActionDescription(iAction)];
  
  [iAction setVisualMode:[ibVisual configuration]];
  
  /* Save visual if needed */
  if ([ibVisual configuration] == kiTunesSettingCustom) {
    ITunesVisual visual;
    [ibVisual getVisual:&visual];
    [iAction setVisual:&visual];
  }
}

- (void)plugInViewWillBecomeHidden {
  if ([ibVisual configuration] == kiTunesSettingDefault) {
    // Update defaut configuration
    ITunesVisual visual;
    [ibVisual getVisual:&visual];
    [ITunesAction setDefaultVisual:&visual];
    [ibVisual hide:nil];
  }
}

- (void)settingWillChangeConfiguration:(ITunesVisualSetting *)settings {
  ITunesVisual visual;
  [settings getVisual:&visual];
  switch ([settings configuration]) {
    case kiTunesSettingCustom:
      [[self sparkAction] setVisual:&visual];
      break;
    case kiTunesSettingDefault:
      [ITunesAction setDefaultVisual:&visual];
      break;
  }
}

- (void)settingDidChangeConfiguration:(ITunesVisualSetting *)settings {
  // Load corresponding configuration
  switch ([settings configuration]) {
    case kiTunesSettingCustom: {
      const ITunesVisual *visual = [[self sparkAction] visual];
      [settings setVisual:visual ? : &kiTunesDefaultSettings];
    }
      break;
    case kiTunesSettingDefault:
      [settings setVisual:[ITunesAction defaultVisual]];
      break;
  }
}

#pragma mark ITunesActionPlugin Specific methods
- (BOOL)showInfo {
  return [[self sparkAction] showInfo];
}
- (void)setShowInfo:(BOOL)flag {
  [[self sparkAction] setShowInfo:flag];
}

- (void)loadPlaylists {
  NSDictionary *lists = [[self class] iTunesPlaylists];
  [self willChangeValueForKey:@"playlists"];
  if (_playlists)
    _playlists = nil;
  SPXSetterRetain(it_playlists, lists);
  [self didChangeValueForKey:@"playlists"];
}

- (iTunesAction)iTunesAction {
  return [[self sparkAction] iTunesAction];
}

- (void)setITunesAction:(iTunesAction)newAction {
  if ([self iTunesAction] != newAction) {
    [[self sparkAction] setITunesAction:newAction];
    if (kiTunesPlayPlaylist == newAction && ![self playlists]) {
      [self loadPlaylists];
      [self setPlaylist:[[self playlists] objectAtIndex:0]];
    }
  }
  [[ibName cell] setPlaceholderString:[self defaultName]];
  int idx = -1;
  switch ([self iTunesAction]) {
    case kiTunesLaunch:
      idx = 0;
      break;
    case kiTunesRateTrack:
      idx = 1;
      break;
    case kiTunesPlayPlaylist:
      idx = 2;
      break;
    case kiTunesRateUp:
    case kiTunesRateDown:
    case kiTunesBackTrack:
    case kiTunesNextTrack:
      idx = 3;
      break;
    case kiTunesPlayPause:
      idx = 4;
      break;
    case kiTunesShowTrackInfo:
      idx = 5;
      break;
    default:
      idx = 6;
      break;
  }
  [ibTabView selectTabViewItemAtIndex:idx];
}

- (SInt32)rating {
  return [[self sparkAction] rating] / 10;
}

- (void)setRating:(SInt32)rate {
  [[self sparkAction] setRating:rate * 10];
}

- (BOOL)lsPlay {
  return [[self sparkAction] launchPlay];
}
- (void)setLsPlay:(BOOL)flag {
  [[self sparkAction] setLaunchPlay:flag];
}
- (BOOL)lsHide { 
  return [[self sparkAction] launchHide]; 
}
- (void)setLsHide:(BOOL)flag {
  [self willChangeValueForKey:@"lsBackground"];
  /* If hide, disable and force background */
  [[self sparkAction] setLaunchHide:flag];
  [self didChangeValueForKey:@"lsBackground"];
  [ibBackground setEnabled:!flag];
}

- (BOOL)lsBackground { 
  return [[self sparkAction] launchHide] || [[self sparkAction] launchBackground];
}
- (void)setLsBackground:(BOOL)flag {
  [[self sparkAction] setLaunchBackground:flag];
}

- (IBAction)toggleSettings:(id)sender {
  if ([ibOptionsTab indexOfSelectedTabViewItem]) {
    [ibOptionsTab selectTabViewItemAtIndex:0];
  } else {
    [ibOptionsTab selectTabViewItemAtIndex:1];
  }
}

#pragma mark -
- (NSString *)defaultName {
  switch ([self iTunesAction]) {
    case kiTunesPlayPlaylist:
      return NSLocalizedStringFromTableInBundle(@"DEFAULT_PLAY_PLAYLIST_NAME", nil, kiTunesActionBundle,
                                                @"Play Playlist * Default Name *");
    case kiTunesRateTrack:
      return NSLocalizedStringFromTableInBundle(@"DEFAULT_RATE_TRACK_NAME", nil, kiTunesActionBundle,
                                                @"Rate Track * Default Name *");
    default:
      return ITunesActionDescription([self sparkAction]);
  }
}

#pragma mark -
#pragma mark iTunes Playlists
- (NSArray *)playlists {
  if (!_playlists && it_playlists) {
    _playlists = [it_playlists.allKeys sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
      NSNumber *v1 = [[self->it_playlists objectForKey:obj1] objectForKey:@"kind"];
      NSNumber *v2 = [[self->it_playlists objectForKey:obj2] objectForKey:@"kind"];
      NSInteger result = [v1 compare:v2];
      if (result == NSOrderedSame)
        result = [obj1 caseInsensitiveCompare:obj2];
      return result;
    }];
  }
  return _playlists;
}

static
NSURL *_iTunesGetiAppsLibraryPath(void) {
  NSURL *url = nil;
  CFArrayRef paths = CFPreferencesCopyValue(CFSTR("iTunesRecentDatabases"), CFSTR("com.apple.iApps"), kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
  if (paths) {
    CFStringRef path = CFArrayGetCount(paths) > 0 ? CFArrayGetValueAtIndex(paths, 0) : NULL;
    if (path)
      url = [NSURL fileURLWithPath:SPXCFToNSString(path)];
    CFRelease(paths);
  }
  return url;
}

static
NSURL *_iTunesGetLibraryPathFromPreferences(Boolean compat) {
  NSURL *path = nil;
  CFDataRef data = CFPreferencesCopyValue(CFSTR("alis:1:iTunes Library Location"),
                                          iTunesBundleIdentifier(),
                                          kCFPreferencesCurrentUser,
                                          kCFPreferencesAnyHost);
  if (data) {
    CFDataRef bookmark = CFURLCreateBookmarkDataFromAliasRecord(kCFAllocatorDefault, data);
    if (bookmark) {
      CFURLRef url = CFURLCreateByResolvingBookmarkData(kCFAllocatorDefault, bookmark, kCFURLBookmarkResolutionWithoutUIMask | kCFURLBookmarkResolutionWithoutMountingMask, NULL, NULL, NULL, NULL);
      if (url) {
        path = SPXCFURLBridgingRelease(CFURLCreateCopyAppendingPathComponent(kCFAllocatorDefault, url, compat ? CFSTR("iTunes Music Library.xml") : CFSTR("iTunes Library.xml"), false));
        CFRelease(url);
      }
      CFRelease(bookmark);
    }
  }
  return path;
}

static 
NSURL *_iTunesGetLibraryFileInFolder(NSSearchPathDirectory folder, Boolean compat) {
  NSURL *url = [NSFileManager.defaultManager URLForDirectory:folder inDomain:NSUserDomainMask appropriateForURL:nil create:NO error:NULL];
  /* Get User Special Folder */
  if (url)
    /* Get User Music Library */
    url = [url URLByAppendingPathComponent:compat ? @"/iTunes/iTunes Music Library.xml" : @"/iTunes/iTunes Library.xml"];

  return url;
}

WB_INLINE
NSURL *__iTunesFindLibrary(Boolean compat) {
  NSURL *file;
  
  /* Get from iApps preferences */
  file = _iTunesGetiAppsLibraryPath();
  
  /* Get from iTunes preferences */
  if (!file || ![file checkResourceIsReachableAndReturnError:NULL]) {
    file = _iTunesGetLibraryPathFromPreferences(compat);
  }
  
  /* Search in User Music Folder */
  if (!file || ![file checkResourceIsReachableAndReturnError:NULL]) {
    file = _iTunesGetLibraryFileInFolder(NSMusicDirectory, compat);
  }
  
  /* Search in User Document folder */
  if (!file || ![file checkResourceIsReachableAndReturnError:NULL]) {
    file = _iTunesGetLibraryFileInFolder(NSDocumentDirectory, compat);
  }
  
  if (file && ![file checkResourceIsReachableAndReturnError:NULL])
    file = nil;
  
  return file;
}

+ (NSDictionary *)iTunesPlaylists {
  NSDictionary *playlists = SPXCFDictionaryBridgingRelease(iTunesCopyPlaylists(NULL));
  if (nil == playlists) {
    NSURL *file = __iTunesFindLibrary(false);
    if (!file)
      file = __iTunesFindLibrary(true);
    
    if (!file)
      return nil;
    
    NSDictionary *library = [[NSDictionary alloc] initWithContentsOfURL:file];
    if (library) {
      NSMutableDictionary *pl = [[NSMutableDictionary alloc] init];
      NSDictionary *list;
      NSEnumerator *lists = [library[@"Playlists"] objectEnumerator];
      while (list = [lists nextObject]) {
        NSString *name = list[@"Name"];
        if (!name)
          continue;

        NSNumber *visible = list[@"Visible"];
        if (visible && !visible.boolValue)
          continue;

        UInt32 type = kPlaylistUser;
        if (list[@"Smart Info"] != nil) type = kPlaylistSmart;
        else if ([list[@"Folder"] boolValue]) type = kPlaylistFolder;
        else if ([list[@"Music"] boolValue]) type = kPlaylistMusic;
        else if ([list[@"Movies"] boolValue]) type = kPlaylistMovies;
        else if ([list[@"TV Shows"] boolValue]) type = kPlaylistTVShow;
        
        else if ([list[@"Podcasts"] boolValue]) type = kPlaylistPodcast;
        else if ([list[@"Audiobooks"] boolValue]) type = kPlaylistBooks;
        else if ([list[@"Purchased Music"] boolValue]) type = kPlaylistPurchased;
        
        NSNumber *ppid = nil;
        NSString *uid = list[@"Playlist Persistent ID"];
        if (uid)
          ppid = @(strtoll([uid UTF8String], NULL, 16));
        
        NSDictionary *plist = @{ @"kind": @(type), @"uid": ppid };
        if (name)
          [pl setObject:plist forKey:name];
      }
      playlists = pl;
    }
  }
  return playlists;
}

#pragma mark Playlist menu
- (void)menuNeedsUpdate:(NSMenu *)menu {
  if (!ia_apFlags.loaded) {
    NSImage *user = [NSImage imageNamed:@"iTPlaylist" inBundle:kiTunesActionBundle];
    NSImage *smart = [NSImage imageNamed:@"iTSmart" inBundle:kiTunesActionBundle];
    NSImage *folder = [NSImage imageNamed:@"iTFolder" inBundle:kiTunesActionBundle];
    NSInteger count = [menu numberOfItems];
    while (count-- > 0) {
      NSString *title = [[menu itemAtIndex:count] title];
      if (title) {
        NSDictionary *playlist = [it_playlists objectForKey:title];
        if (playlist) {
          switch ([playlist[@"kind"] intValue]) {
            case kPlaylistUser:
              [[menu itemAtIndex:count] setImage:user];
              break;
            case kPlaylistSmart:
              [[menu itemAtIndex:count] setImage:smart];
              break;
            case kPlaylistFolder:
              [[menu itemAtIndex:count] setImage:folder];
              break;
            case kPlaylistMusic:
              [[menu itemAtIndex:count] setImage:[NSImage imageNamed:@"iTMusic" inBundle:kiTunesActionBundle]];
              break;
          }
        }
      }
    }
    ia_apFlags.loaded = YES;
  }
}

#pragma mark -
#pragma mark Dynamic Plugin
+ (NSImage *)plugInIcon {
  NSImage *icon = ITunesGetApplicationIcon();
  if (!icon)
    icon = [super plugInIcon];
  return icon;
}

- (BOOL)hasCustomView {
  return YES;
}

@end
