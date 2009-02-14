/*
 *  AppleScriptAction.m
 *  Spark Plugins
 *
 *  Created by Black Moon Team.
 *  Copyright (c) 2004 - 2007, Shadow Lab. All rights reserved.
 */

#import "AppleScriptAction.h"

#import <OSAKit/OSAKit.h>

#import WBHEADER(WBAlias.h)
#import WBHEADER(NSImage+WonderBox.h)
#import WBHEADER(WonderBoxFunctions.h)

static NSString * const kOSAScriptActionDataKey = @"OSAScriptData";
static NSString * const kOSAScriptActionTypeKey = @"OSAScriptType";
static NSString * const kOSAScriptActionSourceKey = @"OSAScriptSource";
static NSString * const kOSAScriptActionRepeatInterval = @"OSAScriptRepeatInterval";

@implementation AppleScriptAction

#pragma mark Protocols Implementation
- (id)copyWithZone:(NSZone *)zone {
  AppleScriptAction* copy = [super copyWithZone:zone];
  copy->as_alias = [as_alias copy];
  copy->as_script = [as_script copy];
  return copy;
}

- (void)encodeWithCoder:(NSCoder *)coder {
  [super encodeWithCoder:coder];
  if (as_alias)
    [coder encodeObject:as_alias forKey:kOSAScriptActionDataKey];
  if (as_script) 
    [coder encodeObject:[as_script source] forKey:kOSAScriptActionSourceKey];
  
  [coder encodeDouble:as_repeat forKey:kOSAScriptActionRepeatInterval];
}

- (id)initWithCoder:(NSCoder *)coder {
  if (self = [super initWithCoder:coder]) {
    as_alias = [[coder decodeObjectForKey:kOSAScriptActionDataKey] retain];
    NSString *src = [coder decodeObjectForKey:kOSAScriptActionSourceKey];
    if (nil != src)
      as_script = [[OSAScript alloc] initWithSource:src];
    as_repeat = [coder decodeDoubleForKey:kOSAScriptActionRepeatInterval];
  }
  return self;
}

#pragma mark -
- (id)init {
  if (self = [super init]) {
    [self setVersion:0x200];
  }
  return self;
}

- (void)initFromOldPropertyList:(NSDictionary *)plist {
  BOOL file = [[plist objectForKey:@"Script File"] boolValue];
  if (file) {
    WBAlias *alias = [[WBAlias alloc] initWithData:[plist objectForKey:@"Script Data"]];
    [self setScriptAlias:alias];
    [alias release];
  } else {
    id source = [[NSString alloc] initWithData:[plist objectForKey:@"Script Data"]
                                      encoding:NSUTF8StringEncoding];
    [self setScriptSource:source];
    [source release];
  }
  if (![self shouldSaveIcon]) {
    [self setIcon:nil];
  }
}

- (id)initWithSerializedValues:(NSDictionary *)plist {
  if (self = [super initWithSerializedValues:plist]) {
    if ([self version] < 0x200) {
      [self initFromOldPropertyList:plist];
      [self setVersion:0x200];
    } else {
      NSData *data = [plist objectForKey:kOSAScriptActionDataKey];
      OSType type = WBOSTypeFromString([plist objectForKey:kOSAScriptActionTypeKey]);
      switch (type) {
        case 'src ': {
          NSString *src = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
          [self setScriptSource:src];
          [src release];
        }
          break;
        case 'file': {
          [self setScriptAlias:[WBAlias aliasWithData:data]];
        }
          break;
      }
      NSNumber *repeat = [plist objectForKey:kOSAScriptActionRepeatInterval];
      if (repeat)
        as_repeat = [repeat doubleValue];
    }
    /* Update description */
    NSString *description = AppleScriptActionDescription(self);
    if (description)
      [self setActionDescription:description];
  }
  return self;
}

- (void)dealloc {
  [as_script release];
  [as_alias release];
  [super dealloc];
}

- (BOOL)serialize:(NSMutableDictionary *)plist {
  if ([super serialize:plist]) {
    if (as_repeat > 0)
      [plist setObject:WBDouble(as_repeat) forKey:kOSAScriptActionRepeatInterval];
    
    if ([self scriptAlias]) {
      NSData *data = [[self scriptAlias] data];
      if (data) {
        [plist setObject:WBStringForOSType('file') forKey:kOSAScriptActionTypeKey];
        [plist setObject:data forKey:kOSAScriptActionDataKey];
        return YES;
      }
    } else if ([self scriptSource]) {
      NSData *data = [[self scriptSource] dataUsingEncoding:NSUTF8StringEncoding];
      if (data) {
        [plist setObject:WBStringForOSType('src ') forKey:kOSAScriptActionTypeKey];
        [plist setObject:data forKey:kOSAScriptActionDataKey];
        return YES;
      }
    }
  }
  return NO;
}
- (BOOL)shouldSaveIcon {
  return NO;
}
/* Icon lazy loading */
- (NSImage *)icon {
  NSImage *icon = [super icon];
  if (!icon) {
    icon = [NSImage imageNamed:@"AppleScriptIcon" inBundle:AppleScriptActionBundle];
    [super setIcon:icon];
  }
  return icon;
}
- (NSTimeInterval)repeatInterval {
  return as_repeat / 1e3;
}
- (NSTimeInterval)initialRepeatInterval {
  return -1; // Repeat Interval.
}

- (SparkAlert *)performAction {
  NSDictionary *error = nil;
  if (as_script) {
    [as_script executeAndReturnError:&error];
  } else if ([self file]) {
    NSURL *url = [NSURL fileURLWithPath:[self file]];
    as_script = [[OSAScript alloc] initWithContentsOfURL:url
                                                   error:&error];
    if (!error)
      [as_script executeAndReturnError:&error];
  }
  SparkAlert *alert = nil;
  if (error) {
    switch ([[error objectForKey:OSAScriptErrorNumber] intValue]) {
      case 0: // noErr
      case -128: // User Cancel
        return nil;
      default:
        alert = [SparkAlert alertWithMessageText:[NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"ACTION_EXECUTION_ERROR_ALERT", nil,
                                                                                                               AppleScriptActionBundle,
                                                                                                               @"Script Execution error in Action * Title *"), [self name]]
                       informativeTextWithFormat:NSLocalizedStringFromTableInBundle(@"ACTION_EXECUTION_ERROR_ALERT_MSG", nil,
                                                                                    AppleScriptActionBundle,
                                                                                    @"Script Execution error in Action * Msg *"), [error objectForKey:OSAScriptErrorMessage]];
        [alert setHideSparkButton:YES];
    }
  }
  return alert;
}
#pragma mark Ivars
- (NSTimeInterval)repeat {
  return as_repeat;
}
- (void)setRepeat:(NSTimeInterval)anInterval {
  as_repeat = anInterval;
}

- (WBAlias *)scriptAlias {
  return as_alias;
}
- (void)setScriptAlias:(WBAlias *)anAlias {
  WBSetterRetain(&as_alias, anAlias);
}

- (NSString *)file {
  return [[self scriptAlias] path];
}
- (void)setFile:(NSString *)aFile {
  if (aFile != nil) {
    WBAlias *alias = [[WBAlias alloc] initWithPath:aFile];
    [self setScriptAlias:alias];
    [alias release];
  } else {
    [self setScriptAlias:nil];
  }
}

- (NSString *)scriptSource {
  return [as_script source];
}

- (void)setScriptSource:(NSString *)source {
  if (as_script) {
    [as_script release];
    as_script = nil;
  }
  if (source)
    as_script = [[OSAScript alloc] initWithSource:source];
}
@end

//@implementation AppleScriptAction (SparkExport)
//
//- (id)initFromExternalRepresentation:(NSDictionary *)rep {
//  if (self = [super initFromExternalRepresentation:rep]) {
//    NSString *value = [rep objectForKey:@"script-path"];
//    if (value) {
//      WBAlias *alias = [WBAlias aliasWithPath:value];
//      if (alias) {
//        [self setScriptAlias:alias];
//      } else {
//        [self release];
//        self = nil;
//      }
//    } else if (value = [rep objectForKey:@"script-source"]) {
//      [self setScriptSource:value];
//    } else {
//      [self release];
//      self = nil;
//    }
//  }
//  return self;
//}
//
//- (NSMutableDictionary *)externalRepresentation {
//  NSMutableDictionary *plist = [super externalRepresentation];
//  if (plist) {
//    if ([self scriptAlias]) {
//      NSString *path = [[self scriptAlias] path];
//      if (path)
//        [plist setObject:path forKey:@"script-path"];
//    } else if ([self scriptSource]) {
//      [plist setObject:[self scriptSource] forKey:@"script-source"];
//    } 
//  }
//  return plist;
//}
//
//@end

#pragma mark Compatibility
@interface AppleScriptOSAAction : NSObject {
}
@end
@implementation AppleScriptOSAAction

- (id)initWithSerializedValues:(NSDictionary *)plist {
  [self release];
  return [[AppleScriptAction alloc] initWithSerializedValues:plist];
}

@end

#pragma mark -
NSString *AppleScriptActionDescription(AppleScriptAction *anAction) {
  if ([anAction scriptSource]) {
    return NSLocalizedStringFromTableInBundle(@"DESC_EXECUTE_SOURCE", nil, AppleScriptActionBundle,
                                              @"Simple Script Action Description");
  } else if ([anAction file]) {
    return [NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"DESC_EXECUTE_FILE", nil, AppleScriptActionBundle,
                                                                         @"File Script Action Description (%@ => File name)"),
      [[anAction file] lastPathComponent]];
  } else {
    return @"<Invalid Description>";
  }
}

