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
#import <ShadowKit/SKLSFunctions.h>
#import <ShadowKit/SKAEFunctions.h>
#import <HotKeyToolKit/HotKeyToolKit.h>

static NSString* const kITunesFlagsKey = @"iTunesFlags";
static NSString* const kITunesActionKey = @"iTunesAction";
static NSString* const kITunesPlaylistKey = @"iTunesPlaylist";

NSString * const kiTunesActionBundleIdentifier = @"org.shadowlab.spark.iTunes";

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
  if (ia_iaFlags.autoplay) flags |= 1 << 7;
  if (ia_iaFlags.background) flags |= 1 << 8;
  flags |= ia_iaFlags.visual << 9;
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
  
  if (flags & 1 << 7) ia_iaFlags.autoplay = 1; /* bits 7 */
  if (flags & 1 << 8) ia_iaFlags.background = 1; /* bits 8 */
  
  ia_iaFlags.visual = (flags >> 9) & 0x3; /* bits 9 and 10 */
}

- (id)initWithCoder:(NSCoder *)coder {
  if (self = [super initWithCoder:coder]) {
    [self decodeFlags:[coder decodeIntForKey:kITunesFlagsKey]];
    [self setITunesAction:[coder decodeIntForKey:kITunesActionKey]];
    [self setPlaylist:[coder decodeObjectForKey:kITunesPlaylistKey]];
  }
  return self;
}

- (id)init {
  if (self = [super init]) {
    [self setVersion:0x200];
  }
  return self;
}

SK_INLINE
iTunesAction _iTunesConvertAction(int act) {
  switch (act) {
    case 0:
      return kiTunesLaunch;
    case 1:
      return kiTunesQuit;
    case 2:
      return kiTunesPlayPause;
    case 3:
      return kiTunesBackTrack;
    case 4:
      return kiTunesNextTrack;
    case 5:
      return kiTunesStop;
    case 6:
      return kiTunesVisual;
    case 7:
      return kiTunesVolumeDown;
    case 8:
      return kiTunesVolumeUp;
    case 9:
      return kiTunesEjectCD;
    case 10:
      return kiTunesPlayPlaylist;
    case 11:
      return kiTunesRateTrack;
  }
  return 0;
}

#pragma mark -
#pragma mark Required Methods.
/* initWithSerializedValues: is called when a Action is loaded. You must call [super initWithSerializedValues:plist].
Get all values you set in the -serialize method et configure your Action */
- (id)initWithSerializedValues:(id)plist {
  if (self = [super initWithSerializedValues:plist]) {
    [self setPlaylist:[plist objectForKey:kITunesPlaylistKey]];
    switch ([self version]) {
      case 0x200:
        [self decodeFlags:[[plist objectForKey:kITunesFlagsKey] unsignedIntValue]];
        [self setITunesAction:[[plist objectForKey:kITunesActionKey] unsignedIntValue]];
        break;
      default: /* Old version */
        [self setVersion:0x200];
        [self setRating:[[plist objectForKey:@"iTunesTrackTrate"] intValue]];
        [self setITunesAction:_iTunesConvertAction([[plist objectForKey:kITunesActionKey] intValue])];
        break;
    }
  }
return self;
}

- (void)dealloc {
  [ia_playlist release];
  [super dealloc];
}

/* Use to transform and record you Action in a file. The dictionary returned must contains only PList objects 
See the PropertyList documentation to know more about it */
- (BOOL)serialize:(NSMutableDictionary *)plist {
  [super serialize:plist];
  [plist setObject:SKUInt([self encodeFlags]) forKey:kITunesFlagsKey];
  [plist setObject:SKUInt([self iTunesAction]) forKey:kITunesActionKey];
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

- (void)displayTrackInfo {
//  NSDictionary *dict = (id)iTunesCopyCurrentTrackProperties(NULL);
//  if (dict) {
//    if (!ia_bezel) {
//      [NSBundle loadNibNamed:@"iTunesTrack" owner:self];
//      ia_bezel = [[SKBezelItem alloc] initWithContent:[artwork superview]];
//      [ia_bezel setDelay:1];
//      [ia_bezel setOneShot:YES];
//      [ia_bezel setAdjustSize:YES];
//      [ia_bezel setFrameOrigin:NSMakePoint(50, 50)];
//    }
//    [track setStringValue:[dict objectForKey:@"Name"]];
//    [artist setStringValue:[dict objectForKey:@"Artist"]];
//    [album setStringValue:[dict objectForKey:@"Album"]];
//    [ia_bezel display:nil];
//    [dict release];
//  }
}

- (SparkAlert *)execute {
  SparkAlert *alert = [self check];
  if (alert == nil) {
    switch ([self iTunesAction]) {
      case kiTunesLaunch: {
        LSLaunchFlags flags = kLSLaunchDefaults;
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
        [self displayTrackInfo];
        break;
      case kiTunesBackTrack:
        iTunesSendCommand(kiTunesCommandPreviousTrack);
        [self displayTrackInfo];
        break;
      case kiTunesStop:
        iTunesSendCommand(kiTunesCommandStopPlaying);
        break;
      case kiTunesShowTrackInfo:
        [self displayTrackInfo];
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

- (SInt16)rating {
  return ia_iaFlags.rate;
}

- (void)setRating:(SInt16)aRate {
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
