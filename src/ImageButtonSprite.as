package{
	import flash.events.MouseEvent;
	import flash.utils.Dictionary;
	
	import mx.controls.Image;

	public class ImageButtonSprite extends Image{
		
		private var _enabled:Boolean = true;
		public var change_disabled:Boolean = false;
		
		public function ImageButtonSprite():void{
			if(!change_disabled){
				this.addEventListener(MouseEvent.MOUSE_DOWN, mouse_down);
			}
		}
		
		public function mouse_down(event:MouseEvent):void{
			this.removeEventListener(MouseEvent.MOUSE_DOWN,mouse_down);
			change_selected();
			stage.addEventListener(MouseEvent.MOUSE_UP,mouse_up);
		}
		
		public function mouse_up(event:MouseEvent):void{
			stage.removeEventListener(MouseEvent.MOUSE_UP,mouse_up);
			change_selected();
			this.addEventListener(MouseEvent.MOUSE_DOWN,mouse_down);
		}
		
		public function change_selected():void{
			if(!change_disabled){
				this.selected = !this.selected;
			}
		}
		
		public function get selected():Boolean{
			return _enabled;
		}
		
		public function set selected(value:Boolean):void{
			_enabled = value;
			if(!_enabled){
				this.alpha = 0.0;
			}else{
				this.alpha = 1.0;
			}
		}
		
		/*protected var listeners :Dictionary    = new Dictionary();
		override public function addEventListener( type : String, listener : Function, useCapture : Boolean = false, priority : int = 0, useWeakReference : Boolean = true) : void
		{
			var key : Object = {type:type,useCapture:useCapture};
			if( listeners[ key ] ) {
				removeEventListener( type, listeners[ key ], useCapture );
				listeners[ key ] = null;
			}
			listeners[ key ] = listener;
			
			super.addEventListener( type, listener, useCapture, priority, useWeakReference );
		}
		public function removeListeners () : void
		{
			try
			{
				for (var key:Object in listeners) {
					removeEventListener( key.type, listeners[ key ], key.useCapture );
					listeners[ key ] = null;
				}
			}catch(e:Error){}
		}*/
		
	}
	
	
	
	
}