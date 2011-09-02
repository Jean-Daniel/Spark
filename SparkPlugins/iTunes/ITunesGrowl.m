//
//  ITunesGrowl.m
//  Spark Plugins
//
//  Created by Jean-Daniel Dupas on 05/04/08.
//  Copyright 2008 Ninsight. All rights reserved.
//

#import "ITunesGrowl.h"

#define GrowlApplicationBridge NSClassFromString(@"GrowlApplicationBridge")

@interface NSString (GrowlTunesMultiplicationAdditions)

- (NSString *)stringByMultiplyingBy:(NSUInteger)multi;

@end

static 
NSImage *ITunesGetApplicationIcon(void) {
  NSImage *icon = nil;
  NSString *itunes = [[NSWorkspace sharedWorkspace] absolutePathForAppBundleWithIdentifier:@"com.apple.iTunes"];
  if (itunes) {
    icon = [[NSWorkspace sharedWorkspace] iconForFile:itunes];
  }
  return icon;
}

@implementation ITunesAction (ITunesGrowl)

- (void)displayTrackUsingGrowl:(iTunesTrack *)track {
  if (![GrowlApplicationBridge isGrowlRunning] || !track) return;
  
  OSType cls = 0;
  CFStringRef value = NULL;
	NSString *name = nil, *album = nil, *artist = nil;
  
  iTunesGetObjectType(track, &cls);
  
  /* Track Name */
  if ('cURT' == cls)
    iTunesCopyCurrentStreamTitle(&value); /* current stream title */
  else
    iTunesCopyTrackStringProperty(track, kiTunesNameKey, &value);
  if (value) {
    name = [(id)value retain];
    CFRelease(value);
    value = NULL;
  } else {
    name = [NSLocalizedStringFromTableInBundle(@"<untiled>", nil, kiTunesActionBundle, @"Untitled track info") retain];
  }
  
  /* Album */
  if ('cURT' == cls)
    iTunesCopyTrackStringProperty(track, kiTunesNameKey, &value); /* radio name */
  else
    iTunesCopyTrackStringProperty(track, kiTunesAlbumKey, &value);
  if (value) {
    album = [(id)value retain];
    CFRelease(value);
    value = NULL;
  }
  
  /* Artist */
  if ('cURT' == cls)
    iTunesCopyTrackStringProperty(track, 'pCat', &value); /* category not available for radio */
  else
    iTunesCopyTrackStringProperty(track, kiTunesArtistKey, &value);
  if (value) {
    artist = [(id)value retain];
    CFRelease(value);
    value = NULL;
  }
  
  NSString *composer = @"", *genre = @"";
  
  /* Time and rate */
  SInt32 duration = 0, rate = 0;
  if ('cURT' == cls) {
    iTunesGetPlayerPosition((UInt32 *)&duration); /* duration not available for radio */
  } else {
    iTunesGetTrackIntegerProperty(track, kiTunesDurationKey, &duration);
    iTunesGetTrackIntegerProperty(track, kiTunesRateKey, &rate);
  }
  NSString *timestr = @"";
  SInt32 days = duration / (3600 * 24);
  SInt32 hours = (duration % (3600 * 24)) / 3600;
  SInt32 minutes = (duration % 3600) / 60;
  SInt32 seconds = duration % 60;
  
  if (days > 0) {
    timestr = [NSString stringWithFormat:@"%i:%.2i:%.2i:%.2i", days, hours, minutes, seconds];
  } else if (hours > 0) {
    timestr = [NSString stringWithFormat:@"%i:%.2i:%.2i", hours, minutes, seconds];
  } else if (minutes > 0 || seconds > 0) {
    timestr = [NSString stringWithFormat:@"%i:%.2i", minutes, seconds];
  }
  
  NSString *rating = [self starsForRating:WBUInteger(rate)];
	
	/* Image */
  OSType type;
  NSData *artwork = nil;
  CFDataRef data = NULL;
  if (noErr == iTunesCopyTrackArtworkData(track, &data, &type) && data) {
    artwork = [(id)data retain];
    CFRelease(data);
  }
  if (!artwork) {
    NSImage *icon = ITunesGetApplicationIcon();
    if (icon) artwork = [[icon TIFFRepresentation] retain];
  }
  
  NSString *displayString;
  if ([composer length] > 0) {
    displayString = [[NSString alloc] initWithFormat:@"%@ — %@\n%@ (Composed by %@)\n%@\n%@", 
                     timestr, rating, artist, composer, album, genre];
  } else {
    displayString = [[NSString alloc] initWithFormat:@"%@ — %@\n%@\n%@\n%@", 
                     timestr, rating, artist, album, genre];
  }
  
  [GrowlApplicationBridge notifyWithTitle:name
                              description:displayString
                         notificationName:@"org.shadowlab.spark.itunes.info"
                                 iconData:artwork
                                 priority:0
                                 isSticky:NO
                             clickContext:nil
                               identifier:@"Spark - iTunes Track"];
  [displayString release];
  [composer release];
  [artwork release];
  [artist release];
  [album release];
  [genre release];
  [name release];
}

#pragma mark -
- (NSString *)starsForRating:(NSNumber *)aRating withStarCharacter:(unichar)star {
	int rating = aRating ? [aRating intValue] : 0;
  
	enum {
		BLACK_STAR  = 0x272F, SPACE          = 0x0020, MIDDLE_DOT   = 0x00B7,
		ONE_HALF    = 0x00BD,
		ONE_QUARTER = 0x00BC, THREE_QUARTERS = 0x00BE,
		ONE_THIRD   = 0x2153, TWO_THIRDS     = 0x2154,
		ONE_FIFTH   = 0x2155, TWO_FIFTHS     = 0x2156, THREE_FIFTHS = 0x2157, FOUR_FIFTHS   = 0x2158,
		ONE_SIXTH   = 0x2159, FIVE_SIXTHS    = 0x215a,
		ONE_EIGHTH  = 0x215b, THREE_EIGHTHS  = 0x215c, FIVE_EIGHTHS = 0x215d, SEVEN_EIGHTHS = 0x215e,
    
		//rating <= 0: dot, space, dot, space, dot, space, dot, space, dot (five dots).
		//higher ratings mean fewer characters. rating >= 100: five black stars.
		numChars = 9,
	};
  
	static unichar fractionChars[] = {
		/*0/20*/ 0,
		/*1/20*/ ONE_FIFTH, TWO_FIFTHS, THREE_FIFTHS,
		/*4/20 = 1/5*/ ONE_FIFTH,
		/*5/20 = 1/4*/ ONE_QUARTER,
		/*6/20*/ ONE_THIRD, FIVE_EIGHTHS,
		/*8/20 = 2/5*/ TWO_FIFTHS, TWO_FIFTHS,
		/*10/20 = 1/2*/ ONE_HALF, ONE_HALF,
		/*12/20 = 3/5*/ THREE_FIFTHS,
		/*13/20 = 0.65; 5/8 = 0.625*/ FIVE_EIGHTHS,
		/*14/20 = 7/10*/ FIVE_EIGHTHS, //highly approximate, of course, but it's as close as I could get :)
		/*15/20 = 3/4*/ THREE_QUARTERS,
		/*16/20 = 4/5*/ FOUR_FIFTHS, FOUR_FIFTHS,
		/*18/20 = 9/10*/ SEVEN_EIGHTHS, SEVEN_EIGHTHS, //another approximation
	};
  
	unichar starBuffer[numChars];
	int     wholeStarRequirement = 20;
	unsigned starsRemaining = 5U;
	unsigned i = 0U;
	for (; starsRemaining--; ++i) {
		if (rating >= wholeStarRequirement) {
			starBuffer[i] = star;
			rating -= 20;
		} else {
			/*examples:
			 *if the original rating is 95, then rating = 15, and we get 3/4.
			 *if the original rating is 80, then rating = 0,  and we get MIDDLE DOT.
			 */
			starBuffer[i] = fractionChars[rating];
			if (!starBuffer[i]) {
				//add a space if this isn't the first 'star'.
				if (i) starBuffer[i++] = SPACE;
				starBuffer[i] = MIDDLE_DOT;
			}
			rating = 0; //ensure that remaining characters are MIDDLE DOT.
		}
	}
  
	return [NSString stringWithCharacters:starBuffer length:i];
}

- (NSString *)starsForRating:(NSNumber *)rating {
//  enum {
//		BLACK_STAR  = 0x2605, PINWHEEL_STAR  = 0x272F
//  };
//	return [self starsForRating:rating withStarCharacter:(floor(NSAppKitVersionNumber) > NSAppKitVersionNumber10_3_5) ? PINWHEEL_STAR : BLACK_STAR];
  return [self starsForRating:rating withStarCharacter:0x2605];
}

@end

@implementation NSString (GrowlTunesMultiplicationAdditions)

- (NSString *)stringByMultiplyingBy:(NSUInteger)multi {
	NSUInteger length = [self length];
	NSUInteger length_multi = length * multi;
  
	unichar *buf = malloc(sizeof(unichar) * length_multi);
	if (!buf)
		return nil;
  
	for (unsigned i = 0U; i < multi; ++i)
		[self getCharacters:&buf[length * i]];
  
	NSString *result = [NSString stringWithCharacters:buf length:length_multi];
	free(buf);
	return result;
}

@end
