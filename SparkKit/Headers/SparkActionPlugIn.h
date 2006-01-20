/*
 *  SparkActionPlugin.h
 *  Short-Cut
 *
 *  Created by Fox on Mon Dec 08 2003.
 *  Copyright (c) 2004 Shadow Lab. All rights reserved.
 *
 */

#import <SparkKit/SparkKitBase.h>

/*!
	@function	SparkDisplayAlerts
 	@abstract   Display alert dialog.
	@discussion Can be use in during a key execution to display an alert message. As Spark Daemon is 
 				a background application, you cannot use NSAlert and other graphics objects.
 	@param      alerts An Array of <code>SparkAlert</code>.
*/
SPARK_EXPORT
void SparkDisplayAlerts(NSArray *alerts);
#define SparkDisplayAlert(alert)		SparkDisplayAlerts([NSArray arrayWithObject:alert])

/*!
    @class 		SparkActionPlugIn
    @abstract   This class is the base class to do a Spark PlugIn. If you want to add some kind of Action to Spark, 
 				you will use a subclass of SparkActionPlugIn.
 	@discussion This is an Abstract class, so it can't be instanciated. Some methode must be implemented by subclass.
 				If you use this class in IB, you can define an Outlet with name actionView.
*/
@class SparkAction, SparkAlert;
@interface SparkActionPlugIn : NSObject {  
  @private
  NSView *_actionView;
  SparkAction *_action;
  NSUndoManager *_undo;
  NSString *_name;
  NSImage *_icon;
}

/*!
    @method     actionView
    @abstract   This methode is call when an action editor is opened. The base implementation try to
 				open the Main Nib File of the bundle and return	the view attache to the <i>actionView</i> IBOutlet.
    @discussion You normally don't override this method. Just set the main nib File in the plist Bundle.
 				Set the owner of this nib file on this class, and set <code>actionView</code> IBOutlet on the customView you want to use.
 	@result     The <code>NSView</code> that will be diplay in the Spark Action Editor.
*/
- (NSView *)actionView;

/*!
	@method     loadSparkAction:toEdit:
	@param		anAction
 	@param		isEditing YES if editing an Action, NO if loading a new Action.
	@abstract   The default implementation do nothing if <i>isEditing</i> is NO, else it record <i>action</i> name
 				and icon in the undo manager, so if user cancel, name and icon will be restored.
	@discussion Methode called when an plugin action editor is loaded.<br />
 				You can use this method to bind <i>action</i> value into your configuration view, and if user
 				is going to edit the <i>action</i>, you can also save <i>action</i> state to revert if user cancel.
*/
- (void)loadSparkAction:(SparkAction *)anAction toEdit:(BOOL)isEditing;


/*!
	@method     sparkEditorShouldConfigureAction:
	@abstract   Default implementation just returns nil.
	@discussion Methode call just before the editor will close and create or update an Action.
				You should verify infos needed to create action and if infos are missing or
				are not valid, you can return an NSAlert that will be displayed.
	@result     An alert you want display to the user or nil if all fields are OK.
*/
- (NSAlert *)sparkEditorShouldConfigureAction;

/*!
	@method     configureAction
	@abstract   Default implementation just returns nil.
	@discussion <strong>Required!</strong> This methode must configure the Action.
 				<code>configureAction</code> is called when user want to create an Action. In this methode you must 
 				set all require parameters of your Action (including name, icon, and description).
 				This method is not called when a user begin to edit a Action and then clic on the "Cancel" button.
*/
- (void)configureAction;

/*!
    @method     revertEditing
    @abstract   Method call when user is editing an action and push cancel button.
 	@discussion You can use this method to revert Action state. You can also used the Undo manager.
*/
- (void)revertEditing;

/*!
   @method     sparkAction
   @abstract   Returns the Action currently edited by the receiver.  
*/
- (id)sparkAction;

#pragma mark -
#pragma mark Accessor Methods
/*!
    @method     name
    @abstract   Return the receiver <i>sparkAction</i> name.
*/
- (NSString *)name;
/*!
    @method     setName:
    @abstract   Set the receiver <i>sparkAction</i> name.
    @param      name The name of this Action.
*/
- (void)setName:(NSString *)name;
/*!
    @method     icon
    @abstract   Returns the receiver <i>sparkAction</i> icon.
*/
- (NSImage *)icon;
/*!
    @method     setIcon:
    @abstract   Sets the receiver <i>sparkAction</i> icon.
    @param      icon The icon to set or nil if you want to use default Action icon.
*/
- (void)setIcon:(NSImage *)icon;

/*!
    @method     undoManager
    @abstract   Return the undo manager used for this action edition.
 	@discussion If this plugin is loaded to create an Action, this method returns nil.
 				When editing an Action, you can obtains an Undo manager. Spark automatically <i>-undo</i> 
 				all registred operation if user cancel edition, so you normaly don't need call -undo directly.
 */
- (NSUndoManager *)undoManager;

@end
