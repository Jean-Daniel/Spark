//
//  AudioOutput.h
//  Labo Test
//
//  Created by Jean-Daniel Dupas on 09/01/07.
//  Copyright 2007 Adamentium. All rights reserved.
//

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

SK_EXPORT 
const UInt32 kAudioOutputVolumeMaxLevel;

#endif /* __AUDIO_OUTPUT_H */
