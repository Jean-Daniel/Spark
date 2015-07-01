/*
 *  AppleScriptAction.m
 *  Spark Plugins
 *
 *  Created by Black Moon Team.
 *  Copyright (c) 2004 - 2007, Shadow Lab. All rights reserved.
 */

#import "AppleScriptAction.h"

#import <OSAKit/OSAKit.h>

#import <WonderBox/WBAlias.h>
#import <WonderBox/WBFunctions.h>
#import <WonderBox/NSImage+WonderBox.h>

static NSString * const kOSAScriptActionDataKey = @"OSAScriptData";
static NSString * const kOSAScriptActionTypeKey = @"OSAScriptType";
static NSString * const kOSAScriptActionSourceKey = @"OSAScriptSource";
static NSString * const kOSAScriptActionRepeatInterval = @"OSAScriptRepeatInterval";

@implementation AppleScriptAction {
@private
  OSAScript *as_script;
  NSTimeInterval as_repeat;
}

#pragma mark Protocols Implementation
- (id)copyWithZone:(NSZone *)zone {
  AppleScriptAction* copy = [super copyWithZone:zone];
  copy->_scriptBookmark = [_scriptBookmark copy];
  copy->as_script = [as_script copy];
  return copy;
}

- (void)encodeWithCoder:(NSCoder *)coder {
  [super encodeWithCoder:coder];
  if (_scriptBookmark)
    [coder encodeObject:_scriptBookmark forKey:kOSAScriptActionDataKey];
  if (as_script) 
    [coder encodeObject:[as_script source] forKey:kOSAScriptActionSourceKey];
  
  [coder encodeDouble:as_repeat forKey:kOSAScriptActionRepeatInterval];
}

- (id)initWithCoder:(NSCoder *)coder {
  if (self = [super initWithCoder:coder]) {
    _scriptBookmark = [coder decodeObjectForKey:kOSAScriptActionDataKey];
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
    NSData *alias = plist[@"Script Data"];
    if (alias)
      _scriptBookmark = [WBAlias aliasFromData:alias];
  } else {
    NSString *source = [[NSString alloc] initWithData:plist[@"Script Data"]
                                             encoding:NSUTF8StringEncoding];
    self.scriptSource = source;
  }
  if (![self shouldSaveIcon])
    self.icon = nil;
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
        }
          break;
        case 'file':
          _scriptBookmark = [WBAlias aliasFromData:data];
        case 'bokm':
          _scriptBookmark = [WBAlias aliasFromBookmarkData:data];
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

- (BOOL)serialize:(NSMutableDictionary *)plist {
  if ([super serialize:plist]) {
    if (as_repeat > 0)
      [plist setObject:@(as_repeat) forKey:kOSAScriptActionRepeatInterval];
    
    if (_scriptBookmark) {
      [plist setObject:WBStringForOSType('bokm') forKey:kOSAScriptActionTypeKey];
      [plist setObject:_scriptBookmark.data forKey:kOSAScriptActionDataKey];
      return YES;
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

- (NSString *)file {
  return _scriptBookmark.path;
}
- (void)setFile:(NSString *)aFile {
  if (aFile != nil) {
    _scriptBookmark = [WBAlias aliasWithURL:[NSURL fileURLWithPath:aFile]];
  } else {
    _scriptBookmark = nil;
  }
}

- (NSString *)scriptSource {
  return [as_script source];
}

- (void)setScriptSource:(NSString *)source {
  if (as_script) {
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
  return (id)[[AppleScriptAction alloc] initWithSerializedValues:plist];
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

