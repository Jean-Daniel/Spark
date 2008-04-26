/*
 *  ITunesInfo.h
 *  Spark Plugins
 *
 *  Created by Black Moon Team.
 *  Copyright (c) 2004 - 2007, Shadow Lab. All rights reserved.
 */

#import "ITunesAESuite.h"

typedef struct _ITunesVisual {
  BOOL growl;
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
@interface ITunesInfo : NSWindowController {
  IBOutlet NSTextField *ibName;
  IBOutlet NSTextField *ibAlbum;
  IBOutlet NSTextField *ibArtist;
  
  IBOutlet NSTextField *ibTime;
	IBOutlet NSImageView *ibArtwork;
	
  IBOutlet ITunesStarView *ibRate;
  IBOutlet ITunesProgressView *ibProgress;
@private
	NSPoint ia_location;
	
  BOOL ia_growl;
	BOOL ia_artwork;
	CGFloat ia_artWidth;
	NSPoint ia_artOrigin;
}

+ (ITunesInfo *)sharedWindow;

- (IBAction)display:(id)sender;

- (void)setTrack:(iTunesTrack *)track visual:(const ITunesVisual *)visual;

/* Settings */
- (void)getVisual:(ITunesVisual *)visual;
- (void)setVisual:(const ITunesVisual *)visual;

- (NSTimeInterval)delay;
- (void)setDelay:(NSTimeInterval)aDelay;
- (void)setPosition:(NSPoint)aPoint;

- (BOOL)usesGrowl;
- (void)setUsesGrowl:(BOOL)flag;

- (BOOL)hasShadow;
- (void)setHasShadow:(BOOL)hasShadow;

- (BOOL)displayArtwork;
- (void)setDisplayArtwork:(BOOL)flag;

- (NSColor *)textColor;
- (void)setTextColor:(NSColor *)aColor;

- (NSColor *)borderColor;
- (void)setBorderColor:(NSColor *)aColor;

- (NSColor *)backgroundColor;
- (void)setBackgroundColor:(NSColor *)aColor;

- (NSColor *)backgroundTopColor;
- (void)setBackgroundTopColor:(NSColor *)aColor;

- (NSColor *)backgroundBottomColor;
- (void)setBackgroundBottomColor:(NSColor *)aColor;

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

enum {
  kiTunesVisualFlagsGrowl = 1 << 0,
	kiTunesVisualFlagsShadow = 1 << 1,
	kiTunesVisualFlagsArtwork = 1 << 2,
};
WB_INLINE
NSData *ITunesVisualPack(ITunesVisual *visual) {
  NSMutableData *data = [[NSMutableData alloc] initWithCapacity:sizeof(ITunesPackedVisual)];
  [data setLength:sizeof(ITunesPackedVisual)];
  ITunesPackedVisual *pack = [data mutableBytes];
	pack->version = 1;
  if (visual->growl)	pack->flags |= kiTunesVisualFlagsGrowl;
	if (visual->shadow)	pack->flags |= kiTunesVisualFlagsShadow;
	if (visual->artwork)	pack->flags |= kiTunesVisualFlagsArtwork;
  pack->delay = CFConvertFloat64HostToSwapped(visual->delay);
  pack->x = CFConvertFloat32HostToSwapped((float)visual->location.x);
  pack->y = CFConvertFloat32HostToSwapped((float)visual->location.y);
  pack->colors[0] = OSSwapHostToBigInt64(ITunesVisualPackColor(visual->text));
  pack->colors[1] = OSSwapHostToBigInt64(ITunesVisualPackColor(visual->border));
  pack->colors[2] = OSSwapHostToBigInt64(ITunesVisualPackColor(visual->backtop));
  pack->colors[3] = OSSwapHostToBigInt64(ITunesVisualPackColor(visual->backbot));
  return [data autorelease];
}

WB_INLINE
BOOL ITunesVisualUnpack(NSData *data, ITunesVisual *visual) {
  NSCParameterAssert(visual != NULL);
	bzero(visual, sizeof(*visual));
  if (!data) return NO;
	
	if ([data length] == sizeof(ITunesPackedVisual_v0)) {
		const ITunesPackedVisual_v0 *pack = [data bytes];
    visual->growl = 0;
		visual->artwork = 0;
		visual->shadow = pack->shadow != 0;
		visual->delay = CFConvertFloat64SwappedToHost(pack->delay);
		visual->location.x = CFConvertFloat32SwappedToHost(pack->x);
		visual->location.y = CFConvertFloat32SwappedToHost(pack->y);
		ITunesVisualUnpackColor(OSSwapBigToHostInt64(pack->colors[0]), visual->text);
		ITunesVisualUnpackColor(OSSwapBigToHostInt64(pack->colors[1]), visual->border);
		ITunesVisualUnpackColor(OSSwapBigToHostInt64(pack->colors[2]), visual->backtop);
		ITunesVisualUnpackColor(OSSwapBigToHostInt64(pack->colors[3]), visual->backbot);
	} else if ([data length] >= sizeof(ITunesPackedVisual)) {
		const ITunesPackedVisual *pack = [data bytes];
		if (pack->version != 1) return NO;
    visual->growl = (pack->flags & kiTunesVisualFlagsGrowl) != 0;
		visual->shadow = (pack->flags & kiTunesVisualFlagsShadow) != 0;
		visual->artwork = (pack->flags & kiTunesVisualFlagsArtwork) != 0;
		visual->delay = CFConvertFloat64SwappedToHost(pack->delay);
		visual->location.x = CFConvertFloat32SwappedToHost(pack->x);
		visual->location.y = CFConvertFloat32SwappedToHost(pack->y);
		ITunesVisualUnpackColor(OSSwapBigToHostInt64(pack->colors[0]), visual->text);
		ITunesVisualUnpackColor(OSSwapBigToHostInt64(pack->colors[1]), visual->border);
		ITunesVisualUnpackColor(OSSwapBigToHostInt64(pack->colors[2]), visual->backtop);
		ITunesVisualUnpackColor(OSSwapBigToHostInt64(pack->colors[3]), visual->backbot);
	} else {
		return NO;
	}
	
  return YES;
}
