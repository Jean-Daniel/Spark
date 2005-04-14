//
//  ShellHotKey.h
//  Spark PlugIns
//
//  Created by Fox on Sat Apr 03 2004.
//  Copyright (c) 2004 Shadow Lab. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <SparkKit/SparkKit_PlugIn.h>

@class SKAlias;
@interface ShellHotKey : SparkHotKey {
  int shell;
  int workingDir;
  
  NSString *cmd;
  NSDictionary *env;
  NSString *workingDirPath;
  SKAlias *scriptFile;
  NSString *args;
  BOOL displayDialog;
  BOOL executeInTerm;
}

- (NSString *)argsStringForString:(NSString *)str;

- (int)shell;
- (void)setShell:(int)newShell;
- (int)workingDir;
- (void)setWorkingDir:(int)newWorkingDir;
- (NSString *)cmd;
- (void)setCmd:(NSString *)newCmd;
- (NSDictionary *)env;
- (void)setEnv:(NSDictionary *)newEnv;
- (NSString *)workingDirPath;
- (void)setWorkingDirPath:(NSString *)newWorkingDirPath;
- (NSString *)scriptFile;
- (void)setScriptFile:(NSString *)newFile;
- (NSString *)args;
- (void)setArgs:(NSString *)newArgs;
- (BOOL)displayDialog;
- (void)setDisplayDialog:(BOOL)newDisplayDialog;
- (BOOL)executeInTerm;
- (void)setExecuteInTerm:(BOOL)newExecuteInTerm;

- (void)setScriptAlias:(SKAlias *)alias;
@end
