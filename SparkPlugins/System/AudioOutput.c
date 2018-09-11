/*
 *  AudioOutput.c
 *  Spark Plugins
 *
 *  Created by Black Moon Team.
 *  Copyright (c) 2004 - 2007, Shadow Lab. All rights reserved.
 */

#include "AudioOutput.h"
#import <AudioToolbox/AudioToolbox.h>

static const
Float32 kAudioOutputVolumeLevels[] = { 
  0.00f,
  0.06f, 0.12f, 0.19f, 0.25f,
  0.31f, 0.37f, 0.44f, 0.50f,
  0.56f, 0.62f, 0.69f, 0.75f,
  0.81f, 0.87f, 0.93f, 1.00f,
};
const
UInt32 kAudioOutputVolumeMaxLevel = 16;

SPX_INLINE
UInt32 __AudioOutputVolumeGetLevel(Float32 output) {
  if (output <= 0.0)
    return 0;
  else if (output >= 1.0)
    return kAudioOutputVolumeMaxLevel;
  for (unsigned level = 0; level < kAudioOutputVolumeMaxLevel; level++) {
    /* If bewteen current level and next level */
    if (output < kAudioOutputVolumeLevels[level + 1]) {
      /* Round level */
      Float32 avg = (kAudioOutputVolumeLevels[level] + kAudioOutputVolumeLevels[level + 1]) / 2.f;
      return output < avg ? level : level + 1;
    }
  }
  return kAudioOutputVolumeMaxLevel;
}

OSStatus AudioOutputGetSystemDevice(AudioDeviceID *device) {
  UInt32 size = (UInt32)sizeof(AudioDeviceID);
  AudioObjectPropertyAddress thePropertyAddress = { kAudioHardwarePropertyDefaultOutputDevice, kAudioObjectPropertyScopeGlobal, kAudioObjectPropertyElementMaster };
  return AudioObjectGetPropertyData(kAudioObjectSystemObject, &thePropertyAddress, 0, NULL, &size, device);
}

#pragma mark Volume
static const AudioObjectPropertyAddress kAudioOutputMasterVolumeProperty = {
  .mSelector = kAudioHardwareServiceDeviceProperty_VirtualMasterVolume,
  .mScope = kAudioDevicePropertyScopeOutput,
  .mElement = kAudioObjectPropertyElementMaster,
};

Boolean AudioOutputHasVolumeControl(AudioDeviceID device, Boolean *isWritable) {
  OSStatus err = AudioObjectIsPropertySettable(device, &kAudioOutputMasterVolumeProperty, isWritable);
  if (noErr == err)
    return true;

  if (isWritable)
    *isWritable = false;
  return AudioObjectHasProperty(device, &kAudioOutputMasterVolumeProperty);
}

OSStatus AudioOutputGetVolume(AudioDeviceID device, Float32 *volume) {
  UInt32 size = (UInt32)sizeof(Float32);
  return AudioObjectGetPropertyData(device, &kAudioOutputMasterVolumeProperty, 0, NULL, &size, volume);
}

OSStatus AudioOutputSetVolume(AudioDeviceID device, Float32 volume) {
  return AudioObjectSetPropertyData(device, &kAudioOutputMasterVolumeProperty, 0, NULL, (UInt32)sizeof(volume), &volume);
}

#pragma mark -
#pragma mark Mute
static const AudioObjectPropertyAddress kAudioDeviceMuteProperty = {
  kAudioDevicePropertyMute,
  kAudioDevicePropertyScopeOutput,
  kAudioObjectPropertyElementMaster,
};

Boolean AudioOutputHasMuteControl(AudioDeviceID device, Boolean *isWritable) {
  OSStatus err = AudioObjectIsPropertySettable(device, &kAudioDeviceMuteProperty, isWritable);
  if (noErr == err)
    return true;

  if (isWritable)
    *isWritable = false;
  return AudioObjectHasProperty(device, &kAudioDeviceMuteProperty);
}

OSStatus AudioOutputIsMuted(AudioDeviceID device, Boolean *mute) {
  UInt32 value = 0;
  UInt32 size = (UInt32)sizeof(UInt32);
  OSStatus err = AudioObjectGetPropertyData(device, &kAudioDeviceMuteProperty, 0, NULL, &size, &value);
  if (noErr == err) {
    *mute = value ? TRUE : FALSE;
  }
  return err;  
}

OSStatus AudioOutputSetMuted(AudioDeviceID device, Boolean mute) {
  UInt32 value = mute ? 1 : 0;
  return AudioObjectSetPropertyData(device, &kAudioDeviceMuteProperty, 0, NULL, (UInt32)sizeof(UInt32), &value);
}

#pragma mark High Level Functions
static 
OSStatus _AudioOutputSetVolume(AudioDeviceID device, Float32 volume) {
  volume = (volume < 0) ? 0 : ((volume > 1) ? 1 : volume);
  return AudioOutputSetVolume(device, volume);
}

OSStatus AudioOutputVolumeUp(AudioDeviceID device, UInt32 *level) {
  Float32 volume;
  OSStatus err = AudioOutputGetVolume(device, &volume);
  if (noErr == err) {
    UInt32 lvl = __AudioOutputVolumeGetLevel(volume);
    if (kAudioOutputVolumeMaxLevel == lvl) {
      /* If not max level */
      if (fnotequal(volume, 1))
        err = _AudioOutputSetVolume(device, 1);
    } else {
      lvl++;
      assert(lvl <= kAudioOutputVolumeMaxLevel);
      err = _AudioOutputSetVolume(device, kAudioOutputVolumeLevels[lvl]);
    }
    if (level)
      *level = lvl;
  }
  return err;
}
OSStatus AudioOutputVolumeDown(AudioDeviceID device, UInt32 *level) {
  Float32 volume;
  OSStatus err = AudioOutputGetVolume(device, &volume);
  if (noErr == err) {
    UInt32 lvl = __AudioOutputVolumeGetLevel(volume);
    if (0 == lvl) {
      /* If not min level */
      if (fnonzero(volume))
        err = _AudioOutputSetVolume(device, 0);
    } else {
      lvl--;
      assert(lvl <= kAudioOutputVolumeMaxLevel);
      err = _AudioOutputSetVolume(device, kAudioOutputVolumeLevels[lvl]);
    }
    if (level)
      *level = lvl;
  }
  return err;
}
/* 0 - 16 */
OSStatus AudioOutputVolumeGetLevel(AudioDeviceID device, UInt32 *level) {
  Float32 volume;
  OSStatus err = AudioOutputGetVolume(device, &volume);
  if (noErr == err) {
    if (level)
      *level = __AudioOutputVolumeGetLevel(volume);
  }
  return err;
}
