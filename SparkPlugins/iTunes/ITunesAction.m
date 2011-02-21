/*
 *  ITunesAction.m
 *  Spark Plugins
 *
 *  Created by Black Moon Team.
 *  Copyright (c) 2004 - 2007, Shadow Lab. All rights reserved.
 */

#import "ITunesAction.h"
#import "ITunesGrowl.h"

#import WBHEADER(WBFunctions.h)
#import WBHEADER(WBAEFunctions.h)
#import WBHEADER(NSImage+WonderBox.h)
#import WBHEADER(WBProcessFunctions.h)

#import <HotKeyToolKit/HotKeyToolKit.h>

static NSString* const kITunesFlagsKey = @"iTunesFlags";
static NSString* const kITunesActionKey = @"iTunesAction";
static NSString* const kITunesVisualKey = @"iTunesVisual";
static NSString* const kITunesPlaylistKey = @"iTunesPlaylist";
static NSString* const kITunesPlaylistIDKey = @"iTunesPlaylistID";

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
WB_INLINE
iTunesAction _iTunesConvertAction(int act) {
  return act >= 0 && act < 11 ? _kActionsMap[act] : 0;
}

@implementation ITunesAction

static ITunesVisual sDefaultVisual = { .delay = -1 };
+ (ITunesVisual *)defaultVisual {
  if (sDefaultVisual.delay >= 0) {
    return &sDefaultVisual;
  } else {
    @synchronized(self) {
      if (sDefaultVisual.delay < 0) {
        NSData *data = SparkPreferencesGetValue(@"iTunesSharedVisual", SparkPreferencesLibrary);
        if (data) {
          if (!ITunesVisualUnpack(data, &sDefaultVisual)) {
            DLog(@"Invalid shared visual: %@", data);
            SparkPreferencesSetValue(@"iTunesSharedVisual", nil, SparkPreferencesLibrary);
          }
        }
      }
      /* Check visual */
      if (sDefaultVisual.delay < 0) {
        memcpy(&sDefaultVisual, &kiTunesDefaultSettings, sizeof(sDefaultVisual));
      }
    }
  }
  return &sDefaultVisual;
}

+ (void)setDefaultVisual:(const ITunesVisual *)visual {
  if (visual) {
    /* If visual as changed */
    if (!ITunesVisualIsEqualTo(visual, &sDefaultVisual)) {
      /* If settings equals defaults settings */
      if (ITunesVisualIsEqualTo(visual, &kiTunesDefaultSettings)) {
        memcpy(&sDefaultVisual, &kiTunesDefaultSettings, sizeof(sDefaultVisual));
        if (kSparkEditorContext == SparkGetCurrentContext()) {
          SparkPreferencesSetValue(@"iTunesSharedVisual", nil, SparkPreferencesLibrary);
        }
      } else {
        memcpy(&sDefaultVisual, visual, sizeof(sDefaultVisual));
        NSData *data = ITunesVisualPack(&sDefaultVisual);
        if (data && kSparkEditorContext == SparkGetCurrentContext()) {
          SparkPreferencesSetValue(@"iTunesSharedVisual", data, SparkPreferencesLibrary);
        }
      }
    }
  } else {
    /* Reset to default */
    if (!ITunesVisualIsEqualTo(&kiTunesDefaultSettings, &sDefaultVisual)) {
      memcpy(&sDefaultVisual, &kiTunesDefaultSettings, sizeof(sDefaultVisual));
    }
    if (kSparkEditorContext == SparkGetCurrentContext()) {
      /* Remove key */
      SparkPreferencesSetValue(@"iTunesSharedVisual", nil, SparkPreferencesLibrary);
    }
  }
}

+ (void)didLoadLibrary:(NSNotification *)aNotification {
  /* Reset settings */
  sDefaultVisual.delay = -1;
}

+ (void)setLibraryPreferenceValue:(id)value forKey:(NSString *)key {
  if (value) {
    if (!ITunesVisualUnpack(value, &sDefaultVisual))
      [self setDefaultVisual:&kiTunesDefaultSettings];
  } else {
    [self setDefaultVisual:&kiTunesDefaultSettings];
  }
}

+ (void)initialize {
  if ([ITunesAction class] == self) {
    if (kSparkDaemonContext == SparkGetCurrentContext()) {
      SparkPreferencesRegisterObserver(self, @selector(setLibraryPreferenceValue:forKey:), 
                                       @"iTunesSharedVisual", SparkPreferencesLibrary);
    }
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didLoadLibrary:)
                                                 name:SparkDidSetActiveLibraryNotification object:nil];
  }
}

#pragma mark Protocols Implementation
- (id)copyWithZone:(NSZone *)zone {
  ITunesAction* copy = [super copyWithZone:zone];
  copy->ia_action = ia_action;
  copy->ia_iaFlags = ia_iaFlags;
  /* Playlist */
  copy->ia_plid = ia_plid;
  copy->ia_playlist = [ia_playlist retain];
  /* Visual */
  if (ia_visual) {
    copy->ia_visual = NSZoneMalloc(nil, sizeof(*ia_visual));
    memcpy(copy->ia_visual, ia_visual, sizeof(*ia_visual));
  }
  return copy;
}

- (UInt32)encodeFlags {
  UInt32 flags = 0;
  flags |= ia_iaFlags.rate;
  if (ia_iaFlags.hide) flags |= 1 << 7;
  if (ia_iaFlags.notify) flags |= 1 << 8;
  if (ia_iaFlags.autoplay) flags |= 1 << 9;
  if (ia_iaFlags.background) flags |= 1 << 10;
  /* Play/Pause flags */
  if (ia_iaFlags.autorun) flags |= 1 << 11;
  if (ia_iaFlags.autoinfo) flags |= 1 << 12;
  /* Visual */
  if (ia_iaFlags.show) flags |= 1 << 16;
  flags |= ia_iaFlags.visual << 17;
  return flags;
}

- (void)encodeWithCoder:(NSCoder *)coder {
  [super encodeWithCoder:coder];
  [coder encodeInt:ia_action forKey:kITunesActionKey];
  [coder encodeInt:[self encodeFlags] forKey:kITunesFlagsKey];
  /* Playlist */
  [coder encodeInt64:ia_plid forKey:kITunesPlaylistIDKey];
  [coder encodeObject:[self playlist] forKey:kITunesPlaylistKey];
  /* Visual */
  if (ia_visual) {
    [coder encodeBytes:(void *)ia_visual length:sizeof(*ia_visual) forKey:kITunesVisualKey];
  }
  return;
}

- (void)decodeFlags:(UInt32)flags {
  ia_iaFlags.rate = flags & 0x7f; /* bits 0 to 6 */
  if (flags & 1 << 7) ia_iaFlags.hide = 1; /* bit 7 */
  if (flags & 1 << 8) ia_iaFlags.notify = 1; /* bit 8 */
  if (flags & 1 << 9) ia_iaFlags.autoplay = 1; /* bit 9 */
  if (flags & 1 << 10) ia_iaFlags.background = 1; /* bit 10 */
  /* Play/Pause flags */
  if (flags & 1 << 11) ia_iaFlags.autorun = 1; /* bit 11 */
  if (flags & 1 << 12) ia_iaFlags.autoinfo = 1; /* bit 12 */
  /* Visual */
  if (flags & 1 << 16) ia_iaFlags.show = 1; /* bit 16 */
  ia_iaFlags.visual = (flags >> 17) & 0x3; /* bits 17 and 18 */
}

- (id)initWithCoder:(NSCoder *)coder {
  if (self = [super initWithCoder:coder]) {
    [self decodeFlags:[coder decodeIntForKey:kITunesFlagsKey]];
    [self setITunesAction:[coder decodeIntForKey:kITunesActionKey]];
    /* Playlist */
    UInt64 plid = [coder decodeInt64ForKey:kITunesPlaylistIDKey];
    [self setPlaylist:[coder decodeObjectForKey:kITunesPlaylistKey] uid:plid];
    
    NSUInteger length = 0;
    const void *visual = [coder decodeBytesForKey:kITunesVisualKey returnedLength:&length];
    if (visual != NULL && sizeof(*ia_visual) == length) {
      ia_visual = NSZoneMalloc(nil, sizeof(*ia_visual));
      memcpy(ia_visual, visual, sizeof(*ia_visual));
    }
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
  if (ia_visual)
    NSZoneFree(nil, ia_visual);
  [super dealloc];
}

#pragma mark -
#pragma mark Required Methods.
- (id)initWithSerializedValues:(id)plist {
  if (self = [super initWithSerializedValues:plist]) {
    /* Playlist */
    UInt64 plid = [[plist objectForKey:kITunesPlaylistIDKey] unsignedLongLongValue];
    [self setPlaylist:[plist objectForKey:kITunesPlaylistKey] uid:plid];
    
    switch ([self version]) {
      case 0x200:
        [self decodeFlags:[[plist objectForKey:kITunesFlagsKey] unsignedIntValue]];
        [self setITunesAction:WBOSTypeFromString([plist objectForKey:kITunesActionKey])];
        NSData *data = [plist objectForKey:kITunesVisualKey];
        if (data) {
          ia_visual = NSZoneMalloc(nil, sizeof(*ia_visual));
          if (!ITunesVisualUnpack(data, ia_visual)) {
            NSZoneFree(nil, ia_visual);
            DLog(@"Error while unpacking visual");
          }
        }
        break;
      default: /* Old version */
        [self setVersion:0x200];
        [self setRating:[[plist objectForKey:@"iTunesTrackTrate"] intValue]];
        [self setITunesAction:_iTunesConvertAction([[plist objectForKey:kITunesActionKey] intValue])];
        
        if (![self shouldSaveIcon]) {
          [self setIcon:nil];
        }
        break;
    }
    
    /* if spark editor, check playlist name */
    if (kSparkEditorContext == SparkGetCurrentContext() && iTunesIsRunning(NULL)) {
      if ([self iTunesAction] == kiTunesPlayPlaylist && ia_plid) {
        iTunesPlaylist playlist = WBAEEmptyDesc();
        OSStatus err = [self playlist] ? iTunesGetPlaylistWithName((CFStringRef)[self playlist], &playlist) : errAENoSuchObject;
        if (err == errAENoSuchObject) {
          err = iTunesGetPlaylistWithID(ia_plid, &playlist);
          if (noErr == err) {
            CFStringRef name = nil;
            if (noErr == iTunesCopyPlaylistStringProperty(&playlist, kiTunesNameKey, &name) && name) {
              [self setPlaylist:(id)name uid:ia_plid];
              CFRelease(name);
            }
          }
        }
        WBAEDisposeDesc(&playlist);
      }
    }
    
    /* Update description */
    NSString *description = ITunesActionDescription(self);
    if (description)
      [self setActionDescription:description];
  }
  return self;
}

- (BOOL)serialize:(NSMutableDictionary *)plist {
  [super serialize:plist];
  [plist setObject:WBUInteger([self encodeFlags]) forKey:kITunesFlagsKey];
  [plist setObject:WBStringForOSType([self iTunesAction]) forKey:kITunesActionKey];
  /* Playlist */
  if ([self playlist]) {
    [plist setObject:[self playlist] forKey:kITunesPlaylistKey];
    [plist setObject:WBUInt64(ia_plid) forKey:kITunesPlaylistIDKey];
  }
  /* Visual */
  if (ia_visual) {
    NSData *data = ITunesVisualPack(ia_visual);
    if (data)
      [plist setObject:data forKey:kITunesVisualKey];
    else
      DLog(@"ERROR: Could not pack visual settings");
  }
  return YES;
}

- (SparkAlert *)actionDidLoad {
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
		case kiTunesToggleMute:
    case kiTunesEjectCD:
      return nil;
    case kiTunesPlayPlaylist:
      //TODO: Check if playlist exist.
      return nil;
    case kiTunesRateUp:
    case kiTunesRateDown:
      return nil;
    case kiTunesRateTrack:
      //TODO: Check rate.
      return nil;
    default:
      return [SparkAlert alertWithMessageText:
              [NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"INVALID_ACTION",
                                                                            nil,
                                                                            kiTunesActionBundle,
                                                                            @"Error: Action unknown * Title * (%@ => name)"), [self name]]
                    informativeTextWithFormat:NSLocalizedStringFromTableInBundle(@"INVALID_ACTION_MSG",
                                                                                 nil,
                                                                                 kiTunesActionBundle,
                                                                                 @"Error: Action unknown * Msg * (%@ => name)"), [self name]];
  }
}

- (NSTimeInterval)repeatInterval {
  switch ([self iTunesAction]) {
    case kiTunesVolumeUp:
    case kiTunesVolumeDown:
      return SparkGetDefaultKeyRepeatInterval();
    default:
      return 0;
  }
}

- (BOOL)usesGrowl {
  switch ([self visualMode]) {
    case kiTunesSettingCustom:
      if (ia_visual)
        return ia_visual->growl;
      // fall
    case kiTunesSettingDefault:
      return [[self class] defaultVisual]->growl;
  }
  return NO;
}

- (void)displayTrackNotification {
  /* Avoid double display. (autoinfo issue) */
  //static CFAbsoluteTime sLastDisplayTime = 0;
  //CFAbsoluteTime absTime = CFAbsoluteTimeGetCurrent();
  //if ([SparkAction currentEventTime] > 0 || (absTime - sLastDisplayTime) > 0.25) {
  iTunesTrack track = WBAEEmptyDesc();
  if (noErr == iTunesGetCurrentTrack(&track)) {
    if ([self usesGrowl]) {
      [self displayTrackUsingGrowl:&track];
    } else {
      ITunesInfo *info = [ITunesInfo sharedWindow];
      switch ([self visualMode]) {
        case kiTunesSettingCustom:
          if (ia_visual) {
            [info setTrack:&track visual:ia_visual];
            break;
          }
          // fall
        case kiTunesSettingDefault:
          [info setTrack:&track visual:[[self class] defaultVisual]];
          break;
      }
      [info display:nil];
    }
    WBAEDisposeDesc(&track);
  }
  //}
  //sLastDisplayTime = absTime;
}

- (void)displayInfoIfNeeded {
  if ([self showInfo]) {
    [self displayTrackNotification];
  }
}

- (void)displayInfoIfRunning {
  ITunesState state;
  if ([self showInfo] && noErr == iTunesGetPlayerState(&state) && kiTunesStatePlaying == state) {
    [self displayTrackNotification];
  }
}

- (void)notifyLaunch {
  IconRef ref = NULL;
  if (noErr == GetIconRef(kOnSystemDisk, kiTunesSignature, 'APPL', &ref)) {
    SparkNotificationDisplayIcon(ref, -1);
    ReleaseIconRef(ref);
  }
}

- (SparkAlert *)performAction {
  SparkAlert *alert = nil;
  switch ([self iTunesAction]) {
    case kiTunesLaunch: {
      ProcessSerialNumber psn = {0, kNoProcess};
      psn = WBProcessGetProcessWithSignature(kiTunesSignature);
      if (psn.lowLongOfPSN == kNoProcess) {
        LSLaunchFlags flags = kLSLaunchDefaults;
        if (ia_iaFlags.hide)
          flags |= kLSLaunchAndHide | kLSLaunchDontSwitch;
        else if (ia_iaFlags.background)
          flags |= kLSLaunchDontSwitch;
        iTunesLaunch(flags, &psn);
        if (ia_iaFlags.notify) {
          [self notifyLaunch];
        }
        if (ia_iaFlags.autoplay)
          iTunesSendCommand(kiTunesCommandPlay);
      } else if (!ia_iaFlags.background) {
        /* if not launch in background, bring to front */
        SetFrontProcess(&psn);
      }
    }
      break;
    case kiTunesQuit:
      iTunesQuit();
      break;
    case kiTunesPlayPause: {
      ProcessSerialNumber psn = {0, kNoProcess};
      psn = WBProcessGetProcessWithSignature(kiTunesSignature);
      if (psn.lowLongOfPSN == kNoProcess) {
        if (ia_iaFlags.autorun) {
          /* Launch iTunes */
          iTunesLaunch(kLSLaunchDefaults | kLSLaunchDontSwitch, &psn);
          /* Display iTunes Icon */
          [self notifyLaunch];
          /* Send Play event*/
          iTunesSendCommand(kiTunesCommandPlay);
        }
      } else {
        iTunesSendCommand(kiTunesCommandPlayPause);
        [self displayInfoIfRunning];
      }
    }
      break;
    case kiTunesPlayPlaylist:
      alert = [self playPlaylist];
      break;
    case kiTunesNextTrack:
      iTunesSendCommand(kiTunesCommandNextTrack);
      [self displayInfoIfNeeded];
      break;
    case kiTunesBackTrack:
      iTunesSendCommand(kiTunesCommandPreviousTrack);
      [self displayInfoIfNeeded];
      break;
    case kiTunesStop:
      iTunesSendCommand(kiTunesCommandStopPlaying);
      break;
    case kiTunesShowTrackInfo:
      [self displayTrackNotification];
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
		case kiTunesToggleMute:
			[self toggleMute];
			break;
    case kiTunesEjectCD:
      [self ejectCD];
      break;
    case kiTunesRateUp:
    case kiTunesRateDown: {
      iTunesTrack track = WBAEEmptyDesc();
      OSStatus err = iTunesGetCurrentTrack(&track);
      if (noErr == err) {
        UInt32 rate = 0;
        
        err = iTunesGetTrackRate(&track, &rate);
        if (noErr == err) {
          Boolean set = false;
          if ([self iTunesAction] == kiTunesRateUp) {
            if (rate < 100) {
              set = true;
              rate = (rate + 20) - (rate % 20);
            }
          } else {
            if (rate > 0) {
              set = true;
              rate = rate - ((rate % 20) ? : 20);
            }
          }
          if (set) {
            err = iTunesSetTrackRate(&track, rate);
            if (noErr == err)
              [self displayInfoIfNeeded];
          }
        }
      }
      check_noerr(err);
      // TODO: check err.
      break;
    } 
    case kiTunesRateTrack:
      iTunesSetCurrentTrackRate([self rating]);
      [self displayInfoIfNeeded];
      break;
  }
  return alert;
}

- (BOOL)shouldSaveIcon {
  return NO;
}
/* Icon lazy loading */
- (NSImage *)icon {
  NSImage *icon = [super icon];
  if (!icon) {
    icon = ITunesActionIcon(self);
    [super setIcon:icon];
  }
  return icon;
}

#pragma mark -
#pragma mark iTunes notification extension
//static
//void iTunesNotificationCallback(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) {
//  OSType sign = WBProcessGetFrontProcessSignature();
//  /* Doe nothing if iTunes is the front application */
//  if (sign != kiTunesSignature) {
//    if (userInfo) {
//      CFStringRef state = CFDictionaryGetValue(userInfo, CFSTR("Player State"));
//      /* Does nothing if iTunes not playing */
//      if (state && CFEqual(state, CFSTR("Playing"))) {
//        ITunesAction *action = (ITunesAction *)observer;
//        if ([action isActive]) {
//          [action displayTrackNotification];
//        }
//      }
//    }
//  }
//}

//- (void)setRegistred:(BOOL)flag {
//  if (ia_action == kiTunesShowTrackInfo && [self autoinfo]) {
//    if (flag) {
//      CFNotificationCenterAddObserver(CFNotificationCenterGetDistributedCenter(), self, iTunesNotificationCallback, 
//                                      CFSTR("com.apple.iTunes.playerInfo"), CFSTR("com.apple.iTunes.player"),
//                                      CFNotificationSuspensionBehaviorDeliverImmediately);
//    } else {
//      CFNotificationCenterRemoveObserver(CFNotificationCenterGetDistributedCenter(), self,
//                                         CFSTR("com.apple.iTunes.playerInfo"), CFSTR("com.apple.iTunes.player"));
//    }
//  }
//  [super setRegistred:flag];
//}

#pragma mark iTunes Action specific Methods
/****************************************************************************************
 *                             	iTunes Action specific Methods							*
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

- (void)setPlaylist:(NSString *)aPlaylist uid:(UInt64)uid {
  ia_plid = uid;
  WBSetterCopy(ia_playlist, aPlaylist);
}

- (iTunesAction)iTunesAction {
  return ia_action;
}

- (void)setITunesAction:(iTunesAction)anAction {
  ia_action = anAction;
}

- (const ITunesVisual *)visual {
  return ia_visual;
}
- (void)setVisual:(const ITunesVisual *)visual {
  if (visual) {
    if (!ia_visual)
      ia_visual = NSZoneMalloc(nil, sizeof(*ia_visual));
    memcpy(ia_visual, visual, sizeof(*ia_visual));
  } else if (ia_visual) {
    NSZoneFree(nil, ia_visual);
    ia_visual = NULL;
  }
}

- (BOOL)showInfo {
  return ia_iaFlags.show;
}
- (void)setShowInfo:(BOOL)flag {
  WBFlagSet(ia_iaFlags.show, flag);
}
- (BOOL)launchHide { return ia_iaFlags.hide; }
- (BOOL)launchPlay { return ia_iaFlags.autoplay; }
- (BOOL)launchNotify { return ia_iaFlags.notify; }
- (BOOL)launchBackground { return ia_iaFlags.background; }
- (void)setLaunchHide:(BOOL)flag { WBFlagSet(ia_iaFlags.hide, flag); }
- (void)setLaunchPlay:(BOOL)flag { WBFlagSet(ia_iaFlags.autoplay, flag); }
- (void)setLaunchNotify:(BOOL)flag { WBFlagSet(ia_iaFlags.notify, flag); }
- (void)setLaunchBackground:(BOOL)flag { WBFlagSet(ia_iaFlags.background, flag); }

/* Play/Pause setting */
- (BOOL)autorun { return ia_iaFlags.autorun; }
- (void)setAutorun:(BOOL)flag { WBFlagSet(ia_iaFlags.autorun, flag); }

- (BOOL)autoinfo { return ia_iaFlags.autoinfo; }
- (void)setAutoinfo:(BOOL)flag { WBFlagSet(ia_iaFlags.autoinfo, flag); }

- (int)visualMode {
  return ia_iaFlags.visual;
}
- (void)setVisualMode:(NSInteger)mode {
  ia_iaFlags.visual = mode;
}

#pragma mark -
- (void)switchVisualStat {
  Boolean state;
  OSStatus err = iTunesGetVisualEnabled(&state);
  if (noErr == err) {
    verify_noerr(iTunesSetVisualEnabled(!state));
  }
}

- (void)volumeUp {
  SInt16 volume = 0;
  if (noErr == iTunesGetSoundVolume(&volume)) {
    SInt16 newVol = MIN(100, volume + 5);
    if (newVol != volume)
      verify_noerr(iTunesSetSoundVolume(newVol));
  }
}

- (void)volumeDown {
  SInt16 volume = 0;
  if (noErr == iTunesGetSoundVolume(&volume)) {
    SInt16 newVol = MAX(0, volume - 5);
    if (newVol != volume)
      verify_noerr(iTunesSetSoundVolume(newVol));
  }
}

- (void)toggleMute {
	Boolean mute;
	if (noErr == iTunesIsMuted(&mute))
		verify_noerr(iTunesSetMuted(!mute));
}

- (void)ejectCD {
  CGKeyCode code = HKMapGetKeycodeAndModifierForUnichar('e', NULL);
  if (code != kHKInvalidVirtualKeyCode) {
    HKEventTarget target = { .signature = kiTunesSignature };
    HKEventPostKeystrokeToTarget(code, kCGEventFlagMaskCommand, target, kHKEventTargetSignature, NULL, kHKEventDefaultLatency);
  }
}

- (SparkAlert *)playPlaylist {
  NSString *name = [self playlist];
  OSStatus err = iTunesPlayPlaylistWithName((CFStringRef)name);
  if (err == errAENoSuchObject && ia_plid != 0) {
    err = iTunesPlayPlaylistWithID(ia_plid);
  }
  if (err == errAENoSuchObject) {
    return [SparkAlert alertWithMessageText:
            [NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"PLAYLIST_NOT_FOUND",
                                                                          nil,
                                                                          kiTunesActionBundle,
                                                                          @"Error: no such object playlist * Title * (%@ => name)"), name]
                  informativeTextWithFormat:NSLocalizedStringFromTableInBundle(@"PLAYLIST_NOT_FOUND_MSG",
                                                                               nil,
                                                                               kiTunesActionBundle,
                                                                               @"Error: no such playlist * Msg * (%@ => name)"), [self name]];
  }
  return nil;
}

@end

NSImage *ITunesActionIcon(ITunesAction *action) {
  NSString *icon = nil;
  switch ([action iTunesAction]) {
    case kiTunesLaunch:
      icon = @"iTunes";
      break;
    case kiTunesQuit:
      icon = @"iTunes";
      break;   
    case kiTunesPlayPause:
      icon = @"iTPlay";
      break;
    case kiTunesPlayPlaylist:
      icon = @"iTPlaylist";
      break;
    case kiTunesBackTrack:
      icon = @"iTBack";
      break;
    case kiTunesNextTrack:
      icon = @"iTNext";
      break;
    case kiTunesStop:
      icon = @"iTStop";
      break;
    case kiTunesShowTrackInfo:
      icon = @"iTInfo";
      break;
    case kiTunesRateUp:
    case kiTunesRateDown:  
    case kiTunesRateTrack:
      icon = @"iTStar";
      break;
    case kiTunesVisual:
      icon = @"iTVisual";
      break;
    case kiTunesVolumeDown:
      icon = @"iTVolumeDown";
      break;
    case kiTunesVolumeUp:
      icon = @"iTVolumeUp";
      break;
		case kiTunesToggleMute:
			icon = nil; // TODO: mute icon
			break;
    case kiTunesEjectCD:
      icon = @"iTEject";
      break;
  }
  return icon ? [NSImage imageNamed:icon inBundle:kiTunesActionBundle] : nil;
}

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
    case kiTunesRateUp:
      desc = NSLocalizedStringFromTableInBundle(@"DESC_RATE_UP", nil, bundle,
                                                @"Increase current track rate * Action Description *");
      break;
    case kiTunesRateDown:
      desc = NSLocalizedStringFromTableInBundle(@"DESC_RATE_DOWN", nil, bundle,
                                                @"Reduce current track rate * Action Description *");
      break;
    case kiTunesRateTrack: {
      char rate[32];
      if ([action rating] % 20)
        snprintf(rate, 32, "%.1f", [action rating] / 20.0);
      else
        snprintf(rate, 32, "%i", (int)[action rating] / 20);
      desc = [NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"DESC_RATE_TRACK", nil, bundle,
                                                                           @"Rate Track * Action Description * (%s = rating)"),
              rate];
    }
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
      break;
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
		case kiTunesToggleMute:
			desc = NSLocalizedStringFromTableInBundle(@"DESC_TOGGLE_MUTE", nil, bundle,
                                                @"Toggle Mute * Action Description *");
			break;
    case kiTunesEjectCD:
      desc = NSLocalizedStringFromTableInBundle(@"DESC_EJECT", nil, bundle,
                                                @"Eject CD * Action Description *");
      break;
  }
  return desc;
}

