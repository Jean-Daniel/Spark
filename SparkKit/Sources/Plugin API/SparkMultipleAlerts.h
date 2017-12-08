/*
 *  SparkMultipleAlerts.h
 *  SparkKit
 *
 *  Created by Black Moon Team.
 *  Copyright (c) 2004 - 2007 Shadow Lab. All rights reserved.
 */

#import <SparkKit/SparkDefine.h>

NS_ASSUME_NONNULL_BEGIN

SPARK_OBJC_EXPORT
@interface SparkMultipleAlerts : NSWindowController

- (instancetype)init;

- (instancetype)initWithAlert:(SparkAlert *)alert;
- (instancetype)initWithAlerts:(NSArray *)alerts;

- (IBAction)close:(nullable id)sender;

- (NSArray *)alerts;

- (NSUInteger)alertCount;

- (void)addAlert:(SparkAlert *)alert;
- (void)addAlerts:(NSArray *)alerts;
- (void)addAlertWithMessageText:(NSString *)message informativeTextWithFormat:(NSString *)format,...;

- (void)insertAlert:(SparkAlert *)alert atIndex:(NSUInteger)index;

- (void)removeAlert:(SparkAlert *)alert;
- (void)removeAlertAtIndex:(NSUInteger)index;
- (void)removeAlerts:(NSArray *)alerts;
- (void)removeAllAlerts;

- (void)showAlerts;
- (void)beginSheetModalForWindow:(NSWindow *)sheetWindow completionHandler:(void (^ __nullable)(NSModalResponse returnCode))handler;

@end

NS_ASSUME_NONNULL_END
