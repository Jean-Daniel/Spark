//
//  SEHTMLGenerator.m
//  Spark Editor
//
//  Created by Grayfox on 28/10/07.
//  Copyright 2007 Shadow Lab. All rights reserved.
//

#import "SEHTMLGenerator.h"

#import "Spark.h"
#import "SELibraryDocument.h"
#import "SETriggersController.h" // trigger sorting

#import <SparkKit/SparkEntry.h>
#import <SparkKit/SparkPlugIn.h>
#import <SparkKit/SparkLibrary.h>
#import <SparkKit/SparkObjectSet.h>
#import <SparkKit/SparkEntryManager.h>
#import <SparkKit/SparkActionLoader.h>

#import <WonderBox/WBBase64.h>
#import <WonderBox/WBXMLTemplate.h>

@implementation SEHTMLGenerator

- (id)initWithDocument:(SELibraryDocument *)document {
  if (self = [super init]) {
    se_doc = document;
  }
  return self;
}

- (BOOL)includesIcon {
  return se_icons;
}
- (void)setIncludesIcons:(BOOL)flag {
  se_icons = flag;
}

- (BOOL)strikeDisabled {
	return se_strike;
}
- (void)setStrikeDisabled:(BOOL)flag {
	se_strike = flag;
}

- (NSInteger)groupBy {
  return se_group;
}
- (void)setGroupBy:(NSInteger)group {
  se_group = group;
}

static
NSInteger _SESortEntries(id e1, id e2, void *ctxt) {
  return [[e1 trigger] compare:(id)[e2 trigger]];
}

- (void)dumpCategories:(NSArray *)categories entries:(NSArray *)entries template:(WBTemplate *)tpl {
  entries = [entries sortedArrayUsingFunction:_SESortEntries context:nil];
  for (NSUInteger idx = 0; idx < [categories count]; idx++) {
    bool dump = false;
    WBTemplate *block = [tpl blockWithName:@"category"];
    SparkPlugIn *plugin = [categories objectAtIndex:idx];
    for (NSUInteger idx2 = 0; idx2 < [entries count]; idx2++) {
      SparkEntry *entry = [entries objectAtIndex:idx2];
      SparkAction *action = [entry action];
      if ([action isKindOfClass:[plugin actionClass]]) {
        dump = true;
        WBTemplate *ablock = [block blockWithName:@"entry"];
        [ablock setVariable:[entry name] forKey:@"name"];
        if (se_icons && [ablock containsKey:@"icon"])
          [ablock setVariable:[self imageTagForImage:[entry icon] size:NSMakeSize(16, 16)] ?: @"" forKey:@"icon"];
        [ablock setVariable:[entry triggerDescription] forKey:@"keystroke"];
        [ablock setVariable:[entry actionDescription] forKey:@"description"];
				if (se_strike)
					[ablock setVariable:[entry isEnabled] ? @"enabled" : @"disabled" forKey:@"status"];
				else 
					[ablock setVariable:@"enabled" forKey:@"status"];
        [ablock dumpBlock];
      }
    }
    if (dump) {
      [block setVariable:[plugin name] forKey:@"name"];
      if (se_icons && [block containsKey:@"icon"]) 
        [block setVariable:[self imageTagForImage:[plugin icon] size:NSMakeSize(18, 18)] forKey:@"icon"];
      [block dumpBlock];
    }
  }
}

- (NSString *)se_template {
  return se_group == 0 ? @"SEExportShortcut" : @"SEExportApp";
}
static
NSComparisonResult _SETriggerCompare(SparkTrigger *t1, SparkTrigger *t2, void *ctxt) {
  return SETriggerSortValue(t1) - SETriggerSortValue(t2);
}

- (BOOL)writeToFile:(NSString *)path atomically:(BOOL)useAuxiliaryFile error:(NSError **)error {
  NSString *file = [[NSBundle mainBundle] pathForResource:[self se_template] ofType:@"xml"];
  NSAssert1(file, @"Missing resource file: %@.xml", [self se_template]);
  
  WBTemplate *tpl = [[WBXMLTemplate alloc] initWithContentsOfFile:file encoding:NSUTF8StringEncoding];
  [tpl setVariable:@"Spark Library" forKey:@"title"];

  SparkLibrary *library = [se_doc library];
  SparkEntryManager *manager = [library entryManager];

  NSArray *plugins = [[SparkActionLoader sharedLoader] plugIns];
  plugins = [plugins sortedArrayUsingDescriptors:gSortByNameDescriptors];
  
  if (se_group == 1) {
    NSMutableArray *customs = [NSMutableArray array];

    SparkApplication *app = [library systemApplication];

    if ([manager containsEntryForApplication:app])
      [customs addObject:app];

    [library.applicationSet enumerateObjectsUsingBlock:^(id obj, BOOL *stop) {
      if ([manager containsEntryForApplication:app])
        [customs addObject:app];
    }];
    
    [customs sortedArrayUsingFunction:SparkObjectCompare context:nil];
    
    /* foreach application that contains at least one entry */
    for (NSUInteger idx = 0; idx < [customs count]; idx++) {
      app = [customs objectAtIndex:idx];
      WBTemplate *block = [tpl blockWithName:@"application"];
      [block setVariable:[app name] forKey:@"name"];
      if (se_icons && [block containsKey:@"icon"]) 
        [block setVariable:[self imageTagForImage:[app icon] size:NSMakeSize(20, 20)] forKey:@"icon"];
      
      /* process entries */
      [self dumpCategories:plugins entries:[manager entriesForApplication:app] template:block];
      
      [block dumpBlock];
    }
  } else {
    NSArray *triggers = [[[library triggerSet] allObjects] sortedArrayUsingFunction:_SETriggerCompare context:nil];
    
    /* foreach trigger */
    for (NSUInteger idx = 0, count = [triggers count]; idx < count; idx++) {
      SparkTrigger *trigger = [triggers objectAtIndex:idx];
      WBTemplate *block = [tpl blockWithName:@"shortcut"];
      [block setVariable:[trigger triggerDescription] forKey:@"description"];
      
      // retreive entries list.
//      if (se_icons && [block containsKey:@"icon"]) 
//        [block setVariable:[self imageTagForImage:[app icon] size:NSMakeSize(20, 20)] forKey:@"icon"];
      
      /* process entries */
//      [self dumpCategories:plugins entries:[manager entriesForApplication:app] template:block];
      
      [block dumpBlock];
    }
    
  }
  [tpl writeToFile:path atomically:useAuxiliaryFile andReset:NO];
  [tpl release];
  return YES;
}

- (NSString *)imageTagForImage:(NSImage *)image size:(NSSize)size {
  size_t bytesPerRow = size.width * 4;
  char *data = malloc(bytesPerRow * size.height);
  CGColorSpaceRef space = CGColorSpaceCreateWithName(kCGColorSpaceGenericRGB);
  CGContextRef ctxt = CGBitmapContextCreate(data, size.width, size.height, 8, bytesPerRow, space, kCGImageAlphaPremultipliedLast);
  CGContextClearRect(ctxt, CGRectMake(0, 0, size.width, size.height));
  CGContextSetInterpolationQuality(ctxt, kCGInterpolationHigh);
  CGColorSpaceRelease(space);
  
  NSGraphicsContext *gctxt = [NSGraphicsContext graphicsContextWithGraphicsPort:ctxt flipped:NO];
  NSGraphicsContext *current = [NSGraphicsContext currentContext];
  [NSGraphicsContext setCurrentContext:gctxt];
  
  NSSize simg = [image size];
  [image drawInRect:NSMakeRect(0, 0, size.width, size.height)
           fromRect:NSMakeRect(0, 0, simg.width, simg.height) 
          operation:NSCompositeSourceOver 
           fraction:1];
  [NSGraphicsContext setCurrentContext:current];
  
  CGImageRef img = CGBitmapContextCreateImage(ctxt);
  CFMutableDataRef png = CFDataCreateMutable(kCFAllocatorDefault, 0);
  CGImageDestinationRef dest = CGImageDestinationCreateWithData(png, kUTTypePNG, 1, NULL);
  CGImageDestinationAddImage(dest, img, NULL);
  CGImageDestinationFinalize(dest);
  CGImageRelease(img);
  CFRelease(dest);
  
  CFDataRef b64 = WBBase64CreateDataByEncodingData(png);
  CGContextRelease(ctxt);
  CFRelease(png);
  free(data);
  
  if (b64) {
    CFMutableStringRef str = CFStringCreateMutable(kCFAllocatorDefault, 0);
    CFStringAppend(str, CFSTR("<img class=\"icon\" alt=\"icon\" src=\"data:image/png;base64, "));
    CFStringAppendCString(str, (const char *)CFDataGetBytePtr(b64), kCFStringEncodingASCII);
    CFStringAppend(str, CFSTR("\" />"));
    CFRelease(b64);
    return [(id)str autorelease];
  }
  return nil;
}

@end
