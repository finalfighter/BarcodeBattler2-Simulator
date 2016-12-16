// ActionScript file
package{
	
	public class C2PassCode{
		
		//戦士
		public var barcode_data1:BarcodeData;
		
		//魔法使い
		public var barcode_data2:BarcodeData;
		
		//チェックデジット
		public var unioncheckdigit:int;
		
		//入力したパスコード
		public var passcode:String;
		
		
		public function init(bd1:BarcodeData,bd2:BarcodeData,pc:String=null):void{
			
			barcode_data1=bd1;
			barcode_data2=bd2;
			passcode=pc;
			
			unioncheckdigit = int(barcode_data1.barcode.charAt(12)) + int(barcode_data2.barcode.charAt(12));
			if(unioncheckdigit >= 10){
				unioncheckdigit=unioncheckdigit-10;
			}
			
		}
		
		public function generate_passcode_from_passcode_number(passcode_number:int):String{
			//10の位
			var numten:int = int(passcode_number / 10); 
			//1の位
			var numone:int = passcode_number - numten*10;
			
			//チェックデジット
			//0011223344
			var passcode_checkdigit:Array= new Array(0,0,1,1,2,2,3,3,4,4);
			var checkdigit_key:int = int(numten)+int(numone); 
			if(checkdigit_key >= 10){
				checkdigit_key = checkdigit_key - 10;
			}
			var checkdigit:int= unioncheckdigit + passcode_checkdigit[checkdigit_key];
			if(checkdigit >=10){
				checkdigit = checkdigit - 10;
			}
			
			return numten.toString()+numten.toString()+numone.toString()+numone.toString()+checkdigit.toString();
		}
		
		//パスコードを生成して返す
		public function generate_passcode(special:int):String{
			
			var array:Array = new Array(5,10,15,20,25,35,36,37,38,39,40,41,42,43,44,45,46,47,48,49);
			var passcode_number:int = array[special - 80];
			
			return generate_passcode_from_passcode_number(passcode_number);
		}
		
		
		//パスコード番号を返す。パスコードが間違っていた場合は-1を返す
		public function generate_passcode_number():int{
			if(passcode.charAt(0) != passcode.charAt(1)){
				return -1;
			}
			if(passcode.charAt(2) != passcode.charAt(3)){
				return -1;
			}
			
			var passcode_number:int = int(passcode.charAt(0))*10+int(passcode.charAt(2));
			
			//0011223344
			var passcode_checkdigit:Array= new Array(0,0,1,1,2,2,3,3,4,4);
			var checkdigit_key:int = int(passcode.charAt(0))+int(passcode.charAt(2)); 
			if(checkdigit_key >= 10){
				checkdigit_key = checkdigit_key - 10;
			}
			
			var checkdigit:int= unioncheckdigit + passcode_checkdigit[checkdigit_key];
			if(checkdigit >=10){
				checkdigit = checkdigit - 10;
			}
			
			if(int(passcode.charAt(4)) != checkdigit){
				return -1;
			}
			
			return  passcode_number;
		}
		
		public function generate_passcode_barcode_data(bd:BarcodeData,passcode_number:int):BarcodeData{
			bd.hp = calchp(bd.hp,passcode_number-1);
			bd.st = calcst(bd.st,passcode_number-1);;
			bd.df = calcdf(bd.df,passcode_number-1);
			return bd;
		}
		
		public function calchp(hp:int,passcode_number:int):int{
			if(passcode_number == -1){
				return hp;
			}
			
			var floorhp:int = Math.floor(hp*passcode_number/10);
			var count:int=0;
			while(floorhp > 655){
				count=1;
				floorhp = floorhp - 655;
			}
			
			var floorceilhp:int = Math.floor(passcode_number/2)*Math.ceil(passcode_number/2);
			while(floorceilhp > 655){
				count=1;
				floorceilhp = floorceilhp - 655;
			}
			
			var calchp:int = hp + floorhp + floorceilhp;
			if(calchp > 999){
				calchp = 999;
			}else{
				calchp = calchp - count;
			}
			
			if(passcode_number >= 90 && passcode_number % 2 == 0){
				calchp = calchp - 1;
			}
			
			return calchp;
			
		}
		
		
		public function calcst(st:int,passcode_number:int):int{
			if(passcode_number == -1){
				return st;
			}
			
			var array:Array = new Array(
				0,0,0,0,0,1,1,1,2,
				3,4,4,5,6,7,9,10,11,12,
				14,16,17,19,21,23,25,27,
				29,31,33,36,38,40,43,46,
				49,51,54,57,60,64,67,70,
				73,77,81,84,88,92,96,100,
				104,108,112,116,121,125,129,
				134,139,144,148,153,158,163,
				169,174,179,184,190,196);
			
			if(array[passcode_number] === null){
				return 199;
			}
				
			var calcst:int = int(st)+Math.floor(st*passcode_number/9)+array[passcode_number];
			if(calcst > 199){
				return 199;
			}
			
			return calcst;
			
		}
		
		public function calcdf(df:int,passcode_number:int):int{
			if(passcode_number == -1){
				return df;
			}
			
			var array:Array = new Array(
				0,0,0,0,0,1,1,2,3,
				4,5,6,7,8,9,11,12,14,
				16,18,20,22,24,26,28,
				31,33,36,39,42,45,48,
				51,54,57,61,64,68,72,
				76,80,84,88,92,96,101,
				105,110,115,120,125,130,
				135,140,145,151,156,162,
				168,174,180,186,192,198);
			
			if(!array[passcode_number] === null){
				return 199;
			}
			
			var calcdf:int = int(df)+Math.floor(df*passcode_number/12)+array[passcode_number];
			if(calcdf > 199){
				return 199;
			}
			
			return calcdf;
		}
		
	}
	
}