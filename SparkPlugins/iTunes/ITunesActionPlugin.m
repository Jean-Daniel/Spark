/*
 *  ITunesActionPlugin.m
 *  Spark Plugins
 *
 *  Created by Black Moon Team.
 *  Copyright (c) 2004 - 2006, Shadow Lab. All rights reserved.
 */

#import "ITunesActionPlugin.h"

#import "ITunesAction.h"
#import "ITunesAESuite.h"
#import "ITunesVisualSetting.h"

#import <ShadowKit/SKAlias.h>
#import <ShadowKit/SKFunctions.h>
#import <ShadowKit/SKExtensions.h>
#import <ShadowKit/SKImageUtils.h>
#import <ShadowKit/SKFSFunctions.h>
#import <ShadowKit/SKLSFunctions.h>
#import <ShadowKit/SKAppKitExtensions.h>

static 
NSImage *ITunesGetApplicationIcon() {
  NSImage *icon = nil;
  NSString *itunes = SKLSFindApplicationForSignature(kiTunesSignature);
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

- (void)pluginViewWillBecomeHidden {
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
  SKSetterRetain(it_playlists, lists);
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
    case kiTunesPlayPause:
    case kiTunesBackTrack:
    case kiTunesNextTrack:
      idx = 3;
      break;
    default:
      idx = 4;
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
  SKSetterCopy(it_playlist, aPlaylist);
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
  if (!it_lists && it_playlists) {
    it_lists = [[[it_playlists allKeys] sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)] retain];
  }
  return it_lists;
}

static
NSString *iTunesGetLibraryPath() {
  NSString *path = nil;
  CFDataRef data = CFPreferencesCopyValue(CFSTR("alis:1:iTunes Library Location"),
                                          CFSTR("com.apple.iTunes"),
                                          kCFPreferencesCurrentUser,
                                          kCFPreferencesAnyHost);
  if (data) {
    SKAlias *alias = [[SKAlias alloc] initWithData:(id)data];
    if (alias) {
      path = [[alias path] stringByAppendingPathComponent:@"iTunes Music Library.xml"];
      [alias release];
    }
    CFRelease(data);
  }
  return path;
}

static 
NSString *iTunesFindLibraryFile(int folder) {
  FSRef ref;
  NSString *file = nil;
  /* Get User Special Folder */
  if (noErr == FSFindFolder(kUserDomain, folder, kDontCreateFolder, &ref)) {
    file = [NSString stringFromFSRef:&ref];
    if (file) {
      /* Get User Music Library */
      file = [file stringByAppendingPathComponent:@"/iTunes/iTunes Music Library.xml"];
    }
  }
  return file;
}

+ (NSDictionary *)iTunesPlaylists {
  NSMutableDictionary *playlists = (id)iTunesCopyPlaylists();
  if (nil == playlists) {
    /* First check user preferences */
    NSString *file = iTunesGetLibraryPath();
    
    if (!file || ![[NSFileManager defaultManager] fileExistsAtPath:file]) {
      /* Search in User Music Folder */
      file = iTunesFindLibraryFile(kMusicDocumentsFolderType);
      /* If doesn't exists Search in Document folder */
      if (!file || ![[NSFileManager defaultManager] fileExistsAtPath:file]) {
        file = iTunesFindLibraryFile(kDocumentsFolderType);
        if (!file || ![[NSFileManager defaultManager] fileExistsAtPath:file])
          return nil;
      }
    }
    
    NSDictionary *library = [[NSDictionary alloc] initWithContentsOfFile:file];
    if (library) {
      playlists = [[NSMutableDictionary alloc] init];
      NSDictionary *list;
      NSEnumerator *lists = [[library objectForKey:@"Playlists"] objectEnumerator];
      while (list = [lists nextObject]) {
        int type = 0;
        if ([list objectForKey:@"Smart Info"] != nil)
          type = 1;
        else if ([[list objectForKey:@"Folder"] boolValue])
          type = 2;
        
        NSNumber *ppid = nil;
        NSString *uid = [list objectForKey:@"Playlist Persistent ID"];
        if (uid) {
          ppid = SKULongLong(strtoll([uid UTF8String], NULL, 16));
        }
        
        NSDictionary *plist = [[NSDictionary alloc] initWithObjectsAndKeys:
          SKUInt(type), @"kind",
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
    unsigned count = [menu numberOfItems];
    while (count-- > 0) {
      NSString *title = [[menu itemAtIndex:count] title];
      if (title) {
        NSDictionary *playlist = [it_playlists objectForKey:title];
        if (playlist) {
          switch ([[playlist objectForKey:@"kind"] intValue]) {
            case 0:
              [[menu itemAtIndex:count] setImage:user];
              break;
            case 1:
              [[menu itemAtIndex:count] setImage:smart];
              break;
            case 2:
              [[menu itemAtIndex:count] setImage:folder];
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

@end
