//
//  AppleScriptAction.m
//  Spark
//
//  Created by Fox on Fri Feb 20 2004.
//  Copyright (c) 2004 Shadow Lab. All rights reserved.
//

#import "AppleScriptAction.h"
#import "AppleScriptActionPlugin.h"

static NSString * const kASActionScriptDataKey = @"Script Data";
static NSString * const kASActionScriptFileKey = @"Script File";

NSString * const kASActionBundleIdentifier = @"org.shadowlab.spark.applescript";

@implementation AppleScriptAction

#pragma mark Protocols Implementation
- (id)copyWithZone:(NSZone *)zone {
  AppleScriptAction* copy = [super copyWithZone:zone];
  copy->as_script = [as_script copy];
  copy->as_alias = [as_alias copy];
  return copy;
}

- (void)encodeWithCoder:(NSCoder *)coder {
  [super encodeWithCoder:coder];
  if (as_script) 
    [coder encodeObject:[as_script source] forKey:kASActionScriptDataKey];
  if (as_alias)
    [coder encodeObject:as_alias forKey:kASActionScriptFileKey];
}

- (id)initWithCoder:(NSCoder *)coder {
  if (self = [super initWithCoder:coder]) {
    NSString *src = [coder decodeObjectForKey:kASActionScriptDataKey];
    if (nil != src)
      as_script = [[NSAppleScript alloc] initWithSource:src];
    as_alias = [[coder decodeObjectForKey:kASActionScriptFileKey] retain];
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
  [as_alias release];
  [as_script release];
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

- (SparkAlert *)performAction {
  id error = nil;
  id alert = nil;
  if ([self script] != nil) {
    [[self script] executeAndReturnError:&error];
  } else if ([self file] != nil) {
    id scriptUrl = [NSURL fileURLWithPath:[self file]];
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
  return as_alias;
}
- (void)setScriptAlias:(SKAlias *)anAlias {
  SKSetterRetain(as_alias, anAlias);
}

- (id)script {
  return as_script;
}
- (void)setScript:(id)aScript {
  SKSetterRetain(as_script, aScript);
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

@end

NSString *AppleScriptActionDescription(AppleScriptAction *anAction) {
  if ([anAction script]) {
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

