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
import flash.display.Loader;
import flash.events.Event;
import flash.events.MouseEvent;
import flash.geom.Matrix;
import flash.net.URLLoader;
import flash.net.URLRequest;
import flash.utils.ByteArray;

import mx.events.ListEvent;
import mx.graphics.codec.JPEGEncoder;

public function barcode_cards_init():void{
	var list_loader:URLLoader = new URLLoader(new URLRequest("xml/list.xml"));
	var name_loader:URLLoader = new URLLoader(new URLRequest("xml/bb2.xml"));
	list_loader.addEventListener(Event.COMPLETE,list_load_complete);
	name_loader.addEventListener(Event.COMPLETE,name_load_complete);
	
	card_list_datagrid.addEventListener(ListEvent.CHANGE,barcode_list_load);
	card_name_datagrid.addEventListener(ListEvent.CHANGE,barcode_cards_load);
	
}

//初期リスト読み込み
public function list_load_complete(event:Event):void{
	var xml:XML = new XML(event.currentTarget.data);
	card_list_datagrid.dataProvider = xml.item;
}

//初期カードリスト読み込み
public function name_load_complete(event:Event):void{
	var xml:XML = new XML(event.currentTarget.data);
	card_name_datagrid.dataProvider = xml.item;
}


//カードリスト読み込み処理実行
public function barcode_list_load(event:ListEvent):void{

	var url:String = "xml/" + card_list_datagrid.selectedItem.xml;
	var name_loader:URLLoader = new URLLoader(new URLRequest(url));
	name_loader.addEventListener(Event.COMPLETE,name_load_complete);
	
}

public var back_img_loader:Loader;

//true:表 false:裏
public var front_back:Boolean=true;


//カード読み込み処理実行
public function barcode_cards_load(event:ListEvent):void{
	
	card_image.load(card_name_datagrid.selectedItem.front_img);
	front_back = true;
	card_image.addEventListener(MouseEvent.CLICK,change_front_back_image);
	
	//card_in.text = card_name_datagrid.selectedItem.barcode;
	
	back_img_loader = new Loader();
	back_img_loader.contentLoaderInfo.addEventListener(Event.COMPLETE,barcode_cards_load_done);
	back_img_loader.load(new URLRequest(card_name_datagrid.selectedItem.back_img));
}

//読み込み処理完了
public function barcode_cards_load_done(event:Event):void{
	var bitmap_data:BitmapData = new BitmapData(back_img_loader.width,back_img_loader.height);
	bitmap_data.draw(back_img_loader);
	
	var clip_bitmap_data:BitmapData = clip(bitmap_data,0,178,330,50);
	
	analyze_barcode_data(clip_bitmap_data);
}

/**
 *
 * BitmapData の切り抜き
 *
 * @param       BitmapData      src         元となる BitmapData オブジェクト
 * @param       int             x           切り抜く領域の左上座標・x値
 * @param       int         　  y           切り抜く領域の左上座標・y値
 * @param       int             w           切り抜く領域の幅（width）
 * @param       int             h           切り抜く領域の高さ（height）
 * @return      BitmapData      切り抜かれた画像データ
 *
 */
public function clip(src:BitmapData, x:int, y:int, w:int, h:int):BitmapData
{
	var res:BitmapData = new BitmapData(w, h);
	res.draw(src, new Matrix(1, 0, 0, 1, -x, -y));
	return res;
}

//表裏変更処理
public function change_front_back_image(event:MouseEvent):void{
	if(front_back){
		card_image.load(card_name_datagrid.selectedItem.back_img);
		front_back = false;
	}else{
		card_image.load(card_name_datagrid.selectedItem.front_img);
		front_back = true;
	}
}

public function analyze_barcode_data(bitmap_data:BitmapData):void{
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
		card_in.text = card_name_datagrid.selectedItem.barcode;
	}else{
		var barcode:ParsedResult = ResultParser.parseResult(result);
		
		var barcode_str:String;
		barcode_str = barcode.toString();
		
		while(barcode_str.length < 13){
			barcode_str = "0" + barcode_str;
		}
		
		card_in.text = barcode_str; 
	}
}
