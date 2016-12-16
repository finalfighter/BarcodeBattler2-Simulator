// ActionScript file
package{
	import flash.utils.getDefinitionByName;
	import flash.utils.getQualifiedClassName;
	
	import flashx.textLayout.tlf_internal;
	
	import mx.core.ClassFactory;
	import mx.utils.ObjectUtil;
	
	public class C1WorldData {
		//合計値
		public var unioncheckdigit:int = 0;
		
		//ステージ
		public var default_stage:Array = new Array("E-1","E-2","E-3","E-4","E-5","E-6");
		public var stage:Array = new Array("E-1","E-2","E-3","E-4","E-5","E-6");
		public var select_stage:int = 0;
		
		//ワールド。LHはキー取得後に追加される
		public var default_world:Array = new Array("L-1","L-2","L-3","L-4","L-5");
		public var world:Array = new Array("L-1","L-2","L-3","L-4","L-5");
		public var select_world:int = 0;
		
		public var default_passcode_number:Array = new Array(
			10,16,24,31,38,45
		);
		
		//敵
		public var default_enemy:Array = new Array(
			//L1
			new Array("01","02","03","04","HH"),
			//L2
			new Array("01","02","03","04","HH"),
			//L3
			new Array("01","02","03","04","HH"),
			//L4
			new Array("01","02","03","04","HH"),
			//L5
			new Array("01","02","03","04","HH"),
			//LH
			new Array("01","02","03","04","HH")
		);
		
		public var enemy:Array = new Array(
			//L1
			new Array("01","02","03","04","HH"),
			//L2
			new Array("01","02","03","04","HH"),
			//L3
			new Array("01","02","03","04","HH"),
			//L4
			new Array("01","02","03","04","HH"),
			//L5
			new Array("01","02","03","04","HH"),
			//LH
			new Array("01","02","03","04","HH")
		);
		
		public var select_enemy:int = 0;
		
		public var default_key:Array = new Array(
			new Array("L1-1","L3-2","L5-3"),
			new Array("L2-2","L4-3","L5-1"),
			new Array("L1-1","L3-2","L5-3"),
			new Array("L2-1","L3-3","L5-4"),
			new Array("L1-4","L2-2","L4-3" )
		);

		public var key:Array   = new Array("L1-1","L3-2","L5-3");

		public var default_race_list:Array = new Array(0,1,2,3,4,4);
		public var default_job_list:Array  = new Array(7,2,8,4,5);
		
		public var default_enemy_paramater:Array = new Array(
			//E1
			new Array(
				//HP
				new Array(
					21,27,33,40,48,56,64,72,81,91
					),
				//ST
				new Array(
					7,8,9,11,12,15,16,18,21,23
					),
				//DF
				new Array(
					9,10,12,14,15,18,20,21,24,27
					),
				//戦闘後回復
				new Array(
					//L1,L2,L3, L4, L5 ,LH
					1,1,1,1,1,2
					),
				//ポインタ
				new Array(
					0,0,4,4,3,3,2,2,1,1
					),
				//ボス撃破後回復HP
				new Array(
					15,18,21,24,27
					)
			),
			//E2
			new Array(
				//HP
				new Array(
					72,81,91,101,111,121,132,144,156,168
				),
				//ST
				new Array(
					18,21,23,26,28,30,33,35,39,41
				),
				//DF
				new Array(
					21,24,27,30,31,34,37,39,43,46
				),
				//戦闘後回復
				new Array(
					//L1,L2,L3, L4, L5 ,LH
					2,2,2,2,2,2
				),
				//ポインタ
				new Array(
					4,4,3,3,2,2,1,1,0,0
				),
				//ボス撃破後回復HP
				new Array(
					36,39,42,45,48
				)
			),
			//E3
			new Array(
				//HP
				new Array(
					144,156,168,180,193,207,221,235,249,264
				),
				//ST
				new Array(
					35,39,41,44,48,51,55,58,61,65
				),
				//DF
				new Array(
					39,43,46,48,51,55,59,61,65,69
				),
				//戦闘後回復
				new Array(
					//L1,L2,L3, L4, L5 ,LH
					3,2,3,3,3,2
				),
				//ポインタ
				new Array(
					4,4,3,3,2,2,1,1,0,0
				),
				//ボス撃破後回復HP
				new Array(
					57,60,63,66,69
				)
			),
			//E4
			new Array(
				//HP
				new Array(
					235,249,264,280,296,312,328,345,363,381
				),
				//ST
				new Array(
					58,61,65,68,73,76,80,85,89,94
				),
				//DF
				new Array(
					61,65,69,72,76,80,83,87,91,96
				),
				//戦闘後回復
				new Array(
					//L1,L2,L3, L4, L5 ,LH
					3,4,3,3,3,4
				),
				//ポインタ
				new Array(
					3,3,4,4,0,0,1,1,2,2
				),
				//ボス撃破後回復HP
				new Array(
					78,81,84,87,90
				)
			),
			//E5
			new Array(
				//HP
				new Array(
					345,363,381,399,417,436,456,476,496,516
				),
				//ST
				new Array(
					85,89,94,98,102,107,111,117,121,126
				),
				//DF
				new Array(
					87,91,96,99,103,108,112,117,121,125
				),
				//戦闘後回復
				new Array(
					//L1,L2,L3, L4, L5 ,LH
					4,4,4,4,4,4
				),
				//ポインタ
				new Array(
					3,3,4,4,0,0,1,1,2,2
				),
				//ボス撃破後回復HP
				new Array(
					99,102,105,108,110
				)
			),
			//E6
			new Array(
				//HP
				new Array(
					476,496,516,537,559,581,603,625,648,672
				),
				//ST
				new Array(
					117,121,126,132,137,143,148,153,159,164
				),
				//DF
				new Array(
					117,121,125,130,135,141,145,150,155,160
				),
				//戦闘後回復
				new Array(
					//L1,L2,L3, L4, L5 ,LH
					4,4,4,4,4,4
				),
				//ポインタ
				new Array(
					2,2,3,3,4,4,0,0,1,1
				),
				//ボス撃破後回復HP
				new Array(
					120,123,126,129,132
				)
			)
		);
		
		public var infomation_flag_a:Boolean=false; //情報カード：５
		public var infomation_flag_b:Boolean=false; //情報かーど：６
		
		
		public function init(checkdigit1:int,checkdigit2:int):void{
			unioncheckdigit = checkdigit1+ checkdigit2;
			if(unioncheckdigit >= 10){
				unioncheckdigit = unioncheckdigit -10;
			}
		}
		
		//該当ワールドのクリアパスコード番号を返す
		public function get_passcode_number(stage_number=null):int{
			if(stage_number === null){
				return default_passcode_number[select_stage];
			}else{
				return default_passcode_number[stage_number];
			}
		}
		
		
		//ワールドを初期化
		public function reset_world():void{
			world = clone(default_world);
			enemy = clone(default_enemy);
			select_enemy = 0;
			reset_key();
		}
		
		//キーを初期化
		public function reset_key():void{
			switch(int(String(world[select_world]).substr(-1,1))){
				//ステージ１
				case 0:
					switch(unioncheckdigit){
						case 0:
						case 1:
							key = clone(default_key[0]);
						break;
						
						case 8:
						case 9:
							key = clone(default_key[1]);
						break;
						
						case 6:
						case 7:
							key = clone(default_key[2]);
						break;
						
						case 4:
						case 5:
							key = clone(default_key[3]);
						break;
						
						case 2:
						case 3:
							key = clone(default_key[4]);
						break;
					}
				break;
				
				//ステージ２
				case 1:
				//ステージ３
				case 2:
					switch(unioncheckdigit){
						case 0:
						case 1:
							key = clone(default_key[4]);
							break;
						
						case 8:
						case 9:
							key = clone(default_key[0]);
							break;
						
						case 6:
						case 7:
							key = clone(default_key[1]);
							break;
						
						case 4:
						case 5:
							key = clone(default_key[2]);
							break;
						
						case 2:
						case 3:
							key = clone(default_key[3]);
							break;
					}
				break;
				


				
				//ステージ４
				case 3:
				//ステージ５
				case 4:
					switch(unioncheckdigit){
						case 0:
						case 1:
							key = clone(default_key[3]);
							break;
						
						case 8:
						case 9:
							key = clone(default_key[4]);
							break;
						
						case 6:
						case 7:
							key = clone(default_key[0]);
							break;
						
						case 4:
						case 5:
							key = clone(default_key[1]);
							break;
						
						case 2:
						case 3:
							key = clone(default_key[2]);
							break;
					}	
				break;

				
				//ステージ6
				case 5:
					switch(unioncheckdigit){
						case 0:
						case 1:
							key = clone(default_key[2]);
							break;
						
						case 8:
						case 9:
							key = clone(default_key[3]);
							break;
						
						case 6:
						case 7:
							key = clone(default_key[4]);
							break;
						
						case 4:
						case 5:
							key = clone(default_key[0]);
							break;
						
						case 2:
						case 3:
							key = clone(default_key[1]);
							break;
					}	
				break;
			}
		}
		
		
		//キーの個数を取得
		public function key_number():int{
			return 3-key.length;
		}
		
		
		//キーを敵に渡す
		public function add_key():void{
			var world_string:String = String(world[select_world]).substr(-1,1); 
			if(world_string =="H"){
				var world_int:int = 5;
			}else{
				var world_int:int = int(world_string) - 1;	
			}
			var enemy_string:String = enemy[world_int][select_enemy];
			if(enemy_string == "HH"){
				var enemy_int:int = 4;
				//L1形式に変換
				var world_enemy:String = "L"+world_string+"-H";
			}else{
				var enemy_int:int = int(enemy_string) - 1;
				//L1-1形式に変換
				var world_enemy:String = "L"+world_string+"-"+ (enemy_int+1).toString();
			}
			
			key.unshift(world_enemy);
			
			
		}
		
		public function infomation_key():String{
			//L1-1
			return String(key[0]);
		}
		
		//キーがあるかどうか
		public function is_key():Boolean{
			var world_string:String = String(world[select_world]).substr(-1,1); 
			if(world_string =="H"){
				var world_int:int = 5;
			}else{
				var world_int:int = int(world_string) - 1;	
			}
			var enemy_string:String = enemy[world_int][select_enemy];
			if(enemy_string == "HH"){
				var enemy_int:int = 4;
				//L1形式に変換
				var world_enemy:String = "L"+world_string;
			}else{
				var enemy_int:int = int(enemy_string) - 1;
				//L1-1形式に変換
				var world_enemy:String = "L"+world_string+"-"+ (enemy_int+1).toString();
			}
			
			for each(var key_string:String in key){
				if(key_string.indexOf(world_enemy) >=0){
					return true;
				}
			}
			
			return false;
			
		}
		
		//キーを削除
		public function delete_key():void{
			var world_string:String = String(world[select_world]).substr(-1,1); 
			if(world_string =="H"){
				var world_int:int = 5;
			}else{
				var world_int:int = int(world_string) - 1;	
			}
			var enemy_string:String = enemy[world_int][select_enemy];
			if(enemy_string == "HH"){
				var enemy_int:int = 4;
				//L1形式に変換
				var world_enemy:String = "L"+world_string;
			}else{
				var enemy_int:int = int(enemy_string) - 1;
				//L1-1形式に変換
				var world_enemy:String = "L"+world_string+"-"+ (enemy_int+1).toString();
			}
			
			var i:int = 0;
			for each(var key_string:String in key){
				var key_index:int = key_string.indexOf(world_enemy);
				if(key_index >=0){
					key.splice(i,1);	
				}
				i = i+1;
			}
			
		}
		
		//倒した敵を削除
		public function delete_enemy():void{
			var world_string:String = String(world[select_world]).substr(-1,1); 
			if(world_string =="H"){
				var world_int:int = 5;
			}else{
				var world_int:int = int(world_string) - 1;	
			}
			var enemy_string:String = enemy[world_int][select_enemy];
			if(enemy_string == "HH"){
				//敵を全削除
				enemy[world_int].splice(0,5);
			}else{
				//敵を単一削除
				enemy[world_int].splice(select_enemy,1);
			}
			
		}
		
		//敵のいる最初のワールドをセットする
		public function set_start_world():void{
			for(var i=0; i<=5;i++){
				var enemy_length:int = (enemy[i]).length;
				if(enemy_length > 0){
					select_world = i;
					break;
				}
			}
		}
		
		//そのワールドに敵がいるかどうか
		public function is_world():Boolean{
			var enemy_length:int = (enemy[get_world_number()]).length;
			if(enemy_length == 0){
				return false;
			}
			
			return true;
		}
		
	
		
		public function get_world_number():int{
			var world_string:String = String(world[select_world]).substr(-1,1); 
			if(world_string =="H"){
				var world_int:int = 5;
			}else{
				var world_int:int = int(world_string) - 1;	
			}
			return world_int;
		}
		
		public function get_enemy_number():int{
			var world_int:int = get_world_number();
			var enemy_string:String = enemy[world_int][select_enemy];
			if(enemy_string == "HH"){
				var enemy_int:int = 4;
			}else{
				var enemy_int:int = int(enemy_string) - 1;
			}
			return enemy_int;
		}
		
		//敵番号選択
		public function select_enemy_number():int{
			
			var enemy_length:int = (enemy[get_world_number()]).length
			if(enemy_length == 0){
				return -1;
			}
			
			var enemy_number:int = Math.floor(Math.random() * (enemy_length));
			return enemy_number;
		}
		
		public function generate_enemy_paramater():BarcodeData{
			var barcode_data:BarcodeData = new BarcodeData();
			
			var stage_int:int = int(String(stage[select_stage]).substr(-1,1)) - 1;
			var world_string:String = String(world[select_world]).substr(-1,1);
			if(world_string =="H"){
				var world_int:int = 5;
			}else{
				var world_int:int = int(world_string) - 1;	
			}
			var enemy_string:String = enemy[world_int][select_enemy];
			if(enemy_string == "HH"){
				var enemy_int:int = 4;
			}else{
				var enemy_int:int = int(enemy_string) - 1;
			}
			
			var pointer:int    = default_enemy_paramater[stage_int][4][unioncheckdigit] + world_int;
			while(pointer >= 5){
				pointer = pointer -5;
			}
			
			if(world_string == "H"){
				pointer = enemy_int;
				var hp_array:Array = default_enemy_paramater[stage_int][0].slice(5,10);
				var st_array:Array = default_enemy_paramater[stage_int][1].slice(5,10);
				var df_array:Array = default_enemy_paramater[stage_int][2].slice(5,10);
			}else{
				var hp_array:Array = default_enemy_paramater[stage_int][0].slice((enemy_int),enemy_int+5);
				var st_array:Array = default_enemy_paramater[stage_int][1].slice((enemy_int),enemy_int+5);
				var df_array:Array = default_enemy_paramater[stage_int][2].slice((enemy_int),enemy_int+5);
			}
			
			barcode_data.barcode = "0000000000000";
			barcode_data.hp = hp_array[pointer];
			barcode_data.st = st_array[pointer];
			barcode_data.df = df_array[pointer];
			if(enemy_string == "HH"){
				barcode_data.speed = 6;
			}else{
				barcode_data.speed = 5;
			}
			
			barcode_data.race = default_race_list[world_int];
			barcode_data.job  = default_job_list[enemy_int];
			barcode_data.pp = 5;
			if(barcode_data.job > 6){
				barcode_data.mp = 10;
			}else{
				barcode_data.mp = 0;
			}
			barcode_data.special = 0;
			barcode_data.live    = true;
			
			return barcode_data;
		}
		
		//戦闘後ST、DFを算出する
		public function generate_st_df():int{
			var stage_int:int = int(String(stage[select_stage]).substr(-1,1)) - 1;
			var world_string:String = String(world[select_world]).substr(-1,1); 
			if(world_string =="H"){
				var world_int:int = 5;
			}else{
				var world_int:int = int(world_string) - 1;	
			}
			
			var pointer:int    = default_enemy_paramater[stage_int][4][unioncheckdigit] + world_int;
			while(pointer >= 5){
				pointer = pointer -5;
			}
			
			//Hのとき、ポインタは特別に5とする
			if(world_int == 5){
				pointer = 5;
			}
			
			var energy_stdf:Array = default_enemy_paramater[stage_int][3];
			return energy_stdf[pointer];
		}
		
		//ボスの戦闘後HPを算出する
		public function generate_boss_energy():int{
			var stage_int:int = int(String(stage[select_stage]).substr(-1,1)) - 1;
			var world_string:String = String(world[select_world]).substr(-1,1); 
			if(world_string =="H"){
				var world_int:int = 5;
			}else{
				var world_int:int = int(world_string) - 1;	
			}
			var enemy_string:String = enemy[world_int][select_enemy];
			if(enemy_string != "HH"){
				return -1;
			}
			
			var pointer:int    = default_enemy_paramater[stage_int][4][unioncheckdigit] + world_int;
			while(pointer >= 5){
				pointer = pointer -5;
			}
			
			var energy_array:Array = default_enemy_paramater[stage_int][5];
			return energy_array[pointer];
		}
		
		
		
		
		//パワーアップするパスコードのチェック
		public function c1_powerup_passcode(passcode:String):Boolean{
			switch(passcode){
				case "815":
				case "031":
				case "009":
				case "099":
				case "077":
					return true;
				break;
				
				default:
					return false;
			}
		}
		
		public function generate_passcode_barcode_data(barcode_data:BarcodeData,passcode:String):BarcodeData{
			switch(passcode){
				case "815":
					barcode_data.hp = Math.floor(barcode_data.hp*1.4)+4;
					barcode_data.st = Math.floor(barcode_data.st*13/9);
					barcode_data.df = Math.floor(barcode_data.df*16/12);
				break;	
					
				case "031":
					barcode_data.hp = Math.floor(barcode_data.hp*1.6)+9;
					barcode_data.st = Math.floor(barcode_data.st*15/9)+1;
					barcode_data.df = Math.floor(barcode_data.df*18/12)+1;
				break;	
				
				case "009":
					barcode_data.hp = Math.floor(barcode_data.hp*1.7)+12;
					barcode_data.st = Math.floor(barcode_data.st*16/9)+1;
					barcode_data.df = Math.floor(barcode_data.df*19/12)+2;
				break;	
					
				case "099":
					barcode_data.hp = Math.floor(barcode_data.hp*1.8)+16;
					barcode_data.st = Math.floor(barcode_data.st*17/9)+2;
					barcode_data.df = Math.floor(barcode_data.df*20/12)+3;
				break;	
					
				case "077":
					barcode_data.hp = Math.floor(barcode_data.hp*1.9)+20;
					barcode_data.st = Math.floor(barcode_data.st*18/9)+3;
					barcode_data.df = Math.floor(barcode_data.df*21/12)+4;
				break;
			}
			
			return barcode_data;
		}
		
		
		//ジャンプパスコードチェック
		public function jump_stage_passcode(passcode:String):Boolean{
			if(passcode.charAt(0)+passcode.charAt(1)=="31"){
				var passcode_checkdigit:int = 1+unioncheckdigit;
			}else if(passcode.charAt(0)+passcode.charAt(1)=="38"){
				passcode_checkdigit = 0+unioncheckdigit;			
			}else{
				return false;
			}
			
			if(passcode_checkdigit > 9){
				passcode_checkdigit = passcode_checkdigit - 10;
			}

			//チェックデジットが一致
			if(passcode.charAt(2) == passcode_checkdigit.toString()){  
				return true;
			}
			
			return false;
		}
		
		
		public  function createCloneInstanceInt(pobjInstance:*):*
		{	
			if(pobjInstance == null){
				return null;
			}
			
			var className:String = getQualifiedClassName(pobjInstance);
			var clazz:Class = getDefinitionByName(className) as Class;
			
			var o:Object = ObjectUtil.getClassInfo(pobjInstance);
			var ins:* = new ClassFactory(clazz).newInstance();
			
			for each (var q:* in o.properties)
			{
				try
				{
						ins[q] = pobjInstance[q];
				}
				catch (e:Error)
				{
					//privateのものはｾｯﾄできないためとりあえずtry catchで除外
				}
			}
			return ins;
		}

		import flash.utils.ByteArray; 
		
		function clone(source:Object):* 
		{ 
			var myBA:ByteArray = new ByteArray(); 
			myBA.writeObject(source); 
			myBA.position = 0; 
			return(myBA.readObject()); 
		}
		
	}
}