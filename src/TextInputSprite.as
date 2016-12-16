package{
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.DisplayObject;
	import flash.filters.DropShadowFilter;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.text.TextField;
	import flash.text.TextFormat;
	
	import mx.core.UIComponent;
	
	public class TextInputSprite extends UIComponent{
		private var _text:String;
		private var _textField:TextField;
		private var _textFormat:TextFormat;
		private var _bmp:Bitmap;
		private var _bmpData:BitmapData;

 		[Bindable]   
    	[Embed("bb2digits/-.png")]   
    	private var minus_png:Class;
    	private var minus_bmp:Bitmap = new minus_png(); 
  	
  		[Bindable]   
    	[Embed("bb2digits/=.png")]   
    	private var equal_png:Class;   
   		private var equal_bmp:Bitmap = new equal_png();
   
   		[Bindable]   
    	[Embed("bb2digits/0.png")]   
    	private var zero_png:Class;
   		private var zero_bmp:Bitmap = new zero_png();
    
  		[Bindable]   
    	[Embed("bb2digits/1.png")]   
    	private var one_png:Class;   
   		private var one_bmp:Bitmap = new one_png();
   		     
    	[Bindable]   
	   	[Embed("bb2digits/2.png")]   
    	private var two_png:Class;
   		private var two_bmp:Bitmap = new two_png();
   				
		[Bindable]   
	   	[Embed("bb2digits/3.png")]   
    	private var three_png:Class;
   		private var three_bmp:Bitmap = new three_png();
   		
		[Bindable]   
	   	[Embed("bb2digits/4.png")]   
    	private var four_png:Class;
   		private var four_bmp:Bitmap = new four_png();    	

		[Bindable]   
	   	[Embed("bb2digits/5.png")]   
    	private var five_png:Class;
   		private var five_bmp:Bitmap = new five_png();
   		    
		[Bindable]   
	   	[Embed("bb2digits/6.png")]   
    	private var six_png:Class;
		private var six_bmp:Bitmap = new six_png();

		[Bindable]   
	   	[Embed("bb2digits/7.png")]   
    	private var seven_png:Class;
		private var seven_bmp:Bitmap = new seven_png();

		[Bindable]   
	   	[Embed("bb2digits/8.png")]   
    	private var eight_png:Class;
		private var eight_bmp:Bitmap = new eight_png();

		[Bindable]   
	   	[Embed("bb2digits/9.png")]   
    	private var nine_png:Class;
		private var nine_bmp:Bitmap = new nine_png();
		
		[Bindable]   
		[Embed("bb2digits/a.png")]   
		private var a_png:Class;
		private var a_bmp:Bitmap = new a_png();
		
		[Bindable]   
	   	[Embed("bb2digits/c.png")]   
    	private var c_png:Class;
		private var c_bmp:Bitmap = new c_png();
    	
		[Bindable]   
	   	[Embed("bb2digits/d.png")]   
    	private var d_png:Class;
 		private var d_bmp:Bitmap = new d_png();
    	
		[Bindable]   
	   	[Embed("bb2digits/e.png")]   
    	private var e_png:Class;
 		private var e_bmp:Bitmap = new e_png();
    	
		[Bindable]   
	   	[Embed("bb2digits/f.png")]   
    	private var f_png:Class;
 		private var f_bmp:Bitmap = new f_png();

		[Bindable]   
		[Embed("bb2digits/g.png")]   
		private var g_png:Class;
		private var g_bmp:Bitmap = new g_png();
		
		[Bindable]   
		[Embed("bb2digits/h.png")]   
		private var h_png:Class;
		private var h_bmp:Bitmap = new h_png();
		
		[Bindable]   
		[Embed("bb2digits/i.png")]   
		private var i_png:Class;
		private var i_bmp:Bitmap = new i_png();
				
		[Bindable]   
		[Embed("bb2digits/l.png")]   
		private var l_png:Class;
		private var l_bmp:Bitmap = new l_png();
		
		[Bindable]   
	   	[Embed("bb2digits/n.png")]   
    	private var n_png:Class;
 		private var n_bmp:Bitmap = new n_png();
		
		[Bindable]   
		[Embed("bb2digits/o.png")]   
		private var o_png:Class;
		private var o_bmp:Bitmap = new o_png();
		
		[Bindable]   
		[Embed("bb2digits/p.png")]   
		private var p_png:Class;
		private var p_bmp:Bitmap = new p_png();
		
		[Bindable]   
		[Embed("bb2digits/q.png")]   
		private var q_png:Class;
		private var q_bmp:Bitmap = new q_png();
		
		[Bindable]   
		[Embed("bb2digits/s.png")]   
		private var s_png:Class;
		private var s_bmp:Bitmap = new s_png();
		
		[Bindable]   
		[Embed("bb2digits/v.png")]   
		private var v_png:Class;
		private var v_bmp:Bitmap = new v_png();
		
		[Bindable]   
	   	[Embed("bb2digits/space.png")]   
    	private var space_png:Class;
 		private var space_bmp:Bitmap = new space_png();

		private var _bitmapData:BitmapData;
		private var _bitmap:Bitmap;

        public function TextInputSprite():void{
        	super(); 
			
			//描画領域の作成		
			_bitmapData = new BitmapData(125,40,true,0x000000);	
			_bitmap = new Bitmap(_bitmapData);
			this.addChild(DisplayObject(_bitmap));
        }
        
        private function disp_val(value:*):String{
			if(value is String){
				var value_str:String = value as String;
				while(value_str.length < 5){
					value_str = value_str+" ";
				}
			}else{
				var num:int = value as int;
				if(num != 0){
					if(num < 0){
						num = 0 - num;
					}
					value_str = num.toString() + "00";
				}else{
					value_str = "00";
				}
				
				while(value_str.length < 5){
					value_str = " " + value_str;
				}
			}
			return value_str;
		}		
        
	    public function get text():String
	    {
	        return _text;
	    }
	    
	    private function display_str(str:String):void{
	    	
	    	var rectangle:Rectangle = new Rectangle(0,0,25,40);
			var point:Point = new Point();
			point.y = 0;
					
			for(var i:int=0; i<str.length; i++){
				point.x = i*25;
				var char:String = str.charAt(i).toLowerCase();
				switch(char){
					case "-":
						_bitmapData.copyPixels(minus_bmp.bitmapData,rectangle,point);
					break;
					
					case "=":
						_bitmapData.copyPixels(equal_bmp.bitmapData,rectangle,point);
					break;
					
					case "0":
						_bitmapData.copyPixels(zero_bmp.bitmapData,rectangle,point);
					break;
						
					case "1":
						_bitmapData.copyPixels(one_bmp.bitmapData,rectangle,point);
					break;
					
					case "2":
						_bitmapData.copyPixels(two_bmp.bitmapData,rectangle,point);
					break;
					
					case "3":
						_bitmapData.copyPixels(three_bmp.bitmapData,rectangle,point);
					break;
					
					case "4":
						_bitmapData.copyPixels(four_bmp.bitmapData,rectangle,point);
					break;
					
					case "5":
						_bitmapData.copyPixels(five_bmp.bitmapData,rectangle,point);
					break;
					
					case "6":
						_bitmapData.copyPixels(six_bmp.bitmapData,rectangle,point);
					break;
					
					case "7":
						_bitmapData.copyPixels(seven_bmp.bitmapData,rectangle,point);
					break;
					
					case "8":
						_bitmapData.copyPixels(eight_bmp.bitmapData,rectangle,point);
					break;
					
					case "9":
						_bitmapData.copyPixels(nine_bmp.bitmapData,rectangle,point);
					break;
					
					case "a":
						_bitmapData.copyPixels(a_bmp.bitmapData,rectangle,point);
					break;
					
					case "c":
						_bitmapData.copyPixels(c_bmp.bitmapData,rectangle,point);
					break;
					
					case "d":
						_bitmapData.copyPixels(d_bmp.bitmapData,rectangle,point);
					break;
					
					case "e":
						_bitmapData.copyPixels(e_bmp.bitmapData,rectangle,point);
					break;
					
					case "f":
						_bitmapData.copyPixels(f_bmp.bitmapData,rectangle,point);
					break;
					
					case "g":
						_bitmapData.copyPixels(g_bmp.bitmapData,rectangle,point);
					break;
					
					case "h":
						_bitmapData.copyPixels(h_bmp.bitmapData,rectangle,point);
					break;
					
					case "i":
						_bitmapData.copyPixels(i_bmp.bitmapData,rectangle,point);
					break;

					case "l":
						_bitmapData.copyPixels(l_bmp.bitmapData,rectangle,point);
					break;
					
					case "n":
						_bitmapData.copyPixels(n_bmp.bitmapData,rectangle,point);
					break;

					case "o":
						_bitmapData.copyPixels(o_bmp.bitmapData,rectangle,point);
					break;
					
					case "p":
						_bitmapData.copyPixels(p_bmp.bitmapData,rectangle,point);
					break;
					
					case "q":
						_bitmapData.copyPixels(q_bmp.bitmapData,rectangle,point);
					break;
					
					case "s":
						_bitmapData.copyPixels(s_bmp.bitmapData,rectangle,point);
					break;
					
					case "v":
						_bitmapData.copyPixels(v_bmp.bitmapData,rectangle,point);
					break;
					
					case " ":
						_bitmapData.copyPixels(space_bmp.bitmapData,rectangle,point);
					break;
					
				}
			}
	    }

		public function get pp_text():String{
			return _text;
		}

		public function set pp_text(value:*):void{
			
			if(value < 10){
				var str:String = "  "+value.toString();
			}else{
				str = " "+value.toString();
			}
			str = disp_val(str);
			display_str(str);
			_text = str;
		}

		public function get mp_text():String{
			return _text;
		}

		public function set mp_text(value:*):void{
			this.pp_text = value;
		}
		
		//stdf:STかDFの場合は19900以上を19900と表示する
		public function set text(value:*):void{
	
			var str:String = disp_val(value);
			display_str(str);
			_text = str;
			
			
		}
		
		
		
	}
	
}