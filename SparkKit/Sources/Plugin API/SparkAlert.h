/*
 *  SparkAlert.h
 *  SparkKit
 *
 *  Created by Black Moon Team.
 *  Copyright (c) 2004 - 2007 Shadow Lab. All rights reserved.
 */
/*!
    @header SparkAlert
    @abstract SparkAlert Declaration
*/
#import <SparkKit/SparkKit.h>

/*!
 @abstract A simple Alert class use to wrap alerts dialog.
 Usefull to display many errors in one windows (SparkMultipleAlerts) or to defere alert window creation.
*/
SPARK_OBJC_EXPORT
@interface SparkAlert : NSObject {
@private
  BOOL sp_hide;
  NSString *sp_message;
  NSString *sp_informative;
}

+ (id)alertWithMessageText:(NSString *)message informativeTextWithFormat:(NSString *)format,...;

+ (id)alertWithMessageText:(NSString *)message informativeTextWithFormat:(NSString *)format args:(va_list)args;

/*!
 When a SparkAlert is displayed, you can display or hide the alternate Button that is used to launch Spark.
 */
@property(nonatomic) BOOL hideSparkButton;

@property(nonatomic, copy) NSString *messageText;
@property(nonatomic, copy) NSString *informativeText;

@end
