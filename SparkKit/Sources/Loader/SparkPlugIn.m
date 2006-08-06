/*
 *  SparkPlugIn.m
 *  SparkKit
 *
 *  Created by Black Moon Team.
 *  Copyright (c) 2004 - 2006 Shadow Lab. All rights reserved.
 *
 */

#import "SparkPrivate.h"

#import <SparkKit/SparkPlugIn.h>

#import <ShadowKit/SKImageUtils.h>
#import <ShadowKit/SKCGFunctions.h>

@implementation SparkPlugIn

+ (void)initialize {
  if ([SparkPlugIn class] == self) {
    [self exposeBinding:@"path"];
    [self exposeBinding:@"name"];
    [self exposeBinding:@"icon"];
  }
}

- (id)initWithBundle:(NSBundle *)bundle {
  if (self = [super init]) {
    //[[NSScriptSuiteRegistry sharedScriptSuiteRegistry] loadSuitesFromBundle:bundle];
    sp_class = [bundle principalClass];
    [self setPath:[bundle bundlePath]];
    [self setBundleIdentifier:[bundle bundleIdentifier]];
  }
  return self;
}

+ (id)plugInWithBundle:(NSBundle *)bundle {
  return [[[self alloc] initWithBundle:bundle] autorelease]; 
}

- (void)dealloc {
  [sp_name release];
  [sp_path release];
  [sp_icon release];
  [sp_bundle release];
  [sp_descIcon release];
  [sp_description release];
  [super dealloc];
}

- (NSString *)name {
  if (sp_name == nil) {
    [self setName:[sp_class plugInName]];
  }
  return sp_name;
}
- (void)setName:(NSString *)newName {
  SKSetterRetain(sp_name, newName);
}

- (NSString *)path {
  return sp_path;
}

- (void)setPath:(NSString *)newPath {
  SKSetterRetain(sp_path, newPath);
}

- (NSImage *)icon {
  if (sp_icon == nil) {
    [self setIcon:[sp_class plugInIcon]];
  }
  return sp_icon;
}
- (void)setIcon:(NSImage *)icon {
  SKSetterRetain(sp_icon, icon);
}

- (NSString *)bundleIdentifier {
  return sp_bundle;
}
- (void)setBundleIdentifier:(NSString *)identifier {
  SKSetterRetain(sp_bundle, identifier);
}

- (NSImage *)descriptionIcon {
  if (sp_descIcon == nil) {
    NSImage *image = [sp_class descriptionIcon];
    if (!image) {
      /* Compose image */
      NSImage *icon = [self icon];
      image = [[NSImage alloc] initWithSize:NSMakeSize(32, 32)];
      [image lockFocus];
      CGContextRef ctxt = [[NSGraphicsContext currentContext] graphicsPort];
      CGContextClearRect(ctxt, CGRectMake(0, 0, 32, 32));
      
      CGContextSetGrayFillColor(ctxt, 0.60f, 1);
      SKCGContextAddRoundRect(ctxt, CGRectMake(0, 0, 32, 32), 8.f);
      CGContextFillPath(ctxt);
      
      CGContextSetGrayFillColor(ctxt, 0.80f, 1);
      SKCGContextAddRoundRect(ctxt, CGRectMake(2, 2, 28, 28), 6.f);
      CGContextFillPath(ctxt);
      
      NSSize src = [icon size];
      NSRect dest = NSMakeRect(8, 8, 16, 16);
      float ratio = SKScaleGetProportionalRatio(src, dest);
      if (ratio < 1.f) {
        dest.size.width = src.width * ratio;
        dest.size.height = src.height * ratio;
      }
      dest.origin.x = 8.f + (16.f - NSWidth(dest)) / 2.f;
      dest.origin.y = 8.f + (16.f - NSHeight(dest)) / 2.f;  
      [icon drawInRect:dest fromRect:NSMakeRect(0, 0, src.width, src.height) operation:NSCompositeSourceOver fraction:1];
      
      [image unlockFocus];
      [image autorelease];
    }
    [self setDescriptionIcon:image];
  }
  return sp_descIcon;
}
- (void)setDescriptionIcon:(NSImage *)anImage {
  SKSetterRetain(sp_descIcon, anImage);
}
- (NSString *)plugInDescription {
  if (sp_description == nil) {
    NSString *desc = [sp_class plugInDescription];
    if (desc)
      [self setPlugInDescription:desc];
  }
  return sp_description;
}
- (void)setPlugInDescription:(NSString *)aDescription {
  SKSetterCopy(sp_description, aDescription);
}

- (Class)pluginClass {
  return sp_class;
}

- (Class)actionClass {
  return [sp_class actionClass];
}

- (NSString *)description {
  return [NSString stringWithFormat:@"<%@ %p> {Name: %@,\nPlugInClass: %@}",
    [self class], self,
    [self name], [self pluginClass]];
}

@end
