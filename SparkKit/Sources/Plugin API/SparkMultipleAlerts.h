/*
 *  SparkMultipleAlerts.h
 *  SparkKit
 *
 *  Created by Black Moon Team.
 *  Copyright (c) 2004 - 2007 Shadow Lab. All rights reserved.
 */

#import <SparkKit/SparkKit.h>

SPARK_OBJC_EXPORT
@interface SparkMultipleAlerts : NSObject {
  IBOutlet NSButton *nextButton;
  IBOutlet NSButton *previousButton;
  IBOutlet NSButton *openSparkButton;
  
  IBOutlet NSTextField *counter;
  IBOutlet NSWindow *alertWindow;
  IBOutlet NSTextView *messageText;
  IBOutlet NSTextView *informativeText;
@private
  NSNib *sp_nib;
  BOOL sp_retain;
  NSUInteger sp_index;
	NSMutableArray *sp_alerts;
}

- (id)initWithAlert:(SparkAlert *)alert;
- (id)initWithAlerts:(NSArray *)alerts;

- (IBAction)close:(id)sender;

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
- (void)beginSheetModalForWindow:(NSWindow *)window modalDelegate:(id)delegate didEndSelector:(SEL)didEndSelector contextInfo:(void *)contextInfo;

@end
