/*
 *  ITunesInfo.h
 *  Spark Plugins
 *
 *  Created by Black Moon Team.
 *  Copyright (c) 2004 - 2007, Shadow Lab. All rights reserved.
 */

#import "ITunesAESuite.h"

typedef struct _ITunesVisual {
  BOOL shadow;
	BOOL artwork;
  NSPoint location;
  NSTimeInterval delay;
  /* Colors */ 
  CGFloat text[4];
  CGFloat border[4];
  CGFloat backtop[4];
  CGFloat backbot[4];
} ITunesVisual;

WB_PRIVATE
BOOL ITunesVisualIsEqualTo(const ITunesVisual *v1, const ITunesVisual *v2);

WB_PRIVATE
const NSPoint kiTunesUpperLeft;
WB_PRIVATE
const NSPoint kiTunesUpperRight;
WB_PRIVATE
const NSPoint kiTunesBottomLeft;
WB_PRIVATE
const NSPoint kiTunesBottomRight;

WB_PRIVATE
const ITunesVisual kiTunesDefaultSettings;

@class ITunesStarView, ITunesProgressView;
@interface ITunesInfo : NSWindowController <NSWindowDelegate>

+ (ITunesInfo *)sharedWindow;

- (IBAction)display:(id)sender;

- (void)setTrack:(iTunesTrack *)track visual:(const ITunesVisual *)visual;

/* Settings */
- (void)getVisual:(ITunesVisual *)visual;
- (void)setVisual:(const ITunesVisual *)visual;

@property(nonatomic) NSTimeInterval delay;

@property(nonatomic) NSPoint position;

@property(nonatomic) BOOL hasShadow;

@property(nonatomic) BOOL displayArtwork;

@property(nonatomic, retain) NSColor *textColor;

@property(nonatomic, retain) NSColor *borderColor;

@property(nonatomic, retain) NSColor *backgroundColor;

@property(nonatomic, retain) NSColor *backgroundTopColor;

@property(nonatomic, retain) NSColor *backgroundBottomColor;

/* Internal */
- (void)setArtworkVisible:(BOOL)flag;
- (void)setDuration:(SInt32)aTime rate:(SInt32)rate;
@end

WB_INLINE
UInt64 ITunesVisualPackColor(CGFloat color[4]) {
  UInt64 pack = 0;
  pack |= (llround(color[0] * 0xffff) & 0xffff) << 0;
  pack |= (llround(color[1] * 0xffff) & 0xffff) << 16;
  pack |= (llround(color[2] * 0xffff) & 0xffff) << 32;
  pack |= (llround(color[3] * 0xffff) & 0xffff) << 48;
  return pack;
}

WB_INLINE
void ITunesVisualUnpackColor(UInt64 pack, CGFloat color[4]) {
  color[0] = (CGFloat)((pack >> 0) & 0xffff) / 0xffff;
  color[1] = (CGFloat)((pack >> 16) & 0xffff) / 0xffff;
  color[2] = (CGFloat)((pack >> 32) & 0xffff) / 0xffff;
  color[3] = (CGFloat)((pack >> 48) & 0xffff) / 0xffff;
}

typedef struct __attribute__ ((packed)) {
	UInt8 version;
  UInt32 flags;
  UInt64 colors[4];
  CFSwappedFloat32 x, y;
  CFSwappedFloat64 delay;
} ITunesPackedVisual;

typedef struct __attribute__ ((packed)) {
	UInt8 shadow;
  UInt64 colors[4];
  CFSwappedFloat32 x, y;
  CFSwappedFloat64 delay;
} ITunesPackedVisual_v0;

typedef NS_OPTIONS(NSUInteger, ITunesVisualFlags) {
  kiTunesVisualFlagsReserved = 1 << 0,
	kiTunesVisualFlagsShadow   = 1 << 1,
	kiTunesVisualFlagsArtwork  = 1 << 2,
};

WB_EXPORT
NSData *ITunesVisualPack(ITunesVisual *visual);

WB_EXPORT
BOOL ITunesVisualUnpack(NSData *data, ITunesVisual *visual);
