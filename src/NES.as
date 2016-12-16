// ActionScript file
package {
	public class NES{
	
		public var CarryFlag:int = 0;
		public var ZeroFlag:int  = 0;
		
		public function clc():void{
			CarryFlag = 0;
		}
		public function sec():void{
			CarryFlag = 1;
		}
		public function inc(num:int):int{
			num = num + 1;
			if(num > 255){
				num = num - 255;
				CarryFlag = 1;
			}else{
				CarryFlag = 0;
			}
			if(num == 0){
				ZeroFlag = 1;
			}else{
				ZeroFlag = 0;
			}
			return num;
		}
		
		public function cmp(num:int,num2:int):void{
			num = num - num2;
			if(num == 0){
				ZeroFlag = 1;
			}else{
				ZeroFlag = 0;
			}
			if(num < 0){
				CarryFlag = 0;
			}else{
				CarryFlag = 1;
			}
		}
		
		public function bcc():Boolean{
			if(CarryFlag == 0){
				return true;
			}
			return false;
		}
		
		public function bcs():Boolean{
			if(CarryFlag == 1){
				return true;
			}else{
				return false;
			}
		}
		
		public function bne():Boolean{
			if(ZeroFlag == 0){
				return true;
			}
			return false;
		}
		
		public function adc(num:int,num2:int):int{
			num = num + num2 + CarryFlag;
			if(num > 255){
				num = num - 255;
				CarryFlag = 1;
			}else{
				CarryFlag = 0;
			}
			if(num == 0){
				ZeroFlag = 1;
			}else{
				ZeroFlag = 0;
			}
			
			return num;
		}
		
		public function sbc(num:int,num2:int):int{
			var UnCarryFlag:int = (CarryFlag)?0:1;
			num = num - num2 - UnCarryFlag;
			if(num >=0){
				CarryFlag = 1;
			}else{
				num = num + 255;
				CarryFlag = 0;
			}
			if(num == 0){
				ZeroFlag = 1;
			}else{
				ZeroFlag = 0;
			}
			return num;
		}
		
		//8桁の2進数算出
		public function decbin8(num:int):String{
				var bin8:String = num.toString(2);
				while( bin8.length < 8){
					bin8 = "0" + bin8;
				}
				return bin8;
		}
		
		//算術右シフト
		public function lsr(num:int):int{
			var bin8:String = decbin8(num);
			if(int(bin8.charAt(7)) == 1){
				CarryFlag = 1;
			}else{
				CarryFlag = 0;
			}
			bin8 = "0"+bin8.substr(0,7);
			num = parseInt(bin8,2);
			if(num == 0){
				ZeroFlag = 1;
			}else{
				ZeroFlag = 0;
			}
			return num;
		}
		
		//算術左シフト
		public function asl(num:int):int{
			var bin8:String = decbin8(num);
			if(int(bin8.charAt(0)) == 1){
				CarryFlag = 1;		
			}else{
				CarryFlag = 0;
			}		
			bin8 = bin8.substr(1,7)+"0";
			num = parseInt(bin8,2);
			if(num == 0){
				ZeroFlag = 1;
			}else{
				ZeroFlag = 0;
			}
			return num;
		}
		
		//左ローテート
		public function rol(num:int):int{
			var bin8:String = decbin8(num);
			bin8 = bin8.substr(1,7)+CarryFlag.toString();
			if(int(decbin8(num).charAt(0)) == 1){
				CarryFlag = 1;		
			}else{
				CarryFlag = 0;
			}
			num = parseInt(bin8,2);
			if(num == 0){
				ZeroFlag = 1;
			}else{
				ZeroFlag = 0;
			}
			return num;
		}
		
		public function ror(num:int):int{
			var bin8:String = decbin8(num);
			bin8 = CarryFlag.toString()+bin8.substr(0,7);
			if(int(decbin8(num).substr(7,1)) == 1){
				CarryFlag = 1;
			}else{
				CarryFlag = 0;
			}
			num = parseInt(bin8,2);
			if(num == 0){
				ZeroFlag = 1;
			}else{
				ZeroFlag = 0;
			}
			return num;
		}
		
		public function ora(num:int,num2:int):int{
			return int(num | num2);
	}
	}
}