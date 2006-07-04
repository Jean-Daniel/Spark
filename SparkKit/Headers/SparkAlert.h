/*
 *  SparkAlert.h
 *  SparkKit
 *
 *  Created by Fox on Wed Mar 17 2004.
 *  Copyright (c) 2004 Shadow Lab. All rights reserved.
 *
 */
/*!
    @header SparkAlert
    @abstract SparkAlert Declaration
*/
#import <Foundation/Foundation.h>

/*!
    @class SparkAlert
    @abstract A simple Alert class use to wrap alerts dialog. 
 	Usefull to display many errors in one windows (SparkMultipleAlerts) or to defere alert window creation.
*/
@interface SparkAlert : NSObject {
@private
  BOOL sp_hide;
  NSString *sp_message;
  NSString *sp_informative;
}

/*!
    @method     alertWithMessageText:informativeTextWithFormat:
    @abstract   (description)
    @param      message (description)
    @param      format,... (description)
    @result     (description)
*/
+ (id)alertWithMessageText:(NSString *)message informativeTextWithFormat:(NSString *)format,...;


+ (id)alertWithMessageText:(NSString *)message informativeTextWithFormat:(NSString *)format args:(va_list)args;

/*!
    @method     messageText
    @abstract   Returns the message for this alert.
*/
- (NSString *)messageText;
/*!
    @method     setMessageText:
    @abstract   Sets the message for this alert.
    @param      newMessageText The message displayed to user.
*/
- (void)setMessageText:(NSString *)newMessageText;

/*!
    @method     informativeText
    @abstract   Returns informative text for this alert.
*/
- (NSString *)informativeText;
/*!
    @method     setInformativeText:
    @abstract   Sets informative text for this alert.
    @param      newInformativeText The informative text.
*/
- (void)setInformativeText:(NSString *)newInformativeText;


/*!
    @method     hideSparkButton
    @abstract   When a SparkAlert is displayed, you can display or hide the alternate Button that is used to launch Spark.
    @result     Returns the current state.
*/
- (BOOL)hideSparkButton;
/*!
    @method     setHideSparkButton:
    @abstract   Default is YES if Spark isn't the current application, NO otherwise.
    @param      flag YES to hide the "Launch Spark" button, NO to display it.
*/
- (void)setHideSparkButton:(BOOL)flag;

@end
