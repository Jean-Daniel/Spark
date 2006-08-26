/*
 *  SparkActionPlugIn.h
 *  SparkKit
 *
 *  Created by Black Moon Team.
 *  Copyright (c) 2004 - 2006 Shadow Lab. All rights reserved.
 *
 */

#import <SparkKit/SparkKit.h>

/*!
@function	SparkDisplayAlerts
 @abstract Display alert dialog.
	@discussion Can be use in during a key execution to display an alert message. As Spark Daemon is 
 a background application, you cannot use NSAlert and other graphics objects.
 @param alerts An Array of <code>SparkAlert</code>.
 */
SPARK_EXPORT
void SparkDisplayAlerts(NSArray *alerts);
#define SparkDisplayAlert(alert)		SparkDisplayAlerts([NSArray arrayWithObject:alert])

/*!
@class SparkActionPlugIn
@abstract This class is the base class to do a Spark PlugIn. If you want to add some kind of Action to Spark, 
you will use a subclass of SparkActionPlugIn.
@discussion This is an Abstract class, so it can't be instanciated. Some methode must be implemented by subclass.
If you use this class in IB, you can define an Outlet with name actionView.
*/
@class SparkAction;
@interface SparkActionPlugIn : NSObject {  
  @private
  NSView *sp_view;
  SparkAction *sp_action;
  
  struct _sp_sapFlags {
    unsigned int ownership:1;
    unsigned int reserved:31;
  } sp_sapFlags;
  
  /*Keep binary compatibility */
  void *sp_reserved;
  void *sp_reserved2;
}

/*!
@method
 @abstract This methode is call when an action editor is opened. The base implementation try to
 open the Main Nib File of the bundle and return the view attache to the <i>actionView</i> IBOutlet.
 @discussion You normally don't override this method. Just set the main nib File in the plist Bundle.
 Set the owner of this nib file on this class, and set <code>actionView</code> IBOutlet on the customView you want to use.
 @result The <code>NSView</code> that will be diplay in the Spark Action Editor.
 */
- (NSView *)actionView;

  /*!
	@method
   @param anAction
   @param isEditing YES if editing <code>anAction</code>, NO if <code>anAction</code> is a new instance.
   @abstract The default implementation do nothing.
   @discussion Methode called when an plugin action editor is loaded.<br />
   You can use this method to bind <i>action</i> value into your configuration view.
   */
- (void)loadSparkAction:(SparkAction *)anAction toEdit:(BOOL)isEditing;


  /*!
	@method
   @abstract Default implementation just returns nil.
   @discussion Methode call just before the editor will close and create or update an Action.
   You should verify infos needed to create action and if infos are missing or
   are not valid, you can return an NSAlert that will be displayed.
   @result An alert you want display to the user or nil if all fields are OK.
   */
- (NSAlert *)sparkEditorShouldConfigureAction;

  /*!
	@method
   @abstract Default implementation just returns nil.
   @discussion <strong>Required!</strong> This methode must configure the Action.
   <code>configureAction</code> is called when user want to create an Action. In this methode you must 
   set all require parameters of your Action (including name, icon, and description).
   Spark call <code>-configureAction</code> only if <code>-sparkEditorShouldConfigureAction</code> returned nil. 
   */
- (void)configureAction;

  /*!
  @method
   @abstract Returns the action currently edited by the receiver.
   */
- (id)sparkAction;

#pragma mark -
#pragma mark Convenient Accessors
  /*!
  @method
   @abstract Returns the receiver <i>sparkAction</i> name.
   */
- (NSString *)name;
  /*!
  @method
   @abstract Set the receiver <i>sparkAction</i> name.
   @param name The new name.
   */
- (void)setName:(NSString *)name;

  /*!
  @method
   @abstract Returns the receiver <i>sparkAction</i> icon.
   */
- (NSImage *)icon;
  /*!
  @method
   @abstract Sets the receiver <i>sparkAction</i> icon.
   @param icon The new icon or nil if you want to use default action icon.
   */
- (void)setIcon:(NSImage *)icon;

@end
