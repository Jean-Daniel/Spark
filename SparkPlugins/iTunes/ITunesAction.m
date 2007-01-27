/*
 *  ITunesAction.m
 *  Spark Plugins
 *
 *  Created by Black Moon Team.
 *  Copyright (c) 2004 - 2006, Shadow Lab. All rights reserved.
 */

#import "ITunesAction.h"

#import "ITunesAESuite.h"

#import <ShadowKit/SKFunctions.h>
#import <ShadowKit/SKLSFunctions.h>
#import <ShadowKit/SKAEFunctions.h>
#import <ShadowKit/SKProcessFunctions.h>
#import <ShadowKit/SKAppKitExtensions.h>

#import <HotKeyToolKit/HotKeyToolKit.h>

static NSString* const kITunesFlagsKey = @"iTunesFlags";
static NSString* const kITunesActionKey = @"iTunesAction";
static NSString* const kITunesVisualKey = @"iTunesVisual";
static NSString* const kITunesPlaylistKey = @"iTunesPlaylist";
static NSString* const kITunesPlaylistIDKey = @"iTunesPlaylistID";

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

static ITunesVisual defaultVisual = {delay: -1};
+ (ITunesVisual *)defaultVisual {
  if (defaultVisual.delay >= 0) {
    return &defaultVisual;
  } else {
    @synchronized(self) {
      if (defaultVisual.delay < 0) {
        CFPreferencesAppSynchronize((CFStringRef)kSparkPreferencesIdentifier);
        CFDataRef data = CFPreferencesCopyAppValue(CFSTR("iTunesSharedVisual"), (CFStringRef)kSparkPreferencesIdentifier);
        if (data) {
          if (!ITunesVisualUnpack((id)data, &defaultVisual)) {
            DLog(@"Invalid shared visual: %@", data);
            CFPreferencesSetAppValue(CFSTR("iTunesSharedVisual"), NULL, (CFStringRef)kSparkPreferencesIdentifier);
          }
          CFRelease(data);
        }
      }
      /* Check visual */
      if (defaultVisual.delay < 0) {
        memcpy(&defaultVisual, &kiTunesDefaultSettings, sizeof(defaultVisual));
      }
    }
  }
  return &defaultVisual;
}

+ (void)setDefaultVisual:(const ITunesVisual *)visual {
  BOOL change = NO;
  NSData *data = nil;
  if (visual) {
    /* If visual as changed */
    if (!ITunesVisualIsEqualTo(visual, &defaultVisual)) {
      /* If settings equals defaults settings */
      if (ITunesVisualIsEqualTo(visual, &kiTunesDefaultSettings)) {
        CFPreferencesSetAppValue(CFSTR("iTunesSharedVisual"), NULL, (CFStringRef)kSparkPreferencesIdentifier);
      } else {
        memcpy(&defaultVisual, visual, sizeof(defaultVisual));
        data = ITunesVisualPack(&defaultVisual);
        if (data && kSparkEditorContext == SparkGetCurrentContext()) {
          CFPreferencesSetAppValue(CFSTR("iTunesSharedVisual"), (CFDataRef)data, (CFStringRef)kSparkPreferencesIdentifier);
        }
      }
      change = YES;
    }
  } else {
    if (kSparkEditorContext == SparkGetCurrentContext()) {
      /* Remove key */
      CFPreferencesSetAppValue(CFSTR("iTunesSharedVisual"), NULL, (CFStringRef)kSparkPreferencesIdentifier);
    }
    /* Reset to default */
    if (!ITunesVisualIsEqualTo(&kiTunesDefaultSettings, &defaultVisual)) {
      memcpy(&defaultVisual, &kiTunesDefaultSettings, sizeof(defaultVisual));
      change = YES;
    }
  }
  if (change && kSparkEditorContext == SparkGetCurrentContext()) {
    /* Reload configuration server side */
    AppleEvent aevt = SKAEEmptyDesc();

    OSStatus err = SKAECreateEventWithTargetSignature(kSparkDaemonHFSCreatorType, 'SpiT', 'SetV', &aevt);
    require_noerr(err, bail);
    
    err = SKAEAddSubject(&aevt);
    require_noerr(err, bail);
    
    err = SKAEAddCFData(&aevt, keyDirectObject, (CFDataRef)data);
    require_noerr(err, bail);
    
    err = SKAESendEventNoReply(&aevt);
    check_noerr(err);
    
bail:
      SKAEDisposeDesc(&aevt);
  }
}

+ (void)initialize {
  if ([ITunesAction class] == self) {
    if (kSparkDaemonContext == SparkGetCurrentContext()) {
      [[NSAppleEventManager sharedAppleEventManager] setEventHandler:self
                                                         andSelector:@selector(handleAppleEvent:withReplyEvent:)
                                                       forEventClass:'SpiT'
                                                          andEventID:'SetV'];
    }
  }
}

+ (void)handleAppleEvent:(NSAppleEventDescriptor *)event withReplyEvent:(NSAppleEventDescriptor *)replyEvent {
  /* Invalidate visual cache */
  CFDataRef data = NULL;
  if (noErr == SKAEGetCFDataFromAppleEvent([event aeDesc], keyDirectObject, typeData, &data)) {
    if (data) {
      if (!ITunesVisualUnpack((id)data, &defaultVisual))
        [self setDefaultVisual:&kiTunesDefaultSettings];
      CFRelease(data);
    } else {
      [self setDefaultVisual:&kiTunesDefaultSettings];
    }
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
    
    unsigned length = 0;
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
        [self setITunesAction:SKOSTypeFromString([plist objectForKey:kITunesActionKey])];
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
        break;
    }
    
    /* if spark editor, check playlist name */
    if (kSparkEditorContext == SparkGetCurrentContext()) {
      if ([self iTunesAction] == kiTunesPlayPlaylist && ia_plid) {
        iTunesPlaylist playlist = SKAEEmptyDesc();
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
        SKAEDisposeDesc(&playlist);
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
  [plist setObject:SKUInt([self encodeFlags]) forKey:kITunesFlagsKey];
  [plist setObject:SKStringForOSType([self iTunesAction]) forKey:kITunesActionKey];
  /* Playlist */
  if ([self playlist]) {
    [plist setObject:[self playlist] forKey:kITunesPlaylistKey];
    [plist setObject:SKULongLong(ia_plid) forKey:kITunesPlaylistIDKey];
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
                                                                      @"Error: Action unknown * Title * (%@ => name)"), [self name]]
                    informativeTextWithFormat:NSLocalizedStringFromTableInBundle(@"INVALID_ACTION_MSG",
                                                                                 nil,
                                                                                 kiTunesActionBundle,
                                                                                 @"Error: Action unknown * Msg * (%@ => name)"), [self name]];
  }
}

- (NSTimeInterval)repeatInterval {
  if ([self iTunesAction] == kiTunesVolumeDown || [self iTunesAction] == kiTunesVolumeUp) {
    return SparkGetDefaultKeyRepeatInterval();
  }
  return 0;
}

- (void)displayTrackNotification {
  iTunesTrack track = SKAEEmptyDesc();

  ITunesInfo *info = [ITunesInfo sharedWindow];
  if (noErr == iTunesGetCurrentTrack(&track)) {
    [info setTrack:&track];
    SKAEDisposeDesc(&track);
    switch ([self visualMode]) {
      case kiTunesSettingCustom:
        if (ia_visual) {
          [info setVisual:ia_visual];
          break;
        }
        // fall
      case kiTunesSettingDefault:
        [info setVisual:[[self class] defaultVisual]];
    }
    [info display:nil];
  }
}

- (void)displayInfoIfNeeded {
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
      SKProcessGetProcessWithSignature(kiTunesSignature);
      if (psn.lowLongOfPSN == kNoProcess) {
        LSLaunchFlags flags = kLSLaunchDefaults;
        if (ia_iaFlags.hide)
          flags |= kLSLaunchAndHide | kLSLaunchDontSwitch;
        else if (ia_iaFlags.background)
          flags |= kLSLaunchDontSwitch;
        iTunesLaunch(flags);
        if (ia_iaFlags.notify) {
          [self notifyLaunch];
        }
        if (ia_iaFlags.autoplay)
          iTunesSendCommand(kiTunesCommandPlay);
      }
    }
      break;
    case kiTunesQuit:
      iTunesQuit();
      break;
    case kiTunesPlayPause:
      iTunesSendCommand(kiTunesCommandPlayPause);
      [self displayInfoIfNeeded];
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
    case kiTunesEjectCD:
      [self ejectCD];
      break;
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
  SKSetterCopy(ia_playlist, aPlaylist);
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
  SKSetFlag(ia_iaFlags.show, flag);
}
- (BOOL)launchHide { return ia_iaFlags.hide; }
- (BOOL)launchPlay { return ia_iaFlags.autoplay; }
- (BOOL)launchNotify { return ia_iaFlags.notify; }
- (BOOL)launchBackground { return ia_iaFlags.background; }
- (void)setLaunchHide:(BOOL)flag { SKSetFlag(ia_iaFlags.hide, flag); }
- (void)setLaunchPlay:(BOOL)flag { SKSetFlag(ia_iaFlags.autoplay, flag); }
- (void)setLaunchNotify:(BOOL)flag { SKSetFlag(ia_iaFlags.notify, flag); }
- (void)setLaunchBackground:(BOOL)flag { SKSetFlag(ia_iaFlags.background, flag); }

- (int)visualMode {
  return ia_iaFlags.visual;
}
- (void)setVisualMode:(int)mode {
  ia_iaFlags.visual = mode;
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
                                                                               @"Error: no such playlist * Msg * (%@ => name)"), name];
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
      icon = @"Play";
      break;
    case kiTunesPlayPlaylist:
      icon = @"Playlist";
      break;
    case kiTunesBackTrack:
      icon = @"Back";
      break;
    case kiTunesNextTrack:
      icon = @"Next";
      break;
    case kiTunesStop:
      icon = @"Stop";
      break;
    case kiTunesShowTrackInfo:
      icon = @"Info";
      break;
    case kiTunesRateTrack:
      icon = @"Star";
      break;
    case kiTunesVisual:
      icon = @"Visual";
      break;
    case kiTunesVolumeDown:
      icon = @"VolumeDown";
      break;
    case kiTunesVolumeUp:
      icon = @"VolumeUp";
      break;
    case kiTunesEjectCD:
      icon = @"Eject";
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
    case kiTunesRateTrack: {
      char rate[32];
      if ([action rating] % 20)
        snprintf(rate, 32, "%.1f", [action rating] / 20.0);
      else
        snprintf(rate, 32, "%li", [action rating] / 20);
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
    case kiTunesEjectCD:
      desc = NSLocalizedStringFromTableInBundle(@"DESC_EJECT", nil, bundle,
                                                @"Eject CD * Action Description *");
      break;
  }
  return desc;
}

