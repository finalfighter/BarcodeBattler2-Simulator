import com.google.zxing.BarcodeFormat;
import com.google.zxing.BinaryBitmap;
import com.google.zxing.BufferedImageLuminanceSource;
import com.google.zxing.DecodeHintType;
import com.google.zxing.MultiFormatReader;
import com.google.zxing.Result;
import com.google.zxing.client.result.ParsedResult;
import com.google.zxing.client.result.ResultParser;
import com.google.zxing.common.GlobalHistogramBinarizer;
import com.google.zxing.common.flexdatatypes.HashTable;

import flash.display.BitmapData;
import flash.events.Event;
import flash.events.MouseEvent;
import flash.media.Camera;
import flash.net.FileFilter;
import flash.net.FileReference;
import flash.net.SharedObject;

import mx.controls.Image;

public var my_reader:MultiFormatReader;
public function barcode_reader_init():void{
	my_reader = new MultiFormatReader();
	auto_input_check_box_load();
	auto_input.addEventListener(Event.CHANGE,auto_input_check_box_save);
}

//画像選択ダイアログ
public var file_reference:FileReference;
public function select_image(event:MouseEvent):void{
	if(camera){
		video_display.attachCamera(null);
		video_display.close();
		video_display.mx_internal::videoPlayer.clear()
	}	
	file_reference = new FileReference();
	var file_filter:FileFilter  = new FileFilter('画像',"*.jpg;*.gif;*.png");
	file_reference.addEventListener(Event.SELECT,file_select);
	file_reference.addEventListener(Event.COMPLETE,file_select_complete);
	file_reference.browse([file_filter]);
}

//画像選択
public function file_select(event:Event):void{
	file_reference.removeEventListener(	Event.SELECT,file_select);
	file_reference.load();
}

//画像ロード
public var image:Image;
public function file_select_complete(event:Event):void{
	file_reference.removeEventListener(Event.COMPLETE,file_select_complete);
	if(image){
		video_display.removeChild(image);
		image = null;
	}
	image = new Image();
	image.width = 320;
	image.height = 240;
	image.load(file_reference.data);
	image.addEventListener(Event.COMPLETE,image_load_complete);
}

public function image_load_complete(event:Event):void{
	image.removeEventListener(Event.COMPLETE,image_load_complete);
	video_display.addChild(image);
	
	var bitmap_data:BitmapData = (image.content as Bitmap).bitmapData;
	analyze_bmp_data(bitmap_data);
}

public function select_imate_input(event:MouseEvent):void{
	if(image){
		var bitmap_data:BitmapData = new BitmapData(image.width,image.height);
		bitmap_data.draw(image);
		
		analyze_bmp_data(bitmap_data);	
	}else{
		card_in.text ="0";
		card_reader_visible_check();		
	}
	
}

public var camera:Camera;
public function get_camera(event:MouseEvent):void{
	if(image){
		video_display.removeChild(image);
		image = null;
	}
	camera = Camera.getCamera();
	if(camera){
		camera.setMode(320,240,60);
		video_display.attachCamera(camera);
		
		//カメラからbitmapdata作成
		var bitmap_data:BitmapData = new BitmapData(video_display.width,video_display.height);
		bitmap_data.draw(video_display);
		
		analyze_bmp_data(bitmap_data);
	}else{
		card_in.text ="0";
		card_reader_visible_check();
	}
}

public function analyze_bmp_data(bitmap_data:BitmapData):void{
	
	var lsource:BufferedImageLuminanceSource = new BufferedImageLuminanceSource(bitmap_data);
	var bitmap:BinaryBitmap = new BinaryBitmap(new GlobalHistogramBinarizer(lsource));
	
	//8桁と13桁のみ許可
	var ht:HashTable = new HashTable();
	ht.Add(DecodeHintType.POSSIBLE_FORMATS,BarcodeFormat.EAN_8);
	ht.Add(DecodeHintType.POSSIBLE_FORMATS,BarcodeFormat.EAN_13);
	
	var result:Result = null;
	try{
		result = my_reader.decode(bitmap,ht);
	}catch(e:Error){
	}
	
	if(!result){
		card_in.text ="0";
	}else{
		var barcode:ParsedResult = ResultParser.parseResult(result);
		card_in.text = barcode.toString();
	}
	card_reader_visible_check();
}


public function card_reader_visible_check():void{
	if(auto_input.selected){
		card_reader_visible = false;
		init_card_reader(new MouseEvent(MouseEvent.CLICK));
		card_insert(new MouseEvent(MouseEvent.CLICK));
	}
}

public function auto_input_check_box_load():void{
	var bb2_simulator:SharedObject = SharedObject.getLocal("bb2_simulator");
	if (bb2_simulator.data.auto_input == undefined) {	
		auto_input.selected = false;
		bb2_simulator.data.auto_input = false;
	} else if (bb2_simulator.data.auto_input) {	
		auto_input.selected = true;
	} else {	
		auto_input.selected = false;		
	}
}

public function auto_input_check_box_save(event:Event):void{
	if(event.type == Event.CHANGE){
		var bb2_simulator:SharedObject = SharedObject.getLocal("bb2_simulator");
		bb2_simulator.data.auto_input = auto_input.selected;
	}
}

