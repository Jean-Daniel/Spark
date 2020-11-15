/*
 *  SparkServerProtocol.h
 *  SparkKit
 *
 *  Created by Black Moon Team.
 *  Copyright (c) 2004 - 2007 Shadow Lab. All rights reserved.
 */

#if !defined(__SPARK_SERVER_PROTOCOL_H)
#define __SPARK_SERVER_PROTOCOL_H 1

#if defined(__OBJC__)

#import <SparkKit/SparkDefine.h>

@protocol SparkLibrary;

@protocol SparkEditor
- (void)setLibrary:(id<SparkLibrary>)library uuid:(NSUUID *)uuid;
- (void)setDaemonEnabled:(BOOL)isEnabled;
@end

@protocol SparkAgent
- (void)register:(id<SparkEditor>)editor;
@end

SPARK_EXPORT
NSXPCInterface *SparkAgentInterface(void);

SPARK_EXPORT
NSXPCInterface *SparkEditorInterface(void);

#endif /* __OBJC__ */

#endif /* __SPARK_SERVER_PROTOCOL_H */
