/*
 *  AppleScriptAction.m
 *  Spark Plugins
 *
 *  Created by Black Moon Team.
 *  Copyright (c) 2004 - 2006, Shadow Lab. All rights reserved.
 */

#import "AppleScriptAction.h"

#import <OSAKit/OSAKit.h>

#import <ShadowKit/SKAlias.h>
#import <ShadowKit/SKFunctions.h>
#import <ShadowKit/SKClassCluster.h>
#import <ShadowKit/SKAppKitExtensions.h>

static NSString * const kOSAScriptActionDataKey = @"OSAScriptData";
static NSString * const kOSAScriptActionTypeKey = @"OSAScriptType";

NSString * const kASActionBundleIdentifier = @"org.shadowlab.spark.applescript";

@interface AppleScriptNSAction : AppleScriptAction {
  /* AppleScript */
  NSAppleScript *as_script;
}

@end

@interface AppleScriptOSAAction : AppleScriptAction {
  /* OSA Script */
  OSAScript *as_script;
}

@end

SKClassCluster(AppleScriptAction);

@implementation SKClusterPlaceholder(AppleScriptAction) (ASClassCluster)

- (id)init {
  /* OSAKit require Mac OS 10.4 or later */
  if (SKSystemMajorVersion() >= 10 && SKSystemMinorVersion() >= 4)
    return [[AppleScriptOSAAction alloc] init];
  else
    return [[AppleScriptNSAction alloc] init];
}

- (id)initWithSerializedValues:(NSDictionary *)plist {
  /* OSAKit require Mac OS 10.4 or later */
  if (SKSystemMajorVersion() >= 10 && SKSystemMinorVersion() >= 4)
    return [[AppleScriptOSAAction alloc] initWithSerializedValues:plist];
  else
    return [[AppleScriptNSAction alloc] initWithSerializedValues:plist];
}

@end

@implementation AppleScriptAction

#pragma mark Protocols Implementation
- (id)copyWithZone:(NSZone *)zone {
  AppleScriptAction* copy = [super copyWithZone:zone];
  copy->as_alias = [as_alias copy];
  return copy;
}

- (void)encodeWithCoder:(NSCoder *)coder {
  [super encodeWithCoder:coder];
  if (as_alias)
    [coder encodeObject:as_alias forKey:kOSAScriptActionDataKey];
}

- (id)initWithCoder:(NSCoder *)coder {
  if (self = [super initWithCoder:coder]) {
    as_alias = [[coder decodeObjectForKey:kOSAScriptActionDataKey] retain];
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
    SKAlias *alias = [[SKAlias alloc] initWithData:[plist objectForKey:@"Script Data"]];
    [self setScriptAlias:alias];
    [alias release];
  }
  else {
    id source = [[NSString alloc] initWithData:[plist objectForKey:@"Script Data"]
                                      encoding:NSUTF8StringEncoding];
    [self setScriptSource:source];
    [source release];
  }
}

- (id)initWithSerializedValues:(NSDictionary *)plist {
  if (self = [super initWithSerializedValues:plist]) {
    if ([self version] < 0x200) {
      [self initFromOldPropertyList:plist];
      [self setVersion:0x200];
    } else {
      NSData *data = [plist objectForKey:kOSAScriptActionDataKey];
      OSType type = SKOSTypeFromString([plist objectForKey:kOSAScriptActionTypeKey]);
      switch (type) {
        case 'src ': {
          NSString *src = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
          [self setScriptSource:src];
          [src release];
        }
          break;
        case 'file': {
          [self setScriptAlias:[SKAlias aliasWithData:data]];
        }
          break;
      }
    }
    /* Update description */
    NSString *description = AppleScriptActionDescription(self);
    if (description)
      [self setActionDescription:description];
  }
  return self;
}

- (void)dealloc {
  [as_alias release];
  [super dealloc];
}

- (BOOL)serialize:(NSMutableDictionary *)plist {
  if ([super serialize:plist]) {
    if ([self scriptAlias]) {
      NSData *data = [[self scriptAlias] data];
      if (data) {
        [plist setObject:SKStringForOSType('file') forKey:kOSAScriptActionTypeKey];
        [plist setObject:data forKey:kOSAScriptActionDataKey];
        return YES;
      }
    } else if ([self scriptSource]) {
      NSData *data = [[self scriptSource] dataUsingEncoding:NSUTF8StringEncoding];
      if (data) {
        [plist setObject:SKStringForOSType('src ') forKey:kOSAScriptActionTypeKey];
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

- (SKAlias *)scriptAlias {
  return as_alias;
}
- (void)setScriptAlias:(SKAlias *)anAlias {
  SKSetterRetain(as_alias, anAlias);
}

- (NSString *)file {
  return [[self scriptAlias] path];
}
- (void)setFile:(NSString *)aFile {
  if (aFile != nil) {
    SKAlias *alias = [[SKAlias alloc] initWithPath:aFile];
    [self setScriptAlias:alias];
    [alias release];
  } else {
    [self setScriptAlias:nil];
  }
}

- (NSString *)scriptSource {
  SKClusterException();
  return nil;
}

- (void)setScriptSource:(NSString *)source {
  SKClusterException();
}

@end

@implementation AppleScriptNSAction 

- (id)copyWithZone:(NSZone *)zone {
  AppleScriptNSAction* copy = [super copyWithZone:zone];
  copy->as_script = [as_script copy];
  return copy;
}

- (void)encodeWithCoder:(NSCoder *)coder {
  [super encodeWithCoder:coder];
  if (as_script) 
    [coder encodeObject:[as_script source] forKey:@"OSAScriptActionSource"];
}

- (id)initWithCoder:(NSCoder *)coder {
  if (self = [super initWithCoder:coder]) {
    NSString *src = [coder decodeObjectForKey:@"OSAScriptActionSource"];
    if (nil != src)
      as_script = [[NSAppleScript alloc] initWithSource:src];
  }
  return self;
}

- (void)dealloc {
  [as_script release];
  [super dealloc];
}

#pragma mark Action
- (SparkAlert *)performAction {
  NSDictionary *error = nil;
  if (as_script) {
    [as_script executeAndReturnError:&error];
  } else if ([self file]) {
    NSURL *url = [NSURL fileURLWithPath:[self file]];
    as_script = [[NSAppleScript alloc] initWithContentsOfURL:url
                                                       error:&error];
    if (!error)
      [as_script executeAndReturnError:&error];
  }
  SparkAlert *alert = nil;
  if (error) {
    switch ([[error objectForKey:NSAppleScriptErrorNumber] intValue]) {
      case 0: // noErr
      case -128: // User Cancel
        return nil;
      default:
        alert = [SparkAlert alertWithMessageText:[NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"ACTION_EXECUTION_ERROR_ALERT", nil,
                                                                                                               AppleScriptActionBundle,
                                                                                                               @"Script Execution error in Action * Title *"), [self name]]
                       informativeTextWithFormat:NSLocalizedStringFromTableInBundle(@"ACTION_EXECUTION_ERROR_ALERT_MSG", nil,
                                                                                    AppleScriptActionBundle,
                                                                                    @"Script Execution error in Action * Msg *"), [error objectForKey:NSAppleScriptErrorMessage]];
        [alert setHideSparkButton:YES];
    }
  }
  return alert;
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
    as_script = [[NSAppleScript alloc] initWithSource:source];
}

@end

#pragma mark -
@implementation AppleScriptOSAAction 

- (id)copyWithZone:(NSZone *)zone {
  AppleScriptOSAAction* copy = [super copyWithZone:zone];
  copy->as_script = [as_script copy];
  return copy;
}

- (void)encodeWithCoder:(NSCoder *)coder {
  [super encodeWithCoder:coder];
  if (as_script) 
    [coder encodeObject:[as_script source] forKey:@"OSAScriptActionSource"];
}

- (id)initWithCoder:(NSCoder *)coder {
  if (self = [super initWithCoder:coder]) {
    NSString *src = [coder decodeObjectForKey:@"OSAScriptActionSource"];
    if (nil != src)
      as_script = [[OSAScript alloc] initWithSource:src];
  }
  return self;
}

- (void)dealloc {
  [as_script release];
  [super dealloc];
}

#pragma mark Action
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

