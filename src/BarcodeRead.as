// ActionScript file
package{
	import mx.controls.TextInput;
	
	
	//バーコードを読み込みパラメータをBarcodeDataにセットする
	public class BarcodeRead{
		
		public var barcode_data:BarcodeData; 
		public var debug:TextInput;
		//barcode:バーコード文字列  count:入力カウント(1枚目か2枚目か) barcode1:1枚目のバーコード番号 shift:バーコードシフト hero:主人公フラグが必要か job:職業固定が必要か(null,warrior,magician) item:アイテム固定が必要か c1_flag 
		public function init(barcode:String,count:int=1,barcode1_data:BarcodeData=null,shift:int=0,hero:Boolean=false,job:String=null,item:Boolean=false,c1_flag:Boolean=false):Boolean{
				
				if(!check_barcode(barcode)){
					return false;
				}
				
				if(!check_degit(barcode)){
					return false;
				}
				
				barcode_data = new BarcodeData();
				barcode_data.barcode = barcode;
				
				var post_read_flag:Boolean=false;
				if(prepost_check()){
					pre_reading();
				}else{
					post_read_flag=true;
					post_reading(shift);
				}
				
				if(count==1){
					//1枚目はアイテム不可
					if(barcode_data.race>4){
						return false;
					}
					
					//主人公フラグ
					if(hero && barcode_data.special!=18 && barcode_data.special!=50 && !post_read_flag){
						return false;
					}
					
					//主人公でHP6000、ST2000、DF2000以上ははじく
					if(barcode_data.special == 50 && (barcode_data.hp >=60 || barcode_data.st >= 20 || barcode_data.df >= 20)){
						return false;
					}
					
					//heroフラグたっている（＝C1、C2モードのときはHP、ST、DFを再計算）
					if(hero && post_read_flag && barcode_data.race <= 4){
						calc_c1_reading();
					}
					
					//jobチェック
					if(job == "warrior"){
						//戦士のみ受け付けで魔法使いだった場合
						if(barcode_data.job >6){
							return false;
						}
					}else if(job == "magician"){
						//魔法使いのみ受け付けで戦士だった場合
						if(barcode_data.job <=6 ){
							return false;
						}
					}
					
				}
				
				//C2アイテム固定チェック
				if(barcode1_data && item){
					if(barcode_data.race <= 4){
						//合体できないバーコードであることを確認
						if(barcode_data.race != barcode1_data.race || barcode_data.job != barcode1_data.job){
							return false;
						}
					}
				}
				
				if(barcode1_data){
					//同じバーコードは合体不可
					var barcode_check:String;
					var barcode_check1:String;
					if(barcode.length >= 13){
						barcode_check = barcode.charAt(6)+barcode.charAt(7)+barcode.charAt(8)+barcode.charAt(9)+barcode.charAt(10)+barcode.charAt(11)+barcode.charAt(12);
					}else{
						barcode_check = barcode.charAt(1)+barcode.charAt(2)+barcode.charAt(3)+barcode.charAt(4)+barcode.charAt(5)+barcode.charAt(6)+barcode.charAt(7);
					}
					
					var barcode1:String = barcode1_data.barcode;
					if(barcode1_data.barcode.length >=13){
						barcode_check1 = barcode1.charAt(6)+barcode1.charAt(7)+barcode1.charAt(8)+barcode1.charAt(9)+barcode1.charAt(10)+barcode1.charAt(11)+barcode1.charAt(12);
					}else{
						barcode_check1 = barcode1.charAt(1)+barcode1.charAt(2)+barcode1.charAt(3)+barcode1.charAt(4)+barcode1.charAt(5)+barcode1.charAt(6)+barcode1.charAt(7);
					}
					
					if(barcode_check == barcode_check1){
						return false;
					}
					
					//HPアイテム系チェック
					if(barcode_data.race == 9){
						//情報カードは入力不可
						if(barcode_data.job == 5 || barcode_data.job == 6){
							if(!c1_flag){
								return false;
							}
						}
						
						//戦士はMPアップ不可
						if(barcode1_data.job <= 6){
							if(barcode_data.job >= 8){
								return false;
							}
						} 
					}
					
					//魔法使いは武器・防具は不可
					if(barcode_data.job >= 7){
						if(barcode_data.race >= 5 && barcode_data.race <= 8){
							return false;
						}
					}
				}
				return true;
		}
		
		protected function calc_c1_reading():void{
			//HP,ST,DFを元に再計算
			barcode_data.hp = Math.floor(barcode_data.hp / 10); 
			barcode_data.st = Math.floor(barcode_data.st / 10) + 1;
			barcode_data.df = Math.floor(barcode_data.df / 10) + 3;
		}
		
		//デジットチェック
		protected function check_degit(barcode:String):Boolean{
			
			if(barcode.length == 8){
				barcode = "00000" + barcode;
			}
			
			//奇数
			var odd_digit:int = 0;
			for(var i:int = 0; i <= barcode.length-2; i=i+2){
				odd_digit = odd_digit + int(barcode.charAt(i));
			}

			//偶数
			var even_digit:int = 0;
			for(i = 1; i <= barcode.length-1; i=i+2){
				even_digit = even_digit + int(barcode.charAt(i));
			}

			//1桁目から引く
			var calc_check_digit:int = 10 - ((odd_digit + even_digit*3) % 10);
			if(calc_check_digit == 10){
				calc_check_digit = 0;
			}

			//最終桁目取り出し
			var check_digit:int = int(barcode.charAt(barcode.length -1));
			if(calc_check_digit != check_digit){
				return false;
			}
			return true;
		}
		
		//8桁13桁簡易チェック
		protected function check_barcode(barcode:String):Boolean{
			if(barcode.length != 13 && barcode.length != 8){
				return false;
			}
			return true;
		}
		
		//前読みか後読みか判別 true:前読み　false:後読み
		protected function prepost_check():Boolean{
			var barcode:String = barcode_data.barcode;
			if(barcode.length == 8){
				return false;
			}
			
			var head_digit:int = int(barcode.charAt(0));
			if(head_digit == 0 || head_digit == 1){
				if(int(barcode.charAt(7)) >= 0 && int(barcode.charAt(7)) <= 4){
					return true;
				}else{
					//前読みとして読んだ場合HP5000、ST1900、DF1900以下の場合は5-9でも前読みに
					var hp:int = int(barcode.charAt(0) + barcode.charAt(1) + barcode.charAt(2));
					var st:int = int(barcode.charAt(3) + barcode.charAt(4));
					var df:int = int(barcode.charAt(5) + barcode.charAt(6));
					if(hp <= 50 && st <= 19 && df <=19){
						return true;
					}
					return false;
				}
			}else{
				if(int(barcode.charAt(2)) == 9 && int(barcode.charAt(9)) == 5){
					return true;
				}else{
					return false;
				}
			}
		}
		
		//前読み
		protected function pre_reading():void{
			var barcode:String = barcode_data.barcode;

			//種族取得
			barcode_data.race= int(barcode.charAt(7));
	
			//特殊能力
			barcode_data.special = int(barcode.charAt(10) + barcode.charAt(11));
			
			//キャラクター
			if(barcode_data.race >=0 && barcode_data.race <= 4){
				//HP
				barcode_data.hp = int(barcode.charAt(0) + barcode.charAt(1) + barcode.charAt(2));
				
				//ST
				barcode_data.st = int(barcode.charAt(3) + barcode.charAt(4));

				//DF
				barcode_data.df = int(barcode.charAt(5) + barcode.charAt(6));

				//ST/DF追加処理
				if(barcode_data.race == 0 && barcode_data.hp >= 200){
					var check_stdf:int = int(barcode.charAt(3) + barcode.charAt(4));
					if(check_stdf==13 || check_stdf==29 || check_stdf==45 || check_stdf== 61 || check_stdf==77 || check_stdf==93){
						barcode_data.st = barcode_data.st + 100;
						barcode_data.df = barcode_data.df + 100;
					}
					
					barcode_data.st = barcode_data.st + 100;
					
					if(barcode_data.st > 256){
						barcode_data.st = barcode_data.st - 255;
					}
					
				}else if(barcode_data.race == 1 && barcode_data.hp >= 200){
					var check_stdf:int = int(barcode.charAt(5) + barcode.charAt(6));
					if(check_stdf==13 || check_stdf==29 || check_stdf==45 || check_stdf== 61 || check_stdf==77 || check_stdf==93){
						barcode_data.st = barcode_data.st + 100;
						barcode_data.df = barcode_data.df + 100;
					}
					
					barcode_data.df = barcode_data.df + 100;
					
					if(barcode_data.df > 256){
						barcode_data.df = barcode_data.st - 255;
					}
				}else if(barcode_data.race == 2 && barcode_data.hp >= 200){
					barcode_data.st = barcode_data.st + 100;
					barcode_data.df = barcode_data.df + 100;
				}
				
				//Speed
				barcode_data.speed = int(barcode.charAt(11));

				//job
				barcode_data.job = int(barcode.charAt(8));

				//PP
				barcode_data.pp = 5;

				//MP
				if(barcode_data.job >= 6){
					barcode_data.mp = 10;
				}else{
					barcode_data.mp = 0;
				}

			//STアイテム
			}else if(barcode_data.race >=5 && barcode_data.race <= 6){
				barcode_data.st = int(barcode.charAt(3) + barcode.charAt(4));
				if(barcode_data.special == 31 && Math.floor(Math.random() * 2) == 0){
					barcode_data.st = 0 - barcode_data.st;	
				}
			//DFアイテム
			}else if(barcode_data.race >=7 && barcode_data.race <= 8){
				barcode_data.df = int(barcode.charAt(5) + barcode.charAt(6));
				if(barcode_data.special == 32 && Math.floor(Math.random() * 2) == 0){
					barcode_data.df = 0 - barcode_data.df;	
				}
			//HPアイテム/情報カード/薬草アップ/MPアップ
			}else{
				//HPアイテムの種類判別用に職業保存
				barcode_data.job = int(barcode.charAt(8));
				
				//HPアイテム
				if(barcode_data.job >= 0 &&  4 >= barcode_data.job){
					barcode_data.hp = int(barcode.charAt(0) + barcode.charAt(1) + barcode.charAt(2));
					if(barcode_data.special == 30 && Math.floor(Math.random() * 2) == 0){
						barcode_data.hp = 0 - barcode_data.hp;	
					}
				//情報カード
				}else if(barcode_data.job == 5 || barcode_data.job == 6){
				//薬草アップ
				}else if(barcode_data.job == 7){
					barcode_data.pp = int(barcode.charAt(3) + barcode.charAt(4));
				//MPアップ
				}else{
					barcode_data.mp = int(barcode.charAt(5) + barcode.charAt(6));
				}
			}
			
		}
		
		//後読み
		protected function post_reading(shift:int=+2):void{
				var barcode:String = barcode_data.barcode;

				//13桁
				if(barcode.length==13){
	
					//先頭へのズレの場合
					if(shift == +2){
						shift = -8;
					}
					
					//種族取得
					barcode_data.race = int(barcode.charAt(12));
	
					//キャラクター
					if(barcode_data.race >=0 && barcode_data.race <= 4){
						
						//HP
						barcode_data.hp = int((Math.floor(int(barcode.charAt(11+shift))/2)).toString()+barcode.charAt(10+shift)+barcode.charAt(9+shift));

						//ST
						var tmpst:int = int(barcode.charAt(10+shift)) + 7;
						if(tmpst > 11){
							tmpst = tmpst - 10;
						}
						var tmpst2:int = int(barcode.charAt(9+shift)) + 5 % 10;
						if(tmpst2 >= 10){
							tmpst2 = tmpst2 - 10;
						}
						barcode_data.st = int(tmpst.toString() + tmpst2.toString());
	
						//DF
						var tmpdf:int = int(barcode.charAt(9+shift))+7;
						if(tmpdf >= 10){
							tmpdf = tmpdf - 10;
						}
						var tmpdf2:int  = int(barcode.charAt(8+shift))+7;
						if(tmpdf2 >= 10){
							tmpdf2 = tmpdf2 - 10;
						}
						barcode_data.df = int(tmpdf.toString()+ tmpdf2.toString());
	
						
						
						//Speed
						barcode_data.speed = int(barcode.charAt(10));
	
						//job
						barcode_data.job = int(barcode.charAt(5));

	
						//PP
						barcode_data.pp = 5;
						
						//MP
						if(barcode_data.job >= 6){
							barcode_data.mp = 10;
						}else{
							barcode_data.mp = 0;
						}
	
					//STアイテム
					}else if(barcode_data.race >=5 && barcode_data.race <= 6){
	
						if(int(barcode.charAt(10)) >= 5 && int(barcode.charAt(10)) <= 8){
							barcode_data.st = int("1" + ((int(barcode.charAt(9))+5)%10).toString()); 
						}else if(int(barcode.charAt(10)) == 3 || int(barcode.charAt(10)) == 4){
							barcode_data.st = int("3" + ((int(barcode.charAt(9))+5)%10).toString());
						}else{
							barcode_data.st = int("2" + ((int(barcode.charAt(9))+5)%10).toString());
						}
	
					//DFアイテム
					}else if(barcode_data.race >=7 && barcode_data.race <= 8){
	
						if(int(barcode.charAt(9)) >= 3 && int(barcode.charAt(9)) <= 6){
							barcode_data.df =(int(barcode.charAt(8))+7)%10; 
						}else if(int(barcode.charAt(9)) == 1 || int(barcode.charAt(9)) == 2){
							barcode_data.df = int("2" + ((int(barcode.charAt(8))+7)%10).toString());
						}else{
							barcode_data.df = int("1" + ((int(barcode.charAt(8))+7)%10).toString());
						}
					//HPアイテム
					}else{
						//HPアイテムの種類判別用
						barcode_data.job = 0;
						barcode_data.hp = int(Math.floor(int(barcode.charAt(11))/8).toString()+ barcode.charAt(10) + barcode.charAt(9));
					}
					
					//特殊能力
					var tmpspecial:int = int(barcode.charAt(8));
					if(tmpspecial >= 0 && tmpspecial <= 3){
						barcode_data.special = int(barcode.charAt(10));
					}else if(tmpspecial >= 8 && tmpspecial <= 9){
						barcode_data.special = int("2" + barcode.charAt(10));
					}else{
						barcode_data.special = int("1" + barcode.charAt(10));
					}
	
				//8桁
				}else{
					
					//先頭へのズレの場合
					if(shift == +2){
						shift = -3;
					}
	
					//種族取得
					barcode_data.race = int(barcode.charAt(7));
	
					//キャラクター
					if(int(barcode_data.race) >=0 && int(barcode_data.race)<= 4){

						//HP
						barcode_data.hp = int(Math.floor(int(barcode.charAt(6+shift))/2).toString()+barcode.charAt(5+shift)+barcode.charAt(4+shift));
	
						//ST
						tmpst = int(barcode.charAt(5+shift)) + 7;
						if(tmpst > 11){
							tmpst = tmpst - 10;
						}
						tmpst2 = int(barcode.charAt(4+shift)) + 5 % 10;
						if(tmpst2 >= 10){
							tmpst2 = tmpst2 - 10;
						}
						barcode_data.st = int(tmpst.toString()+tmpst2.toString());
						
						//DF
						tmpdf = int(barcode.charAt(4+shift))+7;
						if(tmpdf >= 10){
							tmpdf = tmpdf - 10;
						}
						tmpdf2  = int(barcode.charAt(3+shift))+7;
						if(tmpdf2 >= 10){
							tmpdf2 = tmpdf2 - 10;
						}
						barcode_data.df = int(tmpdf.toString()+ tmpdf2.toString());
	
						//Speed
						barcode_data.speed = int(barcode.charAt(5));
	
						//job
						barcode_data.job = 4;

	
						//PP
						barcode_data.pp = 5;
	
						//MP
						barcode_data.mp = 0;
	
					//STアイテム
					}else if(barcode_data.race >=5 && barcode_data.race <= 6){
	
						if(int(barcode.charAt(5)) >= 5 && int(barcode.charAt(5)) <= 8){
							barcode_data.st = int("1"+((int(barcode.charAt(4))+5)%10).toString());
						}else if(int(barcode.charAt(5)) == 3 || int(barcode.charAt(5)) == 4){
							barcode_data.st = int("3"+((int(barcode.charAt(4))+5)%10).toString());
						}else{
							barcode_data.st = int("2"+((int(barcode.charAt(4))+5)%10).toString()); 
						}
	
					//DFアイテム
					}else if(barcode_data.race >=7 && barcode_data.race <= 8){
	
						if(int(barcode.charAt(4)) >= 3 && int(barcode.charAt(4)) <= 6){
							barcode_data.df =int((int(barcode.charAt(3))+7)%10); 
						}else if(int(barcode.charAt(4)) == 1 || int(barcode.charAt(4)) == 2){
							barcode_data.df = int("2"+((int(barcode.charAt(3))+7)%10).toString());
						}else{
							barcode_data.df = int("1"+((int(barcode.charAt(3))+7)%10).toString());
						}
					//HPアイテム
					}else{
						//HPアイテムの種類判別用
						barcode_data.job = 0;
						barcode_data.hp = int(Math.floor(int(barcode.charAt(6))/8)+barcode.charAt(5)+barcode.charAt(4));
					}
					
					//特殊能力
					tmpspecial = int(barcode.charAt(3));
					if(tmpspecial >= 0 && tmpspecial <= 3){
						barcode_data.special = int(barcode.charAt(5));
					}else if(tmpspecial >= 8 && tmpspecial <= 9){
						barcode_data.special = int("2"+barcode.charAt(5));
					}else{
						barcode_data.special = int("1"+barcode.charAt(5));
					}
				}
			}
	
		}
		
	}
	