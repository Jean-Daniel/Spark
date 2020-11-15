/*
 *  ITunesAction.m
 *  Spark Plugins
 *
 *  Created by Black Moon Team.
 *  Copyright (c) 2004 - 2007, Shadow Lab. All rights reserved.
 */

#import "ITunesAction.h"

#import <WonderBox/WonderBox.h>

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

NSImage *ITunesGetApplicationIcon(void) {
  NSImage *icon = nil;
  NSURL *itunes = [NSWorkspace.sharedWorkspace URLForApplicationWithBundleIdentifier:SPXCFToNSString(iTunesBundleIdentifier())];
  if (itunes)
    [itunes getResourceValue:&icon forKey:NSURLEffectiveIconKey error:NULL];

  return icon;
}

@implementation ITunesAction {
@private
  UInt64 ia_plid;
  NSString *ia_playlist;

  struct _ia_iaFlags {
    unsigned int rate:7; /* 0 to 100 */
    /* launch flags */
    unsigned int hide:1;
    unsigned int notify:1;
    unsigned int autoplay:1;
    unsigned int background:1;
    /* Play/Pause settings */
    unsigned int autorun:1;
    /* Track Info */
    unsigned int autoinfo:1;
    /* visuals settings */
    unsigned int show:1; /* visual enabled */
    unsigned int visual:2; /* visual type: default, custom */
    unsigned int reserved:16;
  } ia_iaFlags;

  ITunesVisual *ia_visual;
}

#pragma mark Protocols Implementation
- (id)copyWithZone:(NSZone *)zone {
  ITunesAction* copy = [super copyWithZone:zone];
  copy->_iTunesAction = _iTunesAction;
  copy->ia_iaFlags = ia_iaFlags;
  /* Playlist */
  copy->ia_plid = ia_plid;
  copy->ia_playlist = ia_playlist;
  /* Visual */
  if (ia_visual) {
    copy->ia_visual = malloc(sizeof(*ia_visual));
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
  [coder encodeInteger:_iTunesAction forKey:kITunesActionKey];
  [coder encodeInteger:[self encodeFlags] forKey:kITunesFlagsKey];
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
      ia_visual = malloc(sizeof(*ia_visual));
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
  if (ia_visual)
    free(ia_visual);
}

#pragma mark -
#pragma mark Required Methods.
- (id)initWithSerializedValues:(id)plist {
  if (self = [super initWithSerializedValues:plist]) {
    /* Playlist */
    UInt64 plid = [[plist objectForKey:kITunesPlaylistIDKey] unsignedLongLongValue];
    [self setPlaylist:[plist objectForKey:kITunesPlaylistKey] uid:plid];

    NSData *data = nil;
    switch ([self version]) {
      case 0x200:
        [self decodeFlags:[[plist objectForKey:kITunesFlagsKey] unsignedIntValue]];
        [self setITunesAction:WBOSTypeFromString([plist objectForKey:kITunesActionKey])];
        data = [plist objectForKey:kITunesVisualKey];
        if (data) {
          ia_visual = malloc(sizeof(*ia_visual));
          if (!ITunesVisualUnpack(data, ia_visual)) {
            free(ia_visual);
            spx_debug("Error while unpacking visual");
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
    if (kSparkContext_Editor == SparkGetCurrentContext()) {
      if ([self iTunesAction] == kiTunesPlayPlaylist && ia_plid) {
        iTunesPlaylist playlist = WBAEEmptyDesc();
        OSStatus err = [self playlist] ? iTunesGetPlaylistWithName(SPXNSToCFString(self.playlist), &playlist) : errAENoSuchObject;
        if (err == errAENoSuchObject) {
          err = iTunesGetPlaylistWithID(ia_plid, &playlist);
          if (noErr == err) {
            CFStringRef name = iTunesCopyPlaylistStringProperty(&playlist, kiTunesNameKey, &err);
            if (name)
              [self setPlaylist:SPXCFStringBridgingRelease(name) uid:ia_plid];
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
  [plist setObject:@([self encodeFlags]) forKey:kITunesFlagsKey];
  [plist setObject:WBStringForOSType([self iTunesAction]) forKey:kITunesActionKey];
  /* Playlist */
  if ([self playlist]) {
    [plist setObject:[self playlist] forKey:kITunesPlaylistKey];
    [plist setObject:@(ia_plid) forKey:kITunesPlaylistIDKey];
  }
  /* Visual */
  if (ia_visual) {
    NSData *data = ITunesVisualPack(ia_visual);
    if (data)
      [plist setObject:data forKey:kITunesVisualKey];
    else
      spx_debug("ERROR: Could not pack visual settings");
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

- (void)displayTrackNotification {
  /* Avoid double display. (autoinfo issue) */
  //static CFAbsoluteTime sLastDisplayTime = 0;
  //CFAbsoluteTime absTime = CFAbsoluteTimeGetCurrent();
  //if ([SparkAction currentEventTime] > 0 || (absTime - sLastDisplayTime) > 0.25) {
  iTunesTrack track = WBAEEmptyDesc();
  if (noErr == iTunesGetCurrentTrack(&track)) {
    ITunesInfo *info = [ITunesInfo sharedWindow];
    switch ([self visualMode]) {
      case kiTunesSettingCustom:
        if (ia_visual) {
          [info setTrack:&track visual:ia_visual];
          break;
        }
        // fall
      case kiTunesSettingDefault: {
        ITunesVisual visual = {};
        [self.preferences getDefaultVisual:&visual];
        [info setTrack:&track visual:&visual];
      }
        break;
    }
    [info display:nil];
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
  if (kCFCoreFoundationVersionNumber >= 1665.15) {
    NSImage *icon = ITunesGetApplicationIcon();
    if (icon)
      SparkNotificationDisplayImage(icon, -1);
  } else {
    if (noErr == GetIconRef(kOnSystemDisk, 'hook', 'APPL', &ref)) {
      SparkNotificationDisplayIcon(ref, -1);
      ReleaseIconRef(ref);
    }
  }
}

static
NSRunningApplication *iTunesLaunch(NSWorkspaceLaunchOptions flags) {
  NSURL *url = [[NSWorkspace sharedWorkspace] URLForApplicationWithBundleIdentifier:SPXCFToNSString(iTunesBundleIdentifier())];
  return [[NSWorkspace sharedWorkspace] launchApplicationAtURL:url options:flags configuration:@{} error:NULL];
}

- (SparkAlert *)performAction {
  SparkAlert *alert = nil;
  switch ([self iTunesAction]) {
    case kiTunesLaunch: {
      NSRunningApplication *iTunes = [NSRunningApplication runningApplicationsWithBundleIdentifier:SPXCFToNSString(iTunesBundleIdentifier())].firstObject;
      if (!iTunes) {
        NSWorkspaceLaunchOptions flags = NSWorkspaceLaunchDefault;
        if (ia_iaFlags.hide)
          flags |= NSWorkspaceLaunchAndHide | NSWorkspaceLaunchWithoutActivation;
        else if (ia_iaFlags.background)
          flags |= NSWorkspaceLaunchWithoutActivation;
        iTunes = iTunesLaunch(flags);
        if (ia_iaFlags.notify) {
          [self notifyLaunch];
        }
        if (ia_iaFlags.autoplay) {
          pid_t pid = iTunes.processIdentifier;
          OSStatus err = iTunesSendCommand(kiTunesCommandPlay, pid);
          if (noErr != err)
            spx_log_error("play event failed: %d", err);
        }
      } else if (!ia_iaFlags.background) {
        /* if not launch in background, bring to front */
        [iTunes activateWithOptions:NSApplicationActivateIgnoringOtherApps];
      }
    }
      break;
    case kiTunesQuit:
      iTunesQuit();
      break;
    case kiTunesPlayPause: {
      NSRunningApplication *iTunes = [NSRunningApplication runningApplicationsWithBundleIdentifier:SPXCFToNSString(iTunesBundleIdentifier())].firstObject;
      if (!iTunes) {
        if (ia_iaFlags.autorun) {
          /* Launch iTunes */
          iTunes = iTunesLaunch(NSWorkspaceLaunchDefault | NSWorkspaceLaunchWithoutActivation);
          /* Display iTunes Icon */
          [self notifyLaunch];
          /* Send Play event*/
          iTunesSendCommand(kiTunesCommandPlay, iTunes.processIdentifier);
        }
      } else {
        iTunesSendCommand(kiTunesCommandPlayPause, iTunes.processIdentifier);
        [self displayInfoIfRunning];
      }
    }
      break;
    case kiTunesPlayPlaylist:
      alert = [self playPlaylist];
      break;
    case kiTunesNextTrack:
      iTunesSendCommand(kiTunesCommandNextTrack, 0);
      [self displayInfoIfNeeded];
      break;
    case kiTunesBackTrack:
      iTunesSendCommand(kiTunesCommandPreviousTrack, 0);
      [self displayInfoIfNeeded];
      break;
    case kiTunesStop:
      iTunesSendCommand(kiTunesCommandStopPlaying, 0);
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
          bool set = false;
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
      assert(noErr == err);
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
  SPXSetterCopy(ia_playlist, aPlaylist);
}

- (const ITunesVisual *)visual {
  return ia_visual;
}
- (void)setVisual:(const ITunesVisual *)visual {
  if (visual) {
    if (!ia_visual)
      ia_visual = malloc(sizeof(*ia_visual));
    memcpy(ia_visual, visual, sizeof(*ia_visual));
  } else if (ia_visual) {
    free(ia_visual);
    ia_visual = NULL;
  }
}

- (BOOL)showInfo {
  return ia_iaFlags.show;
}
- (void)setShowInfo:(BOOL)flag {
  SPXFlagSet(ia_iaFlags.show, flag);
}
- (BOOL)launchHide { return ia_iaFlags.hide; }
- (BOOL)launchPlay { return ia_iaFlags.autoplay; }
- (BOOL)launchNotify { return ia_iaFlags.notify; }
- (BOOL)launchBackground { return ia_iaFlags.background; }
- (void)setLaunchHide:(BOOL)flag { SPXFlagSet(ia_iaFlags.hide, flag); }
- (void)setLaunchPlay:(BOOL)flag { SPXFlagSet(ia_iaFlags.autoplay, flag); }
- (void)setLaunchNotify:(BOOL)flag { SPXFlagSet(ia_iaFlags.notify, flag); }
- (void)setLaunchBackground:(BOOL)flag { SPXFlagSet(ia_iaFlags.background, flag); }

/* Play/Pause setting */
- (BOOL)autorun { return ia_iaFlags.autorun; }
- (void)setAutorun:(BOOL)flag { SPXFlagSet(ia_iaFlags.autorun, flag); }

- (BOOL)autoinfo { return ia_iaFlags.autoinfo; }
- (void)setAutoinfo:(BOOL)flag { SPXFlagSet(ia_iaFlags.autoinfo, flag); }

- (NSInteger)visualMode {
  return ia_iaFlags.visual;
}
- (void)setVisualMode:(NSInteger)mode {
  ia_iaFlags.visual = (uint8_t)mode;
}

#pragma mark -
- (void)switchVisualStat {
  bool state;
  OSStatus err = iTunesGetVisualEnabled(&state);
  if (noErr == err) {
    spx_verify_noerr(iTunesSetVisualEnabled(!state));
  }
}

- (void)volumeUp {
  int16_t volume = 0;
  if (noErr == iTunesGetSoundVolume(&volume)) {
    int16_t newVol = (int16_t)MIN(100, volume + 5);
    if (newVol != volume)
      spx_verify_noerr(iTunesSetSoundVolume(newVol));
  }
}

- (void)volumeDown {
  int16_t volume = 0;
  if (noErr == iTunesGetSoundVolume(&volume)) {
    int16_t newVol = (int16_t)MAX(0, volume - 5);
    if (newVol != volume)
      spx_verify_noerr(iTunesSetSoundVolume(newVol));
  }
}

- (void)toggleMute {
  bool mute;
  if (noErr == iTunesIsMuted(&mute))
    spx_verify_noerr(iTunesSetMuted(!mute));
}

- (void)ejectCD {
  CGKeyCode code = [[HKKeyMap currentKeyMap] keycodeForCharacter:'e' modifiers:NULL];
  if (code != kHKInvalidVirtualKeyCode) {
    HKEventTarget target = { .bundle = iTunesBundleIdentifier() };
    HKEventPostKeystrokeToTarget(code, kCGEventFlagMaskCommand, target, kHKEventTargetBundle, NULL, kHKEventDefaultLatency);
  }
}

- (SparkAlert *)playPlaylist {
  NSString *name = [self playlist];
  OSStatus err = iTunesPlayPlaylistWithName(SPXNSToCFString(name));
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

@implementation SparkPreference (iTunesPlugin)

- (void)getDefaultVisual:(ITunesVisual *)visual {
  visual->delay = -1;

  NSData *data = [self objectForKey:@"iTunesSharedVisual"];
  if (data) {
    if (!ITunesVisualUnpack(data, visual)) {
      spx_debug("Invalid shared visual: %@", data);
      [self setObject:nil forKey:@"iTunesSharedVisual"];
    }
  }
  /* Check visual */
  if (visual->delay < 0)
    memcpy(visual, &kiTunesDefaultSettings, sizeof(kiTunesDefaultSettings));
}

- (void)setDefaultVisual:(const ITunesVisual *)visual {
  if (visual) {
    NSData *data = ITunesVisualPack(visual);
    if (data)
      [SparkUserDefaults() setObject:data forKey:@"iTunesSharedVisual"];
  } else {
    [self setObject:nil forKey:@"iTunesSharedVisual"];
  }
}

@end
