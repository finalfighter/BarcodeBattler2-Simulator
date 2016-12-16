// ActionScript file
package{
	import flash.media.Sound;
	
	public class SoundEffect{

		[Embed(source='se/battle_critical.mp3')]	
		private static const BattleCritical:Class;           
		public var battle_critical_mp3:Sound = new BattleCritical(); 		
		
		[Embed(source='se/critical.mp3')]	
		private static const Critical:Class;           
		public var critical_mp3:Sound = new Critical();
		
		[Embed(source='se/battle_end.mp3')]
		private static const BattleEnd:Class;
		public var battle_end_mp3:Sound = new BattleEnd();
		
		[Embed(source='se/battle_end_c2.mp3')]
		private static const BattleEndC2:Class;
		public var battle_end_c2_mp3:Sound = new BattleEndC2();
		
		[Embed(source='se/battle_miss.mp3')]
		private static const BattleMiss:Class;
		public var battle_miss_mp3:Sound = new BattleMiss();
		
		[Embed(source='se/battle.mp3')]
		private static const Battle:Class;
		public var battle_mp3:Sound = new Battle();		
		
		[Embed(source='se/card_in_error.mp3')]
		private static const CardInError:Class;
		public var card_in_error_mp3:Sound = new CardInError();
		
		[Embed(source='se/card_in_power.mp3')]
		private static const CardIn:Class;
		public var card_in_mp3:Sound = new CardIn();
		
		[Embed(source='se/card_in_power.mp3')]
		private static const Power:Class;
		public var power_mp3:Sound = new Power();
		
		[Embed(source='se/change.mp3')]
		private static const Change:Class;
		public var change_mp3:Sound = new Change();
		
		[Embed(source='se/decide_first_player.mp3')]
		private static const DecideFirstPlayer:Class;
		public var decide_first_player_mp3:Sound = new DecideFirstPlayer();			
		
		[Embed(source='se/decide.mp3')]
		private static const Decide:Class;
		public var decide_mp3:Sound = new Decide();
		
		[Embed(source='se/miss.mp3')]
		private static const Miss:Class;
		public var miss_mp3:Sound = new Miss();		
		
		[Embed(source='se/on.mp3')]
		private static const On:Class;
		public var on_mp3:Sound = new On();
		
		[Embed(source='se/select.mp3')]
		private static const Select:Class;
		public var select_mp3:Sound = new Select();
		
		[Embed(source='se/status_down.mp3')]
		private static const StatusDown:Class;
		public var status_down_mp3:Sound = new StatusDown();
		
		[Embed(source='se/passcode.mp3')]
		private static const PassCode:Class;
		public var passcode_mp3:Sound = new PassCode();
		
	}
}