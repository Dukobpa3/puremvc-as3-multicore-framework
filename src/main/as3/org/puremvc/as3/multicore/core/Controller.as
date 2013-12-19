/*
 PureMVC MultiCore - Copyright(c) 2006-08 Futurescale, Inc., Some rights reserved.
 Your reuse is governed by the Creative Commons Attribution 3.0 United States License
*/
package org.puremvc.as3.multicore.core
{
	import org.puremvc.as3.multicore.interfaces.*;
	import org.puremvc.as3.multicore.patterns.observer.*;
	
	/**
	 * A Multiton <code>IController</code> implementation.
	 * 
	 * <P/>
	 * In PureMVC, the <code>Controller</code> class follows the
	 * 'Command and Controller' strategy, and assumes these 
	 * responsibilities:
	 * <UL>
	 * <LI> Remembering which <code>ICommand</code>s 
	 * are intended to handle which <code>INotifications</code>.</LI>
	 * <LI> Registering itself as an <code>IObserver</code> with
	 * the <code>View</code> for each <code>INotification</code> 
	 * that it has an <code>ICommand</code> mapping for.</LI>
	 * <LI> Creating a new instance of the proper <code>ICommand</code>
	 * to handle a given <code>INotification</code> when notified by the <code>View</code>.</LI>
	 * <LI> Calling the <code>ICommand</code>'s <code>execute</code>
	 * method, passing in the <code>INotification</code>.</LI> 
	 * </UL>
	 * 
	 * <P/>
	 * Your application must register <code>ICommands</code> with the 
	 * Controller.
	 *
	 * <P/>
 	 * The simplest way is to subclass <code>Facade</code>,
	 * and use its <code>initializeController</code> method to add your 
	 * registrations.
	 * 
	 * @see org.puremvc.as3.multicore.core.View View
	 * @see org.puremvc.as3.multicore.patterns.observer.Observer Observer
	 * @see org.puremvc.as3.multicore.patterns.observer.Notification Notification
	 * @see org.puremvc.as3.multicore.patterns.command.SimpleCommand SimpleCommand
	 * @see org.puremvc.as3.multicore.patterns.command.MacroCommand MacroCommand
	 */
	public class Controller implements IController
	{
		
		/**
		 * Constructor. 
		 * 
		 * <P>
		 * This <code>IController</code> implementation is a Multiton, 
		 * so you should not call the constructor 
		 * directly, but instead call the static Factory method, 
		 * passing the unique key for this instance 
		 * <code>Controller.getInstance( multitonKey )</code></P>
		 * 
		 * @throws Error Error if instance for this Multiton key has already been constructed
		 * 
		 */
		public function Controller( key:String )
		{
			if (instanceMap[ key ] != null) throw Error(MULTITON_MSG);
			multitonKey = key;
			instanceMap[ multitonKey ] = this;
			commandMap = new Array();	
			initializeController();	
		}
		
		/**
		 * Initialize the Multiton <code>Controller</code> instance.
		 * 
		 * <P>Called automatically by the constructor.</P> 
		 * 
		 * <P>Note that if you are using a subclass of <code>View</code>
		 * in your application, you should <i>also</i> subclass <code>Controller</code>
		 * and override the <code>initializeController</code> method in the 
		 * following way:</P>
		 * 
		 * <listing>
		 *		// ensure that the Controller is talking to my IView implementation
		 *		override public function initializeController(  ) : void 
		 *		{
		 *			view = MyView.getInstance();
		 *		}
		 * </listing>
		 * 
		 * @return void
		 */
		protected function initializeController(  ) : void 
		{
			view = View.getInstance( multitonKey );
		}
	
		/**
		 * <code>Controller</code> Multiton Factory method.
		 * 
		 * @return the Multiton instance of <code>Controller</code>
		 */
		public static function getInstance( key:String ) : IController
		{
			if ( instanceMap[ key ] == null ) instanceMap[ key ] = new Controller( key );
			return instanceMap[ key ];
		}

		/**
		 * If an <code>ICommand</code> has previously been registered 
		 * to handle a the given <code>INotification</code>, then it is executed.
		 * 
		 * @param note an <code>INotification</code>
		 */
		public function executeCommand( note : INotification ) : void
		{
			var commandClassRef : Class = commandMap[ note.getName() ];
			if ( commandClassRef == null ) return;

			var commandInstance : ICommand = new commandClassRef();
			commandInstance.initializeNotifier( multitonKey );
			commandInstance.execute( note );
		}

		/**
		 * Register a particular <code>ICommand</code> class as the handler 
		 * for a particular <code>INotification</code>.
		 * 
		 * <P>
		 * If an <code>ICommand</code> has already been registered to 
		 * handle <code>INotification</code>s with this name, it is no longer
		 * used, the new <code>ICommand</code> is used instead.</P>
		 * 
		 * The Observer for the new ICommand is only created if this the 
		 * first time an ICommand has been regisered for this Notification name.
		 * 
		 * @param notificationName the name of the <code>INotification</code>
		 * @param commandClassRef the <code>Class</code> of the <code>ICommand</code>
		 */
		public function registerCommand( notificationName : String, commandClassRef : Class ) : void
		{
			if ( commandMap[ notificationName ] == null ) {
				view.registerObserver( notificationName, new Observer( executeCommand, this ) );
			}
			commandMap[ notificationName ] = commandClassRef;
		}
		
		/**
		 * Check if a Command is registered for a given Notification 
		 * 
		 * @param notificationName
		 * @return whether a Command is currently registered for the given <code>notificationName</code>.
		 */
		public function hasCommand( notificationName:String ) : Boolean
		{
			return commandMap[ notificationName ] != null;
		}

		/**
		 * Remove a previously registered <code>ICommand</code> to <code>INotification</code> mapping.
		 * 
		 * @param notificationName the name of the <code>INotification</code> to remove the <code>ICommand</code> mapping for
		 */
		public function removeCommand( notificationName : String ) : void
		{
			// if the Command is registered...
			if ( hasCommand( notificationName ) )
			{
				// remove the observer
				view.removeObserver( notificationName, this );
							
				// remove the command
				commandMap[ notificationName ] = null;
			}
		}
		
		/**
		 * Remove an IController instance
		 * 
		 * @param key of IController instance to remove
		 */
		public static function removeController( key:String ):void
		{
			delete instanceMap[ key ];
		}

		// Local reference to View 
		protected var view : IView;
		
		// Mapping of Notification names to Command Class references
		protected var commandMap : Array;

		// The Multiton Key for this Core
		protected var multitonKey : String;

		// Singleton instance
		protected static var instanceMap : Array = new Array();

		// Message Constants
		protected const MULTITON_MSG : String = "Controller instance for this Multiton key already constructed!";

	}
}