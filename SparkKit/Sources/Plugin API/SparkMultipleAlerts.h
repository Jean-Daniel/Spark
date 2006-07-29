/*
 *  SparkMultipleAlerts.h
 *  SparkKit
 *
 *  Created by Black Moon Team.
 *  Copyright © 2004 - 2006 Shadow Lab. All rights reserved.
 *
 */

#import <SparkKit/SparkKit.h>

@interface SparkMultipleAlerts : NSObject {
  IBOutlet NSButton *nextButton;
  IBOutlet NSButton *previousButton;
  IBOutlet NSButton *openSparkButton;
  
  IBOutlet NSTextField *counter;
  IBOutlet NSWindow *alertWindow;
  IBOutlet NSTextView *messageText;
  IBOutlet NSTextView *informativeText;
@private
  id sp_alerts;
  NSNib *sp_nib;
  BOOL sp_retain;
  unsigned sp_index;
}

- (id)initWithAlert:(SparkAlert *)alert;
- (id)initWithAlerts:(NSArray *)alerts;

- (IBAction)close:(id)sender;

- (NSArray *)alerts;

- (int)alertCount;

- (void)addAlert:(SparkAlert *)alert;
- (void)addAlerts:(NSArray *)alerts;
- (void)addAlertWithMessageText:(NSString *)message informativeTextWithFormat:(NSString *)format,...;

- (void)insertAlert:(SparkAlert *)alert atIndex:(int)index;

- (void)removeAlert:(SparkAlert *)alert;
- (void)removeAlertAtIndex:(int)index;
- (void)removeAlerts:(NSArray *)alerts;
- (void)removeAllAlerts;

- (void)showAlerts;
- (void)beginSheetModalForWindow:(NSWindow *)window modalDelegate:(id)delegate didEndSelector:(SEL)didEndSelector contextInfo:(void *)contextInfo;

@end
