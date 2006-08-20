//
//  ITunesActionPlugin.m
//  Spark
//
//  Created by Fox on Sun Feb 15 2004.
//  Copyright (c) 2004 Shadow Lab. All rights reserved.
//

#if defined (DEBUG)
#warning Debug defined in iTunesAction!
#endif

#import "ITunesActionPlugin.h"
#import "ITunesAESuite.h"
#import "ITunesAction.h"

#import <ShadowKit/SKExtensions.h>
#import <ShadowKit/SKFSFunctions.h>
#import <ShadowKit/SKAppKitExtensions.h>

volatile int SparkiTunesGDBWorkaround = 0;

NSString * const kiTunesActionBundleIdentifier = @"org.shadowlab.spark.iTunes";

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
  /* Super loadSparkAction:toEdit: set name and icon of self */
  [super loadSparkAction:sparkAction toEdit:flag];
  
  /* if flag == NO, the user want to create a new Action, else he wants to edit an existing Action */
  if (flag) {
    /* Set Action menu on the Action action */
    [self setITunesAction:[sparkAction iTunesAction]];
    [self setRate:[sparkAction rating] / 20];
    if ([sparkAction playlist]) {
      [self loadPlaylists];
      [self setPlaylist:[sparkAction playlist]];
    }
  } else {
    /* Default action for the iTunes Action Menu */
    [self setITunesAction:kiTunesPlayPause];
  }
}

- (NSAlert *)sparkEditorShouldConfigureAction {
  /* This is a basic plugIn so there is nothing required */
  /* If plugIn configuration require something the user don't set,
  tell him here by returning a NSAlert */
  return nil;
}

/* You need configure the new Action or modifie the existing Action here */
- (void)configureAction {
  /* Get the current Action */
  ITunesAction *iAction = [self sparkAction];
  /* Set Name */
  if ([[[iAction name] stringByTrimmingWhitespaceAndNewline] length] == 0)
    [iAction setName:[self defaultName]];
  [iAction setPlaylist:([self iTunesAction] == kiTunesPlayPlaylist) ? [self playlist] : nil];
  [iAction setRating:[self rate] * 20];
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
  [iAction setActionDescription:[self actionDescription]];
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
    default:
      idx = 3;
      break;
  }
  [optionsView selectTabViewItemAtIndex:idx];
}

- (unsigned)rate {
  return it_rate;
}

- (void)setRate:(unsigned)newRate {
  it_rate = newRate;
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

- (NSString *)actionDescription {
  NSString *desc = nil;
  switch ([self iTunesAction]) {
    case kiTunesLaunch:
      desc = NSLocalizedStringFromTableInBundle(@"DESC_LAUNCH", nil, kiTunesActionBundle,
                                                @"Launch iTunes * Action Description *");
      break;
    case kiTunesQuit:
      desc = NSLocalizedStringFromTableInBundle(@"DESC_QUIT", nil, kiTunesActionBundle,
                                                @"Quit iTunes * Action Description *");
      break;
    case kiTunesPlayPause:
      desc = NSLocalizedStringFromTableInBundle(@"DESC_PLAY_PAUSE", nil, kiTunesActionBundle,
                                                @"Play/Pause * Action Description *");
      break;
    case kiTunesPlayPlaylist:
      desc = [NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"DESC_PLAY_LIST", nil, kiTunesActionBundle,
                                                                           @"Play Playlist * Action Description * (%@ = playlist name)"),
        [self playlist]];
      break;
    case kiTunesRateTrack:
      desc = [NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"DESC_RATE_TRACK", nil, kiTunesActionBundle,
                                                                           @"Rate Track * Action Description * (%i = rating)"),
        [self rate]];
      break;
    case kiTunesNextTrack:
      desc = NSLocalizedStringFromTableInBundle(@"DESC_NEXT", nil, kiTunesActionBundle,
                                                @"Next Track * Action Description *");
      break;
    case kiTunesBackTrack:
      desc = NSLocalizedStringFromTableInBundle(@"DESC_PREVIOUS", nil, kiTunesActionBundle,
                                                @"Previous Track * Action Description *");
      break;
    case kiTunesStop:
      desc = NSLocalizedStringFromTableInBundle(@"DESC_STOP", nil, kiTunesActionBundle,
                                                @"Stop * Action Description *");
      break;
    case kiTunesVisual:
      desc = NSLocalizedStringFromTableInBundle(@"DESC_VISUAL", nil, kiTunesActionBundle,
                                                @"Start/Stop Visual * Action Description *");
      break;
    case kiTunesVolumeDown:
      desc = NSLocalizedStringFromTableInBundle(@"DESC_VOLUME_DOWN", nil, kiTunesActionBundle,
                                                @"Volume Down * Action Description *");
      break;
    case kiTunesVolumeUp:
      desc = NSLocalizedStringFromTableInBundle(@"DESC_VOLUME_UP", nil, kiTunesActionBundle,
                                                @"Volume Up * Action Description *");
      break;
    case kiTunesEjectCD:
      desc = NSLocalizedStringFromTableInBundle(@"DESC_EJECT", nil, kiTunesActionBundle,
                                                @"Eject CD * Action Description *");
      break;
    default:
      desc = NSLocalizedStringFromTableInBundle(@"DESC_ERROR", nil, kiTunesActionBundle,
                                                @"Unknown Action * Action Description *");
  }
  return desc;
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
      return [self actionDescription];
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
  NSMutableArray *playlists = (id)iTunesCopyPlaylists();
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
