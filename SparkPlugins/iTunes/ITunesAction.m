//
//  ITunesAction.m
//  Spark
//
//  Created by Fox on Sun Feb 15 2004.
//  Copyright (c) 2004 Shadow Lab. All rights reserved.
//

#import "ITunesAction.h"
#import "ITunesAction.h"

#import "ITunesAESuite.h"
#import <ShadowKit/SKBezelItem.h>
#import <ShadowKit/SKLSFunctions.h>
#import <ShadowKit/SKAEFunctions.h>
#import <HotKeyToolKit/HotKeyToolKit.h>

static NSString* const kITunesRateKey = @"iTunesTrackTrate";
static NSString* const kITunesActionKey = @"iTunesAction";
static NSString* const kITunesPlaylistKey = @"iTunesPlaylist";

@implementation ITunesAction

+ (void)initialize {
  static BOOL tooLate = NO;
  if (!tooLate) {
    [self setVersion:0x100];
    tooLate = YES;
  }
}

#pragma mark Protocols Implementation

- (id)copyWithZone:(NSZone *)zone {
  ITunesAction* copy = [super copyWithZone:zone];
  copy->ia_action = ia_action;
  copy->ia_rating = ia_rating;
  copy->ia_playlist = [ia_playlist copy];
  return copy;
}

- (void)encodeWithCoder:(NSCoder *)coder {
  [super encodeWithCoder:coder];
  [coder encodeInt:ia_rating forKey:kITunesRateKey];
  [coder encodeInt:ia_action forKey:kITunesActionKey];
  [coder encodeObject:[self playlist] forKey:kITunesPlaylistKey];
  return;
}

- (id)initWithCoder:(NSCoder *)coder {
  if (self = [super initWithCoder:coder]) {
    [self setRating:[coder decodeIntForKey:kITunesRateKey]];
    [self setITunesAction:[coder decodeIntForKey:kITunesActionKey]];
    [self setPlaylist:[coder decodeObjectForKey:kITunesPlaylistKey]];
  }
  return self;
}

#pragma mark -
#pragma mark Required Methods.
/* initFromPropertyList is called when a Action is loaded. You must call [super initFromPropertyList:plist].
Get all values you set in the -propertyList method et configure your Action */
- (id)initFromPropertyList:(id)plist {
  if (self = [super initFromPropertyList:plist]) {
    [self setITunesAction:[[plist objectForKey:kITunesActionKey] intValue]];
    [self setRating:[[plist objectForKey:kITunesRateKey] unsignedShortValue]];
    [self setPlaylist:[plist objectForKey:kITunesPlaylistKey]];
  }
  return self;
}

- (void)dealloc {
  [ia_bezel release];
  [ia_playlist release];
  [super dealloc];
}

/* Use to transform and record you Action in a file. The dictionary returned must contains only PList objects 
See the PropertyList documentation to know more about it */
- (NSMutableDictionary *)propertyList {
  NSMutableDictionary *dico = [super propertyList];
  [dico setObject:SKUInt([self rating]) forKey:kITunesRateKey];
  [dico setObject:SKInt([self iTunesAction]) forKey:kITunesActionKey];
  if ([self playlist])
    [dico setObject:[self playlist] forKey:kITunesPlaylistKey];
  return dico;
}

- (SparkAlert *)check {
  switch ([self iTunesAction]) {
    case kiTunesLaunch:
    case kiTunesQuit:
    case kiTunesPlayPause:
    case kiTunesNextTrack:
    case kiTunesBackTrack:
    case kiTunesStop:
    case kiTunesVisual:
    case kiTunesVolumeDown:
    case kiTunesVolumeUp:
    case kiTunesEjectCD:
      return nil;
    case kiTunesPlayPlaylist:
      //TODO: Check if playlist exist.
      return nil;
    case kiTunesRateTrack:
      //TODO: Check rate.
      return nil;
    default:
      return [SparkAlert alertWithMessageText:
        [NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"INVALID_ACTION",
                                                                      nil,
                                                                      kiTunesActionBundle,
                                                                      @"Error: Action unknown ** Title ** (param: name)"), [self name]]
                    informativeTextWithFormat:NSLocalizedStringFromTableInBundle(@"INVALID_ACTION_MSG",
                                                                                 nil,
                                                                                 kiTunesActionBundle,
                                                                                 @"Error: Action unknown ** Msg **"), [self name]];
  }
}

- (NSTimeInterval)repeatInterval {
  if ([self iTunesAction] == kiTunesVolumeDown || [self iTunesAction] == kiTunesVolumeUp) {
    return SparkGetDefaultKeyRepeatInterval();
  }
  return 0;
}

- (void)displayTrackInfo {
  NSDictionary *dict = (id)iTunesCopyCurrentTrackProperties(NULL);
  if (dict) {
    if (!ia_bezel) {
      [NSBundle loadNibNamed:@"iTunesTrack" owner:self];
      ia_bezel = [[SKBezelItem alloc] initWithContent:[artwork superview]];
      [ia_bezel setDelay:1];
      [ia_bezel setAdjustSize:YES];
      [ia_bezel setFrameOrigin:NSMakePoint(50, 50)];
    }
    [track setStringValue:[dict objectForKey:@"Name"]];
    [artist setStringValue:[dict objectForKey:@"Artist"]];
    [album setStringValue:[dict objectForKey:@"Album"]];
    [ia_bezel display:nil];
    [dict release];
  }
}

- (SparkAlert *)execute {
  SparkAlert *alert = [self check];
  if (alert == nil) {
    switch ([self iTunesAction]) {
      case kiTunesLaunch:
        [self launchITunes];
        break;
      case kiTunesQuit:
        [self quitITunes];
        break;
      case kiTunesPlayPause:
        [self sendAppleEvent:'PlPs'];
        break;
      case kiTunesPlayPlaylist:
        alert = [self playPlaylist:[self playlist]];
        break;
      case kiTunesNextTrack:
        [self sendAppleEvent:'Next'];
        [self displayTrackInfo];
        break;
      case kiTunesBackTrack:
        [self sendAppleEvent:'Back'];
        [self displayTrackInfo];
        break;
      case kiTunesStop:
        [self sendAppleEvent:'Stop'];
        break;
      case kiTunesVisual:
        [self switchVisualStat];
        break;
      case kiTunesVolumeDown:
        [self volumeDown];
        break;
      case kiTunesVolumeUp:
        [self volumeUp];
        break;
      case kiTunesEjectCD:
        [self ejectCD];
        break;
      case kiTunesRateTrack:
        iTunesRateCurrentSong([self rating]);
        break;
    }
  }
  return alert;
}

#pragma mark -
#pragma mark iTunes Action specific Methods
/****************************************************************************************
*                             iTunes Action specific Methods							*
****************************************************************************************/

- (SInt16)rating {
  return ia_rating;
}

- (void)setRating:(SInt16)aRate {
  ia_rating = aRate;
}

- (NSString *)playlist {
  return ia_playlist;
}

- (void)setPlaylist:(NSString *)newPlaylist {
  if (ia_playlist != newPlaylist) {
    [ia_playlist release];
    ia_playlist = [newPlaylist copy];
  }
}

- (iTunesAction)iTunesAction {
  return ia_action;
}

- (void)setITunesAction:(iTunesAction)newITunesAction {
  if (ia_action != newITunesAction) {
    ia_action = newITunesAction;
  }
}

- (void)launchITunes {
  [[NSWorkspace sharedWorkspace] launchApplication:SKFindApplicationForSignature('hook')];
}

- (void)quitITunes {
  SKAESendSimpleEvent(kITunesSignature, kCoreEventClass, kAEQuitApplication);
}

- (void)sendAppleEvent:(OSType)eventType {
  SKAESendSimpleEvent(kITunesSignature, 'hook', eventType);
}

- (void)switchVisualStat {
  Boolean state;
  OSStatus err = iTunesGetVisualState(&state);
  if (noErr == err) {
    iTunesSetVisualState(!state);
  }
}

- (void)volumeUp {
  SInt16 volume = 0;
  if (noErr == iTunesGetVolume(&volume)) {
    SInt16 newVol = MIN(100, volume + 5);
    if (newVol != volume)
      iTunesSetVolume(newVol);
  }
}

- (void)volumeDown {
  SInt16 volume = 0;
  if (noErr == iTunesGetVolume(&volume)) {
    SInt16 newVol = MAX(0, volume - 5);
    if (newVol != volume)
      iTunesSetVolume(newVol);
  }
}

- (void)ejectCD {
  CGKeyCode code = HKMapGetKeycodeAndModifierForUnichar('e', NULL, NULL);
  if (code != kHKInvalidVirtualKeyCode) {
    HKEventTarget target = { signature:kITunesSignature };
    HKEventPostKeystrokeToTarget(code, kCGEventFlagMaskCommand, target, kHKEventTargetSignature, NULL);
  }
}

- (SparkAlert *)playPlaylist:(NSString *)name {
  OSStatus err = iTunesPlayPlaylist((CFStringRef)name);
  if (err == errAENoSuchObject) {
    return [SparkAlert alertWithMessageText:@"Impossible de jouer la Playlist." informativeTextWithFormat:@"La Playlist %@ est introuvable.", name];
  }
  return nil;
}

@end
