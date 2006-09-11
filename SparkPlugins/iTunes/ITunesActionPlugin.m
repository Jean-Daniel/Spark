/*
 *  ITunesActionPlugin.m
 *  Spark Plugins
 *
 *  Created by Black Moon Team.
 *  Copyright (c) Shadow Lab. 2004 - 2006. All rights reserved.
 */

#import "ITunesActionPlugin.h"
#import "ITunesAESuite.h"
#import "ITunesAction.h"

#import <ShadowKit/SKExtensions.h>
#import <ShadowKit/SKFSFunctions.h>
#import <ShadowKit/SKAppKitExtensions.h>

@implementation ITunesActionPlugin

+ (BOOL)automaticallyNotifiesObserversForKey:(NSString *)key {
  return ![key isEqualToString:@"playlists"];
}

- (id)init {
  if (self = [super init]) {
  }
  return self;
}

- (void)dealloc {
  [it_playlist release];
  [it_playlists release];
  [super dealloc];
}

/* This function is called when the user open the iTunes Action Editor Panel */
- (void)loadSparkAction:(id)sparkAction toEdit:(BOOL)flag {
  /* if flag == NO, the user want to create a new Action, else he wants to edit an existing Action */
  if (flag) {
    /* Set Action menu on the Action action */
    [self setITunesAction:[sparkAction iTunesAction]];
    if ([sparkAction playlist]) {
      [self loadPlaylists];
      [self setPlaylist:[sparkAction playlist]];
    }
    [nameField setStringValue:[sparkAction name] ? : @""];
  } else {
    /* Default action for the iTunes Action Menu */
    [self setITunesAction:kiTunesPlayPause];
  }
}

- (NSAlert *)sparkEditorShouldConfigureAction {
  
  return nil;
}

/* You need configure the new Action or modifie the existing Action here */
- (void)configureAction {
  /* Get the current Action */
  ITunesAction *iAction = [self sparkAction];
  /* Set Name */
  [iAction setName:[nameField stringValue]];
  if ([[[iAction name] stringByTrimmingWhitespaceAndNewline] length] == 0)
    [iAction setName:[self defaultName]];
  
  [iAction setPlaylist:([self iTunesAction] == kiTunesPlayPlaylist) ? [self playlist] : nil];
  
  /* Set Icon */
  NSString  *iconName = nil;
  switch ([self iTunesAction]) {
    case kiTunesLaunch:
      iconName = @"Launch";
      break;
    case kiTunesPlayPause:
      iconName = @"Play";
      break;
    case kiTunesPlayPlaylist:
      iconName = @"Play";
      break;
    case kiTunesBackTrack:
      iconName = @"Back";
      break;
    case kiTunesNextTrack:
      iconName = @"Next";
      break;
    case kiTunesStop:
      iconName = @"Stop";
      break;
    case kiTunesShowTrackInfo:
      iconName = @"TrackInfo";
      break;
    case kiTunesVisual:
      iconName = @"Visual";
      break;
    case kiTunesVolumeDown:
      iconName = @"VolumeDown";
      break;
    case kiTunesVolumeUp:
      iconName = @"VolumeUp";
      break;
    case kiTunesEjectCD:
      iconName = @"Eject";
      break;
    default:
      iconName = nil;
      break;
  }
  if (iconName)
    [iAction setIcon:[NSImage imageNamed:iconName inBundle:kiTunesActionBundle]];
  
  /* Set Description */
  [iAction setActionDescription:ITunesActionDescription(iAction)];
}

#pragma mark ее ITunesActionPlugin & configView Specific methodes ее
/********************************************************************************************************
*                             ITunesActionPlugin & configView Specific methodes							*
********************************************************************************************************/

- (void)loadPlaylists {
  NSArray *lists = [[self class] iTunesPlaylists];
  [self willChangeValueForKey:@"playlists"];
  [self setPlaylists:lists];
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
  [[nameField cell] setPlaceholderString:[self defaultName]];
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
  [optionsView selectTabViewItemAtIndex:idx];
}

- (SInt32)rating {
  return [[self sparkAction] rating] / 20;
}

- (void)setRating:(SInt32)rate {
  [[self sparkAction] setRating:rate * 20];
}

- (NSString *)playlist {
  return it_playlist;
}

- (void)setPlaylist:(NSString *)aPlaylist {
  SKSetterCopy(it_playlist, aPlaylist);
}

- (NSArray *)playlists {
  return it_playlists;
}

- (void)setPlaylists:(NSArray *)thePlaylists {
  SKSetterRetain(it_playlists, thePlaylists);
}

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
    /* Search in User Music Folder */
    NSString *file = iTunesFindLibraryFile(kMusicDocumentsFolderType);
    
    /* If doesn't exists Search in Document folder */
    if (!file || ![[NSFileManager defaultManager] fileExistsAtPath:file]) {
      file = iTunesFindLibraryFile(kDocumentsFolderType);
      if (!file || ![[NSFileManager defaultManager] fileExistsAtPath:file])
        return nil;
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

@end
