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
#import <SparkKit/SparkAction.h>
#import <SparkKit/SparkPlugIn.h>
#import <SparkKit/SparkTrigger.h>
#import <SparkKit/SparkLibrary.h>
#import <SparkKit/SparkObjectSet.h>
#import <SparkKit/SparkApplication.h>
#import <SparkKit/SparkEntryManager.h>
#import <SparkKit/SparkActionLoader.h>

#import <WonderBox/WBXMLTemplate.h>

@implementation SEHTMLGenerator {
@private
  SELibraryDocument *_document;
}

- (id)initWithDocument:(SELibraryDocument *)document {
  if (self = [super init]) {
    _document = document;
  }
  return self;
}

static
NSInteger _SESortEntries(SparkEntry *e1, SparkEntry *e2, void *ctxt) {
  return [e1.trigger compare:e2.trigger];
}

- (void)dumpCategories:(NSArray *)categories entries:(NSArray *)entries template:(WBTemplate *)tpl {
  entries = [entries sortedArrayUsingFunction:_SESortEntries context:nil];
  for (NSUInteger idx = 0; idx < [categories count]; idx++) {
    bool dump = false;
    WBTemplate *block = [tpl blockWithName:@"category"];
    SparkPlugIn *plugin = categories[idx];
    for (NSUInteger idx2 = 0; idx2 < [entries count]; idx2++) {
      SparkEntry *entry = entries[idx2];
      SparkAction *action = [entry action];
      if ([action isKindOfClass:[plugin actionClass]]) {
        dump = true;
        WBTemplate *ablock = [block blockWithName:@"entry"];
        [ablock setVariable:[entry name] forKey:@"name"];
        if (_includesIcons && [ablock containsKey:@"icon"])
          [ablock setVariable:[self imageTagForImage:[entry icon] size:NSMakeSize(16, 16)] ?: @"" forKey:@"icon"];
        [ablock setVariable:[entry triggerDescription] forKey:@"keystroke"];
        [ablock setVariable:[entry actionDescription] forKey:@"description"];
				if (_strikeDisabled)
					[ablock setVariable:[entry isEnabled] ? @"enabled" : @"disabled" forKey:@"status"];
				else 
					[ablock setVariable:@"enabled" forKey:@"status"];
        [ablock dumpBlock];
      }
    }
    if (dump) {
      [block setVariable:[plugin name] forKey:@"name"];
      if (_includesIcons && [block containsKey:@"icon"])
        [block setVariable:[self imageTagForImage:[plugin icon] size:NSMakeSize(18, 18)] forKey:@"icon"];
      [block dumpBlock];
    }
  }
}

- (NSString *)se_template {
  return _groupBy == 0 ? @"SEExportShortcut" : @"SEExportApp";
}
static
NSComparisonResult _SETriggerCompare(SparkTrigger *t1, SparkTrigger *t2, void *ctxt) {
  return SETriggerSortValue(t1) - SETriggerSortValue(t2);
}

- (BOOL)writeToURL:(NSURL *)url atomically:(BOOL)useAuxiliaryFile error:(__autoreleasing NSError **)error {
  NSURL *tplURL = [[NSBundle mainBundle] URLForResource:[self se_template] withExtension:@"xml"];
  NSAssert1(tplURL, @"Missing resource file: %@.xml", [self se_template]);
  
  WBTemplate *tpl = [[WBXMLTemplate alloc] initWithContentsOfURL:tplURL encoding:NSUTF8StringEncoding];
  [tpl setVariable:@"Spark Library" forKey:@"title"];

  SparkLibrary *library = [_document library];
  SparkEntryManager *manager = [library entryManager];

  NSArray *plugins = [[SparkActionLoader sharedLoader] plugIns];
  plugins = [plugins sortedArrayUsingDescriptors:gSortByNameDescriptors];
  
  if (_groupBy == 1) {
    NSMutableArray *customs = [NSMutableArray array];

    SparkApplication *system = [library systemApplication];

    if ([manager containsEntryForApplication:system])
      [customs addObject:system];

    [library.applicationSet enumerateObjectsUsingBlock:^(id obj, BOOL *stop) {
      if ([manager containsEntryForApplication:system])
        [customs addObject:system];
    }];
    
    [customs sortedArrayUsingComparator:SparkObjectCompare];
    
    /* foreach application that contains at least one entry */
    for (SparkApplication *app in customs) {
      WBTemplate *block = [tpl blockWithName:@"application"];
      [block setVariable:app.name forKey:@"name"];
      if (_includesIcons && [block containsKey:@"icon"])
        [block setVariable:[self imageTagForImage:app.icon size:NSMakeSize(20, 20)] forKey:@"icon"];
      
      /* process entries */
      [self dumpCategories:plugins entries:[manager entriesForApplication:app] template:block];
      
      [block dumpBlock];
    }
  } else {
    NSArray *triggers = [[[library triggerSet] allObjects] sortedArrayUsingFunction:_SETriggerCompare context:nil];
    
    /* foreach trigger */
    for (NSUInteger idx = 0, count = [triggers count]; idx < count; idx++) {
      SparkTrigger *trigger = triggers[idx];
      WBTemplate *block = [tpl blockWithName:@"shortcut"];
      [block setVariable:[trigger triggerDescription] forKey:@"description"];
      
      // retreive entries list.
//      if (_includesIcon && [block containsKey:@"icon"])
//        [block setVariable:[self imageTagForImage:[app icon] size:NSMakeSize(20, 20)] forKey:@"icon"];
      
      /* process entries */
//      [self dumpCategories:plugins entries:[manager entriesForApplication:app] template:block];
      
      [block dumpBlock];
    }
    
  }
  [tpl writeToURL:url atomically:useAuxiliaryFile andReset:NO];
  return YES;
}

- (NSString *)imageTagForImage:(NSImage *)image size:(NSSize)size {
  size_t bytesPerRow = ceil(size.width) * 4;
  char *data = malloc(bytesPerRow * ceil(size.height));
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
  
  CFDataRef b64 = SPXCFDataBridgingRetain([SPXCFToNSData(png) base64EncodedDataWithOptions:0]);
  CGContextRelease(ctxt);
  CFRelease(png);
  free(data);
  
  if (b64) {
    CFMutableStringRef str = CFStringCreateMutable(kCFAllocatorDefault, 0);
    CFStringAppend(str, CFSTR("<img class=\"icon\" alt=\"icon\" src=\"data:image/png;base64, "));
    CFStringAppendCString(str, (const char *)CFDataGetBytePtr(b64), kCFStringEncodingASCII);
    CFStringAppend(str, CFSTR("\" />"));
    CFRelease(b64);
    return SPXCFStringBridgingRelease(str);
  }
  return nil;
}

@end
