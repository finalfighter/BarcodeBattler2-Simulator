// ActionScript file
package{
	import mx.messaging.AbstractConsumer;
	
	public class BarcodeWorld{
		import NES;
		protected var nes:NES;
		
		public function BarcodeWorld(){
			if(!nes){
				nes = new NES();
			}
		}
		
		//$18*$1C={$25$24}
		public function dadf(object:Object):void{
			//参照渡し用にObject使用
			var m0018:int = object.m0018;
			var m001C:int = object.m001C;
			var m0000:int = 0;
			var m0024:int = 0;
			var m0025:int = 0;
			
			nes.ZeroFlag = 0;
			nes.CarryFlag = 0;
			
			while(true){
				//dae7:
				m0018 = nes.lsr(m0018);
				try{
					if(nes.CarryFlag==0){
						//goto daf8;
						throw new Error("daf8");
					}
					nes.clc();
					m0024=nes.adc(m001C,m0024);
					m0025=nes.adc(m0000,m0025);
					
				}catch(e:Error){
				}
				
				//daf8:
				m001C = nes.asl(m001C);
				m0000 = nes.rol(m0000);
				if(m0018!=0){
					//goto dae7;
				}else{
					break;
				}
			}
			
			object.m0024=m0024;
			object.m0025=m0025;
			
		}
		
		//{$19$18}/{$1D$1C}={$25$24}
		public function dbcd(object:Object):void{
			var m0018:int = object.m0018;
			var m0019:int = object.m0019;
			var m001C:int = object.m001C;
			var m001D:int = object.m001D;
			var m0024:int = 0;
			var m0025:int = 0;
			var m002C:int = 0;
			var m002D:int = 0;
			var RegisterX:int = 0x10;
			
			while(true){
				//dbd9:
				m0024 = nes.asl(m0024);
				m0025 = nes.rol(m0025);
				m0018 = nes.asl(m0018);
				m0019 = nes.rol(m0019);
				m002C = nes.rol(m002C);
				m002D = nes.rol(m002D);
				
				try{
					nes.cmp(m002D,m001D);
					if(nes.bcc()){
						//goto dc05;
						throw new Error("dc05");
					}
						
					try{
						if(nes.bne()){
							throw new Error("dbf3");
						}
						nes.cmp(m002C,m001C);
						if(nes.bcc()){
							throw new Error("dc05");
						}
						
					}catch(e:Error){
						if(e.message != "dbf3"){
							throw e;
						}
					}
					
					//daf3:
					m002C = nes.sbc(m002C,m001C);
					m002D = nes.sbc(m002D,m001D);
					m0024 = nes.inc(m0024);
					if(nes.bne()){
						throw new Error("dc05");
					}
					m0025 = nes.inc(m0025);
					
				}catch(e:Error){
				}
				
				//dc05:
				RegisterX = RegisterX - 1;
				if(RegisterX != 0){
					//goto dbd9;
				}else{
					break;
				}
			}
			
			object.m0024 = m0024;
			object.m0025 = m0025;
			
		}
		
		//{$19$18}*{$1D$1C}={$27$26$25$24}
		public function db01(object:Object):void{
			var m0018:int = object.m0018;
			var m0019:int = object.m0019;
			var m001C:int = object.m001C;
			var m001D:int = object.m001D;
			var m0000:int = 0;
			var m0001:int = 0;
			var m0024:int = 0;
			var m0025:int = 0;
			var m0026:int = 0;
			var m0027:int = 0;
			nes.ZeroFlag = 0;
			nes.CarryFlag = 0;
			
			//db0f:
			while(true){
				m0019 = nes.lsr(m0019);
				m0018 = nes.ror(m0018);
				try{
					if(nes.bcc()){
						throw new Error("db2e");
					}
					nes.clc();
					m0024 = nes.adc(m001C,m0024);
					m0025 = nes.adc(m001D,m0025);
					m0026 = nes.adc(m0000,m0026);
					m0027 = nes.adc(m0001,m0027);
					
				}catch(e:Error){
				}
				
				//db2e:
				m001C = nes.asl(m001C);
				m001D = nes.rol(m001D);
				m0000 = nes.rol(m0000);
				m0001 = nes.rol(m0001);
				m0018 = nes.ora(m0018,m0019);
				if(m0018 != 0){
					//goto db0f;
				}else{
					break;
				}
					
			}
			
			object.m0024 = m0024;
			object.m0025 = m0025;
			object.m0026 = m0026;
			object.m0027 = m0027;
			
		}
		
		//{$19$18}*$1C/0A={$19$18}
		public function f_8bdf(object:Object):void{
			var m0018:int = object.m0018;
			var m0019:int = object.m0019;
			var m001A:int = 0;
			var m001B:int = 0;
			var m001C:int = object.m001C;
			var m001D:int = 0;
			var m001E:int = 0;
			var m001F:int = 0;
			
			var input:Object = new Object();
			input.m0018 = m0018;
			input.m0019 = m0019;
			input.m001C = m001C;
			input.m001D = m001D;
			input.m0024 = 0;
			input.m0025 = 0;
			input.m0026 = 0;
			input.m0027 = 0;
			
			db01(input);
			
			m0018 = input.m0024;
			m0019 = input.m0025;
			m001A = input.m0026;
			m001B = input.m0027;
			m001C = 0x0A;
			m001D = 0;
			m001E = 0;
			m001F = 0;
			
			input = new Object();
			input.m0018 = m0018;
			input.m0019 = m0019;
			input.m001A = m001A; 
			input.m001B = m001B;
			input.m001C = m001C;
			input.m001D = m001D;
			input.m001E = m001E;
			input.m001F = m001F;
			input.m0024 = 0;
			input.m0025 = 0;
			input.m0026 = 0;
			input.m0027 = 0;
			dc09(input);
			
			//8C13(999より大きかった判定)
			nes.cmp(input.m0025,0x03);
			if(!nes.bcc()){
				if(nes.bne()){
					input.m0025 = 0x03;
					input.m0024 = 0xE7;
				}else{
					nes.cmp(input.m0024,0xE7);
					if(!nes.bcc()){
						input.m0025 = 0x03;
						input.m0024 = 0xE7;
					}
				}
			}
			
			object.m0018 = input.m0024;
			object.m0019 = input.m0025;
			
		}
		
		//{$1B$1A$19$18}/{$1F$1E$1D1C}={$27$26$25$24}
		public function dc09(object:Object):void{
			var m0018:int = object.m0018;
			var m0019:int = object.m0019;
			var m001A:int = object.m001A;
			var m001B:int = object.m001B;
			var m001C:int = object.m001C;
			var m001D:int = object.m001D;
			var m001E:int = object.m001E;
			var m001F:int = object.m001F;
			var m0024:int = 0;
			var m0025:int = 0;
			var m0026:int = 0;
			var m0027:int = 0;
			var m002C:int = 0;
			var m002D:int = 0;
			var m002E:int = 0;
			var m002F:int = 0;
			var RegisterX:int = 0x20;
			
			//dc1d:
			while(true){
				m0024 = nes.asl(m0024);
				m0025 = nes.rol(m0025);
				m0026 = nes.rol(m0026);
				m0027 = nes.rol(m0027);
				m0018 = nes.asl(m0018);
				m0019 = nes.rol(m0019);
				m001A = nes.rol(m001A);
				m001B = nes.rol(m001B);
				m002C = nes.rol(m002C);
				m002D = nes.rol(m002D);
				m002E = nes.rol(m002E);
				m002F = nes.rol(m002F);
				
				try{
					
					try{
						nes.cmp(m002F,m001F);
						if(nes.bcc()){
							throw new Error("dc79");
						}
						if(nes.bne()){
							throw new Error("dc53");
						}
						nes.cmp(m002E,m001E);
						if(nes.bcc()){
							throw new Error("dc79");
						}
						if(nes.bne()){
							throw new Error("dc53");
						}
						nes.cmp(m002D,m001D);
						if(nes.bcc()){
							throw new Error("dc79");
						}
						if(nes.bne()){
							throw new Error("dc53");
						}
						nes.cmp(m002C,m001C);
						if(nes.bcc()){
							throw new Error("dc79");
						}						
						
					}catch(e:Error){
						if(e.message != "dc53"){
							throw e;
						} 
					}
					
					//dc53:
					m002C = nes.sbc(m002C,m001C);
					m002D = nes.sbc(m002D,m001D);
					m002E = nes.sbc(m002E,m001E);
					m002F = nes.sbc(m002F,m001F);
					m0024 = nes.inc(m0024);
					
					if(nes.bne()){
						throw new Error("dc79");
					}
					m0025 = nes.inc(m0025);
					if(nes.bne()){
						throw new Error("dc79");
					}
					m0026 = nes.inc(m0026);
					if(nes.bne()){
						throw new Error("dc79");
					}
					m0027 = nes.inc(m0027);
										
				}catch(e:Error){
				}
				
				//dc79:
				RegisterX = RegisterX - 1;
				if(RegisterX <= 0){
					break;
				}
				//goto dc1d:

			}
			
			object.m0024 = m0024;
			object.m0025 = m0025;
			object.m0026 = m0026;
			object.m0027 = m0027;
		}
		
		
	}
}