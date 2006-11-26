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
#import <ShadowKit/SKExtensions.h>
#import <ShadowKit/SKFSFunctions.h>
#import <ShadowKit/SKLSFunctions.h>

static 
NSImage *ITunesGetApplicationIcon() {
  NSImage *icon = nil;
  NSString *itunes = SKFindApplicationForSignature(kiTunesSignature);
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
  if (icon)
    [ibIcon setImage:icon];
}

/* This function is called when the user open the iTunes Action Editor Panel */
- (void)loadSparkAction:(id)sparkAction toEdit:(BOOL)flag {
  /* if flag == NO, the user want to create a new Action, else he wants to edit an existing Action */
  if (flag) {
    [self setLsHide:[sparkAction launchHide]];
    /* Set Action menu on the Action action */
    [self setITunesAction:[sparkAction iTunesAction]];
    if ([sparkAction playlist]) {
      [self loadPlaylists];
      [self setPlaylist:[sparkAction playlist]];
    }
    [ibName setStringValue:[sparkAction name] ? : @""];
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
  
  [iAction setPlaylist:([self iTunesAction] == kiTunesPlayPlaylist) ? [self playlist] : nil];
  
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
  NSArray *lists = [[self class] iTunesPlaylists];
  [self setPlaylists:lists];
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
  return it_playlists;
}
- (void)setPlaylists:(NSArray *)thePlaylists {
  SKSetterRetain(it_playlists, thePlaylists);
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

+ (NSArray *)iTunesPlaylists {
  NSMutableArray *playlists = (id)iTunesCopyPlaylistNames();
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
      playlists = [[NSMutableArray alloc] init];
      NSDictionary *list;
      NSEnumerator *lists = [[library objectForKey:@"Playlists"] objectEnumerator];
      while (list = [lists nextObject]) {
        [playlists addObject:[list objectForKey:@"Name"]];
      }
    }
    [library release];
  }
  return [playlists autorelease];
}

#pragma mark -
#pragma mark Dynamic Plugin
+ (NSImage *)plugInIcon {
  NSImage *icon = ITunesGetApplicationIcon();
  if (icon)
    [icon setSize:NSMakeSize(16, 16)];
  else
    icon = [super plugInIcon];
  return icon;
}

@end
