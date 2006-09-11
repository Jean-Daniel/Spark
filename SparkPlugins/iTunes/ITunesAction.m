/*
 *  ITunesAction.m
 *  Spark Plugins
 *
 *  Created by Black Moon Team.
 *  Copyright (c) Shadow Lab. 2004 - 2006. All rights reserved.
 */

#import "ITunesAction.h"

#import "ITunesAESuite.h"

#import <ShadowKit/SKFunctions.h>
#import <ShadowKit/SKLSFunctions.h>
#import <ShadowKit/SKAEFunctions.h>

#import <HotKeyToolKit/HotKeyToolKit.h>

static NSString* const kITunesFlagsKey = @"iTunesFlags";
static NSString* const kITunesActionKey = @"iTunesAction";
static NSString* const kITunesPlaylistKey = @"iTunesPlaylist";

NSString * const kiTunesActionBundleIdentifier = @"org.shadowlab.spark.iTunes";

static const iTunesAction _kActionsMap[] = {
  kiTunesLaunch,
  kiTunesQuit,
  kiTunesPlayPause,
  kiTunesBackTrack,
  kiTunesNextTrack,
  kiTunesStop,
  kiTunesVisual,
  kiTunesVolumeDown,
  kiTunesVolumeUp,
  kiTunesEjectCD,
  kiTunesPlayPlaylist,
  kiTunesRateTrack
};
SK_INLINE
iTunesAction _iTunesConvertAction(int act) {
  return act >= 0 && act < 11 ? _kActionsMap[act] : 0;
}

@implementation ITunesAction

#pragma mark Protocols Implementation
- (id)copyWithZone:(NSZone *)zone {
  ITunesAction* copy = [super copyWithZone:zone];
  copy->ia_action = ia_action;
  copy->ia_iaFlags = ia_iaFlags;
  copy->ia_playlist = [ia_playlist retain];
  return copy;
}

- (UInt32)encodeFlags {
  UInt32 flags = 0;
  flags |= ia_iaFlags.rate;
  if (ia_iaFlags.hide) flags |= 1 << 7;
  if (ia_iaFlags.autoplay) flags |= 1 << 8;
  if (ia_iaFlags.background) flags |= 1 << 9;
  flags |= ia_iaFlags.visual << 10;
  return flags;
}

- (void)encodeWithCoder:(NSCoder *)coder {
  [super encodeWithCoder:coder];
  [coder encodeInt:ia_action forKey:kITunesActionKey];
  [coder encodeInt:[self encodeFlags] forKey:kITunesFlagsKey];
  [coder encodeObject:[self playlist] forKey:kITunesPlaylistKey];
  return;
}

- (void)decodeFlags:(UInt32)flags {
  ia_iaFlags.rate = flags & 0x7f; /* bits 0 to 6 */
  
  if (flags & 1 << 7) ia_iaFlags.hide = 1; /* bit 7 */
  if (flags & 1 << 8) ia_iaFlags.autoplay = 1; /* bit 8 */
  if (flags & 1 << 9) ia_iaFlags.background = 1; /* bit 9 */
  
  ia_iaFlags.visual = (flags >> 10) & 0x3; /* bits 10 and 11 */
}

- (id)initWithCoder:(NSCoder *)coder {
  if (self = [super initWithCoder:coder]) {
    [self decodeFlags:[coder decodeIntForKey:kITunesFlagsKey]];
    [self setITunesAction:[coder decodeIntForKey:kITunesActionKey]];
    [self setPlaylist:[coder decodeObjectForKey:kITunesPlaylistKey]];
  }
  return self;
}

#pragma mark -
- (id)init {
  if (self = [super init]) {
    [self setVersion:0x200];
  }
  return self;
}

- (void)dealloc {
  [ia_playlist release];
  if (visual)
    NSZoneFree(nil, visual);
  [super dealloc];
}

#pragma mark -
#pragma mark Required Methods.
- (id)initWithSerializedValues:(id)plist {
  if (self = [super initWithSerializedValues:plist]) {
    [self setPlaylist:[plist objectForKey:kITunesPlaylistKey]];
    switch ([self version]) {
      case 0x200:
        [self decodeFlags:[[plist objectForKey:kITunesFlagsKey] unsignedIntValue]];
        [self setITunesAction:SKHFSTypeCodeFromFileType([plist objectForKey:kITunesActionKey])];
        break;
      default: /* Old version */
        [self setVersion:0x200];
        [self setRating:[[plist objectForKey:@"iTunesTrackTrate"] intValue]];
        [self setITunesAction:_iTunesConvertAction([[plist objectForKey:kITunesActionKey] intValue])];
        break;
    }
    NSString *description = ITunesActionDescription(self);
    if (description)
      [self setActionDescription:description];
  }
return self;
}

- (BOOL)serialize:(NSMutableDictionary *)plist {
  [super serialize:plist];
  [plist setObject:SKUInt([self encodeFlags]) forKey:kITunesFlagsKey];
  [plist setObject:SKFileTypeForHFSTypeCode([self iTunesAction]) forKey:kITunesActionKey];
  if ([self playlist])
    [plist setObject:[self playlist] forKey:kITunesPlaylistKey];
  return YES;
}

- (SparkAlert *)check {
  switch ([self iTunesAction]) {
    case kiTunesLaunch:
    case kiTunesQuit:
    case kiTunesPlayPause:
    case kiTunesNextTrack:
    case kiTunesBackTrack:
    case kiTunesStop:
    case kiTunesShowTrackInfo:
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

- (SparkAlert *)execute {
  SparkAlert *alert = [self check];
  if (alert == nil) {
    switch ([self iTunesAction]) {
      case kiTunesLaunch: {
        LSLaunchFlags flags = kLSLaunchDefaults;
        if (ia_iaFlags.hide)
          flags |= kLSLaunchAndHide;
        if (ia_iaFlags.background)
          flags |= kLSLaunchDontSwitch;
        iTunesLaunch(flags);
        if (ia_iaFlags.autoplay)
          iTunesSendCommand(kiTunesCommandPlay);
      }
        break;
      case kiTunesQuit:
        iTunesQuit();
        break;
      case kiTunesPlayPause:
        iTunesSendCommand(kiTunesCommandPlayPause);
        break;
      case kiTunesPlayPlaylist:
        alert = [self playPlaylist:[self playlist]];
        break;
      case kiTunesNextTrack:
        iTunesSendCommand(kiTunesCommandNextTrack);
        //[self displayTrackInfo];
        break;
      case kiTunesBackTrack:
        iTunesSendCommand(kiTunesCommandPreviousTrack);
        //[self displayTrackInfo];
        break;
      case kiTunesStop:
        iTunesSendCommand(kiTunesCommandStopPlaying);
        break;
      case kiTunesShowTrackInfo:
        //[self displayTrackInfo];
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
        iTunesSetCurrentTrackRate([self rating]);
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
- (SInt32)rating {
  return ia_iaFlags.rate;
}

- (void)setRating:(SInt32)aRate {
  ia_iaFlags.rate = (aRate > 100) ? 100 : ((aRate < 0) ? 0 : aRate);
}

- (NSString *)playlist {
  return ia_playlist;
}

- (void)setPlaylist:(NSString *)aPlaylist {
  SKSetterCopy(ia_playlist, aPlaylist);
}

- (iTunesAction)iTunesAction {
  return ia_action;
}

- (void)setITunesAction:(iTunesAction)anAction {
  ia_action = anAction;
}

#pragma mark -
- (void)switchVisualStat {
  Boolean state;
  OSStatus err = iTunesGetVisualEnabled(&state);
  if (noErr == err) {
    iTunesSetVisualEnabled(!state);
  }
}

- (void)volumeUp {
  SInt16 volume = 0;
  if (noErr == iTunesGetSoundVolume(&volume)) {
    SInt16 newVol = MIN(100, volume + 5);
    if (newVol != volume)
      iTunesSetSoundVolume(newVol);
  }
}

- (void)volumeDown {
  SInt16 volume = 0;
  if (noErr == iTunesGetSoundVolume(&volume)) {
    SInt16 newVol = MAX(0, volume - 5);
    if (newVol != volume)
      iTunesSetSoundVolume(newVol);
  }
}

- (void)ejectCD {
  CGKeyCode code = HKMapGetKeycodeAndModifierForUnichar('e', NULL, NULL);
  if (code != kHKInvalidVirtualKeyCode) {
    HKEventTarget target = { signature:kiTunesSignature };
    HKEventPostKeystrokeToTarget(code, kCGEventFlagMaskCommand, target, kHKEventTargetSignature, NULL);
  }
}

- (SparkAlert *)playPlaylist:(NSString *)name {
  OSStatus err = iTunesPlayPlaylistWithName((CFStringRef)name);
  if (err == errAENoSuchObject) {
    return [SparkAlert alertWithMessageText:@"Impossible de jouer la Playlist demandee."
                  informativeTextWithFormat:@"La Playlist %@ est introuvable.", name];
  }
  return nil;
}

@end

NSString *ITunesActionDescription(ITunesAction *action) {
  NSString *desc = nil;
  NSBundle *bundle = kiTunesActionBundle;
  switch ([action iTunesAction]) {
    case kiTunesLaunch:
      desc = NSLocalizedStringFromTableInBundle(@"DESC_LAUNCH", nil, bundle,
                                                @"Launch iTunes * Action Description *");
      break;
    case kiTunesQuit:
      desc = NSLocalizedStringFromTableInBundle(@"DESC_QUIT", nil, bundle,
                                                @"Quit iTunes * Action Description *");
      break;
    case kiTunesPlayPause:
      desc = NSLocalizedStringFromTableInBundle(@"DESC_PLAY_PAUSE", nil, bundle,
                                                @"Play/Pause * Action Description *");
      break;
    case kiTunesPlayPlaylist:
      desc = [NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"DESC_PLAY_LIST", nil, bundle,
                                                                           @"Play Playlist * Action Description * (%@ = playlist name)"),
        [action playlist]];
      break;
    case kiTunesRateTrack:
      desc = [NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"DESC_RATE_TRACK", nil, bundle,
                                                                           @"Rate Track * Action Description * (%i = rating)"),
        [action rating]];
      break;
    case kiTunesNextTrack:
      desc = NSLocalizedStringFromTableInBundle(@"DESC_NEXT", nil, bundle,
                                                @"Next Track * Action Description *");
      break;
    case kiTunesBackTrack:
      desc = NSLocalizedStringFromTableInBundle(@"DESC_PREVIOUS", nil, bundle,
                                                @"Previous Track * Action Description *");
      break;
    case kiTunesStop:
      desc = NSLocalizedStringFromTableInBundle(@"DESC_STOP", nil, bundle,
                                                @"Stop * Action Description *");
      break;
    case kiTunesShowTrackInfo:
      desc = NSLocalizedStringFromTableInBundle(@"DESC_TRACK_INFO", nil, bundle,
                                                @"Track Info * Action Description *");
    case kiTunesVisual:
      desc = NSLocalizedStringFromTableInBundle(@"DESC_VISUAL", nil, bundle,
                                                @"Start/Stop Visual * Action Description *");
      break;
    case kiTunesVolumeDown:
      desc = NSLocalizedStringFromTableInBundle(@"DESC_VOLUME_DOWN", nil, bundle,
                                                @"Volume Down * Action Description *");
      break;
    case kiTunesVolumeUp:
      desc = NSLocalizedStringFromTableInBundle(@"DESC_VOLUME_UP", nil, bundle,
                                                @"Volume Up * Action Description *");
      break;
    case kiTunesEjectCD:
      desc = NSLocalizedStringFromTableInBundle(@"DESC_EJECT", nil, bundle,
                                                @"Eject CD * Action Description *");
      break;
  }
  return desc;
}

