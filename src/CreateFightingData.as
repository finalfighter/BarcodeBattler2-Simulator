// ActionScript file
package{
	
	public class CreateFightingData{
		
		public function init(barcode_data1:BarcodeData,barcode_data2:BarcodeData=null):FightingData{
			
			var fighting_data:FightingData = new FightingData();
			
			//2枚
			if(barcode_data2){
				
				var hp:int = barcode_data1.hp + barcode_data2.hp;
				if(hp > 999){
					hp = 999;
				}
				fighting_data.max_hp = hp;
				fighting_data.hp     = hp;
				
				var st:int = barcode_data1.st + barcode_data2.st;
				if(st > 199){
					st = 199;
				}
				if(st < 0){
					st = 0;
				}
				fighting_data.st = st;
				fighting_data.st1 = barcode_data1.st;
				fighting_data.st2 = barcode_data2.st;
				
				var df:int = barcode_data1.df + barcode_data2.df;
				if(df > 199){
					df = 199;
				}
				if(df < 0){
					df = 0;
				}
				fighting_data.df = df;
				fighting_data.df1 = barcode_data1.df;
				fighting_data.df2 = barcode_data2.df;
				
				fighting_data.speed = barcode_data1.speed;				
				
				fighting_data.race1 = barcode_data1.race;
				fighting_data.race2 = barcode_data2.race;
				
				fighting_data.job = barcode_data1.job;
				
				if(barcode_data2.race <=4){
					fighting_data.pp = barcode_data1.pp;
				}else{
					fighting_data.pp = barcode_data1.pp + barcode_data2.pp;
				}
				if(fighting_data.pp > 99){
					fighting_data.pp = 99;
				}
				
				if(barcode_data2.race <=4){
					if(barcode_data1.mp >= 10 || barcode_data2.mp >= 10){
						if(barcode_data1.job <=6){
							fighting_data.mp = 0;
						}else{
							fighting_data.mp = barcode_data1.mp;
						}
					}else{
						fighting_data.mp = 0;
					}
					fighting_data.union_flag = true;
				}else{
					if(barcode_data1.job <=6){
						fighting_data.mp = 0;
					}else{
						fighting_data.mp = barcode_data1.mp + barcode_data2.mp;
					}
				}
				if(fighting_data.mp > 99){
					fighting_data.mp = 99;
				}
				
				fighting_data.pp_ignore_flag = false;
				fighting_data.special1 = barcode_data1.special;
				fighting_data.special2 = barcode_data2.special;
				
			//1枚のみ
			}else{
				
				fighting_data.max_hp = barcode_data1.hp;
				fighting_data.hp = barcode_data1.hp;
				fighting_data.st = barcode_data1.st;
				fighting_data.st1 = barcode_data1.st;
				fighting_data.df =  barcode_data1.df;
				fighting_data.df1 = barcode_data1.df;
				fighting_data.speed = barcode_data1.speed;
				fighting_data.race1 = barcode_data1.race;
				fighting_data.job = barcode_data1.job;
				fighting_data.union_flag = false;
				fighting_data.pp = barcode_data1.pp;
				fighting_data.mp = barcode_data1.mp;
				fighting_data.pp_ignore_flag = false;
				fighting_data.special1 = barcode_data1.special;
			}
			
			return fighting_data;
			
		}
		
	}
	
}