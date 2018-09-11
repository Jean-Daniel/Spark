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

SPX_PRIVATE
OSStatus AudioOutputGetSystemDevice(AudioDeviceID *device);

SPX_PRIVATE
Boolean AudioOutputHasVolumeControl(AudioDeviceID device, Boolean *isWritable);

SPX_PRIVATE
OSStatus AudioOutputGetVolume(AudioDeviceID device, Float32 *volume);
SPX_PRIVATE
OSStatus AudioOutputSetVolume(AudioDeviceID device, Float32 volume);

SPX_PRIVATE
Boolean AudioOutputHasMuteControl(AudioDeviceID device, Boolean *isWritable);

SPX_PRIVATE
OSStatus AudioOutputIsMuted(AudioDeviceID device, Boolean *mute);
SPX_PRIVATE
OSStatus AudioOutputSetMuted(AudioDeviceID device, Boolean mute);

SPX_PRIVATE
OSStatus AudioOutputVolumeUp(AudioDeviceID device, UInt32 *level);
SPX_PRIVATE
OSStatus AudioOutputVolumeDown(AudioDeviceID device, UInt32 *level);
SPX_PRIVATE
OSStatus AudioOutputVolumeGetLevel(AudioDeviceID device, UInt32 *level);

SPX_PRIVATE
const UInt32 kAudioOutputVolumeMaxLevel;

#endif /* __AUDIO_OUTPUT_H */
