/*
 *  AudioOutput.h
 *  Spark Plugins
 *
 *  Created by Black Moon Team.
 *  Copyright (c) 2004 - 2007, Shadow Lab. All rights reserved.
 */

#if !defined(__AUDIO_OUTPUT_H)
#define __AUDIO_OUTPUT_H 1

#include <CoreAudio/CoreAudio.h>

OSStatus AudioOutputGetSystemDevice(AudioDeviceID *device);

Boolean AudioOutputHasVolumeControl(AudioDeviceID device, Boolean *isWritable);

OSStatus AudioOutputGetVolume(AudioDeviceID device, Float32 *left, Float32 *right);
OSStatus AudioOutputSetVolume(AudioDeviceID device, Float32 left, Float32 right);
OSStatus AudioOutputGetStereoChannels(AudioDeviceID device, UInt32 *left, UInt32 *right);

Boolean AudioOutputHasMuteControl(AudioDeviceID device, Boolean *isWritable);

OSStatus AudioOutputIsMuted(AudioDeviceID device, Boolean *mute);
OSStatus AudioOutputSetMuted(AudioDeviceID device, Boolean mute);

OSStatus AudioOutputVolumeUp(AudioDeviceID device, UInt32 *level);
OSStatus AudioOutputVolumeDown(AudioDeviceID device, UInt32 *level);
OSStatus AudioOutputVolumeGetLevel(AudioDeviceID device, UInt32 *level);

WB_EXPORT 
const UInt32 kAudioOutputVolumeMaxLevel;

#endif /* __AUDIO_OUTPUT_H */
