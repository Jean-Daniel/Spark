//
//  AppleScriptAction.m
//  Spark
//
//  Created by Fox on Fri Feb 20 2004.
//  Copyright (c) 2004 Shadow Lab. All rights reserved.
//

#import "AppleScriptAction.h"
#import "AppleScriptActionPlugin.h"

static NSString* const kASActionScriptDataKey = @"Script Data";
static NSString* const kASActionScriptFileKey = @"Script File";

@implementation AppleScriptAction

#pragma mark Protocols Implementation
- (id)copyWithZone:(NSZone *)zone {
  AppleScriptAction* copy = [super copyWithZone:zone];
  copy->_script = [_script copy];
  copy->_scriptAlias = [_scriptAlias copy];
  return copy;
}

- (void)encodeWithCoder:(NSCoder *)coder {
  [super encodeWithCoder:coder];
  if (_script) 
    [coder encodeObject:[_script source] forKey:kASActionScriptDataKey];
  if (_scriptAlias)
    [coder encodeObject:_scriptAlias forKey:kASActionScriptFileKey];
  return;
}

- (id)initWithCoder:(NSCoder *)coder {
  if (self = [super initWithCoder:coder]) {
    id src = [coder decodeObjectForKey:kASActionScriptDataKey];
    if (nil != src)
      _script = [[NSAppleScript alloc] initWithSource:src];
    _scriptAlias = [[coder decodeObjectForKey:kASActionScriptFileKey] retain];
  }
  return self;
}

#pragma mark -
- (id)initFromPropertyList:(NSDictionary *)plist {
  if (self = [super initFromPropertyList:plist]) {
    BOOL file = [[plist objectForKey:kASActionScriptFileKey] boolValue];
    if (file) {
      SKAlias *alias = [[SKAlias alloc] initWithData:[plist objectForKey:kASActionScriptDataKey]];
      [self setScriptAlias:alias];
      [alias release];
    }
    else {
      id source = [[NSString alloc] initWithData:[plist objectForKey:kASActionScriptDataKey]
                                        encoding:NSUTF8StringEncoding];
      NSAppleScript *script = [[NSAppleScript alloc] initWithSource:source];
      [self setScript:script];
      [script release];
      [source release];
    }
  }
  return self;
}

- (void)dealloc {
  [_scriptAlias release];
  [_script release];
  [super dealloc];
}

- (NSMutableDictionary *)propertyList {
  id plist = [super propertyList];
  id data = nil;
  if ([self scriptAlias] != nil) {
    data = [[self scriptAlias] data];
    [plist setObject:SKBool(YES) forKey:kASActionScriptFileKey];
  }
   else if ([self script] != nil) {
    data = [[[self script] source] dataUsingEncoding:NSUTF8StringEncoding];
    [plist setObject:SKBool(NO) forKey:kASActionScriptFileKey];
  }
  [plist setObject:data forKey:kASActionScriptDataKey];
  return plist;
}

- (SparkAlert *)execute {
  id error = nil;
  id alert = nil;
  if ([self script] != nil) {
    [[self script] executeAndReturnError:&error];
  } else if ([self scriptFile] != nil) {
    id scriptUrl = [NSURL fileURLWithPath:[self scriptFile]];
    id script = [[NSAppleScript alloc] initWithContentsOfURL:scriptUrl
                                                       error:nil];
    [self setScript:script];
    [[self script] executeAndReturnError:&error];
    [script release]; // !!!:fox:20040306 => Fix memory leak. (v1.0)
  }
  switch ([[error objectForKey:@"NSAppleScriptErrorNumber"] intValue]) {
    case 0:
    case -128: //=> User Cancel
      return nil;
    default:
      alert = [SparkAlert alertWithMessageText:[NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"ACTION_EXECUTION_ERROR_ALERT", nil,
                                                                                                             AppleScriptActionBundle,
                                                                                                             @"Script Execution error in Action * Title *"), [self name]]
                     informativeTextWithFormat:NSLocalizedStringFromTableInBundle(@"ACTION_EXECUTION_ERROR_ALERT_MSG", nil,
                                                                                  AppleScriptActionBundle,
                                                                                  @"Script Execution error in Action * Msg *"), [error objectForKey:@"NSAppleScriptErrorMessage"]];
      [alert setHideSparkButton:YES];
  }
  return alert;
}

- (SKAlias *)scriptAlias {
  return _scriptAlias;
}

- (void)setScriptAlias:(SKAlias *)newScriptAlias {
  if (_scriptAlias != newScriptAlias) {
    [_scriptAlias release];
    _scriptAlias = [newScriptAlias retain];
  }
}


- (NSAppleScript *)script {
  return [[_script retain] autorelease];
}

- (void)setScript:(NSAppleScript *)newScript {
  if (_script != newScript) {
    [_script release];
    _script = [newScript retain];
  }
}

- (NSString *)scriptFile {
  return [[self scriptAlias] path];
}

- (void)setScriptFile:(NSString *)newScriptFile {
  if (newScriptFile != nil) {
    SKAlias *alias = [[SKAlias alloc] initWithPath:newScriptFile];
    [self setScriptAlias:alias];
    [alias release];
  }
  else {
    [self setScriptAlias:nil];
  }
}


@end
