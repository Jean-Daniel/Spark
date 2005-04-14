//
//  SparkMultipleAlerts.h
//  Labo Test
//
//  Created by Fox on Sun Jul 25 2004.
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface SparkMultipleAlerts : NSObject {
  IBOutlet NSButton *previousButton;
  IBOutlet NSButton *nextButton;
  IBOutlet NSButton *openSparkButton;
  
  IBOutlet NSTextField *counter;
  
  IBOutlet NSTextView *messageText;
  IBOutlet NSTextView *informativeText;
  
  IBOutlet NSWindow *alertWindow; 
  
@private
  id _alerts;
  id _nibFile;
  BOOL _selfRetain;
  unsigned selectedIndex;
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
