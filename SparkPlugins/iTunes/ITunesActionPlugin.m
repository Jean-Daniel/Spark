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

#import WBHEADER(WBAlias.h)
#import WBHEADER(WBFSFunctions.h)
#import WBHEADER(WBLSFunctions.h)
#import WBHEADER(NSImage+WonderBox.h)
#import WBHEADER(NSString+WonderBox.h)
#import WBHEADER(NSTabView+WonderBox.h)

static 
NSImage *ITunesGetApplicationIcon(void) {
  NSImage *icon = nil;
  NSString *itunes = WBLSFindApplicationForSignature(kiTunesSignature);
  if (itunes) {
    icon = [[NSWorkspace sharedWorkspace] iconForFile:itunes];
  }
  return icon;
}

@implementation ITunesActionPlugin

+ (void)initialize {
  if (self == [ITunesActionPlugin class]) {
    [self setKeys:[NSArray arrayWithObject:@"sparkAction"] triggerChangeNotificationsForDependentKey:@"lsPlay"];
    [self setKeys:[NSArray arrayWithObject:@"sparkAction"] triggerChangeNotificationsForDependentKey:@"rating"];
    [self setKeys:[NSArray arrayWithObject:@"sparkAction"] triggerChangeNotificationsForDependentKey:@"showInfo"];
  }
}

- (id)init {
  if (self = [super init]) {
  }
  return self;
}

- (void)dealloc {
  [ibVisual release]; // IB root object
  [it_playlist release];
  [it_playlists release];
  [super dealloc];
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
- (void)loadSparkAction:(id)sparkAction toEdit:(BOOL)flag {
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
  if (it_lists) {
    [it_lists release];
    it_lists = nil;
  }
  WBSetterRetain(it_playlists, lists);
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

- (NSString *)playlist {
  return it_playlist;
}

- (void)setPlaylist:(NSString *)aPlaylist {
  WBSetterCopy(it_playlist, aPlaylist);
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
static
NSInteger _iTunesSortPlaylists(id num1, id num2, void *context) {
  NSDictionary *info = (NSDictionary *)context;
  NSNumber *v1 = [[info objectForKey:num1] objectForKey:@"kind"];
  NSNumber *v2 = [[info objectForKey:num2] objectForKey:@"kind"];
  NSInteger result = [v1 compare:v2];
  if (result == NSOrderedSame) {
    result = [num1 caseInsensitiveCompare:num2];
  }
  return result;
}

- (NSArray *)playlists {
  if (!it_lists && it_playlists) {
    it_lists = [[[it_playlists allKeys] sortedArrayUsingFunction:_iTunesSortPlaylists context:it_playlists] retain];
  }
  return it_lists;
}

static
NSString *_iTunesGetiAppsLibraryPath(void) {
  CFStringRef path = NULL;
  CFArrayRef paths = CFPreferencesCopyValue(CFSTR("iTunesRecentDatabases"), CFSTR("com.apple.iApps"), kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
  if (paths) {
    path = CFArrayGetCount(paths) > 0 ? CFArrayGetValueAtIndex(paths, 0) : NULL;
    if (path) CFRetain(path);
    CFRelease(paths);
  }
  return [(id)path autorelease];
}

static
NSString *_iTunesGetLibraryPathFromPreferences(Boolean compat) {
  NSString *path = nil;
  CFDataRef data = CFPreferencesCopyValue(CFSTR("alis:1:iTunes Library Location"),
                                          CFSTR("com.apple.iTunes"),
                                          kCFPreferencesCurrentUser,
                                          kCFPreferencesAnyHost);
  if (data) {
    WBAlias *alias = [[WBAlias alloc] initFromData:(id)data];
    if (alias) {
      path = [[alias path] stringByAppendingPathComponent:compat ? @"iTunes Music Library.xml" : @"iTunes Library.xml"];
      [alias release];
    }
    CFRelease(data);
  }
  return path;
}

static 
NSString *_iTunesGetLibraryFileInFolder(OSType folder, Boolean compat) {
  FSRef ref;
  NSString *file = nil;
  /* Get User Special Folder */
  if (noErr == FSFindFolder(kUserDomain, folder, kDontCreateFolder, &ref)) {
    file = [NSString stringFromFSRef:&ref];
    if (file) {
      /* Get User Music Library */
      file = [file stringByAppendingPathComponent:compat ? @"/iTunes/iTunes Music Library.xml" : @"/iTunes/iTunes Library.xml"];
    }
  }
  return file;
}

WB_INLINE
NSString *__iTunesFindLibrary(Boolean compat) {
  NSString *file;
  
  /* Get from iApps preferences */
  file = _iTunesGetiAppsLibraryPath();
  
  /* Get from iTunes preferences */
  if (!file || ![[NSFileManager defaultManager] fileExistsAtPath:file]) {
    file = _iTunesGetLibraryPathFromPreferences(compat);
  }
  
  /* Search in User Music Folder */
  if (!file || ![[NSFileManager defaultManager] fileExistsAtPath:file]) {
    file = _iTunesGetLibraryFileInFolder(kMusicDocumentsFolderType, compat);
  }
  
  /* Search in User Document folder */
  if (!file || ![[NSFileManager defaultManager] fileExistsAtPath:file]) {
    file = _iTunesGetLibraryFileInFolder(kDocumentsFolderType, compat);
  }
  
  if (file && ![[NSFileManager defaultManager] fileExistsAtPath:file])
    file = nil;
  
  return file;
}

+ (NSDictionary *)iTunesPlaylists {
  NSMutableDictionary *playlists = iTunesIsRunning(NULL) ? (id)iTunesCopyPlaylists() : nil;
  if (nil == playlists) {
    
    NSString *file = __iTunesFindLibrary(false);
    if (!file)
      file = __iTunesFindLibrary(true);
    
    if (!file)
      return nil;
    
    NSDictionary *library = [[NSDictionary alloc] initWithContentsOfFile:file];
    if (library) {
      playlists = [[NSMutableDictionary alloc] init];
      NSDictionary *list;
      NSEnumerator *lists = [[library objectForKey:@"Playlists"] objectEnumerator];
      while (list = [lists nextObject]) {
        UInt32 type = kPlaylistUser;
        if ([list objectForKey:@"Smart Info"] != nil) type = kPlaylistSmart;
        else if ([[list objectForKey:@"Folder"] boolValue]) type = kPlaylistFolder;
        else if ([[list objectForKey:@"Music"] boolValue]) type = kPlaylistMusic;
        else if ([[list objectForKey:@"Movies"] boolValue]) type = kPlaylistMovie;
        else if ([[list objectForKey:@"TV Shows"] boolValue]) type = kPlaylistTVShow;
        
        else if ([[list objectForKey:@"Podcasts"] boolValue]) type = kPlaylistPodcast;
        else if ([[list objectForKey:@"Audiobooks"] boolValue]) type = kPlaylistBooks;
        else if ([[list objectForKey:@"Purchased Music"] boolValue]) type = kPlaylistPurchased;
        else if ([[list objectForKey:@"Party Shuffle"] boolValue]) type = kPlaylistPartyShuffle;
        
        NSNumber *ppid = nil;
        NSString *uid = [list objectForKey:@"Playlist Persistent ID"];
        if (uid) {
          ppid = WBUInt64(strtoll([uid UTF8String], NULL, 16));
        }
        
        NSDictionary *plist = [[NSDictionary alloc] initWithObjectsAndKeys:
          WBUInt32(type), @"kind",
          ppid, @"uid", nil];
        [playlists setObject:plist forKey:[list objectForKey:@"Name"]];
        [plist release];
      }
    }
    [library release];
  }
  return [playlists autorelease];
}

#pragma mark Playlist menu
- (void)menuNeedsUpdate:(NSMenu *)menu {
  if (!ia_apFlags.loaded) {
    NSImage *user = [NSImage imageNamed:@"iTPlaylist" inBundle:kiTunesActionBundle];
    NSImage *smart = [NSImage imageNamed:@"iTSmart" inBundle:kiTunesActionBundle];
    NSImage *folder = [NSImage imageNamed:@"iTFolder" inBundle:kiTunesActionBundle];
    NSUInteger count = [menu numberOfItems];
    while (count-- > 0) {
      NSString *title = [[menu itemAtIndex:count] title];
      if (title) {
        NSDictionary *playlist = [it_playlists objectForKey:title];
        if (playlist) {
          switch ([[playlist objectForKey:@"kind"] intValue]) {
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
