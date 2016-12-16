
import com.google.zxing.common.zxingByteArray;

import flash.display.StageScaleMode;
import flash.events.Event;
import flash.events.MouseEvent;
import flash.events.TimerEvent;
import flash.media.SoundTransform;
import flash.net.registerClassAlias;
import flash.utils.ByteArray;
import flash.utils.Timer;
import flash.utils.getDefinitionByName;
import flash.utils.getQualifiedClassName;

import mx.core.ClassFactory;
import mx.utils.ObjectUtil;

import org.osmf.events.TimeEvent;

private var bb2_state:int = -1;
//0:電源投入前
//1:電源投入
//2:電源投入処理終了
//3:C0モード選択
//4:1Pカード入力前
//5:1Pカード入力終了
//6:2Pカード入力終了
//7:1Pカード入力終了
//8:2Pカード入力終了

//音声
public var se:SoundEffect = new SoundEffect();

private function init_bb2():void{
	
	change_scale_button.addEventListener(MouseEvent.CLICK,change_scale);
	
	card_in.enabled = false;
	card_in_button.enabled = false;
	init_card_reader_button.enabled = false;
	scale_load();
	sound_mute_load();
	sound_off.addEventListener(MouseEvent.CLICK,change_mute_load);
	power_off(new MouseEvent(MouseEvent.CLICK));
	init_card_reader_button.addEventListener(MouseEvent.CLICK , init_card_reader);
	init_card_reader(new MouseEvent(MouseEvent.CLICK));
	card_reader_visible = true;
	barcode_reader_init();
	barcode_cards_init();
}

private function scale_load():void{
	var bb2_simulator:SharedObject = SharedObject.getLocal("bb2_simulator");
	if(bb2_simulator.data.scale == undefined){
		this.scaleX = 0.5;
		this.scaleY = 0.5;
		bb2_simulator.data.scale = 0.5;
	}else{
		if(bb2_simulator.data.scale >= 0.5){
			this.scaleX = bb2_simulator.data.scale;
			this.scaleY = bb2_simulator.data.scale;
		}else{
			this.scaleX = 0.5;
			this.scaleY = 0.5;
			bb2_simulator.data.scale = this.scaleX;
		}
	}
}

private function change_scale(event:MouseEvent):void{
	
	var bb2_simulator:SharedObject = SharedObject.getLocal("bb2_simulator");
	if(this.scaleX == 0.5){
		this.scaleX = 1.0;
		this.scaleY = 1.0;
	}else{
		this.scaleX = 0.5;
		this.scaleY = 0.5;
	}
	bb2_simulator.data.scale = this.scaleX;
}

private var sound_mute:Boolean = false;
private function sound_mute_load():void{
	var bb2_simulator:SharedObject = SharedObject.getLocal("bb2_simulator");
	if(bb2_simulator.data.sound_mute == undefined){
		SoundMixer.soundTransform = new SoundTransform(1.0);
		bb2_simulator.data.sound_mute = false;
		sound_mute = false
		sound_off.alpha = 0;
	}else{
		if(bb2_simulator.data.sound_mute){
			//ボリュームゼロ
			SoundMixer.soundTransform = new SoundTransform(0);
			sound_mute = true;
			sound_off.alpha = 1;
		}else{
			//ボリューム1
			SoundMixer.soundTransform = new SoundTransform(1.0);
			sound_mute = false;
			sound_off.alpha = 0;
		}
	}
}

private function change_mute_load(event:MouseEvent):void{
	var bb2_simulator:SharedObject = SharedObject.getLocal("bb2_simulator");
	if(sound_mute){
		SoundMixer.soundTransform = new SoundTransform(1.0);
		sound_mute = false;
		sound_off.alpha = 0;
	}else{
		SoundMixer.soundTransform = new SoundTransform(0);
		sound_mute = true;
		sound_off.alpha = 1;
	}
	bb2_simulator.data.sound_mute = sound_mute;

}




private var card_reader_visible:Boolean;
private function init_card_reader(event:Event):void{
	if(card_reader_visible){
		card_reader_visible = false;
		camera_reader.visible = true;
	}else{
		card_reader_visible = true;
		camera_reader.visible = false;
	}
}

//電源オフ(完全初期化)
private function power_off(event:MouseEvent):void{

	SoundMixer.stopAll();
	
	this.visible=false;
	camera_reader.visible = false;
	
	on_off.removeEventListener(MouseEvent.CLICK,power_off);
	if(power_on_timer){
		power_on_timer.removeEventListener(TimerEvent.TIMER,power_on_animation);
		power_on_timer.stop();
		power_on_timer = null;
	}
	if(select_mode_timer){
		select_mode_timer.removeEventListener(TimerEvent.TIMER,power_on_animation);
		select_mode_timer.stop();
		select_mode_timer = null;
	}
	select_button.removeEventListener(MouseEvent.CLICK,inc_mode);
	set_button.removeEventListener(MouseEvent.CLICK,set_mode);
	if(decide_star_timer){
		decide_star_timer.removeEventListener(TimerEvent.TIMER,decide_star_animation);
		decide_star_timer.removeEventListener(TimerEvent.TIMER_COMPLETE,mode_start);
		decide_star_timer.stop();
		decide_star_timer= null;		
	}
	if(card_insert_wait_timer){
		card_insert_wait_timer.removeEventListener(TimerEvent.TIMER,card_insert_wait_animation);
		card_insert_wait_timer.stop();
		card_insert_wait_timer = null;
	}
	if(card_insert_timer){
		card_insert_timer.removeEventListener(TimerEvent.TIMER,card_insert_animation);
		card_insert_timer.removeEventListener(TimerEvent.TIMER_COMPLETE,card_insert_next);
		card_insert_timer.stop();
		card_insert_timer = null;
	}
	if(card_insert_error_timer){
		card_insert_error_timer.removeEventListener(TimerEvent.TIMER,card_insert_error_animation);
		card_insert_error_timer.removeEventListener(TimerEvent.TIMER_COMPLETE,card_insert_error_back);
		card_insert_error_timer.removeEventListener(TimerEvent.TIMER_COMPLETE,card_insert_error_back_c2);
		card_insert_error_timer.stop();
		card_insert_error_timer = null;
	}
	if(card_skip_timer){
		card_skip_timer.removeEventListener(TimerEvent.TIMER,card_skip_animation);
		card_skip_timer.removeEventListener(TimerEvent.TIMER_COMPLETE,card_insert_next);
		card_skip_timer.stop();
		card_skip_timer = null;
	}
	if(decide_first_timer){
		decide_first_timer.removeEventListener(TimerEvent.TIMER,decide_first_player_animation);
		decide_first_timer.removeEventListener(TimerEvent.TIMER_COMPLETE,battle_waiting);
		decide_first_timer.stop();
		decide_first_timer = null;
	}
	if(special_down_timer){
		special_down_timer.removeEventListener(TimerEvent.TIMER,special_down_animation);
		special_down_timer.removeEventListener(TimerEvent.TIMER_COMPLETE,special_down_complete);
		special_down_timer.stop();
		special_down_timer = null;
	}

	if(battle_waiting_timer){
		battle_waiting_timer.removeEventListener(TimerEvent.TIMER,battle_power_animation);
		battle_waiting_timer.stop();
		battle_waiting_timer = null;
	}
	
	if(battle_timer){
		battle_timer.removeEventListener(TimerEvent.TIMER,battle_animation);
		battle_timer.removeEventListener(TimerEvent.TIMER_COMPLETE,battle_complete);
		battle_timer.removeEventListener(TimerEvent.TIMER_COMPLETE,f1_complete);
		battle_timer.removeEventListener(TimerEvent.TIMER_COMPLETE,f2_complete)
		battle_timer.stop();
		battle_timer = null;
	}
	if(item_broke_animation_timer){
		item_broke_animation_timer.removeEventListener(TimerEvent.TIMER,item_broke_animation);
		item_broke_animation_timer.removeEventListener(TimerEvent.TIMER_COMPLETE,battle_complete);
		item_broke_animation_timer.stop();
		item_broke_animation_timer = null;
	}
	if(battle_end_animation_timer){
		battle_end_animation_timer.removeEventListener(TimerEvent.TIMER,battle_end_animation);
		battle_end_animation_timer.removeEventListener(TimerEvent.TIMER_COMPLETE,battle_end);
		battle_end_animation_timer.stop();
		battle_end_animation_timer = null;
	}	
	if(end_text_animation_timer){
		end_text_animation_timer.removeEventListener(TimerEvent.TIMER,end_text_animation);
		end_text_animation_timer.stop();
		end_text_animation_timer = null;
	}
	if(power_timer){
		power_timer.removeEventListener(TimerEvent.TIMER,power_animation);
		power_timer.removeEventListener(TimerEvent.TIMER_COMPLETE,power_complete);
		power_timer.stop();
		power_timer = null;
	}
	if(select_animation_timer){
		select_animation_timer.removeEventListener(TimerEvent.TIMER,select_animation);
		select_animation_timer.stop();
		select_animation_timer = null;
	}
	
	if(use_pp_animation_timer){
		use_pp_animation_timer.removeEventListener(TimerEvent.TIMER,use_pp_animation);
		use_pp_animation_timer.removeEventListener(TimerEvent.TIMER,use_pp_complete);
		use_pp_animation_timer.removeEventListener(TimerEvent.TIMER_COMPLETE,f3_complete);
		use_pp_animation_timer.removeEventListener(TimerEvent.TIMER_COMPLETE,f4_complete);
		use_pp_animation_timer.stop();
		use_pp_animation_timer = null;
	}
	if(f0_animation_timer){
		f0_animation_timer.removeEventListener(TimerEvent.TIMER,f0_animation);
		f0_animation_timer.removeEventListener(TimerEvent.TIMER_COMPLETE,f0_complete);
		f0_animation_timer.stop();
		f0_animation_timer = null;
	}
	if(f5_animation_timer){
		f5_animation_timer.removeEventListener(TimerEvent.TIMER,f5_animation);
		f5_animation_timer.removeEventListener(TimerEvent.TIMER_COMPLETE,f5_complete);
		f5_animation_timer.stop();
		f5_animation_timer = null;
	}
	if(f6_animation_timer){
		f6_animation_timer.removeEventListener(TimerEvent.TIMER,f6_animation);
		f6_animation_timer.removeEventListener(TimerEvent.TIMER_COMPLETE,f6_complete);
		f6_animation_timer.stop();
		f6_animation_timer = null;
	}
	if(f7_animation_timer){
		f7_animation_timer.removeEventListener(TimerEvent.TIMER,f7_animation);
		f7_animation_timer.removeEventListener(TimerEvent.TIMER_COMPLETE,f7_complete);
		f7_animation_timer.stop();
		f7_animation_timer = null;
	}
	if(f8_animation_timer){
		f8_animation_timer.removeEventListener(TimerEvent.TIMER,f8_animation);
		f8_animation_timer.removeEventListener(TimerEvent.TIMER_COMPLETE,f8_complete);
		f8_animation_timer.stop();
		f8_animation_timer = null;
	}
	if(card_insert_wait_c2_timer){
		card_insert_wait_c2_timer.removeEventListener(TimerEvent.TIMER,card_insert_wait_animation_c2);
		card_insert_wait_c2_timer.stop();
		card_insert_wait_c2_timer = null;
	}
	
	if(card_insert_c2_timer){
		card_insert_c2_timer.removeEventListener(TimerEvent.TIMER,card_insert_animation);
		card_insert_c2_timer.removeEventListener(TimerEvent.TIMER_COMPLETE,card_insert_next_c2);
		card_insert_c2_timer.stop();
		card_insert_c2_timer = null;
	}
	
	if(card_insert_error_c2_timer){
		card_insert_error_c2_timer.removeEventListener(TimerEvent.TIMER,card_insert_error_animation_c2);
		card_insert_error_c2_timer.removeEventListener(TimerEvent.TIMER_COMPLETE,card_insert_error_back_c2);
		card_insert_error_c2_timer.stop();
		card_insert_error_c2_timer = null;
	}
	
	if(passcode_wait_c2_timer){
		passcode_wait_c2_timer.removeEventListener(TimerEvent.TIMER,passcode_wait_animation_c2);
		passcode_wait_c2_timer.stop();
		passcode_wait_c2_timer = null;
	}
	
	if(passcode_power_up_c2_timer){
		passcode_power_up_c2_timer.removeEventListener(TimerEvent.TIMER,passcode_power_up_animation_c2);
		passcode_power_up_c2_timer.removeEventListener(TimerEvent.TIMER_COMPLETE,card_enemy_insert_wait_c2);
		passcode_power_up_c2_timer.stop();
		passcode_power_up_c2_timer = null;
	}
	
	if(friend_select_animation_timer){
		friend_select_animation_timer.removeEventListener(TimerEvent.TIMER,friend_select_animation_c2);
		friend_select_animation_timer.removeEventListener(TimerEvent.TIMER_COMPLETE,friend_animation_c2_complete);
		friend_select_animation_timer.stop();
		friend_select_animation_timer = null;
	}
	if(auto_battle_timer){
		auto_battle_timer.removeEventListener(TimerEvent.TIMER_COMPLETE,auto_battle_cpu);
		auto_battle_timer.stop();
		auto_battle_timer = null;
	}
	if(set_friend_item_timer){
		set_friend_item_timer.removeEventListener(TimerEvent.TIMER,set_friend_item_animation);
		set_friend_item_timer.stop();
		set_friend_item_timer = null;
	}
	if(card_enemy_insert_wait_c2_timer){
		card_enemy_insert_wait_c2_timer.removeEventListener(TimerEvent.TIMER,card_enemy_insert_wait_animation_c2);
		card_enemy_insert_wait_c2_timer.stop();
		card_enemy_insert_wait_c2_timer = null;
	}
	if(battle_get_animation_timer){
		battle_get_animation_timer.removeEventListener(TimerEvent.TIMER,battle_get_animation_c1);
		battle_get_animation_timer.removeEventListener(TimerEvent.TIMER,battle_get_animation_c2);
		battle_get_animation_timer.stop();
		battle_get_animation_timer = null;
	}
	if(display_mp_pp_timer){
		display_mp_pp_timer.removeEventListener(TimerEvent.TIMER,display_mp_pp);
		display_mp_pp_timer.removeEventListener(TimerEvent.TIMER_COMPLETE,card_enemy_insert_wait_c2_se);
		display_mp_pp_timer.stop();
		display_mp_pp_timer = null;
	}
	if(battle_end_animation_timer){
		battle_end_animation_timer.removeEventListener(TimerEvent.TIMER,battle_end_animation);
		battle_end_animation_timer.removeEventListener(TimerEvent.TIMER_COMPLETE,battle_end);
		battle_end_animation_timer.removeEventListener(TimerEvent.TIMER_COMPLETE,battle_end_c1);
		battle_end_animation_timer.removeEventListener(TimerEvent.TIMER_COMPLETE,battle_end_c2);
		battle_end_animation_timer.stop();
		battle_end_animation_timer =  null;
	}
	if(escape_from_battle_animation_timer){
		escape_from_battle_animation_timer.removeEventListener(TimerEvent.TIMER,escape_from_battle_animation);
		escape_from_battle_animation_timer.removeEventListener(TimerEvent.TIMER_COMPLETE,c1_stage_select_set);
		escape_from_battle_animation_timer.stop();
		escape_from_battle_animation_timer = null;
	}
	if(escape_from_battle_failed_animaton_timer){
		escape_from_battle_failed_animaton_timer.removeEventListener(TimerEvent.TIMER,escape_from_battle_failed_animaton);
		escape_from_battle_failed_animaton_timer.removeEventListener(TimerEvent.TIMER_COMPLETE,escape_failed_battle_waiting);
		escape_from_battle_failed_animaton_timer.stop();
		escape_from_battle_failed_animaton_timer = null;
	}
	if(passcode_power_up_c2_timer){
		passcode_power_up_c2_timer.removeEventListener(TimerEvent.TIMER,passcode_power_up_animation_c2);
		passcode_power_up_c2_timer.removeEventListener(TimerEvent.TIMER_COMPLETE,card_enemy_insert_wait_c2);
		passcode_power_up_c2_timer.stop();
		passcode_power_up_c2_timer = null;
	}
	if(card_enemy_insert_wait_c2_timer){
		card_enemy_insert_wait_c2_timer.removeEventListener(TimerEvent.TIMER,card_enemy_insert_wait_animation_c2);
		card_enemy_insert_wait_c2_timer.stop();
		card_enemy_insert_wait_c2_timer=null;
	}
	if(passcode_wait_c2_timer){
		passcode_wait_c2_timer.removeEventListener(TimerEvent.TIMER,passcode_wait_animation_c2);
		passcode_wait_c2_timer.stop();
		passcode_wait_c2_timer = null;
	}
	if(select_stage_enemy_animation_timer){
		select_stage_enemy_animation_timer.removeEventListener(TimerEvent.TIMER,stage_enemy_animation);
		select_stage_enemy_animation_timer.stop();
		select_stage_enemy_animation_timer = null;
	}
	if(card_insert_wait_c1_timer){
		card_insert_wait_c1_timer.removeEventListener(TimerEvent.TIMER,card_insert_wait_animation_c1);
		card_insert_wait_c1_timer.stop();
		card_insert_wait_c1_timer = null;
	}
	if(load_status_animation_timer){
		load_status_animation_timer.removeEventListener(TimerEvent.TIMER,load_status_animation);
		load_status_animation_timer.removeEventListener(TimerEvent.TIMER_COMPLETE,card_insert_next_c1);
		load_status_animation_timer.stop();
		load_status_animation_timer = null;
	}
	if(card_insert_error_c1_timer){
		card_insert_error_c1_timer.removeEventListener(TimerEvent.TIMER,card_insert_error_animation_c1);
		card_insert_error_c1_timer.removeEventListener(TimerEvent.TIMER_COMPLETE,card_insert_error_back_c1);
		card_insert_error_c1_timer.stop();
		card_insert_error_c1_timer = null;
	}
	if(c1_passcode_error_animation_timer){
		c1_passcode_error_animation_timer.removeEventListener(TimerEvent.TIMER,c1_passcode_error_animation);
		c1_passcode_error_animation_timer.removeEventListener(TimerEvent.TIMER_COMPLETE,c1_stage_select_click);
		c1_passcode_error_animation_timer.stop();
		c1_passcode_error_animation_timer = null;
	}
	if(display_mp_pp_c1_timer){
		display_mp_pp_c1_timer.removeEventListener(TimerEvent.TIMER,display_mp_pp_c1);
		display_mp_pp_c1_timer.removeEventListener(TimerEvent.TIMER_COMPLETE,c1_stage_select_click);
		display_mp_pp_c1_timer.stop();
		display_mp_pp_c1_timer = null;
	}
	if(escape_from_battle_animation_timer){
		escape_from_battle_animation_timer.removeEventListener(TimerEvent.TIMER,escape_from_battle_animation);
		escape_from_battle_animation_timer.removeEventListener(TimerEvent.TIMER_COMPLETE,c1_stage_select_click);
		escape_from_battle_animation_timer.stop();
		escape_from_battle_animation_timer = null;
	}
	if(call_enemy_animation_timer){
		call_enemy_animation_timer.removeEventListener(TimerEvent.TIMER,call_enemy_animation);
		call_enemy_animation_timer.removeEventListener(TimerEvent.TIMER_COMPLETE,appear_enemy);
		call_enemy_animation_timer.stop();
		call_enemy_animation_timer = null;
	}
	if(appear_enemy_timer){
		appear_enemy_timer.removeEventListener(TimerEvent.TIMER,appear_enemy_animation_c1);
		appear_enemy_timer.removeEventListener(TimerEvent.TIMER_COMPLETE,select_friend_c1);
		appear_enemy_timer.stop();
		appear_enemy_timer = null;
	}
	if(friend_select_animation_c1_timer){
		friend_select_animation_c1_timer.removeEventListener(TimerEvent.TIMER,friend_select_animation_c1);
		friend_select_animation_c1_timer.removeEventListener(TimerEvent.TIMER_COMPLETE,friend_animation_c1_complete);
		friend_select_animation_c1_timer.stop();
		friend_select_animation_c1_timer = null;
	}
	if(escape_from_battle_failed_animaton_timer){
		escape_from_battle_failed_animaton_timer.removeEventListener(TimerEvent.TIMER,escape_from_battle_failed_animaton);
		escape_from_battle_failed_animaton_timer.removeEventListener(TimerEvent.TIMER,escape_from_battle_failed_animaton_complete);
		escape_from_battle_failed_animaton_timer.stop();
		escape_from_battle_failed_animaton_timer = null;
	}
	if(set_friend_item_c1_timer){
		set_friend_item_c1_timer.removeEventListener(TimerEvent.TIMER,set_friend_item_animation_c1);
		set_friend_item_c1_timer.stop();
		set_friend_item_c1_timer = null;
	}
	if(passcode_power_up_c1_timer){
		passcode_power_up_c1_timer.removeEventListener(TimerEvent.TIMER,passcode_power_up_animation_c1);
		passcode_power_up_c1_timer.removeEventListener(TimerEvent.TIMER_COMPLETE,passcode_power_up_complete);
		passcode_power_up_c1_timer.stop();
		passcode_power_up_c1_timer = null;
	}
	
	if(c1_passcode_error_animation_timer){
		c1_passcode_error_animation_timer.removeEventListener(TimerEvent.TIMER,c1_passcode_error_animation);
		c1_passcode_error_animation_timer.removeEventListener(TimerEvent.TIMER_COMPLETE,c1_stage_select_click);
		c1_passcode_error_animation_timer.stop();
		c1_passcode_error_animation_timer = null;
	}	
	if(get_key_animation_timer){
		get_key_animation_timer.removeEventListener(TimerEvent.TIMER,get_key_animation);
		get_key_animation_timer.removeEventListener(TimerEvent.TIMER_COMPLETE,battle_end_c1);
		get_key_animation_timer.stop();
		get_key_animation_timer = null;
	}
	if(save_animation_timer){
		save_animation_timer.removeEventListener(TimerEvent.TIMER,save_animation);
		save_animation_timer.stop();
		save_animation_timer = null;
	}
	if(load_animation_timer){
		load_animation_timer.removeEventListener(TimerEvent.TIMER,load_animation);
		load_animation_timer.stop();
		load_animation_timer = null;
	}
	if(load_status_animation_timer){
		load_status_animation_timer.removeEventListener(TimerEvent.TIMER,load_status_animation);
		load_status_animation_timer.removeEventListener(TimerEvent.TIMER_COMPLETE,card_insert_next_c1);
		load_status_animation_timer.stop();
		load_status_animation_timer = null;
	}
	if(rebirth_animation_timer){
		rebirth_animation_timer.removeEventListener(TimerEvent.TIMER,rebirth_animation);
		rebirth_animation_timer.removeEventListener(TimerEvent.TIMER_COMPLETE,rebirth_end);
		rebirth_animation_timer.stop();
		rebirth_animation_timer = null;
	}
	if(enemy_infomation_animation_timer){
		enemy_infomation_animation_timer.removeEventListener(TimerEvent.TIMER,enemy_infomaiton);
		enemy_infomation_animation_timer.removeEventListener(TimerEvent.TIMER_COMPLETE,rebirth_end);
		enemy_infomation_animation_timer.stop();
	}
	
	if(defeat_boss_animation_timer){
		defeat_boss_animation_timer.removeEventListener(TimerEvent.TIMER,defeat_boss_animation);
		defeat_boss_animation_timer.stop();
		defeat_boss_animation_timer = null;
	}	
		
	on_off.removeEventListener(MouseEvent.CLICK,power_on);
	on_off.removeEventListener(MouseEvent.CLICK,power_off);
	select_button.removeEventListener(MouseEvent.CLICK,inc_mode);
	set_button.removeEventListener(MouseEvent.CLICK,set_mode);
	card_in_button.removeEventListener(MouseEvent.CLICK,card_insert);
	card_in_button.removeEventListener(MouseEvent.CLICK,card_insert_c2);
	card_in_button.removeEventListener(MouseEvent.CLICK,card_enemy_insert_c2);
	card_in_button.removeEventListener(MouseEvent.CLICK,card_item_insert_c2);
	set_button.removeEventListener(MouseEvent.CLICK,card_skip);
	l_battle.removeEventListener(MouseEvent.CLICK,battle);
	r_battle.removeEventListener(MouseEvent.CLICK,battle);
	set_button.removeEventListener(MouseEvent.CLICK,restart_mode);	
	select_button.removeEventListener(MouseEvent.CLICK,select);
	select_button.removeEventListener(MouseEvent.CLICK,select_state);
	set_button.removeEventListener(MouseEvent.CLICK,set_state);
	l_battle.removeEventListener(MouseEvent.CLICK,value_shift);
	l_power.removeEventListener(MouseEvent.CLICK,value_shift);
	r_battle.removeEventListener(MouseEvent.CLICK,value_shift);
	l_battle.removeEventListener(MouseEvent.CLICK,value_shift);
	set_button.removeEventListener(MouseEvent.CLICK,card_enemy_insert_wait_c2);	
	l_power.removeEventListener(MouseEvent.CLICK,select_passcode);
	select_button.removeEventListener(MouseEvent.CLICK,add_passcode);
	set_button.removeEventListener(MouseEvent.CLICK,set_passcode);
	select_button.removeEventListener(MouseEvent.CLICK,add_friend_state);
	set_button.removeEventListener(MouseEvent.CLICK,set_friend_state);
	set_button.removeEventListener(MouseEvent.CLICK,card_insert_next_set_c2);
	set_button.removeEventListener(MouseEvent.CLICK,card_enemy_insert_wait_c2_se);	
	select_button.removeEventListener(MouseEvent.CLICK,select_end_state);
	set_button.removeEventListener(MouseEvent.CLICK,get_mp_pp);
	set_button.removeEventListener(MouseEvent.CLICK,get_mp_pp_c1);
	r_power.removeEventListener(MouseEvent.CLICK,escape);
	set_button.removeEventListener(MouseEvent.CLICK,card_insert_wait_c2_back);
	select_button.removeEventListener(MouseEvent.CLICK,card_insert_wait_c2);
	l_power.removeEventListener(MouseEvent.CLICK,battle_end_l_power);
	r_battle.removeEventListener(MouseEvent.CLICK,save);
	l_power.removeEventListener(MouseEvent.MOUSE_UP,battle_end_c2);
	l_power.removeEventListener(MouseEvent.MOUSE_OUT,battle_end_c2);
	l_power.removeEventListener(MouseEvent.MOUSE_UP,battle_end_c1);
	l_power.removeEventListener(MouseEvent.MOUSE_OUT,battle_end_c1);
	l_power.removeEventListener(MouseEvent.CLICK,show_passcode);
	select_button.removeEventListener(MouseEvent.CLICK,c1_stage_enemy_select);
	set_button.removeEventListener(MouseEvent.CLICK,c1_stage_enemy_set);
	l_power.removeEventListener(MouseEvent.CLICK,card_insert_retry_c1);
	l_battle.removeEventListener(MouseEvent.CLICK,c1_input_passcode);
	select_button.removeEventListener(MouseEvent.CLICK,card_insert_wait_c1);
	card_in_button.removeEventListener(MouseEvent.CLICK,card_insert_c1);
	r_battle.removeEventListener(MouseEvent.CLICK,load);
	r_power.removeEventListener(MouseEvent.CLICK,escape_from_battle);
	select_button.removeEventListener(MouseEvent.CLICK,add_friend_state_c1);
	set_button.removeEventListener(MouseEvent.CLICK,card_insert_wait_c1_back);
	select_button.removeEventListener(MouseEvent.CLICK,c1_stage_select_click);
	set_button.removeEventListener(MouseEvent.CLICK,c1_stage_select_click);
	set_button.removeEventListener(MouseEvent.CLICK,set_friend_state_c1);	
	set_button.removeEventListener(MouseEvent.CLICK,card_insert_next_set_c1);
	card_in_button.removeEventListener(MouseEvent.CLICK,card_item_insert_c1);
	select_button.removeEventListener(MouseEvent.CLICK,c1_input_add_passcode);
	set_button.removeEventListener(MouseEvent.CLICK,c1_input_set_passcode);
	set_button.removeEventListener(MouseEvent.CLICK,save_animation_complete);
	set_button.removeEventListener(MouseEvent.CLICK,defeat_boss_animation_complete);
	l_power.removeEventListener(MouseEvent.CLICK,show_passcode_c1);
	l_power.removeEventListener(MouseEvent.MOUSE_UP,defeat_boss);
	l_power.removeEventListener(MouseEvent.MOUSE_OUT,defeat_boss);
	
	mode=0;
	battle_label.visible = false;
	escape_label.visible = false;
	power_label.visible = false;
	card_input_label.visible =false;
	critical_label.visible=false;
	miss_label.visible=false;
	magician_1p_label.visible=false;
	warrior_1p_label.visible=false;
	key_label.visible=false;
	item_label.visible=false;
	infomation_label.visible=false;
	warrior_2p_label.visible=false;
	magician_2p_label.visible=false;
	hp_1p.text="";
	st_1p.text="";
	df_1p.text="";
	hp_2p.text="";
	st_2p.text="";
	df_2p.text="";
	hp_label.visible=false;
	damage_label.visible=false;
	st_label.visible=false;
	mp_label.visible=false;
	df_label.visible=false;
	pp_label.visible=false;
	light1.selected=false;
	light2.selected=false;
	light3.selected=false;
	light4.selected=false;
	light5.selected=false;
	card_in.enabled = false;
	card_in_button.enabled = false;
	init_card_reader_button.enabled = false;
	on_off.addEventListener(MouseEvent.CLICK,power_on);
	bb2_state=0;
	if(c1_world_data){
		c1_world_data = new C1WorldData();
	}
	this.visible=true;
}

//電源オン
private var power_on_timer:Timer;
private function power_on(event:MouseEvent):void{
	se.on_mp3.play();
	on_off.removeEventListener(MouseEvent.CLICK,power_on);
	on_off.addEventListener(MouseEvent.CLICK,power_off);
	power_on_timer = new Timer(150,9);
	power_on_timer.addEventListener(TimerEvent.TIMER,power_on_animation);
	power_on_timer.start();
	power_on_timer.addEventListener(TimerEvent.TIMER_COMPLETE,select_mode);
	bb2_state=1;
}

//電源オンのアニメーション
private function power_on_animation(event:TimerEvent):void{
	var count:int = event.target.currentCount%3;
	
	switch(count){
		case 0:
		hp_1p.text=" 00";
		st_1p.text="";
		df_1p.text="   00";
		hp_2p.text="   00";
		st_2p.text="";
		df_2p.text=" 00";	
		break;
		
		case 1:
		hp_1p.text="";
		st_1p.text=" 0000";
		df_1p.text="";
		hp_2p.text="";
		st_2p.text=" 0000";
		df_2p.text="";
		break;
		
		case 2:
		hp_1p.text="   00";
		st_1p.text="";
		df_1p.text=" 00";
		hp_2p.text=" 00";
		st_2p.text="";
		df_2p.text="   00";
		break;
	}
	
}

//モード選択
private var mode:int = 0;
private var select_mode_timer:Timer;
private function select_mode(event:TimerEvent):void{

	if(power_on_timer){
		power_on_timer.removeEventListener(TimerEvent.TIMER,power_on_animation);
		power_on_timer.stop();
		power_on_timer = null;
	}
	
	hp_1p.text="";
	st_1p.text="";
	df_1p.text="";
	hp_2p.text="";
	st_2p.text="";
	df_2p.text="";
	light3.selected = true;

	select_mode_timer = new Timer(150);
	select_mode_timer.addEventListener(TimerEvent.TIMER,select_mode_animation);
	select_mode_timer.start();
	select_button.addEventListener(MouseEvent.CLICK,inc_mode);
	set_button.addEventListener(MouseEvent.CLICK,set_mode);
	bb2_state=2;
}

//モード選択のアニメーション
private function select_mode_animation(event:TimerEvent):void{
	var count:int = event.target.currentCount;
	//奇数
	if(count%2==1){
		hp_1p.text="";
		st_1p.text="";
		df_1p.text="";
		hp_2p.text="C-"+mode.toString();
		st_2p.text="";
		df_2p.text="";
	//偶数
	}else{
		hp_1p.text="";
		st_1p.text="";
		df_1p.text="";
		hp_2p.text="C-";
		st_2p.text="";
		df_2p.text="";
	}
	
}

//モード加算処理
private function inc_mode(event:MouseEvent):void{
	se.select_mp3.play();
	mode = mode + 1;
	if(mode == 3){
		mode = 0;
	}
}

//モード決定
private function set_mode(event:MouseEvent):void{
	se.decide_mp3.play();
	select_button.removeEventListener(MouseEvent.CLICK,inc_mode);
	set_button.removeEventListener(MouseEvent.CLICK,set_mode);
	if(select_mode_timer){
		select_mode_timer.removeEventListener(TimerEvent.TIMER,select_mode_animation);
		select_mode_timer.stop();
		select_mode_timer = null;
	}
	bb2_state = 3;
	decide_star();
	
}

//守護星決定処理
private var decide_star_timer:Timer;
//守護星
private var protection_star:int;
private var fighting_calc:FightingCalc;
private function decide_star():void{
	if(!fighting_calc){
		fighting_calc = new FightingCalc();
	}
	
	hp_1p.text="";
	st_1p.text="";
	df_1p.text="";
	hp_2p.text="C-"+mode.toString();
	st_2p.text="";
	df_2p.text="";
	
	//守護星決定
	//0 レトフ(陸)110/500
 	//1 セターン(空)256/500
 	//2 ラト(海)134/500
 	fighting_calc.decide_star();
	
	decide_star_timer = new Timer(150,13);
	decide_star_timer.addEventListener(TimerEvent.TIMER,decide_star_animation);
	decide_star_timer.addEventListener(TimerEvent.TIMER_COMPLETE,mode_start);
	decide_star_timer.start();
	
}

//守護星決定アニメーション
private function decide_star_animation(event:TimerEvent):void{
	var count:int = event.target.currentCount%3;
	switch(count){
		case 1:
			light1.selected = false;
			light2.selected = true;
			light3.selected = false;
			light4.selected = false;
			light5.selected = false;
		break;
		case 2:
			light1.selected = false;
			light2.selected = false;
			light3.selected = true;
			light4.selected = false;
			light5.selected = false;
		break;
		case 0:
			light1.selected = false;
			light2.selected = false;
			light3.selected = false;
			light4.selected = true;
			light5.selected = false;
		break;
	}
	
}

private function mode_start(event:TimerEvent):void{
	card_in_button.enabled = true;
	init_card_reader_button.enabled = true;

	
	decide_star_timer.removeEventListener(TimerEvent.TIMER,decide_star_animation);
	decide_star_timer.removeEventListener(TimerEvent.TIMER_COMPLETE,mode_start);
	decide_star_timer.stop();
	decide_star_timer= null;
	
	switch(fighting_calc.protection_star){
		//0 レトフ(陸)
		case 0:
			light1.selected = false;
			light2.selected = true;
			light3.selected = false;
			light4.selected = false;
			light5.selected = false;
		break;
		
 		//1 セターン
 		case 1:
 			light1.selected = false;
			light2.selected = false;
			light3.selected = true;
			light4.selected = false;
			light5.selected = false;
		break;
		
		//2 ラト
		case 2:
		 	light1.selected = false;
			light2.selected = false;
			light3.selected = false;
			light4.selected = true;
			light5.selected = false;
		break;
	}
	
	switch(mode){
		//C0モード
		case 0:
			se.decide_mp3.play();
			bb2_state = bb2_state + 1;
			card_insert_wait();
		break;	
		
		//C1モード
		case 1:
			se.decide_mp3.play();
			bb2_state = bb2_state + 1;
			card_insert_wait_c1();
		break;
		
		//C2モード
		case 2:
			se.decide_mp3.play();
			bb2_state = bb2_state + 1;
			card_insert_wait_c2();
		break;
	}
}


private var card_insert_wait_timer:Timer;
//カード入力待ち
private function card_insert_wait():void{
	if(!card_insert_wait_timer){
		card_insert_wait_timer = new Timer(500);
		card_insert_wait_timer.addEventListener(TimerEvent.TIMER,card_insert_wait_animation);
		card_insert_wait_timer.start();
	}
	
	switch(bb2_state){
		//1枚目
		case 4:
			hp_1p.text=" ==";
			st_1p.text=" ==";
			df_1p.text=" ==";
			hp_2p.text="";
			st_2p.text="";
			df_2p.text="";
			hp_label.visible=true;
			st_label.visible=true;
			df_label.visible=true;
			card_in_button.addEventListener(MouseEvent.CLICK,card_insert);
			select_image_button.addEventListener(MouseEvent.CLICK,select_image);
			get_camera_button.addEventListener(MouseEvent.CLICK,get_camera);
			card_in.enabled = true;
			card_in_button.enabled=true;
			init_card_reader_button.enabled = true;
		break;
		
		//2枚目
		case 5:
			hp_2p.text=" ==";
			st_2p.text=" ==";
			df_2p.text=" ==";
			card_in_button.addEventListener(MouseEvent.CLICK,card_insert);
			select_image_button.addEventListener(MouseEvent.CLICK,select_image);
			get_camera_button.addEventListener(MouseEvent.CLICK,get_camera);
			card_in.enabled = true;
			card_in_button.enabled=true;
			init_card_reader_button.enabled = true;
		break;
		
		//3枚目
		case 6:
			card_in_button.addEventListener(MouseEvent.CLICK,card_insert);
			select_image_button.addEventListener(MouseEvent.CLICK,select_image);
			get_camera_button.addEventListener(MouseEvent.CLICK,get_camera);
			card_in.enabled = true;
			card_in_button.enabled=true;
			init_card_reader_button.enabled = true;
			set_button.addEventListener(MouseEvent.CLICK,card_skip);
			set_button.enabled = true;
		break;
		
		//4枚目
		case 7:
			card_in_button.addEventListener(MouseEvent.CLICK,card_insert);
			select_image_button.addEventListener(MouseEvent.CLICK,select_image);
			get_camera_button.addEventListener(MouseEvent.CLICK,get_camera);
			card_in.enabled = true;
			card_in_button.enabled=true;
			init_card_reader_button.enabled = true;
			set_button.addEventListener(MouseEvent.CLICK,card_skip);
			set_button.enabled = true;
		break;
		
	}	
}

//カード入力待ちアニメーション
private function card_insert_wait_animation(event:TimerEvent):void{
	var count:int = event.target.currentCount%2;	
	switch(bb2_state){
		//1枚目
		case 4:
			if(count == 1){
				card_input_label.visible =false;
				warrior_1p_label.visible =false;
				magician_1p_label.visible =false;
			}else{
				card_input_label.visible =true;
				warrior_1p_label.visible =true;
				magician_1p_label.visible =true;
			}
		break;
		
		//2枚目
		case 5:
			if(count == 1){
				card_input_label.visible =false;
				warrior_2p_label.visible =false;
				magician_2p_label.visible =false;
			}else{
				card_input_label.visible =true;
				warrior_2p_label.visible =true;
				magician_2p_label.visible =true;
			}
		break;
		
		//3枚目
		case 6:
			if(count == 1){
				warrior_1p_label.visible =false;
				magician_1p_label.visible =false;
				card_input_label.visible =false;
				item_label.visible=false;
			}else{
				if(barcode_data[0].job <= 6){
					warrior_1p_label.visible =true;
					magician_1p_label.visible =false;
				}else{
					warrior_1p_label.visible =false;
					magician_1p_label.visible =true;
				}
				card_input_label.visible = true;
				item_label.visible=true;
			}
		break;
		
		//4枚目
		case 7:
			if(count == 1){
				warrior_2p_label.visible =false;
				magician_2p_label.visible =false;
				card_input_label.visible =false;
				item_label.visible=false;
			}else{
				if(barcode_data[1].job <= 6){
					warrior_2p_label.visible =true;
					magician_2p_label.visible =false;
				}else{
					warrior_2p_label.visible =false;
					magician_2p_label.visible =true;
				}
				card_input_label.visible = true;
				item_label.visible=true;
			}
		break;
		
	}
	
}

//カード入力受付処理
private var card_insert_timer:Timer;
private var card_insert_error_timer:Timer;
private var barcode_data:Array;
private function card_insert(event:MouseEvent):void{
	if(!barcode_data){
		barcode_data = new Array(4);
	}
	
	card_in_button.removeEventListener(MouseEvent.CLICK,card_insert);
	select_image_button.removeEventListener(MouseEvent.CLICK,select_image);
	get_camera_button.removeEventListener(MouseEvent.CLICK,get_camera);
	card_in_button.enabled = false;
	init_card_reader_button.enabled = false;
	
	if(card_insert_wait_timer){
		card_insert_wait_timer.removeEventListener(TimerEvent.TIMER,card_insert_wait_animation);
		card_insert_wait_timer.stop();
		card_insert_wait_timer = null;
	}
	
	switch(bb2_state){
		//1枚目
		case 4:
			var barcode_reader:BarcodeRead = new BarcodeRead();
			var barcode:String = card_in.text;
			var ret:Boolean = barcode_reader.init(barcode,1);
			
			//入力成功
			if(ret){
				se.card_in_mp3.play();
				barcode_data[0] = barcode_reader.barcode_data;
				if(barcode_data[0].job <= 6){
					warrior_1p_label.visible = true;
					magician_1p_label.visible = false;
				}else{
					warrior_1p_label.visible = false;
					magician_1p_label.visible = true;
				}
				
				//変動待ちボタン
				l_battle.addEventListener(MouseEvent.CLICK,value_shift);
				l_power.addEventListener(MouseEvent.CLICK,value_shift);
				r_battle.addEventListener(MouseEvent.CLICK,value_shift);
				r_power.addEventListener(MouseEvent.CLICK,value_shift);
				
				card_input_label.visible = false;
				card_insert_timer = new Timer(80,20);
				card_insert_timer.addEventListener(TimerEvent.TIMER,card_insert_animation);
				card_insert_timer.addEventListener(TimerEvent.TIMER_COMPLETE,card_insert_next);
				card_insert_timer.start();
				
			//入力失敗
			}else{
				se.card_in_error_mp3.play();
				magician_1p_label.visible=false;
				warrior_1p_label.visible=false;
				barcode_data[0] = barcode_reader.barcode_data;
				card_insert_error_timer = new Timer(150,6);
				card_insert_error_timer.addEventListener(TimerEvent.TIMER,card_insert_error_animation);
				card_insert_error_timer.addEventListener(TimerEvent.TIMER_COMPLETE,card_insert_error_back);
				card_insert_error_timer.start();
			}
		break;
		
		//2枚目
		case 5:
			barcode_reader = new BarcodeRead();
			barcode = card_in.text;
			ret = barcode_reader.init(barcode,1);

			//入力成功
			if(ret){
				se.card_in_mp3.play();
				barcode_data[1] = barcode_reader.barcode_data;
				
				if(barcode_data[1].job <= 6){
					warrior_2p_label.visible = true;
					magician_2p_label.visible = false;
				}else{
					warrior_2p_label.visible = false;
					magician_2p_label.visible = true;
				}
				
				//変動待ちボタン
				l_battle.addEventListener(MouseEvent.CLICK,value_shift);
				l_power.addEventListener(MouseEvent.CLICK,value_shift);
				r_battle.addEventListener(MouseEvent.CLICK,value_shift);
				r_power.addEventListener(MouseEvent.CLICK,value_shift);
				
				card_input_label.visible = false;
				card_insert_timer = new Timer(80,20);
				card_insert_timer.addEventListener(TimerEvent.TIMER,card_insert_animation);
				card_insert_timer.addEventListener(TimerEvent.TIMER_COMPLETE,card_insert_next);
				card_insert_timer.start();
				
			//入力失敗
			}else{
				se.card_in_error_mp3.play();
				magician_2p_label.visible=false;
				warrior_2p_label.visible=false;
				barcode_data[1] = barcode_reader.barcode_data;
				card_insert_error_timer = new Timer(150,6);
				card_insert_error_timer.addEventListener(TimerEvent.TIMER,card_insert_error_animation);
				card_insert_error_timer.addEventListener(TimerEvent.TIMER_COMPLETE,card_insert_error_back);
				card_insert_error_timer.start();
			}
		break;
		
		//3枚目
		case 6:
			barcode_reader = new BarcodeRead();
			barcode = card_in.text;
			ret = barcode_reader.init(barcode,2,barcode_data[0]);
			
			//入力成功
			if(ret){
				se.card_in_mp3.play();
				barcode_data[2] = barcode_reader.barcode_data;
				item_label.visible = true;
				card_input_label.visible = false;
				card_insert_timer = new Timer(80,40);
				card_insert_timer.addEventListener(TimerEvent.TIMER,card_insert_animation);
				card_insert_timer.addEventListener(TimerEvent.TIMER_COMPLETE,card_insert_next);
				card_insert_timer.start();
				
			//入力失敗	
			}else{
				se.card_in_error_mp3.play();
				magician_1p_label.visible=false;
				warrior_1p_label.visible=false;
				barcode_data[2] = barcode_reader.barcode_data;
				card_insert_error_timer = new Timer(150,6);
				card_insert_error_timer.addEventListener(TimerEvent.TIMER,card_insert_error_animation);
				card_insert_error_timer.addEventListener(TimerEvent.TIMER_COMPLETE,card_insert_error_back);
				card_insert_error_timer.start();				
			}
			
		break;
		
		//4枚目
		case 7:
			barcode_reader = new BarcodeRead();
			barcode = card_in.text;
			ret = barcode_reader.init(barcode,2,barcode_data[1]);
			
			//入力成功
			if(ret){
				se.card_in_mp3.play();
				barcode_data[3] = barcode_reader.barcode_data;
				item_label.visible = true;
				card_input_label.visible = false;
				card_insert_timer = new Timer(80,40);
				card_insert_timer.addEventListener(TimerEvent.TIMER,card_insert_animation);
				card_insert_timer.addEventListener(TimerEvent.TIMER_COMPLETE,card_insert_next);
				card_insert_timer.start();
				
			//入力失敗	
			}else{
				se.card_in_error_mp3.play();
				magician_2p_label.visible=false;
				warrior_2p_label.visible=false;
				barcode_data[3] = barcode_reader.barcode_data;
				card_insert_error_timer = new Timer(150,6);
				card_insert_error_timer.addEventListener(TimerEvent.TIMER,card_insert_error_animation);
				card_insert_error_timer.addEventListener(TimerEvent.TIMER_COMPLETE,card_insert_error_back);
				card_insert_error_timer.start();				
			}		
		break;

	}
	
}


//裏技（ボタンによる値シフト）
private function value_shift(event:MouseEvent):void{
	
	var shift:int = 0;
	switch(event.currentTarget){
		case l_battle:
			shift = -2;
			break;
		
		case l_power:
			shift = -1;
			break;
		
		case r_battle:
			shift = +1;
			break;
		
		case r_power:
			shift = +2;
			break;

	}
	
	if(bb2_state == 4){		
		var barcode_reader:BarcodeRead = new BarcodeRead();
		var barcode:String = barcode_data[0].barcode;
		var ret:Boolean = barcode_reader.init(barcode,1,null,shift);
		barcode_data[0] = barcode_reader.barcode_data;
	}else if(bb2_state == 5){
		barcode_reader = new BarcodeRead();
		barcode = barcode_data[1].barcode;
		ret = barcode_reader.init(barcode,1,null,shift);
		barcode_data[1] = barcode_reader.barcode_data;
	}
	
}



//カード入力受付アニメーション
private function card_insert_animation(event:TimerEvent):void{
	var count:int = event.currentTarget.currentCount%2;	
	var currentCount:int = event.currentTarget.currentCount;
	
	switch(bb2_state){

		//1枚目		
		case 4:
			if(count == 1){
				hp_1p.text = " ==";
				st_1p.text = " ==";
				df_1p.text = " ==";
			}else{
				hp_1p.text = "";
				st_1p.text = "";
				df_1p.text = "";
			}
		break;
		
		//2枚目
		case 5:
			if(count == 1){
				hp_2p.text = " ==";
				st_2p.text = " ==";
				df_2p.text = " ==";
			}else{
				hp_2p.text = "";
				st_2p.text = "";
				df_2p.text = "";
			}		
		break;
		
		//3枚目
		case 6:
			//点滅表示
			if(currentCount <= 20){
				//薬草アップ,MPアップ
				if(barcode_data[2].race==9 && barcode_data[2].job > 6){
					hp_label.visible = true;
					st_label.visible = false;
					df_label.visible = false;
					mp_label.visible = true;
					pp_label.visible = true;
					st_1p.mp_text = barcode_data[0].mp;
					df_1p.pp_text = barcode_data[0].pp;
				}else{
					hp_label.visible = true;
					st_label.visible = true;
					df_label.visible = true;
					mp_label.visible = false;
					pp_label.visible = false;
				}
				if(barcode_data[0].job > 6){
					warrior_1p_label.enabled = false;
					magician_1p_label.enabled = true;
				}else{
					warrior_1p_label.enabled = true;
					magician_1p_label.enabled = false;
				}
				if(count == 1){
					hp_2p.text = " ==";
					st_2p.text = " ==";
					df_2p.text = " ==";
				}else{
					hp_2p.text = "";
					st_2p.text = "";
					df_2p.text = "";
				}
			//入力パラメータ表示
			}else{
				//薬草アップ,MPアップ
				if(barcode_data[2].race==9 && barcode_data[2].job > 6){
					hp_2p.text = "";
					if(barcode_data[2].mp  > 0){
						st_2p.mp_text = barcode_data[2].mp;
					}else{
						st_2p.text = "";
					}
					if(barcode_data[2].pp  > 0){
						df_2p.pp_text = barcode_data[2].pp;
					}else{
						df_2p.text = "";
					}
				}else{
					if(barcode_data[2].hp != 0){
						hp_2p.text = barcode_data[2].hp;
					}else{
						hp_2p.text = "";
					}
					if(barcode_data[2].st != 0){
						st_2p.text = (barcode_data[2].st>199)?199:barcode_data[2].st;
					}else{
						st_2p.text = "";
					}
					if(barcode_data[2].df != 0){
						df_2p.text = (barcode_data[2].df>199)?199:barcode_data[2].df;
					}else{
						df_2p.text = "";
					}
				}
			}
			
		break;
		
		//4枚目
		case 7:
			//点滅表示
			if(currentCount <= 20){
				//薬草アップ,MPアップ
				if(barcode_data[3].race==9 && barcode_data[3].job > 6){
					hp_label.visible = true;
					st_label.visible = false;
					df_label.visible = false;
					mp_label.visible = true;
					pp_label.visible = true;
					st_2p.mp_text = barcode_data[1].mp;
					df_2p.pp_text = barcode_data[1].pp;
				}else{
					hp_label.visible = true;
					st_label.visible = true;
					df_label.visible = true;
					mp_label.visible = false;
					pp_label.visible = false;
				}
				if(barcode_data[1].job > 6){
					warrior_1p_label.enabled = false;
					magician_1p_label.enabled = true;
				}else{
					warrior_1p_label.enabled = true;
					magician_1p_label.enabled = false;
				}
				
				if(count == 1){
					hp_1p.text = " ==";
					st_1p.text = " ==";
					df_1p.text = " ==";
				}else{
					hp_1p.text = "";
					st_1p.text = "";
					df_1p.text = "";
				}
			//入力パラメータ表示
			}else{
				//薬草アップ,MPアップ
				if(barcode_data[3].race==9 && barcode_data[3].job > 6){
					hp_1p.text = "";
					if(barcode_data[3].mp  > 0){
						st_1p.mp_text = barcode_data[3].mp;
					}else{
						st_1p.text = "";
					}
					if(barcode_data[3].pp  > 0){
						df_1p.pp_text = barcode_data[3].pp;
					}else{
						df_1p.text = "";
					}
				}else{
					if(barcode_data[3].hp != 0){
						hp_1p.text = barcode_data[3].hp;
					}else{
						hp_1p.text = "";
					}
					if(barcode_data[3].st != 0){
						st_1p.text = (barcode_data[3].st>199)?199:barcode_data[3].st;
					}else{
						st_1p.text = "";
					}
					if(barcode_data[3].df != 0){
						df_1p.text = (barcode_data[3].df>199)?199:barcode_data[3].df;
					}else{
						df_1p.text = "";
					}
				}
			}		
		break;
		
	}
}


//SETによるカード入力スキップ
private var card_skip_timer:Timer;
private function card_skip(event:MouseEvent):void{
	card_in_button.removeEventListener(MouseEvent.CLICK,card_insert);
	select_image_button.removeEventListener(MouseEvent.CLICK,select_image);
	get_camera_button.removeEventListener(MouseEvent.CLICK,get_camera);
	card_in.enabled = false;
	card_in_button.enabled=false;
	init_card_reader_button.enabled = false;
	set_button.removeEventListener(MouseEvent.CLICK,card_skip);

	if(card_insert_wait_timer){
		card_insert_wait_timer.removeEventListener(TimerEvent.TIMER,card_insert_wait_animation);
		card_insert_wait_timer.stop();
		card_insert_wait_timer = null;
	}
	
	switch(bb2_state){
		
		//3枚目
		case 6:
			se.decide_mp3.play();
			barcode_data[2] = null;
			card_skip_timer = new Timer(50,2);
			card_skip_timer.addEventListener(TimerEvent.TIMER,card_skip_animation);
			card_skip_timer.addEventListener(TimerEvent.TIMER_COMPLETE,card_insert_next);
			card_skip_timer.start();
		break;
		
		//4枚目
		case 7:
			se.decide_mp3.play();
			barcode_data[3] = null;
			card_skip_timer = new Timer(50,2);
			card_skip_timer.addEventListener(TimerEvent.TIMER,card_skip_animation);
			card_skip_timer.addEventListener(TimerEvent.TIMER_COMPLETE,card_insert_next);
			card_skip_timer.start();
		break;
		
	}	
	
}

//実機っぽくスキップ時に点滅させる
private function card_skip_animation(event:TimerEvent):void{
	
	var currentCount:int = event.currentTarget.currentCount;
	switch(bb2_state){
		
		//3枚目
		case 6:
				hp_2p.text = "";
				st_2p.text = "";
				df_2p.text = "";
		break;
		
		//4枚目
		case 7:
				hp_2p.text = "";
				st_2p.text = "";
				df_2p.text = "";
		break;

	}
}


//カード入力完了→次のステータスへ
private var  fighting_data:Array;
private function card_insert_next(event:TimerEvent):void{

	l_battle.removeEventListener(MouseEvent.CLICK,value_shift);
	l_power.removeEventListener(MouseEvent.CLICK,value_shift);
	r_battle.removeEventListener(MouseEvent.CLICK,value_shift);
	r_power.removeEventListener(MouseEvent.CLICK,value_shift);
	
	if(card_insert_timer){
		card_insert_timer.removeEventListener(TimerEvent.TIMER,card_insert_animation);
		card_insert_timer.removeEventListener(TimerEvent.TIMER_COMPLETE,card_insert_next);
		card_insert_timer.stop();
		card_insert_timer = null;
	}
	if(card_skip_timer){
		card_skip_timer.addEventListener(TimerEvent.TIMER,card_skip_animation);
		card_skip_timer.addEventListener(TimerEvent.TIMER_COMPLETE,card_insert_next);
		card_skip_timer.stop();
		card_skip_timer = null;
	}
	
	switch(bb2_state){
		
		//1枚目
		case 4:
			var bd:BarcodeData = barcode_data[0];
			hp_1p.text = bd.hp;
			st_1p.text = (bd.st > 199)?199:bd.st;
			df_1p.text = (bd.df > 199)?199:bd.df;
			bb2_state = bb2_state + 1;
			card_reader_visible = false;
			init_card_reader(new MouseEvent(MouseEvent.CLICK));
			card_in_button.addEventListener(MouseEvent.CLICK,card_insert);
			select_image_button.addEventListener(MouseEvent.CLICK,select_image);
			get_camera_button.addEventListener(MouseEvent.CLICK,get_camera);
			card_in.enabled = true;
			card_in_button.enabled=true;
			init_card_reader_button.enabled = true;
			card_insert_wait();
		break;
		
		//2枚目
		case 5:
			bd = barcode_data[1];
			hp_2p.text = bd.hp;
			st_2p.text = (bd.st > 199)?199:bd.st;
			df_2p.text = (bd.df > 199)?199:bd.df;
			bb2_state = bb2_state + 1;
			card_reader_visible = false;
			init_card_reader(new MouseEvent(MouseEvent.CLICK));
			card_in_button.addEventListener(MouseEvent.CLICK,card_insert);
			select_image_button.addEventListener(MouseEvent.CLICK,select_image);
			get_camera_button.addEventListener(MouseEvent.CLICK,get_camera);
			card_in.enabled = true;
			card_in_button.enabled=true;
			init_card_reader_button.enabled = true;
			card_insert_wait();		
		break;
		
		//3枚目
		case 6:
			hp_label.visible = true;
			st_label.visible = true;
			df_label.visible = true;
			mp_label.visible = false;
			pp_label.visible = false;
			
			var fd:FightingData = new CreateFightingData().init(barcode_data[0],barcode_data[2]);
			if(!fighting_data){
				fighting_data = new Array(2);
			}
			hp_1p.text = fd.hp;
			st_1p.text = (fd.st>199)?199:fd.st;
			df_1p.text = (fd.df>199)?199:fd.df;
			
			fighting_data[0] = fd;
			if(fd.job > 6){
				magician_1p_label.visible = true;
				warrior_1p_label.visible = false;
			}else{
				magician_1p_label.visible = false;
				warrior_1p_label.visible = true;
			}
			
			bd = barcode_data[1];
			hp_2p.text = bd.hp;
			st_2p.text = (bd.st>199)?199:bd.st;
			df_2p.text = (bd.df>199)?199:bd.df;
			
			bb2_state = bb2_state + 1;
			
			card_reader_visible = false;
			init_card_reader(new MouseEvent(MouseEvent.CLICK));
			card_in_button.addEventListener(MouseEvent.CLICK,card_insert);
			select_image_button.addEventListener(MouseEvent.CLICK,select_image);
			get_camera_button.addEventListener(MouseEvent.CLICK,get_camera);
			card_in.enabled = true;
			card_in_button.enabled=true;
			init_card_reader_button.enabled = true;
			card_insert_wait();
		break;
		
		//4枚目
		case 7:
			hp_label.visible = true;
			st_label.visible = true;
			df_label.visible = true;
			mp_label.visible = false;
			pp_label.visible = false;
			item_label.visible =false;
			card_input_label.visible=false;
			
			fd = new CreateFightingData().init(barcode_data[1],barcode_data[3]);
			hp_2p.text = fd.hp;
			st_2p.text = (fd.st>199)?199:fd.st;
			df_2p.text = (fd.df>199)?199:fd.df;
			fighting_data[1] = fd;
			if(fd.job > 6){
				magician_2p_label.visible = true;
				warrior_2p_label.visible = false;
			}else{
				magician_2p_label.visible = false;
				warrior_2p_label.visible = true;
			}
			
			hp_1p.text = fighting_data[0].hp;
			st_1p.text = (fighting_data[0].st>199)?199:fighting_data[0].st;
			df_1p.text = (fighting_data[0].df>199)?199:fighting_data[0].df;
			
			bb2_state = bb2_state + 1;
			
			card_reader_visible = false;
			init_card_reader(new MouseEvent(MouseEvent.CLICK));
			card_in_button.addEventListener(MouseEvent.CLICK,card_insert);
			select_image_button.addEventListener(MouseEvent.CLICK,select_image);
			get_camera_button.addEventListener(MouseEvent.CLICK,get_camera);
			card_in.enabled = false;
			card_in_button.enabled=false;
			init_card_reader_button.enabled = false;
			
			//ダウン系特殊能力処理へ
			fighting_calc.fighting_data = fighting_data;
			special_down();
		break;
	
	}
					
}

//カード入力失敗アニメーション
private function card_insert_error_animation(event:TimerEvent):void{
	
	var count:int = event.currentTarget.currentCount%2;	
	switch(bb2_state){
	
		//1枚目	
		case 4:
			if(count == 1){
				//アイテムなら
				if(barcode_data[0]!= null && barcode_data[0].race > 4){
					card_input_label.visible = true;
					item_label.visible = true;
					miss_label.visible = false;
				//カード入力ミス
				}else{
					card_input_label.visible = true;
					miss_label.visible = false;
				}
				
			}else{
				if(barcode_data[0]!= null && barcode_data[0].race > 4){
					card_input_label.visible = true;
					item_label.visible = false;
					miss_label.visible = true;
				}else{
					card_input_label.visible = false;
					miss_label.visible = true;
				}
			}
		break;
		
		//2枚目
		case 5:
			if(count == 1){
				//アイテムなら
				if(barcode_data[1]!= null && barcode_data[1].race > 4){
					card_input_label.visible = true;
					item_label.visible = true;
					miss_label.visible = false;
				//カード入力ミス
				}else{
					card_input_label.visible = true;
					miss_label.visible = false;
				}
			}else{
				if(barcode_data[1]!= null && barcode_data[1].race > 4){
					card_input_label.visible = true;
					item_label.visible = false;
					miss_label.visible = true;						
				}else{
					card_input_label.visible = false;
					miss_label.visible = true;
				}
			}		
		break;
		
		//3枚目
		case 6:
			if(count == 1){
				//アイテムなら
				if(barcode_data[2]!= null && barcode_data[2].race > 4){
					card_input_label.visible = true;
					item_label.visible = true;
					miss_label.visible = false;
				//同バーコード
				}else if(barcode_data[2]!= null && barcode_data[0].barcode == barcode_data[2].barcode){
					card_input_label.visible = false;
					item_label.visible = false;
					if(barcode_data[0].job <=6){
						warrior_1p_label.visible = true;
						magician_1p_label.visible = false;
					}else{
						warrior_1p_label.visible = false;
						magician_1p_label.visible = true;
					}
					miss_label.visible = false;
				//カード入力ミス
				}else{
					card_input_label.visible = true;
					item_label.visible = false;
					miss_label.visible = false;
				}
			}else{
				if(barcode_data[2]!= null && barcode_data[2].race > 4){
					card_input_label.visible = true;
					item_label.visible = false;
					miss_label.visible = true;		
				//同バーコード
				}else if(barcode_data[2]!= null && barcode_data[0].barcode == barcode_data[2].barcode){
					card_input_label.visible = false;
					item_label.visible = false;
					if(barcode_data[2].job <=6){
						warrior_1p_label.visible = false;
						magician_1p_label.visible = false;
					}else{
						warrior_1p_label.visible = false;
						magician_1p_label.visible = false;
					}
					miss_label.visible = true;
				}else{
					card_input_label.visible = false;
					item_label.visible = false;
					miss_label.visible = true;
				}
			}	
		break;
		
		//4枚目
		case 7:
			if(count == 1){
				//アイテムなら
				if(barcode_data[3]!= null && barcode_data[3].race > 4){
					card_input_label.visible = true;
					item_label.visible = true;
					miss_label.visible = false;
				//同バーコード
				}else if(barcode_data[3]!= null && barcode_data[1].barcode == barcode_data[3].barcode){
					card_input_label.visible = false;
					item_label.visible = false;
					if(barcode_data[3].job <=6){
						warrior_2p_label.visible = true;
						magician_2p_label.visible = false;
					}else{
						warrior_2p_label.visible = false;
						magician_2p_label.visible = true;
					}
					miss_label.visible = false;					
				//カード入力ミス
				}else{
					card_input_label.visible = true;
					item_label.visible = false;
					miss_label.visible = false;
				}
			}else{
				if(barcode_data[3]!= null && barcode_data[3].race > 4){
					card_input_label.visible = true;
					item_label.visible = false;
					miss_label.visible = true;
				//同バーコード
				}else if(barcode_data[3]!= null && barcode_data[1].barcode == barcode_data[3].barcode){
					card_input_label.visible = false;
					item_label.visible = false;
					if(barcode_data[3].job <=6){
						warrior_2p_label.visible = false;
						magician_2p_label.visible = false;
					}else{
						warrior_2p_label.visible = false;
						magician_2p_label.visible = false;
					}
					miss_label.visible = true;
				}else{
					card_input_label.visible = false;
					item_label.visible = false;
					miss_label.visible = true;
				}
			}		
		break;
	
	}
}

//カード入力失敗
private function card_insert_error_back(event:TimerEvent):void{

	if(card_insert_error_timer){
		card_insert_error_timer.removeEventListener(TimerEvent.TIMER,card_insert_error_animation);
		card_insert_error_timer.removeEventListener(TimerEvent.TIMER_COMPLETE,card_insert_error_back);
		card_insert_error_timer.stop();
		card_insert_error_timer = null;
	}
	
	item_label.visible = false;
	card_input_label.visible = false;
	miss_label.visible = false;
	
	card_reader_visible = false;
	init_card_reader(new MouseEvent(MouseEvent.CLICK));
	card_in_button.addEventListener(MouseEvent.CLICK,card_insert);
	select_image_button.addEventListener(MouseEvent.CLICK,select_image);
	get_camera_button.addEventListener(MouseEvent.CLICK,get_camera);
	card_in.enabled = true;
	card_in_button.enabled=true;
	init_card_reader_button.enabled = true;
	card_insert_wait();
}

//特殊能力23～29、45
private var special_down_timer:Timer;
private function special_down():void{
	
	var special_1p_enabled:Boolean = true;
	var special_2p_enabled:Boolean = true;
	
	//特殊能力45 特殊能力無効化
	if(fighting_data[0].special1 == 45 || fighting_data[0].special2 == 45){
		special_2p_enabled = false;
	}
	if(fighting_data[1].special1 == 45 || fighting_data[1].special2 == 45){
		special_1p_enabled = false;
	}

	if(!special_1p_enabled){
		fighting_data[0].special1 = 0;
		fighting_data[0].special2 = 0;
	}
	if(!special_2p_enabled){
		fighting_data[1].special1 = 0;
		fighting_data[1].special2 = 0;
	}
	
	//ダウン後の値を受け取る
	fighting_data[0] = fighting_calc.calc_special_down(fighting_data[1],fighting_data[0]);
	fighting_data[1] = fighting_calc.calc_special_down(fighting_data[0],fighting_data[1]);
	
	if(!fighting_data[0].down_hp_flag && !fighting_data[0].down_st_flag && !fighting_data[0].down_df_flag &&
		 !fighting_data[1].down_hp_flag && !fighting_data[1].down_st_flag && !fighting_data[1].down_df_flag){
		 decide_first_player(10);	
	}else{
		special_down_timer = new Timer(250,14);	
		special_down_timer.addEventListener(TimerEvent.TIMER,special_down_animation);
		special_down_timer.addEventListener(TimerEvent.TIMER_COMPLETE,special_down_complete);
		special_down_timer.start();
	}
}

//ダウン系特殊能力作用中アニメーション
private function special_down_animation(event:TimerEvent):void{
	var currentCount:int = event.currentTarget.currentCount;
	var count:int = event.currentTarget.currentCount%2;
	if(currentCount < 4){
		return;
	}
	if(currentCount == 5){
		se.status_down_mp3.play();
	}
	
	if(count == 1){
		if(fighting_data[0].down_hp_flag){
			hp_1p.text = " ==";
		}
		if(fighting_data[0].down_st_flag){
			st_1p.text = " ==";
		}
		if(fighting_data[0].down_df_flag){
			df_1p.text = " ==";
		}
		if(fighting_data[1].down_hp_flag){
			hp_2p.text = " ==";
		}
		if(fighting_data[1].down_st_flag){
			st_2p.text = " ==";
		}
		if(fighting_data[1].down_df_flag){
			df_2p.text = " ==";
		}
	}else{
		if(fighting_data[0].down_hp_flag){
			hp_1p.text = "";	
		}
		if(fighting_data[0].down_st_flag){
			st_1p.text = "";
		}
		if(fighting_data[0].down_df_flag){
			df_1p.text = "";	
		}
		if(fighting_data[1].down_hp_flag){
			hp_2p.text = "";	
		}
		if(fighting_data[1].down_st_flag){
			st_2p.text = "";
		}
		if(fighting_data[1].down_df_flag){
			df_2p.text = "";
		}
	}
	
}

//ダウン系完了処理
private function special_down_complete(event:TimerEvent):void{
	
	if(special_down_timer){
		special_down_timer.removeEventListener(TimerEvent.TIMER,special_down_animation);
		special_down_timer.removeEventListener(TimerEvent.TIMER_COMPLETE,special_down_complete);
		special_down_timer.stop();
		special_down_timer = null;
	}
	
	hp_1p.text = fighting_data[0].hp;
	st_1p.text = fighting_data[0].st;
	df_1p.text = fighting_data[0].df;
	hp_2p.text = fighting_data[1].hp;
	st_2p.text = fighting_data[1].st;
	df_2p.text = fighting_data[1].df;
	
	se.decide_first_player_mp3.play();
	decide_first_player(0);
}


//先攻決定
private var decide_first_timer:Timer;
private var battle_waiting_first:Boolean = false;
private function decide_first_player(wait_count:int):void{
	
	//先攻計算
	fighting_calc.decide_first_player();
	
	var timer_count:int = wait_count + 15;
	battle_waiting_first = true;
	decide_first_timer = new Timer(200,timer_count);
	decide_first_timer.addEventListener(TimerEvent.TIMER,decide_first_player_animation);
	decide_first_timer.addEventListener(TimerEvent.TIMER_COMPLETE,battle_waiting);
	decide_first_timer.start();
	
}

//先攻決定アニメーション
private function decide_first_player_animation(event:TimerEvent):void{
	var currentCount:int = event.currentTarget.currentCount;
	var repeatCount:int = event.currentTarget.repeatCount;
	var count:int = event.currentTarget.currentCount%2;
	if(currentCount < repeatCount - 15){
		return;
	}
	if(currentCount == repeatCount - 15){
		se.decide_first_player_mp3.play();
	}
	
	if(count == 1){
		light1.selected = true;
		light2.selected = false;
		light3.selected = false;
		light4.selected = false;
		light5.selected = false;
	}else{
		light1.selected = false;
		light2.selected = false;
		light3.selected = false;
		light4.selected = false;
		light5.selected = true;
	}
}

//先攻決定完了
private var battle_waiting_timer:Timer;
private var auto_battle_timer:Timer;
private function battle_waiting(event:Event):void{
	battle_flag = false;
	
	if(decide_first_timer){
		decide_first_timer.removeEventListener(TimerEvent.TIMER,decide_first_player_animation);
		decide_first_timer.removeEventListener(TimerEvent.TIMER_COMPLETE,battle_waiting);
		decide_first_timer.stop();
		decide_first_timer = null;
	}
	
	if(!battle_waiting_first){
		if(fighting_calc.now_player == 1){
			if(fighting_data[0].hp <= 0){
				call_battle_end();
				return;
			}
		}else{
			if(fighting_data[1].hp <= 0){
				call_battle_end();
				return;
			}
		}
	}
	
	//データ表示
	hp_1p.text = fighting_data[0].hp;
	st_1p.text = fighting_data[0].st;
	df_1p.text = fighting_data[0].df;
	hp_2p.text = fighting_data[1].hp;
	st_2p.text = fighting_data[1].st;
	df_2p.text = fighting_data[1].df;
	hp_label.visible = true;
	damage_label.visible = false;
	st_label.visible = true;
	mp_label.visible = false;
	df_label.visible = true;
	pp_label.visible = false;

	//バトル-パワー表示
	if(!battle_waiting_timer){
		battle_waiting_timer = new Timer(500);
		battle_waiting_timer.addEventListener(TimerEvent.TIMER,battle_power_animation);
		battle_waiting_timer.start();
	}
	
	if(fighting_calc.now_player == 1){
		light1.selected = true;
		light5.selected = false;
		l_battle.addEventListener(MouseEvent.CLICK,battle);
		if(!fighting_data[0].pp_ignore_flag){
			l_power.addEventListener(MouseEvent.CLICK,power);
		}
		//C1
		if(mode == 1){
			r_power.addEventListener(MouseEvent.CLICK,escape);
		}
		select_battle_magic=true;
		select_button.addEventListener(MouseEvent.CLICK,select);
	}else{
		light1.selected = false;
		light5.selected = true;
		
		if(!fighting_data[1].cpu){
			r_battle.addEventListener(MouseEvent.CLICK,battle);
			if(!fighting_data[1].pp_ignore_flag){
				r_power.addEventListener(MouseEvent.CLICK,power);
			}
			select_battle_magic=true;
			select_button.addEventListener(MouseEvent.CLICK,select);
		}else{
			//敵のオート行動
			if(!auto_battle_timer){
				auto_battle_timer = new Timer(200,4);
				auto_battle_timer.addEventListener(TimerEvent.TIMER_COMPLETE,auto_battle_cpu);
				auto_battle_timer.start();
			}
		}
	}
}

//エスケープ
private function escape(event:MouseEvent):void{
	l_battle.removeEventListener(MouseEvent.CLICK,battle);
	l_power.removeEventListener(MouseEvent.CLICK,power);
	r_power.removeEventListener(MouseEvent.CLICK,escape);
	select_button.removeEventListener(MouseEvent.CLICK,select);
	
	var rand:int = Math.floor(Math.random() * 3);
	if(rand >= 1){
		if(!escape_from_battle_animation_timer){
			if(battle_waiting_timer){
				battle_waiting_timer.removeEventListener(TimerEvent.TIMER,battle_power_animation);
				battle_waiting_timer.stop();
				battle_waiting_timer = null;
			}
			battle_label.visible=false;
			power_label.visible=false;
			escape_label.visible=true;
			c1_stage_select_flag = false;
			friend_select_state_c1 = 0;
			se.status_down_mp3.play();
			
			escape_from_battle_animation_timer = new Timer(150,15);
			escape_from_battle_animation_timer.addEventListener(TimerEvent.TIMER,escape_from_battle_animation);
			escape_from_battle_animation_timer.addEventListener(TimerEvent.TIMER_COMPLETE,c1_stage_select_set);
			escape_from_battle_animation_timer.start();
		}
	}else{
		if(!escape_from_battle_failed_animaton_timer){
			se.card_in_error_mp3.play();
			if(battle_waiting_timer){
				battle_label.visible=false;
				power_label.visible=false;
				battle_waiting_timer.stop();
			}
			escape_from_battle_failed_animaton_timer = new Timer(100,8);
			escape_from_battle_failed_animaton_timer.addEventListener(TimerEvent.TIMER,escape_from_battle_failed_animaton);
			escape_from_battle_failed_animaton_timer.addEventListener(TimerEvent.TIMER_COMPLETE,escape_failed_battle_waiting);
			escape_from_battle_failed_animaton_timer.start();
		}
	}
	
}


private function escape_failed_battle_waiting(event:TimerEvent):void{
	fighting_calc.now_player = 2;
	escape_label.visible=false;
	miss_label.visible=false;
	if(escape_from_battle_failed_animaton_timer){
		escape_from_battle_failed_animaton_timer.removeEventListener(TimerEvent.TIMER,escape_from_battle_failed_animaton);
		escape_from_battle_failed_animaton_timer.removeEventListener(TimerEvent.TIMER_COMPLETE,escape_failed_battle_waiting);
		escape_from_battle_failed_animaton_timer.stop();
		escape_from_battle_failed_animaton_timer = null;
	}
	
	if(battle_waiting_timer){
		battle_waiting_timer.start();
	}
		
	battle_waiting(new Event(Event.CHANGE));
}


private function auto_battle_cpu(event:TimerEvent):void{
	if(auto_battle_timer){
		auto_battle_timer.removeEventListener(TimerEvent.TIMER_COMPLETE,auto_battle_cpu);
		auto_battle_timer.stop();
		auto_battle_timer = null;
	}
	
	switch(fighting_calc.calc_action()){
		case 0:
			f0();
		break;
		
		case 1:
			f1();
		break;
		
		case 2:
			f2();
		break;
		
		case 3:
			f3();
		break;
		
		case 4:
			f4();
		break;
		
		case 5:
			f5();
		break;
		
		case 6:
			f6();
		break;
		
		case 7:
			f7();
		break;
		
		case 8:
			f8();
		break;
		
		case 9:
			f9();
		break;
		
		case 10:
			battle(new MouseEvent(MouseEvent.CLICK));
		break;
		
		case 11:
			power(new MouseEvent(MouseEvent.CLICK));
		break;
		
	}
}	

private var battle_get_animation_timer:Timer;
private function call_battle_end():void{
	
	if(battle_waiting_timer){
		battle_waiting_timer.removeEventListener(TimerEvent.TIMER,battle_power_animation);
		battle_waiting_timer.stop();
		battle_waiting_timer = null;
	}
	
	light1.selected = false;
	light2.selected = false;
	light3.selected = false;
	light4.selected = false;
	light5.selected = false;
	battle_label.visible = false;
	power_label.visible = false;		
	miss_label.visible = false;
	critical_label.visible  = false;
	damage_label.visible = false;
	hp_label.visible = true;
	st_label.visible = true;
	df_label.visible = true;
	
	switch(mode){
		//C0モード
		case 0:
			se.battle_end_mp3.play();
			
			if(!battle_end_animation_timer){
				battle_end_animation_timer = new Timer(120,15);
				battle_end_animation_timer.addEventListener(TimerEvent.TIMER,battle_end_animation);
				battle_end_animation_timer.addEventListener(TimerEvent.TIMER_COMPLETE,battle_end);
				battle_end_animation_timer.start();
			}
		break;
		
		case 1:
			card_in_button.removeEventListener(MouseEvent.CLICK,card_insert);
			
			//戦闘中HPをbarcode_dataにコピー
			if(friend_select_state_c1==1){
				barcode_data_c1[4].hp = fighting_calc.fighting_data[0].hp;
				barcode_data_c1[4].mp = fighting_calc.fighting_data[0].mp;
				barcode_data_c1[4].pp = fighting_calc.fighting_data[0].pp;
				if(barcode_data_c1[4].hp <=0){
					barcode_data_c1[4].live=false;
				}
			}else{
				barcode_data_c1[5].hp = fighting_calc.fighting_data[0].hp;
				barcode_data_c1[5].mp = fighting_calc.fighting_data[0].mp;
				barcode_data_c1[5].pp = fighting_calc.fighting_data[0].pp;
				if(barcode_data_c1[5].hp <=0){
					barcode_data_c1[5].live=false;
				}
			}
			
			//主人公両方死亡
			if(!barcode_data_c1[4].live && !barcode_data_c1[5].live){
				se.battle_end_mp3.play();
				
				if(!battle_end_animation_timer){
					battle_end_animation_timer = new Timer(120,15);
					battle_end_animation_timer.addEventListener(TimerEvent.TIMER,battle_end_animation);
					battle_end_animation_timer.addEventListener(TimerEvent.TIMER_COMPLETE,battle_end);
					battle_end_animation_timer.start();
				}
				return;
			}
			
			//主人公片方健在
			se.battle_end_c2_mp3.play();
			
			barcode_data_enemy.hp = fighting_data[1].hp;
			barcode_data_enemy.mp = fighting_data[1].mp;
			barcode_data_enemy.pp = fighting_data[1].pp;
			
			if(!battle_end_animation_timer){
				battle_end_animation_timer = new Timer(120,15);
				battle_end_animation_timer.addEventListener(TimerEvent.TIMER,battle_end_animation);
				battle_end_animation_timer.addEventListener(TimerEvent.TIMER_COMPLETE,battle_end_c1);
				battle_end_animation_timer.start();
			}
			
		break;
		
		//C2
		case 2:
			card_in_button.removeEventListener(MouseEvent.CLICK,card_insert);
			
			//戦闘中HPをbarcode_dataにコピー
			if(friend_select_state==1){
				barcode_data_c2[4].hp = fighting_calc.fighting_data[0].hp;
				barcode_data_c2[4].mp = fighting_calc.fighting_data[0].mp;
				barcode_data_c2[4].pp = fighting_calc.fighting_data[0].pp;
				if(barcode_data_c2[4].hp <=0){
					barcode_data_c2[4].live=false;
				}
			}else{
				barcode_data_c2[5].hp = fighting_calc.fighting_data[0].hp;
				barcode_data_c2[5].mp = fighting_calc.fighting_data[0].mp;
				barcode_data_c2[5].pp = fighting_calc.fighting_data[0].pp;
				if(barcode_data_c2[5].hp <=0){
					barcode_data_c2[5].live=false;
				}
			}
			
			//主人公両方死亡
			if(!barcode_data_c2[4].live && !barcode_data_c2[5].live){
				se.battle_end_mp3.play();
				
				if(!battle_end_animation_timer){
					battle_end_animation_timer = new Timer(120,15);
					battle_end_animation_timer.addEventListener(TimerEvent.TIMER,battle_end_animation);
					battle_end_animation_timer.addEventListener(TimerEvent.TIMER_COMPLETE,battle_end);
					battle_end_animation_timer.start();
				}
				return;
			}
			
			//主人公片方健在
			se.battle_end_c2_mp3.play();
			
			barcode_data_c2[6].hp = fighting_data[1].hp;
			barcode_data_c2[6].mp = fighting_data[1].mp;
			barcode_data_c2[6].pp = fighting_data[1].pp;

			if(!battle_end_animation_timer){
				battle_end_animation_timer = new Timer(120,15);
				battle_end_animation_timer.addEventListener(TimerEvent.TIMER,battle_end_animation);
				battle_end_animation_timer.addEventListener(TimerEvent.TIMER_COMPLETE,battle_end_c2);
				battle_end_animation_timer.start();
			}
			

		break;
		
	}
}


//バトル-パワー表示
private function battle_power_animation(event:TimerEvent):void{
	
	if(battle_power_disable_flag){
		return;
	}
	if(battle_flag){
		battle_label.visible = true;
		power_label.visible  = false;
	}else if(power_flag){
		battle_label.visible = false;
		power_label.visible  = true;
	}else{
		var count:int = event.currentTarget.currentCount%2;
		if(count == 1){
			battle_label.visible = true;
			power_label.visible  = false;
		}else{
			battle_label.visible = false;
			if(fighting_calc.now_player == 1){
				if(fighting_data[0].pp_ignore_flag){
					power_label.visible  = false;
				}else{
					power_label.visible  = true;
				}
			}else{
				if(fighting_data[1].pp_ignore_flag){
					power_label.visible  = false;
				}else{
					power_label.visible  = true;	
				}
			}
		}
	}
}

//攻撃処理
private var battle_timer:Timer;
private var battle_flag:Boolean;
private var battle_end_count:int;
private function battle(event:Event):void{

	battle_flag = true;
	battle_label.visible = true;
	power_label.visible = false;
	l_battle.removeEventListener(MouseEvent.CLICK,battle);
	r_battle.removeEventListener(MouseEvent.CLICK,battle);
	l_power.removeEventListener(MouseEvent.CLICK,power);
	r_power.removeEventListener(MouseEvent.CLICK,power);
	r_power.removeEventListener(MouseEvent.CLICK,escape);
	select_button.removeEventListener(MouseEvent.CLICK,select);
	
	//1Pの攻撃
	if(fighting_calc.now_player == 1){
		//MISS
		var hit:Boolean = fighting_calc.calc_hit(fighting_data[0],fighting_data[1]);
		if(hit){
			var basic_damage:int = fighting_calc.basic_damage(fighting_data[0],fighting_data[1]);
			var multi_damage:int = fighting_calc.special_multi(fighting_data[0],fighting_data[1],basic_damage);
			fighting_calc.display_damage = multi_damage;

			//HIT
			fighting_data[1].hp = fighting_data[1].hp - multi_damage;
			if(fighting_data[1].hp < 0){
				fighting_data[1].hp = 0;
			}
			
			var critical_hit:Boolean = fighting_calc.critical_hit(fighting_data[0]);
			if(critical_hit){
				se.battle_critical_mp3.play();
			}else{
				se.battle_mp3.play();
			}
			
			
		}else{
			se.battle_miss_mp3.play();
			fighting_calc.display_damage = 0;
		}
				
	//2Pの攻撃
	}else{
		hit = fighting_calc.calc_hit(fighting_data[1],fighting_data[0]);
		
		if(hit){
			basic_damage = fighting_calc.basic_damage(fighting_data[1],fighting_data[0]);
			multi_damage = fighting_calc.special_multi(fighting_data[1],fighting_data[0],basic_damage);
			fighting_calc.display_damage = multi_damage;
			
			fighting_data[0].hp = fighting_data[0].hp - multi_damage;
			if(fighting_data[0].hp < 0){
				fighting_data[0].hp = 0;
			}
			
			critical_hit = fighting_calc.critical_hit(fighting_data[1]);
			if(critical_hit){
				se.battle_critical_mp3.play();
			}else{
				se.battle_mp3.play();
			}
			
		}else{
			se.battle_miss_mp3.play();
			fighting_calc.display_damage = 0;
		}
		

		
	}
	
	damage_label.visible = true;
	hp_label.visible = false;
	st_label.visible = false;
	df_label.visible = false;
	
	
	if(!battle_timer){
		if(hit){
			if(critical_hit){
				var time:int = 90;
				battle_end_count = 40;
			}else{
				time = 110;
				battle_end_count = 60;
			}
		}else{
			time = 130;
			battle_end_count = 80;
		}
		battle_timer = new Timer(40,time);
		battle_timer.addEventListener(TimerEvent.TIMER,battle_animation);
		battle_timer.addEventListener(TimerEvent.TIMER_COMPLETE,battle_complete);
		battle_timer.start();
	}
}

//攻撃アニメーション
private function battle_animation(event:TimerEvent):void{
	var currentCount:int = event.currentTarget.currentCount;
	var light_count:int = event.currentTarget.currentCount%10;

	//ダメージ表示
	if(currentCount > battle_end_count){
		light1.selected = false;
		light2.selected = false;
		light3.selected = false;
		light4.selected = false;
		light5.selected = false;
		if(fighting_calc.now_player == 1){
			
			var critical_hit:Boolean = fighting_calc.critical_hit(fighting_data[0]);			
			if(light_count <= 4){
				//会心の一撃
				if(critical_hit){
					critical_label.visible = true;
				}
				
				hp_1p.text = fighting_calc.display_damage;
				//MISS
				if(fighting_calc.display_damage == 0){
					miss_label.visible = true;
				}
			}else{
				critical_label.visible = false;
				miss_label.visible = false;
				hp_1p.text = "";
			}
		}else{
			critical_hit = fighting_calc.critical_hit(fighting_data[1]);
			if(light_count <= 4){
				//会心の一撃
				if(critical_hit){
					critical_label.visible = true;
				}
				hp_2p.text = fighting_calc.display_damage;
				//MISS
				if(fighting_calc.display_damage == 0){
					miss_label.visible = true;
				}
				
			}else{
				critical_label.visible  = false;				
				miss_label.visible = false;
				hp_2p.text = "";
			}
		}		
		return;	
	}

	if(fighting_calc.now_player == 1){
		
		switch(light_count){
			case 0:
			case 1:
				light1.selected = true;
				light2.selected = false;
				light3.selected = false;
				light4.selected = false;
				light5.selected = false;
			break;
			
			case 2:
			case 3:
				light1.selected = false;
				light2.selected = true;
				light3.selected = false;
				light4.selected = false;
				light5.selected = false;
			break;
			
			case 4:
			case 5:
				light1.selected = false;
				light2.selected = false;
				light3.selected = true;
				light4.selected = false;
				light5.selected = false;		
			break;
			
			case 6:
			case 7:
				light1.selected = false;
				light2.selected = false;
				light3.selected = false;
				light4.selected = true;
				light5.selected = false;
			break;
			
			case 8:
			case 9:
				light1.selected = false;
				light2.selected = false;
				light3.selected = false;
				light4.selected = false;
				light5.selected = true;
			break;
		}
		
		switch(light_count){
			case 0:
			case 1:
			case 2:
				hp_1p.text = "-";
				st_1p.text = "";
				df_1p.text = "";
			break;
			
			case 3:
			case 4:
			case 5:
				hp_1p.text = " -";
				st_1p.text = "";
				df_1p.text = "";
			break;
			
			case 6:
			case 7:
			case 8:
				hp_1p.text = "  -";
				st_1p.text = "";
				df_1p.text = "";
			break;
			
			case 9:
				hp_1p.text = "";
				st_1p.text = "";
				df_1p.text = "";
			break;
		}
		
	}else{
		switch(light_count){
			case 0:
			case 1:
				light1.selected = false;
				light2.selected = false;
				light3.selected = false;
				light4.selected = false;
				light5.selected = true;
			break;
			
			case 2:
			case 3:
				light1.selected = false;
				light2.selected = false;
				light3.selected = false;
				light4.selected = true;
				light5.selected = false;
			break;
			
			case 4:
			case 5:
				light1.selected = false;
				light2.selected = false;
				light3.selected = true;
				light4.selected = false;
				light5.selected = false;		
			break;
			
			case 6:
			case 7:
				light1.selected = false;
				light2.selected = true;
				light3.selected = false;
				light4.selected = false;
				light5.selected = false;
			break;
			
			case 8:
			case 9:
				light1.selected = true;
				light2.selected = false;
				light3.selected = false;
				light4.selected = false;
				light5.selected = false;
			break;
		}
		
		switch(light_count){
			case 0:
			case 1:
			case 2:
				hp_2p.text = "  -";
				st_2p.text = "";
				df_2p.text = "";
			break;
			
			case 3:
			case 4:
			case 5:
				hp_2p.text = " -";
				st_2p.text = "";
				df_2p.text = "";
			break;
			
			case 6:
			case 7:
			case 8:
				hp_2p.text = "-";
				st_2p.text = "";
				df_2p.text = "";
			break;
			
			case 9:
				hp_2p.text = "";
				st_2p.text = "";
				df_2p.text = "";
			break;
		}
				
	}
	
}

//攻撃完了
private var battle_end_animation_timer:Timer;
private var item_broke_animation_timer:Timer;
private function battle_complete(event:TimerEvent):void{

	if(battle_timer){
		battle_timer.removeEventListener(TimerEvent.TIMER,battle_animation);
		battle_timer.removeEventListener(TimerEvent.TIMER_COMPLETE,battle_complete);
		battle_timer.removeEventListener(TimerEvent.TIMER_COMPLETE,f1_complete);
		battle_timer.removeEventListener(TimerEvent.TIMER_COMPLETE,f2_complete);
		battle_timer.stop();
		battle_timer = null;
	}
	if(item_broke_animation_timer){
		item_broke_animation_timer.removeEventListener(TimerEvent.TIMER,item_broke_animation);
		item_broke_animation_timer.removeEventListener(TimerEvent.TIMER_COMPLETE,item_broke_complete);
		item_broke_animation_timer.stop();
		item_broke_animation_timer = null;
	}


	//アイテム破壊処理
	//ダメージがＨＩＴ
	if(fighting_calc.display_damage > 0){
		if(fighting_calc.now_player == 1){
			var broken_ret:Boolean = fighting_calc.check_item_broken(fighting_data[0],fighting_data[1]);
		}else{
			broken_ret =  fighting_calc.check_item_broken(fighting_data[1],fighting_data[0]);
		}
		if(broken_ret){
			if(!item_broke_animation_timer){
				se.status_down_mp3.play();
				item_broke_animation_timer = new Timer(250,10);
				item_broke_animation_timer.addEventListener(TimerEvent.TIMER,item_broke_animation);
				item_broke_animation_timer.addEventListener(TimerEvent.TIMER_COMPLETE,item_broke_complete);
				item_broke_animation_timer.start();
			}
			return;
		}
	}

	if(fighting_calc.now_player == 1){
		fighting_calc.now_player = 2;
		light1.selected = false;
		light2.selected = false;
		light3.selected = false;
		light4.selected = false;
		light5.selected = true;

		if(fighting_data[1].hp > 0){		
			se.change_mp3.play();
		}
		
		miss_label.visible = false;
		critical_label.visible  = false;
		damage_label.visible = false;
		hp_label.visible = true;
		st_label.visible = true;
		df_label.visible = true;
		battle_waiting_first = false;
		battle_waiting(new Event(Event.COMPLETE));

	}else{
		
		fighting_calc.now_player = 1;
		light1.selected = true;
		light2.selected = false;
		light3.selected = false;
		light4.selected = false;
		light5.selected = false;

		if(fighting_data[0].hp > 0){		
			se.change_mp3.play();
		}
		
		miss_label.visible = false;
		critical_label.visible  = false;
		damage_label.visible = false;
		hp_label.visible = true;
		st_label.visible = true;
		df_label.visible = true;
		battle_waiting_first = false;
		battle_waiting(new Event(Event.COMPLETE));
	}

}

private function item_broke_animation(event:TimerEvent):void{
	var currentCount:int = event.currentTarget.currentCount;
	var count:int = event.currentTarget.currentCount%2;

	var hp_1p_text = fighting_data[0].hp;
	var st_1p_text = fighting_data[0].st;
	var df_1p_text = fighting_data[0].df;
	var hp_2p_text = fighting_data[1].hp;
	var st_2p_text = fighting_data[1].st;
	var df_2p_text = fighting_data[1].df;
	
	if(count == 0){
		if(fighting_calc.now_player == 1){
			//STアイテム
			if(fighting_data[0].race2 == 5 && !fighting_data[0].st_item_broke_flag){
				st_1p_text = " ==";
			}
			//DFアイテム
			if(fighting_data[1].race2 == 7 && !fighting_data[1].df_item_broke_flag){
				df_2p_text = " ==";
			}
		}else{
			//STアイテム
			if(fighting_data[1].race2 == 5 && !fighting_data[1].st_item_broke_flag){
				st_2p_text = " ==";	
			}
			//DFアイテム
			if(fighting_data[0].race2 == 7 && !fighting_data[0].df_item_broke_flag){
				df_1p_text = " ==";
			}
		}
	}else{
		if(fighting_calc.now_player == 1){
			//STアイテム
			if(fighting_data[0].race2 == 5 && !fighting_data[0].st_item_broke_flag){
				st_1p_text = "";	
			}
			//DFアイテム
			if(fighting_data[1].race2 == 7 && !fighting_data[1].df_item_broke_flag){
				df_2p_text = "";
			}		
		}else{
			//STアイテム
			if(fighting_data[1].race2 == 5 && !fighting_data[1].st_item_broke_flag){
				st_2p_text = "";		
			}
			//DFアイテム
			if(fighting_data[0].race2 == 7 && !fighting_data[0].df_item_broke_flag){
				df_1p_text = "";
			}
		}
	}
	
	hp_1p.text = hp_1p_text;
	st_1p.text = st_1p_text;
	df_1p.text = df_1p_text;
	hp_2p.text = hp_2p_text;
	st_2p.text = st_2p_text;
	df_2p.text = df_2p_text;
	hp_label.visible =  true;
	st_label.visible =  true;
	df_label.visible =  true;
	damage_label.visible = false;
	mp_label.visible = false;
	pp_label.visible = false;
}

//アイテム破壊終了
private function item_broke_complete(event:TimerEvent):void{
	if(fighting_calc.now_player == 1){
			//STアイテム
			if(fighting_data[0].race2 == 5 && !fighting_data[0].st_item_broke_flag){
				fighting_data[0].st = fighting_data[0].st - fighting_data[0].st2;
				fighting_data[0].st_item_broke_flag = true;
			}
			//DFアイテム
			if(fighting_data[1].race2 == 7 && !fighting_data[1].df_item_broke_flag){
				fighting_data[1].df = fighting_data[1].df - fighting_data[1].df2;
				fighting_data[1].df_item_broke_flag = true;
			}		
	}else{
			//STアイテム
			if(fighting_data[1].race2 == 5 && !fighting_data[1].st_item_broke_flag){
				fighting_data[1].st = fighting_data[1].st - fighting_data[1].st2;
				fighting_data[1].st_item_broke_flag = true;
			}
			//DFアイテム
			if(fighting_data[0].race2 == 7 && !fighting_data[0].df_item_broke_flag){
				fighting_data[0].df = fighting_data[0].df - fighting_data[0].df2;
				fighting_data[0].df_item_broke_flag = true;
			}			
	}
	battle_complete(new TimerEvent(TimerEvent.TIMER_COMPLETE));
}


//戦闘終了アニメーション処理
private function battle_end_animation(event:TimerEvent):void{
	var currentCount:int = event.currentTarget.currentCount;
	var count:int = event.currentTarget.currentCount%2;

	if(currentCount > 10){
		if(fighting_calc.now_player == 2){
			hp_1p.text = fighting_data[0].hp;
			st_1p.text = fighting_data[0].st;
			df_1p.text = fighting_data[0].df;
			hp_2p.text = "";
			st_2p.text = "";
			df_2p.text = "";			
		}else{
			hp_2p.text = fighting_data[1].hp;
			st_2p.text = fighting_data[1].st;
			df_2p.text = fighting_data[1].df;
			hp_1p.text = "";
			st_1p.text = "";
			df_1p.text = "";
		}
		return;
	}

	if(count == 0){
		if(fighting_calc.now_player == 2){
			hp_1p.text = fighting_data[0].hp;
			st_1p.text = fighting_data[0].st;
			df_1p.text = fighting_data[0].df;
			hp_2p.text = 0;
			st_2p.text = fighting_data[1].st;
			df_2p.text = fighting_data[1].df;
		}else{
			hp_2p.text = fighting_data[1].hp;
			st_2p.text = fighting_data[1].st;
			df_2p.text = fighting_data[1].df;
			hp_1p.text = 0;
			st_1p.text = fighting_data[0].st;
			df_1p.text = fighting_data[0].df;
		}
	}else{
		if(fighting_calc.now_player == 2){
			hp_1p.text = fighting_data[0].hp;
			st_1p.text = fighting_data[0].st;
			df_1p.text = fighting_data[0].df;
			hp_2p.text = "";
			st_2p.text = "";
			df_2p.text = "";
		}else{
			hp_2p.text = fighting_data[1].hp;
			st_2p.text = fighting_data[1].st;
			df_2p.text = fighting_data[1].df;
			hp_1p.text = "";
			st_1p.text = "";
			df_1p.text = "";			
		}
	}
}

//戦闘終了後アニメーション
private var end_text_animation_timer:Timer;
private function battle_end(event:TimerEvent):void{

		if(battle_end_animation_timer){
			battle_end_animation_timer.removeEventListener(TimerEvent.TIMER,battle_end_animation);
			battle_end_animation_timer.removeEventListener(TimerEvent.TIMER_COMPLETE,battle_end);
			battle_end_animation_timer.stop();
			battle_end_animation_timer = null;
		}
		
		set_button.addEventListener(MouseEvent.CLICK,restart_mode);
		
		if(!end_text_animation_timer){
			end_text_animation_timer = new Timer(150);
			end_text_animation_timer.addEventListener(TimerEvent.TIMER,end_text_animation);
			end_text_animation_timer.start();
		}
		
}

private function end_text_animation(event:TimerEvent):void{
	var count:int = event.currentTarget.currentCount%2;
	if(count == 0){
		if(fighting_calc.now_player == 2){
			hp_1p.text = fighting_data[0].hp;
			st_1p.text = fighting_data[0].st;
			df_1p.text = fighting_data[0].df;
			hp_2p.text = "End";
			st_2p.text = "";
			df_2p.text = "";			
		}else{
			hp_2p.text = fighting_data[1].hp;
			st_2p.text = fighting_data[1].st;
			df_2p.text = fighting_data[1].df;
			hp_1p.text = "End";
			st_1p.text = "";
			df_1p.text = "";
		}
	}else{
		if(fighting_calc.now_player == 2){
			hp_1p.text = fighting_data[0].hp;
			st_1p.text = fighting_data[0].st;
			df_1p.text = fighting_data[0].df;
			hp_2p.text = "";
			st_2p.text = "";
			df_2p.text = "";			
		}else{
			hp_2p.text = fighting_data[1].hp;
			st_2p.text = fighting_data[1].st;
			df_2p.text = fighting_data[1].df;
			hp_1p.text = "";
			st_1p.text = "";
			df_1p.text = "";			
		}
	}
}

//カード入力再スタート準備
private function restart_mode(event:MouseEvent):void{
	se.decide_mp3.play();
	
	set_button.removeEventListener(MouseEvent.CLICK,restart_mode);
	if(end_text_animation_timer){
		end_text_animation_timer.removeEventListener(TimerEvent.TIMER,end_text_animation);
		end_text_animation_timer.stop();
		end_text_animation_timer = null;
	}
	
	switch(mode){
		case 0:
			magician_1p_label.visible = false;
			warrior_1p_label.visible = false;
			warrior_2p_label.visible = false;
			magician_2p_label.visible = false;
			bb2_state = 4;
			card_insert_wait();
		break;
		
		case 2:
			magician_1p_label.visible = false;
			warrior_1p_label.visible = true;
			warrior_2p_label.visible = false;
			magician_2p_label.visible = true;
			bb2_state = 4;
			card_insert_wait_c2();
		break;
		
	}
}



//回復処理
private var power_flag:Boolean;
private var power_timer:Timer;
private function power(event:MouseEvent):void{
	
	power_flag = true;
	battle_label.visible = false;
	power_label.visible = true;
	l_battle.removeEventListener(MouseEvent.CLICK,battle);
	r_battle.removeEventListener(MouseEvent.CLICK,battle);
	l_power.removeEventListener(MouseEvent.CLICK,power);
	r_power.removeEventListener(MouseEvent.CLICK,escape);
	r_power.removeEventListener(MouseEvent.CLICK,power);
	select_button.removeEventListener(MouseEvent.CLICK,select);

	//1Pの回復
	if(fighting_calc.now_player == 1){
		if(fighting_data[0].pp > 0){
			var basic_power:int = fighting_calc.basic_power(fighting_data[0],fighting_data[1]);
			fighting_calc.display_power = basic_power;
		}
	//2Pの回復
	}else{
		if(fighting_data[1].pp > 0){
			basic_power = fighting_calc.basic_power(fighting_data[1],fighting_data[0]);
			fighting_calc.display_power = basic_power;
		}
	}
	
	damage_label.visible = false;
	hp_label.visible = false;
	st_label.visible = false;
	df_label.visible = false;
	
	if(!power_timer){
		power_timer = new Timer(80,40);
		power_timer.addEventListener(TimerEvent.TIMER,power_animation);
		power_timer.addEventListener(TimerEvent.TIMER_COMPLETE,power_complete);
		power_timer.start();
	}
}

//回復アニメーション
private function power_animation(event:TimerEvent):void{
	var currentCount:int = event.currentTarget.currentCount;
	var count:int = event.currentTarget.currentCount%2;
	var fail_count:int = event.currentTarget.currentCount%4;	
	
	battle_label.visible = false;
	power_label.visible = true;
	
	if(fighting_calc.now_player == 1){
		//回復アニメーション
		if(fighting_data[0].pp > 0){
			if(currentCount == 1){
				se.power_mp3.play();
			}
			
			hp_label.visible = true;
			st_label.visible = false;
			df_label.visible = false;
			if(currentCount <= 20){
				if(count == 0){
					hp_2p.text = " ==";
					st_2p.text = "";
					df_2p.text = "";
				}else{
					hp_2p.text = "";
					st_2p.text = "";
					df_2p.text = "";
				}
			}else{
				hp_2p.text = fighting_calc.display_power;
				st_2p.text = "";
				df_2p.text = "";
			}
			
		//薬草０個アニメーション
		}else{
			hp_label.visible = false;
			st_label.visible = false;
			df_label.visible = false;
			pp_label.visible = true;
			if(fail_count == 0){
				hp_1p.text = "";
				st_1p.text = "";
				df_1p.text = "";				
				hp_2p.text = "";
				st_2p.text = "";
				df_2p.pp_text = 0;
			}else{
				hp_1p.text = "";
				st_1p.text = "";
				df_1p.text = "";				
				hp_2p.text = "";
				st_2p.text = "";
				df_2p.text = "";
			}
		}	
	}else{
		//回復アニメーション
		if(fighting_data[1].pp > 0){
			if(currentCount == 1){
				se.power_mp3.play();
			}
			hp_label.visible = true;
			st_label.visible = false;
			df_label.visible = false;
			if(currentCount <= 20){
				if(count == 0){
					hp_1p.text = " ==";
					st_1p.text = "";
					df_1p.text = "";
				}else{
					hp_1p.text = "";
					st_1p.text = "";
					df_1p.text = "";
				}
			}else{
				hp_1p.text = fighting_calc.display_power;
				st_1p.text = "";
				df_1p.text = "";				
			}
			
		//薬草０個アニメーション
		}else{
			hp_label.visible = false;
			st_label.visible = false;
			df_label.visible = false;
			pp_label.visible = true;
			if(fail_count == 0){
				hp_2p.text = "";
				st_2p.text = "";
				df_2p.text = "";				
				hp_1p.text = "";
				st_1p.text = "";
				df_1p.pp_text = 0;
			}else{
				hp_2p.text = "";
				st_2p.text = "";
				df_2p.text = "";				
				hp_1p.text = "";
				st_1p.text = "";
				df_1p.text = "";
			}
		}
	}
	
	
}

//回復終了
private function power_complete(event:TimerEvent):void{
	
	if(power_timer){
		power_timer.removeEventListener(TimerEvent.TIMER,power_animation);
		power_timer.removeEventListener(TimerEvent.TIMER_COMPLETE,power_complete);
		power_timer.stop();
		power_timer = null;
	}

	if(fighting_calc.now_player == 1){
		power_flag = false;
		if(fighting_data[0].pp > 0){
			fighting_data[0].hp = fighting_data[0].hp + fighting_calc.display_power;
			fighting_data[0].pp = fighting_data[0].pp - 1;
			fighting_calc.now_player = 2;
		}


		battle_waiting_first = false;
		battle_waiting(new Event(Event.COMPLETE));
		
	}else{
		
		power_flag = false;
		if(fighting_data[1].pp > 0){
			fighting_data[1].hp = fighting_data[1].hp + fighting_calc.display_power;
			fighting_data[1].pp = fighting_data[1].pp - 1;
			fighting_calc.now_player = 1;
		}
			
		battle_waiting_first = false;
		battle_waiting(new Event(Event.COMPLETE));
	
	}
}



//セレクト開始(薬草,魔法)
private var select_animation_timer:Timer;
private var select_mp_pp:int =  1;	//魔法と薬草どっちを選択してるか。0=mp,デフォルト＝pp=1  
private var select_mp_function:int = -2;	//魔法でどれを選択しているか デフォルト=-2=未選択　 -1=選択開始    0～9=F0～F9
private var select_pp_state:int = -2;	    //薬草何個を選択しているか 　デフォルト=-2=未選択    -1=選択開始   1～3=薬草1個～3個
private var select_mp_enable:Boolean = false;//魔法を選択できるかどうか
private var select_battle_magic:Boolean=true; //F3,F4以外を選択できるかどうか
private var select_magic_pp_use:Boolean=false; //1度でも魔法か薬草を使ったか
private function select(event:MouseEvent):void{

	if(battle_get_animation_timer){
		battle_get_animation_timer.removeEventListener(TimerEvent.TIMER,battle_get_animation_c2);
		battle_get_animation_timer.stop();
		battle_get_animation_timer = null;
	}
	
	l_battle.removeEventListener(MouseEvent.CLICK,battle);
	l_power.removeEventListener(MouseEvent.CLICK,power);
	r_battle.removeEventListener(MouseEvent.CLICK,battle);
	r_power.removeEventListener(MouseEvent.CLICK,escape);
	r_power.removeEventListener(MouseEvent.CLICK,power);
	select_button.removeEventListener(MouseEvent.CLICK,select);

	select_mp_pp = 1;	//薬草を選択
	select_mp_function = -2;	//未選択
	select_pp_state    = -2;	//未選択
	
	if(!select_animation_timer){
		select_animation_timer = new Timer(150);
		select_animation_timer.addEventListener(TimerEvent.TIMER,select_animation);
		select_animation_timer.start();
	}

	//パワーをオンに
	power_flag = true;
	battle_label.visible = false;
	power_label.visible = true;
	
	//ラベル表示
	hp_label.visible = true;
	damage_label.visible = false;
	st_label.visible  = false;
	df_label.visible = false;
	pp_label.visible = true;
	
	if(fighting_calc.now_player == 1){
		hp_1p.text = fighting_data[0].hp;
		df_1p.pp_text = fighting_data[0].pp;
		
		hp_2p.text = "";
		st_2p.text = "";
		df_2p.text = "";
		
		if(fighting_data[0].job <= 6){
			select_mp_enable = false;
			mp_label.visible = false;
			st_1p.text = "";
		}else{
			st_1p.mp_text = fighting_data[0].mp;
			select_mp_enable = true;
			mp_label.visible = true;
		}
	}else{
		hp_2p.text = fighting_data[1].hp;
		df_2p.pp_text = fighting_data[1].pp;
		hp_1p.text = "";
		st_1p.text = "";
		df_1p.text = "";
		
		if(fighting_data[1].job <= 6){
			select_mp_enable = false;
			mp_label.visible = false;
			st_2p.text = "";
		}else{
			st_2p.mp_text = fighting_data[1].mp;
			select_mp_enable = true;
			mp_label.visible = true;
		}
	}

	select_button.addEventListener(MouseEvent.CLICK,select_state);
	set_button.addEventListener(MouseEvent.CLICK,set_state);
	
}

//セレクトアニメーション
private function select_animation(event:TimerEvent):void{
	
	var currentCount:int = event.currentTarget.currentCount;
	var count:int = event.currentTarget.currentCount%2;

	if(fighting_calc.now_player == 1){
		//魔法
		if(select_mp_pp==0){
			//未選択
			if(select_mp_function == -2){
				df_1p.pp_text = fighting_data[0].pp;
				if(count == 0){
					st_1p.mp_text = fighting_data[0].mp;
				}else{
					st_1p.text = "";
				}
				df_2p.text = "";
			//選択開始
			}else if(select_mp_function == -1){
				st_1p.mp_text = fighting_data[0].mp;
				df_1p.pp_text = fighting_data[0].pp;
				if(count == 0){
					st_2p.text = " ==";
				}else{
					st_2p.text = "";
				}
				df_2p.text = "";
			//F0～F9
			}else{
				st_1p.mp_text = fighting_data[0].mp;
				df_1p.pp_text = fighting_data[0].pp;
				if(count == 0){
					st_2p.text = " F"+select_mp_function.toString();
				}else{
					st_2p.text = "";
				}
				df_2p.text = "";
			}
		//薬草
		}else{
			//未選択
			if(select_pp_state == -2){
				if(select_mp_enable){
					st_1p.mp_text = fighting_data[0].mp;
				}else{
					st_1p.mp_text = "";
				}
				if(count == 0){
					df_1p.pp_text = fighting_data[0].pp;
				}else{
					df_1p.text = "";
				}
				st_2p.text = "";
				df_2p.text = "";
			//選択開始
			}else if(select_pp_state == -1){
				if(select_mp_enable){
					st_1p.mp_text = fighting_data[0].mp;
				}else{
					st_1p.mp_text = "";
				}
				df_1p.pp_text = fighting_data[0].pp;
				st_2p.text = "";
				if(count == 0){
					df_2p.text = " ==";
				}else{
					df_2p.text = "";
				}				
			//薬草1～3
			}else{
				if(select_mp_enable){
					st_1p.mp_text = fighting_data[0].mp;
				}else{
					st_1p.mp_text = "";
				}
				df_1p.pp_text = fighting_data[0].pp;
				st_2p.text = "";
				if(count == 0){
					df_2p.pp_text = select_pp_state.toString();
				}else{
					df_2p.text = "";
				}				
			}
		}
	}else{
		//魔法
		if(select_mp_pp==0){
			//未選択
			if(select_mp_function == -2){
				df_2p.pp_text = fighting_data[1].pp;
				if(count == 0){
					st_2p.mp_text = fighting_data[1].mp;
				}else{
					st_2p.text = "";
				}
				df_1p.text = "";
			//選択開始
			}else if(select_mp_function == -1){
				st_2p.mp_text = fighting_data[1].mp;
				df_2p.pp_text = fighting_data[1].pp;
				if(count == 0){
					st_1p.text = " ==";
				}else{
					st_1p.text = "";
				}
				df_1p.text = "";
			//F0～F9
			}else{
				st_2p.mp_text = fighting_data[1].mp;
				df_2p.pp_text = fighting_data[1].pp;
				if(count == 0){
					st_1p.text = " F"+select_mp_function.toString();
				}else{
					st_1p.text = "";
				}
				df_1p.text = "";
			}
		//薬草
		}else{
			//未選択
			if(select_pp_state == -2){
				if(select_mp_enable){
					st_2p.mp_text = fighting_data[1].mp;
				}else{
					st_2p.mp_text = "";
				}
				if(count == 0){
					df_2p.pp_text = fighting_data[1].pp;
				}else{
					df_2p.text = "";
				}
				st_1p.text = "";
				df_1p.text = "";
			//選択開始
			}else if(select_pp_state == -1){
				if(select_mp_enable){
					st_2p.mp_text = fighting_data[1].mp;
				}else{
					st_2p.mp_text = "";
				}
				df_2p.pp_text = fighting_data[1].pp;
				st_1p.text = "";
				if(count == 0){
					df_1p.text = " ==";
				}else{
					df_1p.text = "";
				}				
			//薬草1～3
			}else{
				if(select_mp_enable){
					st_2p.mp_text = fighting_data[1].mp;
				}else{
					st_2p.mp_text = "";
				}
				df_2p.pp_text = fighting_data[1].pp;
				st_1p.text = "";
				if(count == 0){
					df_1p.pp_text = select_pp_state.toString();
				}else{
					df_1p.text = "";
				}				
			}
		}	
	}

	
}

private var button_ignore_state:Boolean = false;
//ステート変更
private function select_state(event:MouseEvent):void{
	
	if(fighting_calc.now_player == 1){
		//未選択
		if(select_mp_function==-2 && select_pp_state == -2){
			se.select_mp3.play();
			if(select_mp_pp == 1 && select_mp_enable){
				select_mp_pp = 0;
			}else{
				select_mp_pp = 1;
			}
		//選択済み
		}else{
			se.select_mp3.play();
			
			//魔法選択中
			if(select_mp_function >= -1){
				
				select_mp_function = fighting_calc.select_next_mp_function(fighting_data[0],select_mp_function,select_battle_magic);
				
			//薬草選択中
			}else if(select_pp_state >= -1){
				
				select_pp_state = fighting_calc.select_next_pp_state(fighting_data[0],select_pp_state);
								
			}
		}
	}else{
		//未選択
		if(select_mp_function==-2 && select_pp_state == -2){
			se.select_mp3.play();
			if(select_mp_pp == 1 && select_mp_enable){
				select_mp_pp = 0;
			}else{
				select_mp_pp = 1;
			}	
		//選択済み
		}else{
			se.select_mp3.play();
			//魔法選択中
			if(select_mp_function >= -1){
				
				select_mp_function = fighting_calc.select_next_mp_function(fighting_data[1],select_mp_function,select_battle_magic);
				
			//薬草選択中
			}else if(select_pp_state >= -1){
				
				select_pp_state = fighting_calc.select_next_pp_state(fighting_data[1],select_pp_state);
				
			}
		}	
	}
	
}

//ステート決定
private function set_state(event:MouseEvent):void{
	
		//魔法選択中
		if(select_mp_pp==0){
			//未選択
			if(select_mp_function==-2){
				se.decide_mp3.play();
				select_mp_function = -1;
			//選択開始
			}else if(select_mp_function == -1){
				se.decide_mp3.play();
				power_flag = false;
				select_button.removeEventListener(MouseEvent.CLICK,select_state);
				set_button.removeEventListener(MouseEvent.CLICK,set_state);
				if(select_animation_timer){
					select_animation_timer.removeEventListener(TimerEvent.TIMER,select_animation);
					select_animation_timer.stop();
					select_animation_timer = null;
				}
				
				//C0モード、戦闘中
				if(select_battle_magic){
					battle_waiting_first = false;
					battle_waiting(new Event(Event.COMPLETE));
				//C2モード、戦闘後
				}else{
					select_end_state(new MouseEvent(MouseEvent.CLICK));
				}
			//魔法選択
			}else{
				select_button.removeEventListener(MouseEvent.CLICK,select_state);
				set_button.removeEventListener(MouseEvent.CLICK,set_state);
				if(select_animation_timer){
					select_animation_timer.removeEventListener(TimerEvent.TIMER,select_animation);
					select_animation_timer.stop();
					select_animation_timer = null;
				}
				use_magic();
			}
		//薬草選択中
		}else{
			//未選択
			if(select_pp_state==-2){
				se.decide_mp3.play();
				select_pp_state = -1;
			//選択開始
			}else if(select_pp_state == -1){
				se.decide_mp3.play();
				power_flag = false;
				select_button.removeEventListener(MouseEvent.CLICK,select_state);
				set_button.removeEventListener(MouseEvent.CLICK,set_state);
				if(select_animation_timer){
					select_animation_timer.removeEventListener(TimerEvent.TIMER,select_animation);
					select_animation_timer.stop();
					select_animation_timer = null;
				}
				
				//C0モード、戦闘中
				if(select_battle_magic){
					battle_waiting_first = false;
					battle_waiting(new Event(Event.COMPLETE));
				//C2モード、戦闘後
				}else{
					select_end_state(new MouseEvent(MouseEvent.CLICK));
				}
			}else{
				power_flag = true;
				select_button.removeEventListener(MouseEvent.CLICK,select_state);
				set_button.removeEventListener(MouseEvent.CLICK,set_state);
				if(select_animation_timer){
					select_animation_timer.removeEventListener(TimerEvent.TIMER,select_animation);
					select_animation_timer.stop();
					select_animation_timer = null;
				}
				use_pp();
			}
		}
		
}



//薬草使用計算
private var use_pp_animation_timer:Timer;
private function use_pp():void{
	
	//1Pの回復
	if(fighting_calc.now_player == 1){
		if(fighting_data[0].pp > 0){
			var pp_power:int = fighting_calc.use_pp_power(fighting_data[0],fighting_data[1],select_pp_state);
			fighting_calc.display_power = pp_power;
		}
	//2Pの回復
	}else{
		if(fighting_data[1].pp > 0){
			pp_power = fighting_calc.use_pp_power(fighting_data[1],fighting_data[0],select_pp_state);
			fighting_calc.display_power = pp_power;
		}
	}	
	
	if(!use_pp_animation_timer){
		se.power_mp3.play();
		use_pp_animation_timer = new Timer(80,40);
		use_pp_animation_timer.addEventListener(TimerEvent.TIMER,use_pp_animation);
		use_pp_animation_timer.addEventListener(TimerEvent.TIMER_COMPLETE,use_pp_complete);
		use_pp_animation_timer.start();
	}
	
}


//薬草使用アニメーション
private function use_pp_animation(event:TimerEvent):void{
		
	var currentCount:int = event.currentTarget.currentCount;
	var count:int = event.currentTarget.currentCount%2;
	
	battle_label.visible = false;
	power_label.visible = true;

	if(fighting_calc.now_player == 1){
		//回復アニメーション
		if(currentCount <= 20){
			if(count == 0){
				hp_2p.text = " ==";
				st_2p.text = "";
				df_2p.text = "";
			}else{
				hp_2p.text = "";
				st_2p.text = "";
				df_2p.text = "";
			}
		}else{
			hp_2p.text = fighting_calc.display_power;
			st_2p.text = "";
			df_2p.text = "";
		}
	}else{
		//回復アニメーション
		if(currentCount <= 20){
			if(count == 0){
				hp_1p.text = " ==";
				st_1p.text = "";
				df_1p.text = "";
			}else{
				hp_1p.text = "";
				st_1p.text = "";
				df_1p.text = "";
			}
		}else{
			hp_1p.text = fighting_calc.display_power;
			st_1p.text = "";
			df_1p.text = "";
		}
	}				
	
	
}

//薬草使用完了
private function use_pp_complete(event:TimerEvent):void{
	
	power_flag = false;
	if(use_pp_animation_timer){
		use_pp_animation_timer.removeEventListener(TimerEvent.TIMER,use_pp_animation);
		use_pp_animation_timer.removeEventListener(TimerEvent.TIMER,use_pp_complete);
		use_pp_animation_timer.removeEventListener(TimerEvent.TIMER_COMPLETE,f3_complete);
		use_pp_animation_timer.removeEventListener(TimerEvent.TIMER_COMPLETE,f4_complete);
		use_pp_animation_timer.stop();
		use_pp_animation_timer = null;
	}
	
	//使った薬草を引く
	if(fighting_calc.now_player == 1){
		fighting_data[0].hp = fighting_data[0].hp + fighting_calc.display_power;
		fighting_data[0].pp = fighting_data[0].pp - select_pp_state;
		fighting_calc.now_player = 2;
	}else{
		fighting_data[1].hp = fighting_data[1].hp + fighting_calc.display_power;
		fighting_data[1].pp = fighting_data[1].pp - select_pp_state;
		fighting_calc.now_player = 1;
	}

	//C0モード、戦闘中
	if(select_battle_magic){
		battle_waiting_first = false;
		battle_waiting(new Event(Event.COMPLETE));
		//C2モード、戦闘後
	}else{
		select_magic_pp_use = true;
		magic_pp_use_copy();
		select_end_state(new MouseEvent(MouseEvent.CLICK));
	}
}



//魔法使用
private function use_magic():void{
	switch(select_mp_function){
		case 0:
			f0();
		break;
		
		case 1:
			f1();
		break;
		
		case 2:
			f2();
		break;
		
		case 3:
			f3();
		break;
		
		case 4:
			f4();
		break;
		
		case 5:
			f5();
		break;
		
		case 6:
			f6();
		break;
		
		case 7:
			f7();
		break;
		
		case 8:
			f8();
		break;
		
		case 9:
			f9();
		break;
	}
	
}

//F0 トルマ  消費0
private var battle_power_disable_flag:Boolean = false;
private var f0_animation_timer:Timer;
private function f0():void{
	battle_power_disable_flag = true;
	battle_label.visible = false;
	power_label.visible = false;
	
	if(fighting_calc.now_player == 1){
		fighting_calc.display_f0_mp = fighting_calc.calc_f0(fighting_data[1]);
	}else{
		fighting_calc.display_f0_mp = fighting_calc.calc_f0(fighting_data[0]);
	}
	
	if(!f0_animation_timer){
		f0_animation_timer = new Timer(150,20);
		f0_animation_timer.addEventListener(TimerEvent.TIMER,f0_animation);
		f0_animation_timer.addEventListener(TimerEvent.TIMER_COMPLETE,f0_complete);
		f0_animation_timer.start();
	}
	se.status_down_mp3.play();
}

private function f0_animation(event:TimerEvent):void{
	var currentCount:int = event.currentTarget.currentCount;
	var count:int = event.currentTarget.currentCount%2;
	
	//MP変更
	if(currentCount == 12){
		se.change_mp3.play();
		if(fighting_calc.now_player == 1){
			fighting_data[0].mp = fighting_data[0].mp + fighting_calc.display_f0_mp;
			if( fighting_data[0].mp > 99){
				fighting_data[0].mp = 99;
			}
			fighting_data[1].mp = fighting_data[1].mp - fighting_calc.display_f0_mp;
		}else{
			fighting_data[1].mp = fighting_data[1].mp + fighting_calc.display_f0_mp;
			if( fighting_data[1].mp > 99){
				fighting_data[1].mp = 99;
			}
			fighting_data[0].mp = fighting_data[0].mp - fighting_calc.display_f0_mp;			
		}
	}

	if(currentCount <12){
		if(fighting_calc.now_player == 1){
			if(count == 0){
				hp_1p.text = fighting_data[0].hp;
				st_1p.mp_text = fighting_data[0].mp;
				df_1p.pp_text = fighting_data[0].pp;
				hp_2p.text = fighting_data[1].hp;
				st_2p.mp_text = fighting_data[1].mp;
				df_2p.pp_text = fighting_data[1].pp;
			}else{
				hp_1p.text = fighting_data[0].hp;
				st_1p.mp_text = fighting_data[0].mp;
				df_1p.pp_text = fighting_data[0].pp;
				hp_2p.text = fighting_data[1].hp;
				st_2p.text = "";
				df_2p.pp_text = fighting_data[1].pp;
			}
		}else{
			if(count == 0){
				hp_2p.text = fighting_data[1].hp;
				st_2p.mp_text = fighting_data[1].mp;
				df_2p.pp_text = fighting_data[1].pp;
				hp_1p.text = fighting_data[0].hp;
				st_1p.mp_text = fighting_data[0].mp;
				df_1p.pp_text = fighting_data[0].pp;
			}else{
				hp_2p.text = fighting_data[1].hp;
				st_2p.mp_text = fighting_data[1].mp;
				df_2p.pp_text = fighting_data[1].pp;
				hp_1p.text = fighting_data[0].hp;
				st_1p.text = "";
				df_1p.pp_text = fighting_data[0].pp;
			}
		}
	}else{
			hp_1p.text = fighting_data[0].hp;
			st_1p.mp_text = fighting_data[0].mp;
			df_1p.pp_text = fighting_data[0].pp;
			hp_2p.text = fighting_data[1].hp;
			st_2p.mp_text = fighting_data[1].mp;
			df_2p.pp_text = fighting_data[1].pp;
	}
	
	
}

private function f0_complete(event:TimerEvent):void{
	battle_power_disable_flag = false;
	power_flag = false;
	if(f0_animation_timer){
		f0_animation_timer.removeEventListener(TimerEvent.TIMER,f0_animation);
		f0_animation_timer.removeEventListener(TimerEvent.TIMER_COMPLETE,f0_complete);
		f0_animation_timer.stop();
		f0_animation_timer = null;
	}
	if(fighting_calc.now_player == 1){
		fighting_calc.now_player = 2;
	}else{
		fighting_calc.now_player = 1;
	}

	battle_waiting_first = false;
	battle_waiting(new Event(Event.COMPLETE));		
}





//F1 ガンツ  消費2
private var f1_animation_timer:Timer;
private function f1():void{
	
	battle_flag = true;
	power_flag  = false;
	battle_label.visible = true;
	power_label.visible = false;

	//データ表示
	hp_1p.text = fighting_data[0].hp;
	st_1p.text = fighting_data[0].st;
	df_1p.text = fighting_data[0].df;
	hp_2p.text = fighting_data[1].hp;
	st_2p.text = fighting_data[1].st;
	df_2p.text = fighting_data[1].df;
	hp_label.visible = true;
	damage_label.visible = false;
	st_label.visible = true;
	mp_label.visible = false;
	df_label.visible = true;
	pp_label.visible = false;

	//1Pの攻撃
	if(fighting_calc.now_player == 1){
		//MISS
		var hit:Boolean = fighting_calc.calc_hit(fighting_data[0],fighting_data[1],0x0F);
		if(hit){
			var basic_damage:int = fighting_calc.basic_damage(fighting_data[0],fighting_data[1]);
			var multi_damage:int = fighting_calc.special_multi(fighting_data[0],fighting_data[1],basic_damage,0x0F);
			fighting_calc.display_damage = multi_damage;

			//HIT
			fighting_data[1].hp = fighting_data[1].hp - multi_damage;
			if(fighting_data[1].hp < 0){
				fighting_data[1].hp = 0;
			}
			
			var critical_hit:Boolean = fighting_calc.critical_hit(fighting_data[0]);
			if(critical_hit){
				se.battle_critical_mp3.play();
			}else{
				se.battle_mp3.play();
			}
			
			
		}else{
			se.battle_miss_mp3.play();
			fighting_calc.display_damage = 0;
		}
				
	//2Pの攻撃
	}else{
		hit = fighting_calc.calc_hit(fighting_data[1],fighting_data[0],0x0F);
		
		if(hit){
			basic_damage = fighting_calc.basic_damage(fighting_data[1],fighting_data[0]);
			multi_damage = fighting_calc.special_multi(fighting_data[1],fighting_data[0],basic_damage,0x0F);
			fighting_calc.display_damage = multi_damage;
			
			fighting_data[0].hp = fighting_data[0].hp - multi_damage;
			if(fighting_data[0].hp < 0){
				fighting_data[0].hp = 0;
			}
			
			critical_hit = fighting_calc.critical_hit(fighting_data[1]);
			if(critical_hit){
				se.battle_critical_mp3.play();
			}else{
				se.battle_mp3.play();
			}
			
		}else{
			se.battle_miss_mp3.play();
			fighting_calc.display_damage = 0;
		}

	}
	
	damage_label.visible = true;
	hp_label.visible = false;
	st_label.visible = false;
	df_label.visible = false;
	
	if(!battle_timer){
		if(hit){
			if(critical_hit){
				var time:int = 90;
				battle_end_count = 40;
			}else{
				time = 110;
				battle_end_count = 60;
			}
		}else{
			time = 130;
			battle_end_count = 80;
		}
		battle_timer = new Timer(40,time);
		battle_timer.addEventListener(TimerEvent.TIMER,battle_animation);
		battle_timer.addEventListener(TimerEvent.TIMER_COMPLETE,f1_complete);
		battle_timer.addEventListener(TimerEvent.TIMER_COMPLETE,battle_complete);
		battle_timer.start();
	}
}

private function f1_complete(event:TimerEvent):void{
	
	if(fighting_calc.now_player == 1){
		fighting_data[0].mp = fighting_data[0].mp - fighting_calc.magic_list[1];
	}else{
		fighting_data[1].mp = fighting_data[1].mp - fighting_calc.magic_list[1];
	}
	
}



//F2 デガンツ　消費5
private function f2():void{
	
	battle_flag = true;
	power_flag  = false;
	battle_label.visible = true;
	power_label.visible = false;

	//データ表示
	hp_1p.text = fighting_data[0].hp;
	st_1p.text = fighting_data[0].st;
	df_1p.text = fighting_data[0].df;
	hp_2p.text = fighting_data[1].hp;
	st_2p.text = fighting_data[1].st;
	df_2p.text = fighting_data[1].df;
	hp_label.visible = true;
	damage_label.visible = false;
	st_label.visible = true;
	mp_label.visible = false;
	df_label.visible = true;
	pp_label.visible = false;

	//1Pの攻撃
	if(fighting_calc.now_player == 1){
		//MISS
		var hit:Boolean = fighting_calc.calc_hit(fighting_data[0],fighting_data[1],0x14);
		if(hit){
			var basic_damage:int = fighting_calc.basic_damage(fighting_data[0],fighting_data[1]);
			var multi_damage:int = fighting_calc.special_multi(fighting_data[0],fighting_data[1],basic_damage,0x14);
			fighting_calc.display_damage = multi_damage;

			//HIT
			fighting_data[1].hp = fighting_data[1].hp - multi_damage;
			if(fighting_data[1].hp < 0){
				fighting_data[1].hp = 0;
			}
			
			var critical_hit:Boolean = fighting_calc.critical_hit(fighting_data[0]);
			if(critical_hit){
				se.battle_critical_mp3.play();
			}else{
				se.battle_mp3.play();
			}
			
			
		}else{
			se.battle_miss_mp3.play();
			fighting_calc.display_damage = 0;
		}
				
	//2Pの攻撃
	}else{
		hit = fighting_calc.calc_hit(fighting_data[1],fighting_data[0],0x14);
		
		if(hit){
			basic_damage = fighting_calc.basic_damage(fighting_data[1],fighting_data[0]);
			multi_damage = fighting_calc.special_multi(fighting_data[1],fighting_data[0],basic_damage,0x14);
			fighting_calc.display_damage = multi_damage;
			
			fighting_data[0].hp = fighting_data[0].hp - multi_damage;
			if(fighting_data[0].hp < 0){
				fighting_data[0].hp = 0;
			}
			
			critical_hit = fighting_calc.critical_hit(fighting_data[1]);
			if(critical_hit){
				se.battle_critical_mp3.play();
			}else{
				se.battle_mp3.play();
			}
			
		}else{
			se.battle_miss_mp3.play();
			fighting_calc.display_damage = 0;
		}

	}
	
	damage_label.visible = true;
	hp_label.visible = false;
	st_label.visible = false;
	df_label.visible = false;
	
	if(!battle_timer){
		if(hit){
			if(critical_hit){
				var time:int = 90;
				battle_end_count = 40;
			}else{
				time = 110;
				battle_end_count = 60;
			}
		}else{
			time = 130;
			battle_end_count = 80;
		}
		battle_timer = new Timer(40,time);
		battle_timer.addEventListener(TimerEvent.TIMER,battle_animation);
		battle_timer.addEventListener(TimerEvent.TIMER_COMPLETE,f2_complete);
		battle_timer.addEventListener(TimerEvent.TIMER_COMPLETE,battle_complete);
		battle_timer.start();
	}	
}
private function f2_complete(event:TimerEvent):void{
	
	if(fighting_calc.now_player == 1){
		fighting_data[0].mp = fighting_data[0].mp - fighting_calc.magic_list[2];
	}else{
		fighting_data[1].mp = fighting_data[1].mp - fighting_calc.magic_list[2];
	}
		
}


//F3 リーモ　消費2
private function f3():void{
	
	//1Pの回復
	if(fighting_calc.now_player == 1){
	
		var f3_power:int = fighting_calc.calc_f3(fighting_data[0]);
		fighting_calc.display_power = f3_power;
		
	//2Pの回復
	}else{
		
		f3_power = fighting_calc.calc_f3(fighting_data[1]);
		fighting_calc.display_power = f3_power;

	}	
	
	if(!use_pp_animation_timer){
		se.power_mp3.play();
		use_pp_animation_timer = new Timer(80,40);
		use_pp_animation_timer.addEventListener(TimerEvent.TIMER,use_pp_animation);
		use_pp_animation_timer.addEventListener(TimerEvent.TIMER_COMPLETE,f3_complete);
		use_pp_animation_timer.start();
	}	
}

private function f3_complete(event:TimerEvent):void{
	power_flag = false;
	if(use_pp_animation_timer){
		use_pp_animation_timer.removeEventListener(TimerEvent.TIMER,use_pp_animation);
		use_pp_animation_timer.removeEventListener(TimerEvent.TIMER,use_pp_complete);
		use_pp_animation_timer.removeEventListener(TimerEvent.TIMER_COMPLETE,f3_complete);
		use_pp_animation_timer.removeEventListener(TimerEvent.TIMER_COMPLETE,f4_complete);
		use_pp_animation_timer.stop();
		use_pp_animation_timer = null;
	}
	
	if(fighting_calc.now_player == 1){
		fighting_data[0].hp = fighting_data[0].hp + fighting_calc.display_power;
		fighting_data[0].mp = fighting_data[0].mp - fighting_calc.magic_list[3];
		fighting_calc.now_player = 2;
	}else{
		fighting_data[1].hp = fighting_data[1].hp + fighting_calc.display_power;
		fighting_data[1].mp = fighting_data[1].mp - fighting_calc.magic_list[3];
		fighting_calc.now_player = 1;
	}
	
	//C0モード、戦闘中
	if(select_battle_magic){
		battle_waiting_first = false;
		battle_waiting(new Event(Event.COMPLETE));
		//C2モード、戦闘後
	}else{
		select_magic_pp_use = true;
		magic_pp_use_copy();
		select_end_state(new MouseEvent(MouseEvent.CLICK));
	}	
	
}


//F4 デリーモ　消費4
private function f4():void{
	
	//1Pの回復
	if(fighting_calc.now_player == 1){
	
		var f4_power:int = fighting_calc.calc_f4(fighting_data[0]);
		fighting_calc.display_power = f4_power;
		
	//2Pの回復
	}else{
		
		f4_power = fighting_calc.calc_f4(fighting_data[1]);
		fighting_calc.display_power = f4_power;

	}	
	
	if(!use_pp_animation_timer){
		se.power_mp3.play();
		use_pp_animation_timer = new Timer(80,40);
		use_pp_animation_timer.addEventListener(TimerEvent.TIMER,use_pp_animation);
		use_pp_animation_timer.addEventListener(TimerEvent.TIMER_COMPLETE,f4_complete);
		use_pp_animation_timer.start();
	}
}

private function f4_complete(event:TimerEvent):void{
		
	power_flag = false;
	if(use_pp_animation_timer){
		use_pp_animation_timer.removeEventListener(TimerEvent.TIMER,use_pp_animation);
		use_pp_animation_timer.removeEventListener(TimerEvent.TIMER,use_pp_complete);
		use_pp_animation_timer.removeEventListener(TimerEvent.TIMER_COMPLETE,f3_complete);
		use_pp_animation_timer.removeEventListener(TimerEvent.TIMER_COMPLETE,f4_complete);
		use_pp_animation_timer.stop();
		use_pp_animation_timer = null;
	}
	
	if(fighting_calc.now_player == 1){
		fighting_data[0].hp = fighting_data[0].hp + fighting_calc.display_power;
		fighting_data[0].mp = fighting_data[0].mp - fighting_calc.magic_list[4];
		fighting_calc.now_player = 2;
	}else{
		fighting_data[1].hp = fighting_data[1].hp + fighting_calc.display_power;
		fighting_data[1].mp = fighting_data[1].mp - fighting_calc.magic_list[4];
		fighting_calc.now_player = 1;
	}
	
	//C0モード、戦闘中
	if(select_battle_magic){
		battle_waiting_first = false;
		battle_waiting(new Event(Event.COMPLETE));
		//C2モード、戦闘後
	}else{
		select_magic_pp_use = true;
		magic_pp_use_copy();
		select_end_state(new MouseEvent(MouseEvent.CLICK));
	}	
	
}


//F5 ニャーヘ　消費3
private var f5_animation_timer:Timer;
private function f5():void{
	battle_power_disable_flag = true;
	battle_label.visible = false;
	power_label.visible = false;
	if(!f5_animation_timer){
		f5_animation_timer = new Timer(150,12);
		f5_animation_timer.addEventListener(TimerEvent.TIMER,f5_animation);
		f5_animation_timer.addEventListener(TimerEvent.TIMER_COMPLETE,f5_complete);
		f5_animation_timer.start();
	}

	hp_label.visible = true;
	damage_label.visible = false;
	st_label.visible = true;
	mp_label.visible = false;
	df_label.visible = true;
	pp_label.visible = false;

	se.status_down_mp3.play();
}

private function f5_animation(event:TimerEvent):void{
	var currentCount:int = event.currentTarget.currentCount;
	var count:int = event.currentTarget.currentCount%2;
	
	if(fighting_calc.now_player == 1){
		if(count == 0){
			hp_1p.text = fighting_data[0].hp;
			st_1p.text = fighting_data[0].st;
			df_1p.text = fighting_data[0].df;
			hp_2p.text = fighting_data[1].hp;
			st_2p.text = fighting_data[1].st;
			df_2p.text = fighting_data[1].df;
		}else{
			hp_1p.text = fighting_data[0].hp;
			st_1p.text = fighting_data[0].st;
			df_1p.text = fighting_data[0].df;
			hp_2p.text = fighting_data[1].hp;
			st_2p.text = fighting_data[1].st;
			df_2p.text = "";
		}	
	}else{
		if(count == 0){
			hp_2p.text = fighting_data[1].hp;
			st_2p.text = fighting_data[1].st;
			df_2p.text = fighting_data[1].df;
			hp_1p.text = fighting_data[0].hp;
			st_1p.text = fighting_data[0].st;
			df_1p.text = fighting_data[0].df;
		}else{
			hp_2p.text = fighting_data[1].hp;
			st_2p.text = fighting_data[1].st;
			df_2p.text = fighting_data[1].df;
			hp_1p.text = fighting_data[0].hp;
			st_1p.text = fighting_data[0].st;
			df_1p.text = "";
		}
	}
}

private function f5_complete(event:TimerEvent):void{
	
	se.change_mp3.play();
	battle_power_disable_flag = false;
	power_flag = false;
	if(f5_animation_timer){
		f5_animation_timer.addEventListener(TimerEvent.TIMER,f5_animation);
		f5_animation_timer.addEventListener(TimerEvent.TIMER_COMPLETE,f5_complete);
		f5_animation_timer.stop();
		f5_animation_timer = null;
	}
	
	if(fighting_calc.now_player == 1){
		var calc_f5:int = fighting_calc.calc_f5(fighting_data[1]);
		fighting_data[1].df1 = fighting_data[1].df1 - calc_f5;
		fighting_data[1].df = fighting_data[1].df2 + fighting_data[1].df1;
		if(fighting_data[1].df > 199){
			fighting_data[1].df = 199;
		}
		fighting_data[0].mp = fighting_data[0].mp - fighting_calc.magic_list[5];
		fighting_calc.now_player = 2;
	}else{
		calc_f5 = fighting_calc.calc_f5(fighting_data[0]);
		fighting_data[0].df1 = fighting_data[0].df1 - calc_f5
		fighting_data[0].df = fighting_data[0].df2 + fighting_data[0].df1;
		if(fighting_data[0].df > 199){
			fighting_data[0].df = 199;
		}
		fighting_data[1].mp = fighting_data[1].mp - fighting_calc.magic_list[5];
		fighting_calc.now_player = 1;
	}

	battle_waiting_first = false;
	battle_waiting(new Event(Event.COMPLETE));	
}


//F6 カチコム　消費5
private var f6_animation_timer:Timer;
private function f6():void{
	battle_power_disable_flag = true;
	battle_label.visible = false;
	power_label.visible = false;
	if(!f6_animation_timer){
		f6_animation_timer = new Timer(150,12);
		f6_animation_timer.addEventListener(TimerEvent.TIMER,f6_animation);
		f6_animation_timer.addEventListener(TimerEvent.TIMER_COMPLETE,f6_complete);
		f6_animation_timer.start();
	}

	hp_label.visible = true;
	damage_label.visible = false;
	st_label.visible = true;
	mp_label.visible = false;
	df_label.visible = true;
	pp_label.visible = false;

	se.status_down_mp3.play();	
}

private function f6_animation(event:TimerEvent):void{
	var currentCount:int = event.currentTarget.currentCount;
	var count:int = event.currentTarget.currentCount%2;
	
	if(fighting_calc.now_player == 1){
		if(count == 0){
			hp_1p.text = fighting_data[0].hp;
			st_1p.text = fighting_data[0].st;
			df_1p.text = fighting_data[0].df;
			hp_2p.text = fighting_data[1].hp;
			st_2p.text = fighting_data[1].st;
			df_2p.text = fighting_data[1].df;
		}else{
			hp_1p.text = fighting_data[0].hp;
			st_1p.text = fighting_data[0].st;
			df_1p.text = "";
			hp_2p.text = fighting_data[1].hp;
			st_2p.text = fighting_data[1].st;
			df_2p.text = fighting_data[1].df;
		}	
	}else{
		if(count == 0){
			hp_2p.text = fighting_data[1].hp;
			st_2p.text = fighting_data[1].st;
			df_2p.text = fighting_data[1].df;
			hp_1p.text = fighting_data[0].hp;
			st_1p.text = fighting_data[0].st;
			df_1p.text = fighting_data[0].df;
		}else{
			hp_2p.text = fighting_data[1].hp;
			st_2p.text = fighting_data[1].st;
			df_2p.text = "";
			hp_1p.text = fighting_data[0].hp;
			st_1p.text = fighting_data[0].st;
			df_1p.text = fighting_data[0].df;
		}
	}	
}

private function f6_complete(event:TimerEvent):void{
	se.change_mp3.play();
	battle_power_disable_flag = false;
	power_flag = false;
	
	if(f6_animation_timer){
		f6_animation_timer.addEventListener(TimerEvent.TIMER,f6_animation);
		f6_animation_timer.addEventListener(TimerEvent.TIMER_COMPLETE,f6_complete);
		f6_animation_timer.stop();
		f6_animation_timer = null;
	}
	
	if(fighting_calc.now_player == 1){
		var calc_f6:int = fighting_calc.calc_f6(fighting_data[0]);
		fighting_data[0].df1 = fighting_data[0].df1 + calc_f6;
		if(fighting_data[0].df1 > 199){
			fighting_data[0].df1 = 199;
		}
		fighting_data[0].df = fighting_data[0].df2 + fighting_data[0].df1;
		if(fighting_data[0].df > 199){
			fighting_data[0].df = 199;
		}
		fighting_data[0].mp = fighting_data[0].mp - fighting_calc.magic_list[6];
		fighting_calc.now_player = 2;
	}else{
		calc_f6 = fighting_calc.calc_f6(fighting_data[1]);
		fighting_data[1].df1 = fighting_data[1].df1 + calc_f6;
		if(fighting_data[1].df1 > 199){
			fighting_data[1].df1 = 199;
		}
		fighting_data[1].df = fighting_data[1].df2 + fighting_data[1].df1;
		if(fighting_data[1].df > 199){
			fighting_data[1].df = 199;
		}
		fighting_data[1].mp = fighting_data[1].mp - fighting_calc.magic_list[6];		
		fighting_calc.now_player = 1;
	}
	
	battle_waiting_first = false;
	battle_waiting(new Event(Event.COMPLETE));		
}



//F7 ヘヘンダ　消費4
private var f7_animation_timer:Timer;
private function f7():void{
	battle_power_disable_flag = true;
	battle_label.visible = false;
	power_label.visible = false;
	if(!f7_animation_timer){
		f7_animation_timer = new Timer(150,12);
		f7_animation_timer.addEventListener(TimerEvent.TIMER,f7_animation);
		f7_animation_timer.addEventListener(TimerEvent.TIMER_COMPLETE,f7_complete);
		f7_animation_timer.start();
	}

	hp_label.visible = true;
	damage_label.visible = false;
	st_label.visible = true;
	mp_label.visible = false;
	df_label.visible = true;
	pp_label.visible = false;

	se.status_down_mp3.play();	
}

private function f7_animation(event:TimerEvent):void{
	var currentCount:int = event.currentTarget.currentCount;
	var count:int = event.currentTarget.currentCount%2;
	
	if(fighting_calc.now_player == 1){
		if(count == 0){
			hp_1p.text = fighting_data[0].hp;
			st_1p.text = fighting_data[0].st;
			df_1p.text = fighting_data[0].df;
			hp_2p.text = fighting_data[1].hp;
			st_2p.text = fighting_data[1].st;
			df_2p.text = fighting_data[1].df;
		}else{
			hp_1p.text = fighting_data[0].hp;
			st_1p.text = fighting_data[0].st;
			df_1p.text = fighting_data[0].df;
			hp_2p.text = fighting_data[1].hp;
			st_2p.text = "";
			df_2p.text = fighting_data[1].df;
		}	
	}else{
		if(count == 0){
			hp_2p.text = fighting_data[1].hp;
			st_2p.text = fighting_data[1].st;
			df_2p.text = fighting_data[1].df;
			hp_1p.text = fighting_data[0].hp;
			st_1p.text = fighting_data[0].st;
			df_1p.text = fighting_data[0].df;
		}else{
			hp_2p.text = fighting_data[1].hp;
			st_2p.text = fighting_data[1].st;
			df_2p.text = fighting_data[1].df;
			hp_1p.text = fighting_data[0].hp;
			st_1p.text = "";
			df_1p.text = fighting_data[0].df;
		}
	}	
}

private function f7_complete(event:TimerEvent):void{
	
	se.change_mp3.play();
	battle_power_disable_flag = false;
	power_flag = false;
	if(f7_animation_timer){
		f7_animation_timer.addEventListener(TimerEvent.TIMER,f7_animation);
		f7_animation_timer.addEventListener(TimerEvent.TIMER_COMPLETE,f7_complete);
		f7_animation_timer.stop();
		f7_animation_timer = null;
	}
	
	if(fighting_calc.now_player == 1){
		var calc_f7:int = fighting_calc.calc_f7(fighting_data[1]);
		fighting_data[1].st1 = fighting_data[1].st1 - calc_f7;
		fighting_data[1].st = fighting_data[1].st2 + fighting_data[1].st1;
		if(fighting_data[1].st > 199){
			fighting_data[1].st = 199;
		}
		fighting_data[0].mp = fighting_data[0].mp - fighting_calc.magic_list[7];
		fighting_calc.now_player = 2;
	}else{
		calc_f7 = fighting_calc.calc_f7(fighting_data[0]);
		fighting_data[0].st1 = fighting_data[0].st1 - calc_f7;
		fighting_data[0].st = fighting_data[0].st2 + fighting_data[0].st1;
		if(fighting_data[0].st > 199){
			fighting_data[0].st = 199;
		}
		fighting_data[1].mp = fighting_data[1].mp - fighting_calc.magic_list[7];
		fighting_calc.now_player = 1;
	}

	battle_waiting_first = false;
	battle_waiting(new Event(Event.COMPLETE));	
}


//F8 タフニ　消費6
private var f8_animation_timer:Timer;
private function f8():void{
	battle_power_disable_flag = true;
	battle_label.visible = false;
	power_label.visible = false;
	if(!f8_animation_timer){
		f8_animation_timer = new Timer(150,12);
		f8_animation_timer.addEventListener(TimerEvent.TIMER,f8_animation);
		f8_animation_timer.addEventListener(TimerEvent.TIMER_COMPLETE,f8_complete);
		f8_animation_timer.start();
	}

	hp_label.visible = true;
	damage_label.visible = false;
	st_label.visible = true;
	mp_label.visible = false;
	df_label.visible = true;
	pp_label.visible = false;

	se.status_down_mp3.play();		
}


private function f8_animation(event:TimerEvent):void{
	
	var currentCount:int = event.currentTarget.currentCount;
	var count:int = event.currentTarget.currentCount%2;
	
	if(fighting_calc.now_player == 1){
		if(count == 0){
			hp_1p.text = fighting_data[0].hp;
			st_1p.text = fighting_data[0].st;
			df_1p.text = fighting_data[0].df;
			hp_2p.text = fighting_data[1].hp;
			st_2p.text = fighting_data[1].st;
			df_2p.text = fighting_data[1].df;
		}else{
			hp_1p.text = fighting_data[0].hp;
			st_1p.text = "";
			df_1p.text = fighting_data[0].df;
			hp_2p.text = fighting_data[1].hp;
			st_2p.text = fighting_data[1].st;
			df_2p.text = fighting_data[1].df;
		}	
	}else{
		if(count == 0){
			hp_2p.text = fighting_data[1].hp;
			st_2p.text = fighting_data[1].st;
			df_2p.text = fighting_data[1].df;
			hp_1p.text = fighting_data[0].hp;
			st_1p.text = fighting_data[0].st;
			df_1p.text = fighting_data[0].df;
		}else{
			hp_2p.text = fighting_data[1].hp;
			st_2p.text = "";
			df_2p.text = fighting_data[1].df;
			hp_1p.text = fighting_data[0].hp;
			st_1p.text = fighting_data[0].st;
			df_1p.text = fighting_data[0].df;
		}
	}		
}

private function f8_complete(event:TimerEvent):void{
	se.change_mp3.play();
	battle_power_disable_flag = false;
	power_flag = false;
	
	if(f8_animation_timer){
		f8_animation_timer.addEventListener(TimerEvent.TIMER,f8_animation);
		f8_animation_timer.addEventListener(TimerEvent.TIMER_COMPLETE,f8_complete);
		f8_animation_timer.stop();
		f8_animation_timer = null;
	}
	
	if(fighting_calc.now_player == 1){
		var calc_f8:int = fighting_calc.calc_f8(fighting_data[0]);
		fighting_data[0].st1 = fighting_data[0].st1 + calc_f8;
		if(fighting_data[0].st1 > 199){
			fighting_data[0].st1 = 199;
		}
		fighting_data[0].st = fighting_data[0].st2 + fighting_data[0].st1;
		if(fighting_data[0].st > 199){
			fighting_data[0].st = 199;
		}
		fighting_data[0].mp = fighting_data[0].mp - fighting_calc.magic_list[8];
		fighting_calc.now_player = 2;
	}else{
		calc_f8 = fighting_calc.calc_f8(fighting_data[1]);
		fighting_data[1].st1 = fighting_data[1].st1 + calc_f8;
		if(fighting_data[1].st1 > 199){
			fighting_data[1].st1 = 199;
		}
		fighting_data[1].st = fighting_data[1].st2 + fighting_data[1].st1;
		if(fighting_data[1].st > 199){
			fighting_data[1].st = 199;
		}
		fighting_data[1].mp = fighting_data[1].mp - fighting_calc.magic_list[8];		
		fighting_calc.now_player = 1;
	}
	
	battle_waiting_first = false;
	battle_waiting(new Event(Event.COMPLETE));	
}



//F9 マミロージャ　消費3
private var f9_animation_timer:Timer;
private function f9():void{
	battle_power_disable_flag = true;
	battle_label.visible = false;
	power_label.visible = false;
	if(!f9_animation_timer){
		f9_animation_timer = new Timer(150,12);
		f9_animation_timer.addEventListener(TimerEvent.TIMER,f9_animation);
		f9_animation_timer.addEventListener(TimerEvent.TIMER_COMPLETE,f9_complete);
		f9_animation_timer.start();
	}

	hp_label.visible = true;
	damage_label.visible = false;
	st_label.visible = true;
	mp_label.visible = false;
	df_label.visible = true;
	pp_label.visible = false;
	hp_1p.text = fighting_data[0].hp;
	st_1p.text = fighting_data[0].st;
	df_1p.text = fighting_data[0].df;
	hp_2p.text = fighting_data[1].hp;
	st_2p.text = fighting_data[1].st;
	df_2p.text = fighting_data[1].df;

	se.status_down_mp3.play();	
}

private function f9_animation(event:TimerEvent):void{
	
	var currentCount:int = event.currentTarget.currentCount;
	var count:int = event.currentTarget.currentCount%2;
	
	if(count == 0){
		power_label.visible = true;
	}else{
		power_label.visible = false;
	}
	
}

private function f9_complete(event:TimerEvent):void{
	se.change_mp3.play();

	if(f9_animation_timer){
		f9_animation_timer.addEventListener(TimerEvent.TIMER,f9_animation);
		f9_animation_timer.addEventListener(TimerEvent.TIMER_COMPLETE,f9_complete);
		f9_animation_timer.stop();
		f9_animation_timer = null;
	}	
	
	if(fighting_calc.now_player == 1){
		fighting_data[1].pp_ignore_flag = true;
		fighting_data[0].mp = fighting_data[0].mp - fighting_calc.magic_list[9];
		fighting_calc.now_player = 2;
	}else{
		fighting_data[0].pp_ignore_flag = true;
		fighting_data[1].mp = fighting_data[1].mp - fighting_calc.magic_list[9];
		fighting_calc.now_player = 1;
	}
	
	battle_power_disable_flag = false;
	power_flag = false;
	battle_waiting_first = false;
	battle_waiting(new Event(Event.COMPLETE));		
}


/////////////////C2////////////////////


private function card_insert_wait_c2_back(event:MouseEvent):void{
	
	select_button.removeEventListener(MouseEvent.CLICK,card_enemy_insert_wait_c2);
	set_button.removeEventListener(MouseEvent.CLICK,card_insert_wait_c2_back);
	
	if(friend_select_state==1){
		friend_select_state=2;
	}else{
		friend_select_state=1;
	}
	bb2_state = 7;
	
	se.card_in_mp3.play();
	if(!friend_select_animation_timer){
		friend_select_animation_timer = new Timer(80,20);
		friend_select_animation_timer.addEventListener(TimerEvent.TIMER,friend_animation_c2);
		friend_select_animation_timer.addEventListener(TimerEvent.TIMER_COMPLETE,friend_animation_c2_complete);
		friend_select_animation_timer.start();
	}
	
	select_button.addEventListener(MouseEvent.CLICK,add_friend_state);
}

private var card_insert_wait_c2_timer:Timer;
//カード入力待ち
private function card_insert_wait_c2():void{
	
	select_button.removeEventListener(MouseEvent.CLICK,card_insert_wait_c2);
	set_button.removeEventListener(MouseEvent.CLICK,card_enemy_insert_wait_c2);
	
	if(!card_insert_wait_c2_timer){
		card_insert_wait_c2_timer = new Timer(500);
		card_insert_wait_c2_timer.addEventListener(TimerEvent.TIMER,card_insert_wait_animation_c2);
		card_insert_wait_c2_timer.start();
	}
	
	switch(bb2_state){
		//1枚目(戦士(主人公))
		case 4:
			hp_1p.text=" ==";
			st_1p.text=" ==";
			df_1p.text=" ==";
			hp_2p.text=" ==";
			st_2p.text=" ==";
			df_2p.text=" ==";
			hp_label.visible=true;
			st_label.visible=true;
			df_label.visible=true;
			warrior_1p_label.visible=true;
			warrior_2p_label.visible=false;
			magician_1p_label.visible=false;
			magician_2p_label.visible=true;
			card_in_button.addEventListener(MouseEvent.CLICK,card_insert_c2);
			select_image_button.addEventListener(MouseEvent.CLICK,select_image);
			get_camera_button.addEventListener(MouseEvent.CLICK,get_camera);
			card_in.enabled = true;
			card_in_button.enabled=true;
			init_card_reader_button.enabled = true;
		break;
		
		//2枚目(魔法使い(主人公))
		case 5:
			hp_2p.text=" ==";
			st_2p.text=" ==";
			df_2p.text=" ==";
			card_in_button.addEventListener(MouseEvent.CLICK,card_insert_c2);
			select_image_button.addEventListener(MouseEvent.CLICK,select_image);
			get_camera_button.addEventListener(MouseEvent.CLICK,get_camera);
			card_in.enabled = true;
			card_in_button.enabled=true;
			init_card_reader_button.enabled = true;
		break;
		
	}	
}


//カード入力待ちアニメーション
private function card_insert_wait_animation_c2(event:TimerEvent):void{
	var count:int = event.target.currentCount%2;	
	switch(bb2_state){
		//1枚目
		case 4:
			if(count == 1){
				card_input_label.visible =false;
				warrior_1p_label.visible =false;
				magician_1p_label.visible =false;
			}else{
				card_input_label.visible =true;
				warrior_1p_label.visible =true;
				magician_1p_label.visible =false;
			}
		break;
		
		//2枚目
		case 5:
			if(count == 1){
				card_input_label.visible =false;
				warrior_2p_label.visible =false;
				magician_2p_label.visible =false;
			}else{
				card_input_label.visible =true;
				warrior_2p_label.visible =false;
				magician_2p_label.visible =true;
			}
		break;
	}
	
}

//カード入力受付処理
private var card_insert_c2_timer:Timer;
private var card_insert_error_c2_timer:Timer;
private var barcode_data_c2:Array;
private function card_insert_c2(event:MouseEvent):void{
	if(!barcode_data_c2){
		barcode_data_c2 = new Array(8);
	}
	
	card_in_button.removeEventListener(MouseEvent.CLICK,card_insert_c2);
	select_image_button.removeEventListener(MouseEvent.CLICK,select_image);
	get_camera_button.removeEventListener(MouseEvent.CLICK,get_camera);
	card_in_button.enabled = false;
	init_card_reader_button.enabled = false;
	
	if(card_insert_wait_c2_timer){
		card_insert_wait_c2_timer.removeEventListener(TimerEvent.TIMER,card_insert_wait_animation_c2);
		card_insert_wait_c2_timer.stop();
		card_insert_wait_c2_timer = null;
	}
	
	switch(bb2_state){
		//1枚目
		case 4:
			var barcode_reader:BarcodeRead = new BarcodeRead();
			var barcode:String = card_in.text;
			var ret:Boolean = barcode_reader.init(barcode,1,null,0,true,"warrior");
			
			//入力成功
			if(ret){
				se.card_in_mp3.play();
				barcode_data_c2[0] = createCloneInstance(barcode_reader.barcode_data);
				barcode_data_c2[2] = createCloneInstance(barcode_reader.barcode_data);
				barcode_data_c2[4] = createCloneInstance(barcode_reader.barcode_data);
				if(barcode_data_c2[0].job <= 6){
					warrior_1p_label.visible = true;
					magician_1p_label.visible = false;
				}else{
					warrior_1p_label.visible = false;
					magician_1p_label.visible = true;
				}
				
				card_input_label.visible = false;
				card_insert_c2_timer = new Timer(80,20);
				card_insert_c2_timer.addEventListener(TimerEvent.TIMER,card_insert_animation);
				card_insert_c2_timer.addEventListener(TimerEvent.TIMER_COMPLETE,card_insert_next_c2);
				card_insert_c2_timer.start();
				
				//入力失敗
			}else{
				se.card_in_error_mp3.play();
				magician_1p_label.visible=false;
				warrior_1p_label.visible=false;
				barcode_data_c2[0] = createCloneInstance(barcode_reader.barcode_data);
				barcode_data_c2[2] = createCloneInstance(barcode_reader.barcode_data);
				barcode_data_c2[4] = createCloneInstance(barcode_reader.barcode_data);
				card_insert_error_c2_timer = new Timer(150,6);
				card_insert_error_c2_timer.addEventListener(TimerEvent.TIMER,card_insert_error_animation_c2);
				card_insert_error_c2_timer.addEventListener(TimerEvent.TIMER_COMPLETE,card_insert_error_back_c2);
				card_insert_error_c2_timer.start();
			}
			break;
		
		//2枚目
		case 5:
			barcode_reader = new BarcodeRead();
			barcode = card_in.text;
			ret = barcode_reader.init(barcode,1,null,0,true,"magician");
			
			//入力成功
			if(ret){
				se.card_in_mp3.play();
				barcode_data_c2[1] = createCloneInstance(barcode_reader.barcode_data);
				barcode_data_c2[3] = createCloneInstance(barcode_reader.barcode_data);
				barcode_data_c2[5] = createCloneInstance(barcode_reader.barcode_data);
				
				if(barcode_data_c2[1].job <= 6){
					warrior_2p_label.visible = true;
					magician_2p_label.visible = false;
				}else{
					warrior_2p_label.visible = false;
					magician_2p_label.visible = true;
				}
				
				card_input_label.visible = false;
				card_insert_c2_timer = new Timer(80,20);
				card_insert_c2_timer.addEventListener(TimerEvent.TIMER,card_insert_animation);
				card_insert_c2_timer.addEventListener(TimerEvent.TIMER_COMPLETE,card_insert_next_c2);
				card_insert_c2_timer.start();
				
				//入力失敗
			}else{
				se.card_in_error_mp3.play();
				magician_2p_label.visible=false;
				warrior_2p_label.visible=false;
				barcode_data_c2[1] = createCloneInstance(barcode_reader.barcode_data);
				barcode_data_c2[3] = createCloneInstance(barcode_reader.barcode_data);
				barcode_data_c2[5] = createCloneInstance(barcode_reader.barcode_data);
				
				card_insert_error_c2_timer = new Timer(150,6);
				card_insert_error_c2_timer.addEventListener(TimerEvent.TIMER,card_insert_error_animation_c2);
				card_insert_error_c2_timer.addEventListener(TimerEvent.TIMER_COMPLETE,card_insert_error_back_c2);
				card_insert_error_c2_timer.start();
			}
			break;
	}
}






//カード入力完了→次のステータスへ
private function card_insert_next_c2(event:Event):void{
	
	if(card_insert_c2_timer){
		card_insert_c2_timer.removeEventListener(TimerEvent.TIMER,card_insert_animation);
		card_insert_c2_timer.removeEventListener(TimerEvent.TIMER_COMPLETE,card_insert_next_c2);
		card_insert_c2_timer.stop();
		card_insert_c2_timer = null;
	}
	
	if(set_friend_item_timer){
		set_friend_item_timer.removeEventListener(TimerEvent.TIMER,set_friend_item_animation);
		set_friend_item_timer.stop();
		set_friend_item_timer = null;
	}
	
	switch(bb2_state){
		
		//1枚目
		case 4:
			var bd:BarcodeData = barcode_data_c2[0];
			hp_1p.text = bd.hp;
			st_1p.text = (bd.st > 199)?199:bd.st;
			df_1p.text = (bd.df > 199)?199:bd.df;
			bb2_state = bb2_state + 1;
			card_reader_visible = false;
			init_card_reader(new MouseEvent(MouseEvent.CLICK));
			card_in_button.addEventListener(MouseEvent.CLICK,card_insert_c2);
			select_image_button.addEventListener(MouseEvent.CLICK,select_image);
			get_camera_button.addEventListener(MouseEvent.CLICK,get_camera);
			card_in.enabled = true;
			card_in_button.enabled=true;
			init_card_reader_button.enabled = true;
			card_insert_wait_c2();
			break;
		
		//2枚目
		case 5:
			bd = barcode_data_c2[1];
			hp_2p.text = bd.hp;
			st_2p.text = (bd.st > 199)?199:bd.st;
			df_2p.text = (bd.df > 199)?199:bd.df;
			bb2_state = bb2_state + 1;
			card_reader_visible = false;
			
			card_in_button.removeEventListener(MouseEvent.CLICK,card_insert_c2);
			select_image_button.removeEventListener(MouseEvent.CLICK,select_image);
			get_camera_button.removeEventListener(MouseEvent.CLICK,get_camera);
			card_in.enabled = false;
			
			//敵カード入力待ちへ
			set_button.addEventListener(MouseEvent.CLICK,card_enemy_insert_wait_c2_se);	
			break;
		
		//敵カード
		case 6:
			bd = barcode_data_c2[6];
			
			hp_1p.text=" ==";
			st_1p.text=" ==";
			df_1p.text=" ==";
			hp_2p.text = bd.hp;
			st_2p.text = (bd.st > 199)?199:bd.st;
			df_2p.text = (bd.df > 199)?199:bd.df;
			
			if(barcode_data_c2[4].live){
				warrior_1p_label.visible=true;
			}else{
				warrior_1p_label.visible=false;
			}
			
			if(barcode_data_c2[5].live){
				magician_1p_label.visible=true;
			}else{
				magician_1p_label.visible=false;
			}
			
			if(bd.job <= 6){
				warrior_2p_label.visible=true;
				magician_2p_label.visible=false;
			}else{
				warrior_2p_label.visible=false;
				magician_2p_label.visible=true;
			}
			
			bb2_state = bb2_state + 1;
			card_reader_visible = false;
			
			card_in_button.removeEventListener(MouseEvent.CLICK,card_insert_c2);
			select_image_button.removeEventListener(MouseEvent.CLICK,select_image);
			get_camera_button.removeEventListener(MouseEvent.CLICK,get_camera);
			card_in.enabled = false;

			friend_select_state=0;
			if(!friend_select_animation_timer){
				friend_select_animation_timer = new Timer(300);
				friend_select_animation_timer.addEventListener(TimerEvent.TIMER,friend_select_animation_c2);
				friend_select_animation_timer.start();
			}
			
			select_button.addEventListener(MouseEvent.CLICK,add_friend_state);
			
			break;
		
		//アイテムカード
		case 7:
			
			hp_label.visible = true;
			st_label.visible = true;
			df_label.visible = true;
			mp_label.visible = false;
			pp_label.visible = false;
			item_label.visible =false;
			card_input_label.visible=false;
			
			if(friend_select_state == 1){
				bd = barcode_data_c2[4];
			}else{
				bd = barcode_data_c2[5];
			}
			
			if(!fighting_data){
				fighting_data = new Array(2);
			}
			
			//入力なし
			if(!barcode_data_c2[7]){
				fighting_data[0] = new CreateFightingData().init(bd,null);
			}else{
				//1p(主人公)のFD作成
				fighting_data[0] = new CreateFightingData().init(bd,barcode_data_c2[7]);
			}
			
			//2p(敵)のFD作成
			fighting_data[1] = new CreateFightingData().init(barcode_data_c2[6],null);
			fighting_data[1].cpu = true;
			
			if(fighting_data[0].job > 6){
				warrior_1p_label.visible=false;
				magician_1p_label.visible=true;
			}else{
				warrior_1p_label.visible=true;
				magician_1p_label.visible=false;
			}
			
			hp_2p.text = fighting_data[1].hp;
			st_2p.text = (fighting_data[1].st>199)?199:fighting_data[1].st;
			df_2p.text = (fighting_data[1].df>199)?199:fighting_data[1].df;
			if(fighting_data[1].job > 6){
				magician_2p_label.visible = true;
				warrior_2p_label.visible = false;
			}else{
				magician_2p_label.visible = false;
				warrior_2p_label.visible = true;
			}
			
			hp_1p.text = fighting_data[0].hp;
			st_1p.text = (fighting_data[0].st>199)?199:fighting_data[0].st;
			df_1p.text = (fighting_data[0].df>199)?199:fighting_data[0].df;
			
			bb2_state = bb2_state + 1;
			
			card_reader_visible = false;
			init_card_reader(new MouseEvent(MouseEvent.CLICK));
			card_in_button.addEventListener(MouseEvent.CLICK,card_insert);
			select_image_button.addEventListener(MouseEvent.CLICK,select_image);
			get_camera_button.addEventListener(MouseEvent.CLICK,get_camera);
			card_in.enabled = false;
			card_in_button.enabled=false;
			init_card_reader_button.enabled = false;
			
			//ダウン系特殊能力処理へ
			fighting_calc.fighting_data = fighting_data;
			special_down();
			
			break;
		
	}
}


//カード入力失敗アニメーション
private function card_insert_error_animation_c2(event:TimerEvent):void{
	
	var count:int = event.currentTarget.currentCount%2;	
	switch(bb2_state){
		
		//1枚目	
		case 4:
			if(count == 1){
				//アイテムなら
				if(barcode_data_c2[0]!= null && barcode_data_c2[0].race > 4){
					card_input_label.visible = true;
					item_label.visible = true;
					miss_label.visible = false;
				//job
				}else if(barcode_data_c2[0]!= null && barcode_data_c2[0].race <= 4){
					if(barcode_data_c2[0].job >=7){
						warrior_1p_label.visible = false;
						magician_1p_label.visible = true;
					}else{
						warrior_1p_label.visible = true;
						magician_1p_label.visible = false;
					}
					miss_label.visible = false;
				//カード入力ミス
				}else{
					card_input_label.visible = true;
					miss_label.visible = false;
				}
				
			}else{
				if(barcode_data_c2[0]!= null && barcode_data_c2[0].race > 4){
					card_input_label.visible = true;
					item_label.visible = false;
					miss_label.visible = true;
				}else if(barcode_data_c2[0]!= null && barcode_data_c2[0].race <= 4){
					warrior_1p_label.visible = false;
					magician_1p_label.visible=false;
					miss_label.visible = true;
					//job
				//カード入力ミス
				}else{
					card_input_label.visible = false;
					miss_label.visible = true;
				}
			}
			break;
		
		//2枚目
		case 5:
			if(count == 1){
				//アイテムなら
				if(barcode_data_c2[1]!= null && barcode_data_c2[1].race > 4){
					card_input_label.visible = true;
					item_label.visible = true;
					miss_label.visible = false;
					//job
				}else if(barcode_data_c2[1].race <= 4){
					if(barcode_data_c2[1].job >=7){
						warrior_2p_label.visible = false;
						magician_2p_label.visible = true;						
					}else{
						warrior_2p_label.visible = true;
						magician_2p_label.visible = false;
					}
					miss_label.visible = false;
					//カード入力ミス
				}else{
					card_input_label.visible = true;
					miss_label.visible = false;
				}
				
			}else{
				if(barcode_data_c2[1]!= null && barcode_data_c2[1].race > 4){
					card_input_label.visible = true;
					item_label.visible = false;
					miss_label.visible = true;
				}else if(barcode_data_c2[1]!= null && barcode_data_c2[1].race <= 4){
					warrior_2p_label.visible=false;
					magician_2p_label.visible = false;
					miss_label.visible = true;
					//job
					//カード入力ミス
				}else{
					card_input_label.visible = false;
					miss_label.visible = true;
				}
			}
			break;
		
		case 6:
			if(count == 1){
				//アイテムなら
				if(barcode_data_c2[6]!= null && barcode_data_c2[6].race > 4){
					card_input_label.visible = true;
					item_label.visible = true;
					miss_label.visible = false;
				}else{
					card_input_label.visible = true;
					miss_label.visible = false;
				}
				
			}else{
				if(barcode_data_c2[6]!= null && barcode_data_c2[6].race > 4){
					card_input_label.visible = true;
					item_label.visible = false;
					miss_label.visible = true;
				}else{
					card_input_label.visible = false;
					miss_label.visible = true;
				}
			}
			break;
		
		
		case 7:
			if(count == 1){
				//アイテム
				if(barcode_data_c2[7]!= null && barcode_data_c2[7].race > 4){
					card_input_label.visible = true;
					item_label.visible = true;
					miss_label.visible = false;
				//job
				}else if(barcode_data_c2[7]!= null && barcode_data_c2[7].race <= 4){
					if(barcode_data_c2[7].job >=7){
						warrior_2p_label.visible = false;
						magician_2p_label.visible = true;						
					}else{
						warrior_2p_label.visible = true;
						magician_2p_label.visible = false;
					}
					item_label.visible = false;
					miss_label.visible = false;
					//カード入力ミス
				}else{
					item_label.visible = false;
					card_input_label.visible = true;
					miss_label.visible = false;
				}
				
			}else{
				//アイテム
				if(barcode_data_c2[7]!= null && barcode_data_c2[7].race > 4){
					card_input_label.visible = true;
					item_label.visible = false;
					miss_label.visible = true;
				}else if(barcode_data_c2[7]!= null && barcode_data_c2[7].race <= 4){
					warrior_2p_label.visible=false;
					magician_2p_label.visible = false;
					item_label.visible = false;
					miss_label.visible = true;
					//job
					//カード入力ミス
				}else{
					card_input_label.visible = false;
					item_label.visible = false;
					miss_label.visible = true;
				}
			}
		break;
				
	}
}


//カード入力失敗
private function card_insert_error_back_c2(event:TimerEvent):void{
	
	if(card_insert_error_timer){
		card_insert_error_timer.removeEventListener(TimerEvent.TIMER,card_insert_error_animation);
		card_insert_error_timer.removeEventListener(TimerEvent.TIMER_COMPLETE,card_insert_error_back_c2);
		card_insert_error_timer.stop();
		card_insert_error_timer = null;
	}
	
	item_label.visible = false;
	card_input_label.visible = false;
	miss_label.visible = false;
	
	card_reader_visible = false;
	init_card_reader(new MouseEvent(MouseEvent.CLICK));
	card_in_button.addEventListener(MouseEvent.CLICK,card_insert_c2);
	select_image_button.addEventListener(MouseEvent.CLICK,select_image);
	get_camera_button.addEventListener(MouseEvent.CLICK,get_camera);
	card_in.enabled = true;
	card_in_button.enabled=true;
	init_card_reader_button.enabled = true;
	
	if(bb2_state < 6){
		card_insert_wait_c2();
	}else if(bb2_state == 6){
		card_enemy_insert_wait_c2(new MouseEvent(MouseEvent.CLICK));
	}else if(bb2_state == 7){
		set_friend_state(new MouseEvent(MouseEvent.CLICK));
	}
}

//カード入力待ち（音鳴らす）
private function card_enemy_insert_wait_c2_se(event:Event):void{
	if(display_mp_pp_timer){
		display_mp_pp_timer.removeEventListener(TimerEvent.TIMER,display_mp_pp);
		display_mp_pp_timer.removeEventListener(TimerEvent.TIMER_COMPLETE,card_enemy_insert_wait_c2_se);
		display_mp_pp_timer.stop();
		display_mp_pp_timer = null;
	}
	
	mp_label.visible=false;
	pp_label.visible=false;
	
	set_button.removeEventListener(MouseEvent.CLICK,card_enemy_insert_wait_c2_se);
	se.decide_mp3.play();
	card_enemy_insert_wait_c2(event);
}

private var card_enemy_insert_wait_c2_timer:Timer;
//カード入力待ち
private function card_enemy_insert_wait_c2(event:Event):void{
	select_button.removeEventListener(MouseEvent.CLICK,card_enemy_insert_wait_c2);
	set_button.removeEventListener(MouseEvent.CLICK,card_insert_wait_c2);
	set_button.removeEventListener(MouseEvent.CLICK,card_insert_wait_c2_back);
	
	if(bb2_state != 6){
		bb2_state = 6;
	}
	
	set_button.removeEventListener(MouseEvent.CLICK,card_enemy_insert_wait_c2);	
	if(!card_enemy_insert_wait_c2_timer){
		card_enemy_insert_wait_c2_timer = new Timer(500);
		card_enemy_insert_wait_c2_timer.addEventListener(TimerEvent.TIMER,card_enemy_insert_wait_animation_c2);
		card_enemy_insert_wait_c2_timer.start();
	}
	
	if(passcode_power_up_c2_timer){
		passcode_power_up_c2_timer.removeEventListener(TimerEvent.TIMER,passcode_power_up_animation_c2);
		passcode_power_up_c2_timer.removeEventListener(TimerEvent.TIMER_COMPLETE,card_enemy_insert_wait_c2);
		passcode_power_up_c2_timer.stop();
		passcode_power_up_c2_timer = null;
	}
	
	switch(bb2_state){
		//1枚目(敵)
		case 6:
			hp_1p.text="";
			st_1p.text="";
			df_1p.text="";
			hp_2p.text=" ==";
			st_2p.text=" ==";
			df_2p.text=" ==";
			card_input_label.visible=false;
			hp_label.visible=true;
			st_label.visible=true;
			df_label.visible=true;
			warrior_1p_label.visible=false;
			magician_1p_label.visible=false;
			warrior_2p_label.visible=false;
			magician_2p_label.visible=false;
			
			//カード入力
			card_in_button.addEventListener(MouseEvent.CLICK,card_enemy_insert_c2);
			select_image_button.addEventListener(MouseEvent.CLICK,select_image);
			get_camera_button.addEventListener(MouseEvent.CLICK,get_camera);
			card_in.enabled = true;
			card_in_button.enabled=true;
			init_card_reader_button.enabled = true;
			
			//パスコード入力
			l_power.addEventListener(MouseEvent.CLICK,select_passcode);
			
			break;
	}
}

//敵カード入力待ちアニメーション
private function card_enemy_insert_wait_animation_c2(event:TimerEvent):void{
	var count:int = event.currentTarget.currentCount%2;
	//1枚目
	switch(bb2_state){
		case 6:
		if(count == 1){
			warrior_2p_label.visible=true;
			magician_2p_label.visible=true;
			card_input_label.visible=true;
		}else{
			warrior_2p_label.visible=false;
			magician_2p_label.visible=false;
			card_input_label.visible=false;
		}
	}
}


//パスコード入力画面
private var passcode_state:int;
private var passcode:String;
private var passcode_wait_c2_timer:Timer;
private function select_passcode(event:MouseEvent):void{
	
	l_power.removeEventListener(MouseEvent.CLICK,select_passcode);
	select_button.addEventListener(MouseEvent.CLICK,add_passcode);
	set_button.addEventListener(MouseEvent.CLICK,set_passcode);
	
	card_in_button.removeEventListener(MouseEvent.CLICK,card_enemy_insert_c2);
	select_image_button.removeEventListener(MouseEvent.CLICK,select_image);
	get_camera_button.removeEventListener(MouseEvent.CLICK,get_camera);
	card_in.enabled = false;
	card_in_button.enabled=false;
	init_card_reader_button.enabled = false;
	
	if(card_enemy_insert_wait_c2_timer){
		card_enemy_insert_wait_c2_timer.removeEventListener(TimerEvent.TIMER,card_enemy_insert_wait_animation_c2);
		card_enemy_insert_wait_c2_timer.stop();
		card_enemy_insert_wait_c2_timer=null;
	}
	
	if(!passcode_wait_c2_timer){
		passcode_wait_c2_timer = new Timer(150);
		passcode_wait_c2_timer.addEventListener(TimerEvent.TIMER,passcode_wait_animation_c2);
		passcode_wait_c2_timer.start();
	}
	
	warrior_1p_label.visible=false;
	magician_1p_label.visible=false;
	warrior_2p_label.visible=false;
	magician_2p_label.visible=false;
	card_input_label.visible=false;
	
	hp_label.visible=false;
	st_label.visible=false;
	df_label.visible=false;
	
	hp_1p.text="p00";
	st_1p.text="";
	df_1p.text="";
	
	hp_2p.text="000"
	st_2p.text="";
	df_2p.text="";
	
	passcode_state = 0;
	passcode="00000";
}


//カード入力待ち
private function passcode_wait_animation_c2(event:TimerEvent):void{
	
	var count:int = event.currentTarget.currentCount%2;	
	
	switch(passcode_state){
		case 0:
			if(count == 1){
				hp_1p.text="p"+passcode.charAt(0).toString()+passcode.charAt(1).toString();
				hp_2p.text=passcode.charAt(2).toString()+passcode.charAt(3).toString()+passcode.charAt(4).toString();
			}else{
				hp_1p.text="p "+passcode.charAt(1).toString();
				hp_2p.text=passcode.charAt(2).toString()+passcode.charAt(3).toString()+passcode.charAt(4).toString();
			}
		break;
		
		case 1:
			if(count == 1){
				hp_1p.text="p"+passcode.charAt(0).toString()+passcode.charAt(1).toString();
				hp_2p.text=passcode.charAt(2).toString()+passcode.charAt(3).toString()+passcode.charAt(4).toString();
			}else{
				hp_1p.text="p"+passcode.charAt(0).toString()+" ";
				hp_2p.text=passcode.charAt(2).toString()+passcode.charAt(3).toString()+passcode.charAt(4).toString();
			}
		break;	
			
		case 2:
			if(count == 1){
				hp_1p.text="p"+passcode.charAt(0).toString()+passcode.charAt(1).toString();
				hp_2p.text=passcode.charAt(2).toString()+passcode.charAt(3).toString()+passcode.charAt(4).toString();
			}else{
				hp_1p.text="p"+passcode.charAt(0).toString()+passcode.charAt(1).toString();
				hp_2p.text=" "+passcode.charAt(3).toString()+passcode.charAt(4).toString();
			}		break;	
			
		case 3:
			if(count == 1){
				hp_1p.text="p"+passcode.charAt(0).toString()+passcode.charAt(1).toString();
				hp_2p.text=passcode.charAt(2).toString()+passcode.charAt(3).toString()+passcode.charAt(4).toString();
			}else{
				hp_1p.text="p"+passcode.charAt(0).toString()+passcode.charAt(1).toString();
				hp_2p.text=passcode.charAt(2).toString()+" "+passcode.charAt(4).toString();
			}
		break;
		
		case 4:
			if(count == 1){
				hp_1p.text="p"+passcode.charAt(0).toString()+passcode.charAt(1).toString();
				hp_2p.text=passcode.charAt(2).toString()+passcode.charAt(3).toString()+passcode.charAt(4).toString();
			}else{
				hp_1p.text="p"+passcode.charAt(0).toString()+passcode.charAt(1).toString();
				hp_2p.text=passcode.charAt(2).toString()+passcode.charAt(3).toString()+" ";
			}
		break;
	}
	
}

//パスコード加算
private function add_passcode(event:MouseEvent):void{
	
	se.select_mp3.play();
	switch(passcode_state){
		case 0:
			var pluscode:int = int(passcode.charAt(0))+1;
			if(pluscode > 9){
				pluscode=0;
			}
			passcode = pluscode.toString()+passcode.charAt(1)+passcode.charAt(2)+passcode.charAt(3)+passcode.charAt(4);
		break;
		
		case 1:
			pluscode = int(passcode.charAt(1))+1;
			if(pluscode > 9){
				pluscode=0;
			}
			passcode = passcode.charAt(0)+pluscode.toString()+passcode.charAt(2)+passcode.charAt(3)+passcode.charAt(4);
		break;
		
		case 2:
			pluscode = int(passcode.charAt(2))+1;
			if(pluscode > 9){
				pluscode=0;
			}
			passcode = passcode.charAt(0)+passcode.charAt(1)+pluscode.toString()+passcode.charAt(3)+passcode.charAt(4);
		break;
		
		case 3:
			pluscode = int(passcode.charAt(3))+1;
			if(pluscode > 9){
				pluscode=0;
			}
			passcode = passcode.charAt(0)+passcode.charAt(1)+passcode.charAt(2)+pluscode.toString()+passcode.charAt(4);
		break;
		
		case 4:
			pluscode = int(passcode.charAt(4))+1;
			if(pluscode > 9){
				pluscode=0;
			}
			passcode = passcode.charAt(0)+passcode.charAt(1)+passcode.charAt(2)+passcode.charAt(3)+pluscode.toString();
		break;
	}
}

//パスコードセット
private var passcode_power_up_c2_timer:Timer;
private function set_passcode(event:MouseEvent):void{
	if(passcode_state !=5){
		se.decide_mp3.play();
	}
	
	passcode_state=passcode_state+1;
	if(passcode_state==5){
		select_button.removeEventListener(MouseEvent.CLICK,add_passcode);
		set_button.removeEventListener(MouseEvent.CLICK,set_passcode);
		
		var c2_passcode:C2PassCode = new C2PassCode();
		c2_passcode.init(barcode_data_c2[0],barcode_data_c2[1],passcode);
		var passcode_number:int = c2_passcode.generate_passcode_number();
		
		//パスコード間違い
		if(passcode_number == -1){
			card_enemy_insert_wait_c2(new MouseEvent(MouseEvent.CLICK));
		//パスコードあってる
		}else{
			//cloneしてコピー(配列は参照渡しになるので防止)
			barcode_data_c2[2] = createCloneInstance(barcode_data_c2[4]);
			barcode_data_c2[3] = createCloneInstance(barcode_data_c2[5]);
			barcode_data_c2[4] = c2_passcode.generate_passcode_barcode_data(createCloneInstance(barcode_data_c2[0]),passcode_number);
			barcode_data_c2[5] = c2_passcode.generate_passcode_barcode_data(createCloneInstance(barcode_data_c2[1]),passcode_number);

			hp_label.visible=true;
			st_label.visible=true;
			df_label.visible=true;
			se.card_in_mp3.play();
			passcode_power_up_c2_timer = new Timer(60,70);
			passcode_power_up_c2_timer.addEventListener(TimerEvent.TIMER,passcode_power_up_animation_c2);
			passcode_power_up_c2_timer.addEventListener(TimerEvent.TIMER_COMPLETE,card_enemy_insert_wait_c2);
			passcode_power_up_c2_timer.start();
			
		}
	}
}

//パスコード入力成功アニメーション
private function passcode_power_up_animation_c2(event:TimerEvent):void{
	var current_count:int = event.currentTarget.currentCount;
	var count:int = event.currentTarget.currentCount%2;
	
	if(current_count <=30){
		if(count == 1){
			hp_1p.text = barcode_data_c2[2].hp;
			st_1p.text = barcode_data_c2[2].st;
			df_1p.text = barcode_data_c2[2].df;
			hp_2p.text = barcode_data_c2[3].hp;
			st_2p.text = barcode_data_c2[3].st;
			df_2p.text = barcode_data_c2[3].df;
			warrior_1p_label.visible = true;
			magician_2p_label.visible = true;
		}else{
			hp_1p.text = "";
			st_1p.text = "";
			df_1p.text = "";
			hp_2p.text = "";
			st_2p.text = "";
			df_2p.text = "";
			warrior_1p_label.visible = false;
			magician_2p_label.visible = false;
		}
	}else{
		hp_1p.text = barcode_data_c2[4].hp;
		st_1p.text = barcode_data_c2[4].st;
		df_1p.text = barcode_data_c2[4].df;
		hp_2p.text = barcode_data_c2[5].hp;
		st_2p.text = barcode_data_c2[5].st;
		df_2p.text = barcode_data_c2[5].df;
		warrior_1p_label.visible = true;
		magician_2p_label.visible = true;
	}
	
}

private function card_enemy_insert_c2(event:MouseEvent):void{
	
	card_in_button.removeEventListener(MouseEvent.CLICK,card_enemy_insert_c2);
	select_image_button.removeEventListener(MouseEvent.CLICK,select_image);
	get_camera_button.removeEventListener(MouseEvent.CLICK,get_camera);
	l_power.removeEventListener(MouseEvent.CLICK,select_passcode);
	
	card_in_button.enabled = false;
	init_card_reader_button.enabled = false;
	
	if(card_enemy_insert_wait_c2_timer){
		card_enemy_insert_wait_c2_timer.removeEventListener(TimerEvent.TIMER,card_enemy_insert_wait_animation_c2);
		card_enemy_insert_wait_c2_timer.stop();
		card_enemy_insert_wait_c2_timer = null;
	}
	
	switch(bb2_state){
		//1枚目
		case 6:
			var barcode_reader:BarcodeRead = new BarcodeRead();
			var barcode:String = card_in.text;
			var ret:Boolean = barcode_reader.init(barcode,1,null,0);
			
			//入力成功
			if(ret){
				se.card_in_mp3.play();
				barcode_data_c2[6] = barcode_reader.barcode_data;
				if(barcode_data_c2[6].job <= 6){
					warrior_2p_label.visible = true;
					magician_2p_label.visible = false;
				}else{
					warrior_2p_label.visible = false;
					magician_2p_label.visible = true;
				}
				
				card_input_label.visible = false;
				card_insert_c2_timer = new Timer(80,20);
				card_insert_c2_timer.addEventListener(TimerEvent.TIMER,card_insert_animation_c2);
				card_insert_c2_timer.addEventListener(TimerEvent.TIMER_COMPLETE,card_insert_next_c2);
				card_insert_c2_timer.start();
				
				//入力失敗
			}else{
				se.card_in_error_mp3.play();
				magician_1p_label.visible=false;
				warrior_1p_label.visible=false;
				barcode_data_c2[6] = barcode_reader.barcode_data;
				card_insert_error_c2_timer = new Timer(150,6);
				card_insert_error_c2_timer.addEventListener(TimerEvent.TIMER,card_insert_error_animation_c2);
				card_insert_error_c2_timer.addEventListener(TimerEvent.TIMER_COMPLETE,card_insert_error_back_c2);
				card_insert_error_c2_timer.start();
			}
			break;
		}
}

//敵カード/アイテムカード入力アニメーション
public function card_insert_animation_c2(event:TimerEvent):void{
	
	var currentCount:int = event.currentTarget.currentCount;
	var count:int = event.currentTarget.currentCount%2;	
	
	switch(bb2_state){
		//1枚目
		case 6:
			if(count == 1){
				hp_2p.text = " ==";
				st_2p.text = " ==";
				df_2p.text = " ==";
			}else{
				hp_2p.text = "";
				st_2p.text = "";
				df_2p.text = "";
			}
		break;
		
		case 7:
			//点滅表示
			if(currentCount <= 20){
				//薬草アップ,MPアップ
				if(barcode_data_c2[7].race==9 && barcode_data_c2[7].job > 6){
					hp_label.visible = true;
					st_label.visible = false;
					df_label.visible = false;
					mp_label.visible = true;
					pp_label.visible = true;
					st_2p.mp_text = barcode_data_c2[7].mp;
					df_2p.pp_text = barcode_data_c2[7].pp;
					
					if(friend_select_state == 1){
						st_1p.mp_text = barcode_data_c1[4].mp;
						df_1p.pp_text = barcode_data_c1[4].pp;
					}else{
						st_1p.mp_text = barcode_data_c1[5].mp;
						df_1p.pp_text = barcode_data_c1[5].pp;
					}
				}else{
					hp_label.visible = true;
					st_label.visible = true;
					df_label.visible = true;
					mp_label.visible = false;
					pp_label.visible = false;
				}
				
				if(barcode_data_c2[7].race <=4){
					if(barcode_data_c2[7].job > 6){
						warrior_2p_label.enabled = false;
						magician_2p_label.enabled = true;
					}else{
						warrior_2p_label.enabled = true;
						magician_2p_label.enabled = false;
					}
				}else{
					warrior_2p_label.visible=false;
					magician_2p_label.visible=false;
					item_label.visible=true;
				}
				
				if(count == 1){
					hp_2p.text = " ==";
					st_2p.text = " ==";
					df_2p.text = " ==";
				}else{
					hp_2p.text = "";
					st_2p.text = "";
					df_2p.text = "";
				}
				//入力パラメータ表示
			}else{
				//薬草アップ,MPアップ
				if(barcode_data_c2[7].race==9 && barcode_data_c2[7].job > 6){
					hp_2p.text = "";
					if(barcode_data_c2[7].mp  > 0){
						st_2p.mp_text = barcode_data_c2[7].mp;
					}else{
						st_2p.text = "";
					}
					if(barcode_data_c2[7].pp  > 0){
						df_2p.pp_text = barcode_data_c2[7].pp;
					}else{
						df_2p.text = "";
					}
				}else{
					if(barcode_data_c2[7].hp > 0){
						hp_2p.text = barcode_data_c2[7].hp;
					}else{
						hp_2p.text = "";
					}
					if(barcode_data_c2[7].st > 0){
						st_2p.text = (barcode_data_c2[7].st>199)?199:barcode_data_c2[7].st;
					}else{
						st_2p.text = "";
					}
					if(barcode_data_c2[7].df > 0){
						df_2p.text = (barcode_data_c2[7].df>199)?199:barcode_data_c2[7].df;
					}else{
						df_2p.text = "";
					}
				}
			}
			break;
		
	}
	
}

//味方(戦士/魔法使い)選択アニメーション
public var friend_select_animation_timer:Timer;
public var friend_select_state:int; //0未選択 1戦士 2魔法使い
public function friend_select_animation_c2(event:TimerEvent):void{
	var count:int = event.currentTarget.currentCount%2;	

	switch(friend_select_state){
		case 0:
			if(count == 1){
				if(barcode_data_c2[4].live){
					warrior_1p_label.visible=true;
				}else{
					warrior_1p_label.visible=false;
				}
				
				if(barcode_data_c2[5].live){
					magician_1p_label.visible=true;
				}else{
					magician_1p_label.visible=false;
				}
			}else{
				warrior_1p_label.visible=false;
				magician_1p_label.visible=false;
			}		
		break;
		
		case 1:
			if(count == 1){
				warrior_1p_label.visible=true;
			}else{
				warrior_1p_label.visible=false;
			}
			magician_1p_label.visible=false;
			
			hp_1p.text=barcode_data_c2[4].hp;
			st_1p.text=barcode_data_c2[4].st;
			df_1p.text=barcode_data_c2[4].df;
		break;
		
		case 2:
			if(count == 1){
				magician_1p_label.visible=true;
			}else{
				magician_1p_label.visible=false;
			}
			warrior_1p_label.visible=false;
			
			hp_1p.text=barcode_data_c2[5].hp;
			st_1p.text=barcode_data_c2[5].st;
			df_1p.text=barcode_data_c2[5].df;
		break;
	}
}

public function friend_animation_c2(event:TimerEvent):void{
	
	var currentCount:int = event.currentTarget.currentCount;
	var count:int = event.currentTarget.currentCount%2;	
	
	if(friend_select_state == 1){
		warrior_1p_label.visible=true;
		magician_1p_label.visible=false;
	}else{
		warrior_1p_label.visible=false;
		magician_1p_label.visible=true;
	}
	
	if(currentCount < 20){
		if(count == 1){
			hp_1p.text = " ==";
			st_1p.text = " ==";
			df_1p.text = " ==";
		}else{
			hp_1p.text = "";
			st_1p.text = "";
			df_1p.text = "";
		}		
	}else{
		if(friend_select_state == 1){
			hp_1p.text = barcode_data_c2[4].hp;
			st_1p.text = barcode_data_c2[4].st;
			df_1p.text = barcode_data_c2[4].df; 
		}else{
			hp_1p.text = barcode_data_c2[5].hp;
			st_1p.text = barcode_data_c2[5].st;
			df_1p.text = barcode_data_c2[5].df;
		}
	}	
	
}

public function friend_animation_c2_complete(event:TimerEvent):void{
	select_button.removeEventListener(MouseEvent.CLICK,add_friend_state);
	set_button.removeEventListener(MouseEvent.CLICK,set_friend_state);	
	
	if(friend_select_animation_timer){
		friend_select_animation_timer.removeEventListener(TimerEvent.TIMER,friend_select_animation_c2);
		friend_select_animation_timer.removeEventListener(TimerEvent.TIMER_COMPLETE,friend_animation_c2_complete);
		friend_select_animation_timer.stop();
		friend_select_animation_timer = null;
	}
	
	set_friend_item_timer = new Timer(200);
	set_friend_item_timer.addEventListener(TimerEvent.TIMER,set_friend_item_animation);
	set_friend_item_timer.start();
	
	//カード入力
	card_in_button.addEventListener(MouseEvent.CLICK,card_item_insert_c2);
	select_image_button.addEventListener(MouseEvent.CLICK,select_image);
	get_camera_button.addEventListener(MouseEvent.CLICK,get_camera);
	
	//カードスキップ
	set_button.addEventListener(MouseEvent.CLICK,card_insert_next_set_c2);
	
	card_in.enabled = true;
	card_in_button.enabled=true;
	init_card_reader_button.enabled = true;
}

public function add_friend_state(event:MouseEvent):void{
	se.select_mp3.play();
	
	switch(friend_select_state){
		case 0:
			if(barcode_data_c2[4].live){
				friend_select_state=1;
			}else{
				friend_select_state=2;
			}
		break;
		
		case 1:
			if(barcode_data_c2[5].live){
				friend_select_state=2;
			}else{
				friend_select_state=1;
			}
		break;
		
		case 2:
			if(barcode_data_c2[4].live){
				friend_select_state=1;
			}else{
				friend_select_state=2;
			}
		break;
	}
	
	set_button.addEventListener(MouseEvent.CLICK,set_friend_state);
}

public function set_friend_state(event:MouseEvent):void{
	se.decide_mp3.play();
	
	select_button.removeEventListener(MouseEvent.CLICK,add_friend_state);
	set_button.removeEventListener(MouseEvent.CLICK,set_friend_state);	
	
	if(friend_select_animation_timer){
		friend_select_animation_timer.removeEventListener(TimerEvent.TIMER,friend_select_animation_c2);
		friend_select_animation_timer.stop();
		friend_select_animation_timer = null;
	}
	
	if(!set_friend_item_timer){
		set_friend_item_timer = new Timer(200);
		set_friend_item_timer.addEventListener(TimerEvent.TIMER,set_friend_item_animation);
		set_friend_item_timer.start();
	}
	
	//カード入力
	card_in_button.addEventListener(MouseEvent.CLICK,card_item_insert_c2);
	select_image_button.addEventListener(MouseEvent.CLICK,select_image);
	get_camera_button.addEventListener(MouseEvent.CLICK,get_camera);
	
	//カードスキップ
	set_button.addEventListener(MouseEvent.CLICK,card_insert_next_set_c2);
	
	card_in.enabled = true;
	card_in_button.enabled=true;
	init_card_reader_button.enabled = true;
	
}

//カードスキップ
public function card_insert_next_set_c2(event:MouseEvent):void{
	se.decide_mp3.play();
	set_button.removeEventListener(MouseEvent.CLICK,card_insert_next_set_c2);
	card_in_button.removeEventListener(MouseEvent.CLICK,card_item_insert_c2);
	select_image_button.removeEventListener(MouseEvent.CLICK,select_image);
	get_camera_button.removeEventListener(MouseEvent.CLICK,get_camera);
	barcode_data_c2[7] = null;
	
	card_insert_next_c2(new MouseEvent(MouseEvent.CLICK));
}


public var set_friend_item_timer:Timer;
public function set_friend_item_animation(event:TimerEvent):void{
	var count:int = event.currentTarget.currentCount%2;
	
	switch(friend_select_state){
		case 1:
			if(count == 1){
				item_label.visible=true;
				warrior_1p_label.visible=true;
				card_input_label.visible=true;
			}else{
				item_label.visible=false;
				warrior_1p_label.visible=false;
				card_input_label.visible=false;
			}
			magician_1p_label.visible=false;
		break;
		
		case 2:
			if(count == 1){
				item_label.visible=true;
				magician_1p_label.visible=true;
				card_input_label.visible=true;
			}else{
				item_label.visible=false;
				magician_1p_label.visible=false;
				card_input_label.visible=false;
			}
			warrior_1p_label.visible=false;
		break;
		
	}
	
}

public function card_item_insert_c2(event:MouseEvent):void{
	card_in_button.removeEventListener(MouseEvent.CLICK,card_item_insert_c2);
	
	if(set_friend_item_timer){
		set_friend_item_timer.removeEventListener(TimerEvent.TIMER,set_friend_item_animation);
		set_friend_item_timer.stop();
		set_friend_item_timer = null;
	}
	
	var barcode_reader:BarcodeRead = new BarcodeRead();
	var barcode:String = card_in.text;
	
	if(friend_select_state == 1){
		var bd:BarcodeData = barcode_data_c2[4];
	}else{
		bd = barcode_data_c2[5];
	}
	
	//アイテムのみ入力
	var ret:Boolean = barcode_reader.init(barcode,2,bd,0,false,null,true);
	//入力成功
	if(ret){
		se.card_in_mp3.play();
		barcode_data_c2[7] = barcode_reader.barcode_data;
		if(barcode_data_c2[7].job <= 6){
			warrior_2p_label.visible = true;
			magician_2p_label.visible = false;
		}else{
			warrior_2p_label.visible = false;
			magician_2p_label.visible = true;
		}
		
		card_input_label.visible = false;
		card_insert_c2_timer = new Timer(80,40);
		card_insert_c2_timer.addEventListener(TimerEvent.TIMER,card_insert_animation_c2);
		card_insert_c2_timer.addEventListener(TimerEvent.TIMER_COMPLETE,card_insert_next_c2);
		card_insert_c2_timer.start();
		
		//入力失敗
	}else{
		se.card_in_error_mp3.play();
		magician_1p_label.visible=false;
		warrior_1p_label.visible=false;
		barcode_data_c2[7] = barcode_reader.barcode_data;
		card_insert_error_c2_timer = new Timer(150,6);
		card_insert_error_c2_timer.addEventListener(TimerEvent.TIMER,card_insert_error_animation_c2);
		card_insert_error_c2_timer.addEventListener(TimerEvent.TIMER_COMPLETE,card_insert_error_back_c2);
		card_insert_error_c2_timer.start();
	}
}

public function battle_get_animation_c2(event:TimerEvent):void{
	
	var count:int = event.currentTarget.currentCount%2;
	
	var bd:BarcodeData;
	if(friend_select_state == 1){
		bd = barcode_data_c2[4];
	}else{
		bd = barcode_data_c2[5];
	}
	
	hp_1p.text = bd.hp;
	
	if(count == 1){
		switch(barcode_data_c2[6].special){
			case 65: //HP+1000
				if(bd.job > 6 && barcode_data_c2[6].job > 6 ){
					mp_label.visible=true;
					st_label.visible=false;
					st_1p.mp_text = bd.mp;
				}else{
					mp_label.visible=false;
					st_label.visible=true;
					st_1p.text = bd.st;
				}
				pp_label.visible=true;
				df_label.visible=false;
				df_1p.pp_text = bd.pp;
				
				hp_2p.text = 10;
				if(barcode_data_c2[6].mp > 0 && barcode_data_c2[6].job > 6 && bd.job > 6){
					st_2p.mp_text = 5; 
				}else{
					st_2p.text = "";
				}
				df_2p.pp_text = 5;
			break;
				
			case 66: //HP+3000
				if(bd.job > 6 && barcode_data_c2[6].job > 6){
					mp_label.visible=true;
					st_label.visible=false;
					st_1p.mp_text = bd.mp;
				}else{
					mp_label.visible=false;
					st_label.visible=true;
					st_1p.text = bd.st;
				}
				pp_label.visible=true;
				df_label.visible=false;
				df_1p.pp_text = bd.pp;
				
				hp_2p.text = 30;
				if(barcode_data_c2[6].mp > 0 && barcode_data_c2[6].job > 6 && bd.job > 6){
					st_2p.mp_text = 5; 
				}else{
					st_2p.text = "";
				}
				df_2p.pp_text = 5;
			break;
			
			case 67: //HP+4000
				if(bd.job > 6 && barcode_data_c2[6].job > 6){
					mp_label.visible=true;
					st_label.visible=false;
					st_1p.mp_text = bd.mp;
				}else{
					mp_label.visible=false;
					st_label.visible=true;
					st_1p.text = bd.st;
				}
				pp_label.visible=true;
				df_label.visible=false;
				df_1p.pp_text = bd.pp;
				
				hp_2p.text = 40;
				if(barcode_data_c2[6].mp > 0 && barcode_data_c2[6].job > 6 && bd.job > 6){
					st_2p.mp_text = 5; 
				}else{
					st_2p.text = "";
				}
				df_2p.pp_text =5;
			break;
			
			case 68: //HP+5000
				if(bd.job > 6 && barcode_data_c2[6].job > 6){
					mp_label.visible=true;
					st_label.visible=false;
					st_1p.mp_text = bd.mp;
				}else{
					mp_label.visible=false;
					st_label.visible=true;
					st_1p.text = bd.st;
				}
				pp_label.visible=true;
				df_label.visible=false;
				df_1p.pp_text = bd.pp;
				
				hp_2p.text = 50;
				if(barcode_data_c2[6].mp > 0 && barcode_data_c2[6].job > 6 && bd.job > 6){
					st_2p.mp_text = 5; 
				}else{
					st_2p.text = "";
				}
				df_2p.pp_text = 5;
			break;
			
			case 69: //HP+10000
				if(bd.job > 6 && barcode_data_c2[6].job > 6){
					mp_label.visible=true;
					st_label.visible=false;
					st_1p.mp_text = bd.mp;
				}else{
					mp_label.visible=false;
					st_label.visible=true;
					st_1p.text = bd.st;
				}
				pp_label.visible=true;
				df_label.visible=false;
				df_1p.pp_text = bd.pp;
				
				hp_2p.text = 100;
				if(barcode_data_c2[6].mp > 0 && barcode_data_c2[6].job > 6 && bd.job > 6){
					st_2p.mp_text = 5; 
				}else{
					st_2p.text = "";
				}
				df_2p.pp_text = 5;
			break;
			
			case 70: //ST+200
				mp_label.visible=false;
				st_label.visible=true;
				st_1p.text = bd.st;
				pp_label.visible=true;
				df_label.visible=false;
				df_1p.pp_text = bd.pp;
				
				hp_2p.text = ""; 
				st_2p.text = 2;
				df_2p.pp_text = 5;
			break;
			
			case 71: //ST+400
				mp_label.visible=false;
				st_label.visible=true;
				st_1p.text = bd.st;
				pp_label.visible=true;
				df_label.visible=false;
				df_1p.pp_text = bd.pp;
				
				hp_2p.text = ""; 
				st_2p.text = 4;
				df_2p.pp_text = 5;
			break;
			
			case 72: //ST+600
				mp_label.visible=false;
				st_label.visible=true;
				st_1p.text = bd.st;
				pp_label.visible=true;
				df_label.visible=false;
				df_1p.pp_text = bd.pp;
				
				hp_2p.text = ""; 
				st_2p.text = 6;
				df_2p.pp_text = 5;
			break;
			
			case 73: //ST+800
				mp_label.visible=false;
				st_label.visible=true;
				st_1p.text = bd.st;
				pp_label.visible=true;
				df_label.visible=false;
				df_1p.pp_text = bd.pp;
				
				hp_2p.text = ""; 
				st_2p.text = 8;
				df_2p.pp_text = 5;
			break;
			
			case 74: //ST+1000
				mp_label.visible=false;
				st_label.visible=true;
				st_1p.text = bd.st;
				pp_label.visible=true;
				df_label.visible=false;
				df_1p.pp_text = bd.pp;
				
				hp_2p.text = ""; 
				st_2p.text = 10;
				df_2p.pp_text = 5;
			break;
			
			case 75: //DF+200
				if(bd.job > 6 && barcode_data_c2[6].job > 6){
					mp_label.visible=true;
					st_label.visible=false;
					st_1p.mp_text = bd.mp;
				}else{
					mp_label.visible=false;
					st_label.visible=true;
					st_1p.text = bd.st;
				}
				pp_label.visible=false;
				df_label.visible=true;
				df_1p.text = bd.df;
				
				hp_2p.text = "";
				if(barcode_data_c2[6].mp > 0 && barcode_data_c2[6].job > 6 && bd.job > 6){
					st_2p.mp_text = 5; 
				}else{
					st_2p.text = "";
				}
				df_2p.text = 2;
			break;
			
			case 76: //DF+400
				if(bd.job > 6 && barcode_data_c2[6].job > 6){
					mp_label.visible=true;
					st_label.visible=false;
					st_1p.mp_text = bd.mp;
				}else{
					mp_label.visible=false;
					st_label.visible=true;
					st_1p.text = bd.st;
				}
				pp_label.visible=false;
				df_label.visible=true;
				df_1p.text = bd.df;
				
				hp_2p.text = "";
				if(barcode_data_c2[6].mp > 0 && barcode_data_c2[6].job > 6 && bd.job > 6){
					st_2p.mp_text = 5; 
				}else{
					st_2p.text = "";
				}
				df_2p.text = 4;
			break;
			
			case 77: //DF+600
				if(bd.job > 6 && barcode_data_c2[6].job > 6){
					mp_label.visible=true;
					st_label.visible=false;
					st_1p.mp_text = bd.mp;
				}else{
					mp_label.visible=false;
					st_label.visible=true;
					st_1p.text = bd.st;
				}
				pp_label.visible=false;
				df_label.visible=true;
				df_1p.text = bd.df;
				
				hp_2p.text = "";
				if(barcode_data_c2[6].mp > 0 && barcode_data_c2[6].job > 6 && bd.job > 6){
					st_2p.mp_text = 5; 
				}else{
					st_2p.text = "";
				}
				df_2p.text = 6;
			break;
			
			case 78: //DF+800
				if(bd.job > 6 && barcode_data_c2[6].job > 6){
					mp_label.visible=true;
					st_label.visible=false;
					st_1p.mp_text = bd.mp;
				}else{
					mp_label.visible=false;
					st_label.visible=true;
					st_1p.text = bd.st;
				}
				pp_label.visible=false;
				df_label.visible=true;
				df_1p.text = bd.df;
				
				hp_2p.text = "";
				if(barcode_data_c2[6].mp > 0 && barcode_data_c2[6].job > 6 && bd.job > 6){
					st_2p.mp_text =  5; 
				}else{
					st_2p.text = "";
				}
				df_2p.text = 8;
			break;
			
			case 79: //DF+1000
				if(bd.job > 6 && barcode_data_c2[6].job > 6){
					mp_label.visible=true;
					st_label.visible=false;
					st_1p.mp_text = bd.mp;
				}else{
					mp_label.visible=false;
					st_label.visible=true;
					st_1p.text = bd.st;
				}
				pp_label.visible=false;
				df_label.visible=true;
				df_1p.text = bd.df;
				
				hp_2p.text = "";
				if(barcode_data_c2[6].mp > 0 && barcode_data_c2[6].job > 6 && bd.job > 6){
					st_2p.mp_text = 5; 
				}else{
					st_2p.text = "";
				}
				df_2p.text = 10;
			break;
			
			default:
				
				if(bd.job > 6 && barcode_data_c2[6].job > 6){
					mp_label.visible=true;
					st_label.visible=false;
					st_1p.mp_text = bd.mp;
				}else{
					mp_label.visible=false;
					st_label.visible=true;
					st_1p.text = bd.st;
				}
				pp_label.visible=true;
				df_label.visible=false;
				df_1p.pp_text = bd.pp;
				
				hp_2p.text = "";
				if(barcode_data_c2[6].mp > 0 && barcode_data_c2[6].job > 6 && bd.job > 6){
					st_2p.mp_text = 5; 
				}else{
					st_2p.text = "";
				}
				df_2p.pp_text = 5;
		}
	}else{
		hp_2p.text = "";
		st_2p.text = "";
		df_2p.text = "";
	}
}

//魔法、薬草使用後にFightingDataをコピーする
public function magic_pp_use_copy():void{
	//C2
	if(mode == 2){
		if(friend_select_state == 1){
			barcode_data_c2[4].hp = fighting_data[0].hp;
			barcode_data_c2[4].mp = fighting_data[0].mp;
			barcode_data_c2[4].pp = fighting_data[0].pp;	
		}else{
			barcode_data_c2[5].hp = fighting_data[0].hp;
			barcode_data_c2[5].mp = fighting_data[0].mp;
			barcode_data_c2[5].pp = fighting_data[0].pp;
		}
	//C1
	}else{
		if(friend_select_state_c1 == 1){
			barcode_data_c1[4].hp = fighting_data[0].hp;
			barcode_data_c1[4].mp = fighting_data[0].mp;
			barcode_data_c1[4].pp = fighting_data[0].pp;	
		}else{
			barcode_data_c1[5].hp = fighting_data[0].hp;
			barcode_data_c1[5].mp = fighting_data[0].mp;
			barcode_data_c1[5].pp = fighting_data[0].pp;
		}
	}
}


public var use_mp_pp_timer:Timer;
public function select_end_state(event:MouseEvent):void{
	l_power.removeEventListener(MouseEvent.CLICK,battle_end_l_power);
	r_battle.removeEventListener(MouseEvent.CLICK,save);
	
	if(battle_get_animation_timer && !select_magic_pp_use){
		//C2
		if(mode  == 2){
			battle_get_animation_timer.removeEventListener(TimerEvent.TIMER,battle_get_animation_c2);
			battle_get_animation_timer.stop();
			battle_get_animation_timer = null;
			
			l_power.removeEventListener(MouseEvent.MOUSE_UP,battle_end_c2);
			l_power.removeEventListener(MouseEvent.MOUSE_OUT,battle_end_c2);
			
			select_button.removeEventListener(MouseEvent.CLICK,select_end_state);
			set_button.removeEventListener(MouseEvent.CLICK,get_mp_pp);
			
		//C1
		}else{
			battle_get_animation_timer.removeEventListener(TimerEvent.TIMER,battle_get_animation_c1);
			battle_get_animation_timer.stop();
			battle_get_animation_timer = null;
			
			select_button.removeEventListener(MouseEvent.CLICK,select_end_state);
			set_button.removeEventListener(MouseEvent.CLICK,get_mp_pp_c1);
			l_power.removeEventListener(MouseEvent.MOUSE_UP,battle_end_c1);
			l_power.removeEventListener(MouseEvent.MOUSE_OUT,battle_end_c1);
			
		}
		
		fighting_calc.now_player = 1;
		select_battle_magic = false;
		select(new MouseEvent(MouseEvent.CLICK));
	}else{
		
		//C2
		if(mode  == 2){
			if(!select_magic_pp_use){
				select_button.addEventListener(MouseEvent.CLICK,select_end_state);
			}else{
				select_button.removeEventListener(MouseEvent.CLICK,select_end_state);
			}
			set_button.addEventListener(MouseEvent.CLICK,get_mp_pp);
			
			battle_get_animation_timer = new Timer(120);
			battle_get_animation_timer.addEventListener(TimerEvent.TIMER,battle_get_animation_c2);
			battle_get_animation_timer.start();
		//C1
		}else{
			if(!select_magic_pp_use){
				select_button.addEventListener(MouseEvent.CLICK,select_end_state);
			}else{
				select_button.removeEventListener(MouseEvent.CLICK,select_end_state);
			}
			set_button.addEventListener(MouseEvent.CLICK,get_mp_pp_c1);
			
			battle_get_animation_timer = new Timer(120);
			battle_get_animation_timer.addEventListener(TimerEvent.TIMER,battle_get_animation_c1);
			battle_get_animation_timer.start();
		}
	}
}

public var display_mp_pp_timer:Timer; 
public function get_mp_pp(event:MouseEvent):void{
	se.decide_mp3.play();
	
	l_power.removeEventListener(MouseEvent.CLICK,show_passcode);
	l_power.removeEventListener(MouseEvent.MOUSE_UP,battle_end_c2);
	l_power.removeEventListener(MouseEvent.MOUSE_OUT,battle_end_c2);
	select_button.removeEventListener(MouseEvent.CLICK,select_end_state);
	set_button.removeEventListener(MouseEvent.CLICK,get_mp_pp);
	
	if(battle_get_animation_timer){
		battle_get_animation_timer.removeEventListener(TimerEvent.TIMER,battle_get_animation_c2);
		battle_get_animation_timer.stop();
		battle_get_animation_timer = null;
	}
	
	switch(barcode_data_c2[6].special){
		case 65: //HP+1000
			if(friend_select_state == 1){
				barcode_data_c2[4].hp = barcode_data_c2[4].hp + 1;
				barcode_data_c2[4].pp = barcode_data_c2[4].pp + 5;
			}else{
				barcode_data_c2[5].hp = barcode_data_c2[5].hp + 1;
				barcode_data_c2[5].pp = barcode_data_c2[5].pp + 5;
				barcode_data_c2[5].mp = barcode_data_c2[5].mp + 5;
			}
			break;
		
		case 66: //HP+3000
			if(friend_select_state == 1){
				barcode_data_c2[4].hp = barcode_data_c2[4].hp + 3;
				barcode_data_c2[4].pp = barcode_data_c2[4].pp + 5;
			}else{
				barcode_data_c2[5].hp = barcode_data_c2[5].hp + 3;
				barcode_data_c2[5].pp = barcode_data_c2[5].pp + 5;
				barcode_data_c2[5].mp = barcode_data_c2[5].mp + 5;
			}
			break;
		
		case 67: //HP+4000
			if(friend_select_state == 1){
				barcode_data_c2[4].hp = barcode_data_c2[4].hp + 4;
				barcode_data_c2[4].pp = barcode_data_c2[4].pp + 5;
			}else{
				barcode_data_c2[5].hp = barcode_data_c2[5].hp + 4;
				barcode_data_c2[5].pp = barcode_data_c2[5].pp + 5;
				barcode_data_c2[5].mp = barcode_data_c2[5].mp + 5;
			}
			break;
		
		case 68: //HP+5000
			if(friend_select_state == 1){
				barcode_data_c2[4].hp = barcode_data_c2[4].hp + 5;
				barcode_data_c2[4].pp = barcode_data_c2[4].pp + 5;
			}else{
				barcode_data_c2[5].hp = barcode_data_c2[5].hp + 5;
				barcode_data_c2[5].pp = barcode_data_c2[5].pp + 5;
				barcode_data_c2[5].mp = barcode_data_c2[5].mp + 5;
			}
			break;
		
		case 69: //HP+10000
			if(friend_select_state == 1){
				barcode_data_c2[4].hp = barcode_data_c2[4].hp + 10;
				barcode_data_c2[4].pp = barcode_data_c2[4].pp + 5;
			}else{
				barcode_data_c2[5].hp = barcode_data_c2[5].hp + 10;
				barcode_data_c2[5].pp = barcode_data_c2[5].pp + 5;
				barcode_data_c2[5].mp = barcode_data_c2[5].mp + 5;
			}
			break;
		
		case 70: //ST+200
			if(friend_select_state == 1){
				barcode_data_c2[4].st = barcode_data_c2[4].st + 2;
				barcode_data_c2[4].pp = barcode_data_c2[4].pp + 5;
			}else{
				barcode_data_c2[5].st = barcode_data_c2[5].st + 2;
				barcode_data_c2[5].pp = barcode_data_c2[5].pp + 5;
			}
			break;
		
		case 71: //ST+400
			if(friend_select_state == 1){
				barcode_data_c2[4].st = barcode_data_c2[4].st + 4;
				barcode_data_c2[4].pp = barcode_data_c2[4].pp + 5;
			}else{
				barcode_data_c2[5].st = barcode_data_c2[5].st + 4;
				barcode_data_c2[5].pp = barcode_data_c2[5].pp + 5;
			}
			break;
		
		case 72: //ST+600
			if(friend_select_state == 1){
				barcode_data_c2[4].st = barcode_data_c2[4].st + 6;
				barcode_data_c2[4].pp = barcode_data_c2[4].pp + 5;
			}else{
				barcode_data_c2[5].st = barcode_data_c2[5].st + 6;
				barcode_data_c2[5].pp = barcode_data_c2[5].pp + 5;
			}
			break;
		
		case 73: //ST+800
			if(friend_select_state == 1){
				barcode_data_c2[4].st = barcode_data_c2[4].st + 8;
				barcode_data_c2[4].pp = barcode_data_c2[4].pp + 5;
			}else{
				barcode_data_c2[5].st = barcode_data_c2[5].st + 8;
				barcode_data_c2[5].pp = barcode_data_c2[5].pp + 5;
			}
			break;
		
		case 74: //ST+1000
			if(friend_select_state == 1){
				barcode_data_c2[4].st = barcode_data_c2[4].st + 10;
				barcode_data_c2[4].pp = barcode_data_c2[4].pp + 5;
			}else{
				barcode_data_c2[5].st = barcode_data_c2[5].st + 10;
				barcode_data_c2[5].pp = barcode_data_c2[5].pp + 5;
			}
			break;
		
		case 75: //DF+200
			if(friend_select_state == 1){
				barcode_data_c2[4].df = barcode_data_c2[4].df + 2;
			}else{
				barcode_data_c2[5].df = barcode_data_c2[5].df + 2;
				barcode_data_c2[5].mp = barcode_data_c2[5].mp + 5;
			}
			break;
		
		case 76: //DF+400
			if(friend_select_state == 1){
				barcode_data_c2[4].df = barcode_data_c2[4].df + 4;
			}else{
				barcode_data_c2[5].df = barcode_data_c2[5].df + 4;
				barcode_data_c2[5].mp = barcode_data_c2[5].mp + 5;
			}
			break;
		
		case 77: //DF+600
			if(friend_select_state == 1){
				barcode_data_c2[4].df = barcode_data_c2[4].df + 6;
			}else{
				barcode_data_c2[5].df = barcode_data_c2[5].df + 6;
				barcode_data_c2[5].mp = barcode_data_c2[5].mp + 5;
			}
			break;
		
		case 78: //DF+800
			if(friend_select_state == 1){
				barcode_data_c2[4].df = barcode_data_c2[4].df + 8;
			}else{
				barcode_data_c2[5].df = barcode_data_c2[5].df + 8;
				barcode_data_c2[5].mp = barcode_data_c2[5].mp + 5;
			}
			break;
		
		case 79: //DF+1000
			if(friend_select_state == 1){
				barcode_data_c2[4].df = barcode_data_c2[4].df + 10;
			}else{
				barcode_data_c2[5].df = barcode_data_c2[5].df + 1;
				barcode_data_c2[5].mp = barcode_data_c2[5].mp + 5;
			}
			break;
		
		default:
			//MP PPをコピー
			if(friend_select_state == 1){
				barcode_data_c2[4].pp = barcode_data_c2[4].pp + 5;
			}else{
				barcode_data_c2[5].pp = barcode_data_c2[5].pp + 5;
				barcode_data_c2[5].mp = barcode_data_c2[5].mp + 5;
			}
	}			
	
	
	if(barcode_data_c2[4].hp > 999){
		barcode_data_c2[4].hp = 999;
	}
	if(barcode_data_c2[4].st > 199){
		barcode_data_c2[4].st = 199;
	}
	if(barcode_data_c2[4].df > 199){
		barcode_data_c2[4].df = 199;
	}
	if(barcode_data_c2[4].pp > 99){
		barcode_data_c2[4].pp = 99;
	}
	if(barcode_data_c2[5].hp > 999){
		barcode_data_c2[5].hp = 999;
	}
	if(barcode_data_c2[5].st > 199){
		barcode_data_c2[5].st = 199;
	}
	if(barcode_data_c2[5].df > 199){
		barcode_data_c2[5].df = 199;
	}
	if(barcode_data_c2[5].mp > 99){
		barcode_data_c2[5].mp = 99;
	}
	if(barcode_data_c2[5].pp > 99){
		barcode_data_c2[5].pp = 99;
	}

	
	if(!display_mp_pp_timer){
		display_mp_pp_timer = new Timer(100,20);
		display_mp_pp_timer.addEventListener(TimerEvent.TIMER,display_mp_pp);
		display_mp_pp_timer.addEventListener(TimerEvent.TIMER_COMPLETE,card_enemy_insert_wait_c2_se);
		display_mp_pp_timer.start();
	}
}

public function display_mp_pp(event:TimerEvent):void{
	
	var bd:BarcodeData;
	if(friend_select_state == 1){
		bd = barcode_data_c2[4];
	}else{
		bd = barcode_data_c2[5];
	}
	
	switch(barcode_data_c2[6].special){
		//ST+XX
		case 70:
		case 71:
		case 72:
		case 73:
		case 74:
			hp_1p.text = bd.hp;
			mp_label.visible=false;
			st_label.visible=true;
			st_1p.text = bd.st;
			pp_label.visible=true;
			df_label.visible=false;
			df_1p.pp_text = bd.pp;
		break;
		
		//DF+XX
		case 75:
		case 76:
		case 77:
		case 78:
		case 79:
			hp_1p.text = bd.hp;
			if(bd.job > 6 && barcode_data_c2[6].job > 6){
				mp_label.visible=true;
				st_label.visible=false;
				st_1p.mp_text = bd.mp;
			}else{
				mp_label.visible=false;
				st_label.visible=true;
				st_1p.text = bd.st;
			}
			pp_label.visible=false;
			df_label.visible=true;
			df_1p.text = bd.df;
		break;
		
		default:
			hp_1p.text = bd.hp;
			if(bd.job > 6 && barcode_data_c2[6].job > 6){
				mp_label.visible=true;
				st_label.visible=false;
				st_1p.mp_text = bd.mp;
			}else{
				mp_label.visible=false;
				st_label.visible=true;
				st_1p.text = bd.st;
			}
			pp_label.visible=true;
			df_label.visible=false;
			df_1p.pp_text = bd.pp;	
	}
	
	hp_2p.text = "";
	st_2p.text = "";
	df_2p.text = "";
}



public function battle_end_c2(event:Event):void{
	l_power.removeEventListener(MouseEvent.MOUSE_UP,battle_end_c2);
	l_power.removeEventListener(MouseEvent.MOUSE_OUT,battle_end_c2);
	
	if(battle_end_animation_timer){
		battle_end_animation_timer.removeEventListener(TimerEvent.TIMER,battle_end_animation);
		battle_end_animation_timer.removeEventListener(TimerEvent.TIMER_COMPLETE,battle_end_c2);
		battle_end_animation_timer.stop();
		battle_end_animation_timer =  null;
	}
	
	if(barcode_data_c2[6].hp <=0){
		if(!battle_get_animation_timer){
			battle_get_animation_timer = new Timer(120);
			battle_get_animation_timer.addEventListener(TimerEvent.TIMER,battle_get_animation_c2);
			battle_get_animation_timer.start();
		}
		
		if(barcode_data_c2[6].special >=80 && barcode_data_c2[6].special<=99){
			l_power.addEventListener(MouseEvent.CLICK,show_passcode);
		}
		select_magic_pp_use = false;
		select_button.addEventListener(MouseEvent.CLICK,select_end_state);
		set_button.addEventListener(MouseEvent.CLICK,get_mp_pp);
		
	}else{
		l_power.removeEventListener(MouseEvent.CLICK,show_passcode);
		select_button.addEventListener(MouseEvent.CLICK,card_enemy_insert_wait_c2);
		set_button.addEventListener(MouseEvent.CLICK,card_insert_wait_c2_back);
	}
}


//パスコード表示
public function show_passcode(event:MouseEvent):void{
	se.passcode_mp3.play();
	
	if(battle_get_animation_timer){
		battle_get_animation_timer.removeEventListener(TimerEvent.TIMER,battle_get_animation_c2);
		battle_get_animation_timer.stop();
		battle_get_animation_timer=null;
	}
	
	l_power.removeEventListener(MouseEvent.CLICK,show_passcode);
	select_button.removeEventListener(MouseEvent.CLICK,select_end_state);
	set_button.removeEventListener(MouseEvent.CLICK,get_mp_pp);
	l_power.addEventListener(MouseEvent.MOUSE_UP,battle_end_c2);
	l_power.addEventListener(MouseEvent.MOUSE_OUT,battle_end_c2);
	
	var c2_passcode:C2PassCode = new C2PassCode();
	c2_passcode.init(barcode_data_c2[0],barcode_data_c2[1]);
	var passcode:String = c2_passcode.generate_passcode(barcode_data_c2[6].special);
	
	//パスコード表示
	hp_1p.text = "p"+passcode.charAt(0)+passcode.charAt(1);
	hp_2p.text = passcode.charAt(2)+passcode.charAt(3)+passcode.charAt(4);
	st_1p.text = "";
	st_2p.text = "";
	df_1p.text = "";
	df_2p.text = "";
	warrior_1p_label.visible=false;
	warrior_2p_label.visible=false;
	magician_1p_label.visible=false;
	magician_2p_label.visible=false;
	
	hp_label.visible=false;
	st_label.visible=false;
	df_label.visible=false;
	mp_label.visible=false;
	pp_label.visible=false;
	
	var passcode_number:int = int(passcode.charAt(0).toString()+passcode.charAt(2).toString());
	
	//パスコード適用
	barcode_data_c2[2] = createCloneInstance(barcode_data_c2[4]);
	barcode_data_c2[3] = createCloneInstance(barcode_data_c2[5]);
	barcode_data_c2[4] = c2_passcode.generate_passcode_barcode_data(createCloneInstance(barcode_data_c2[0]),passcode_number);
	barcode_data_c2[5] = c2_passcode.generate_passcode_barcode_data(createCloneInstance(barcode_data_c2[1]),passcode_number);
}



//////////////////////////////C1
private var card_insert_wait_c1_timer:Timer;

private function card_insert_retry_c1(event:MouseEvent):void{
	if(select_stage_enemy_animation_timer){
		select_stage_enemy_animation_timer.removeEventListener(TimerEvent.TIMER,stage_enemy_animation);
		select_stage_enemy_animation_timer.stop();
		select_stage_enemy_animation_timer = null;
	}
	
	select_button.removeEventListener(MouseEvent.CLICK,c1_stage_enemy_select);
	set_button.removeEventListener(MouseEvent.CLICK,c1_stage_enemy_set);
	l_power.removeEventListener(MouseEvent.CLICK,card_insert_retry_c1);
	l_battle.removeEventListener(MouseEvent.CLICK,c1_input_passcode);
	r_battle.removeEventListener(MouseEvent.CLICK,save);
	
	bb2_state = 4;
	set_button.addEventListener(MouseEvent.CLICK,card_insert_skip_c1);
	card_insert_wait_c1();
}

//カード入力待ち
private function card_insert_wait_c1():void{
	
	select_button.removeEventListener(MouseEvent.CLICK,card_insert_wait_c1);
	
	if(!card_insert_wait_c1_timer){
		card_insert_wait_c1_timer = new Timer(500);
		card_insert_wait_c1_timer.addEventListener(TimerEvent.TIMER,card_insert_wait_animation_c1);
		card_insert_wait_c1_timer.start();
	}
	
	switch(bb2_state){
		//1枚目(戦士(主人公))
		case 4:
			hp_1p.text=" ==";
			st_1p.text=" ==";
			df_1p.text=" ==";
			hp_2p.text=" ==";
			st_2p.text=" ==";
			df_2p.text=" ==";
			hp_label.visible=true;
			st_label.visible=true;
			df_label.visible=true;
			warrior_1p_label.visible=true;
			warrior_2p_label.visible=false;
			magician_1p_label.visible=false;
			magician_2p_label.visible=true;
			card_in_button.addEventListener(MouseEvent.CLICK,card_insert_c1);
			select_image_button.addEventListener(MouseEvent.CLICK,select_image);
			get_camera_button.addEventListener(MouseEvent.CLICK,get_camera);
			r_battle.addEventListener(MouseEvent.CLICK,load);
			card_in.enabled = true;
			card_in_button.enabled=true;
			init_card_reader_button.enabled = true;
			break;
		
		//2枚目(魔法使い(主人公))
		case 5:
			hp_2p.text=" ==";
			st_2p.text=" ==";
			df_2p.text=" ==";
			card_in_button.addEventListener(MouseEvent.CLICK,card_insert_c1);
			select_image_button.addEventListener(MouseEvent.CLICK,select_image);
			get_camera_button.addEventListener(MouseEvent.CLICK,get_camera);
			card_in.enabled = true;
			card_in_button.enabled=true;
			init_card_reader_button.enabled = true;
			break;
		
	}	
}


//カード入力待ちアニメーション
private function card_insert_wait_animation_c1(event:TimerEvent):void{
	var count:int = event.target.currentCount%2;	
	switch(bb2_state){
		//1枚目
		case 4:
			if(count == 1){
				card_input_label.visible =false;
				warrior_1p_label.visible =false;
				magician_1p_label.visible =false;
			}else{
				card_input_label.visible =true;
				warrior_1p_label.visible =true;
				magician_1p_label.visible =false;
			}
			break;
		
		//2枚目
		case 5:
			if(count == 1){
				card_input_label.visible =false;
				warrior_2p_label.visible =false;
				magician_2p_label.visible =false;
			}else{
				card_input_label.visible =true;
				warrior_2p_label.visible =false;
				magician_2p_label.visible =true;
			}
			break;
	}
	
}




//カード入力受付処理
private var card_insert_c1_timer:Timer;
private var card_insert_error_c1_timer:Timer;
private var barcode_data_c1:Array;
private function card_insert_c1(event:MouseEvent):void{
	if(!barcode_data_c1){
		barcode_data_c1 = new Array(6);
	}
	
	card_in_button.removeEventListener(MouseEvent.CLICK,card_insert_c1);
	select_image_button.removeEventListener(MouseEvent.CLICK,select_image);
	get_camera_button.removeEventListener(MouseEvent.CLICK,get_camera);
	card_in_button.enabled = false;
	init_card_reader_button.enabled = false;
	r_battle.removeEventListener(MouseEvent.CLICK,load);
	
	if(card_insert_wait_c1_timer){
		card_insert_wait_c1_timer.removeEventListener(TimerEvent.TIMER,card_insert_wait_animation_c1);
		card_insert_wait_c1_timer.stop();
		card_insert_wait_c1_timer = null;
	}
	
	switch(bb2_state){
		//1枚目
		case 4:
			var barcode_reader:BarcodeRead = new BarcodeRead();
			var barcode:String = card_in.text;
			var ret:Boolean = barcode_reader.init(barcode,1,null,0,true,"warrior");
			
			//入力成功
			if(ret){
				if(c1_world_data){
					c1_world_data.reset_world();
				}
				
				se.card_in_mp3.play();
				
				if(c1_world_data && c1_world_data.select_stage != 0){
					barcode_data_c1[0] = createCloneInstance(barcode_reader.barcode_data);
					var c1_passcode_number:int = c1_world_data.get_passcode_number(c1_world_data.select_stage - 1); 
					var c2_passcode:C2PassCode = new C2PassCode();
					barcode_data_c1[2] = c2_passcode.generate_passcode_barcode_data(createCloneInstance(barcode_data_c1[0]),c1_passcode_number);
					barcode_data_c1[4] = c2_passcode.generate_passcode_barcode_data(createCloneInstance(barcode_data_c1[0]),c1_passcode_number);
				}else{
					barcode_data_c1[0] = createCloneInstance(barcode_reader.barcode_data);
					barcode_data_c1[2] = createCloneInstance(barcode_reader.barcode_data);
					barcode_data_c1[4] = createCloneInstance(barcode_reader.barcode_data);
				}
				
				if(barcode_data_c1[0].job <= 6){
					warrior_1p_label.visible = true;
					magician_1p_label.visible = false;
				}else{
					warrior_1p_label.visible = false;
					magician_1p_label.visible = true;
				}
				
				card_input_label.visible = false;
				card_insert_c1_timer = new Timer(80,20);
				card_insert_c1_timer.addEventListener(TimerEvent.TIMER,card_insert_animation);
				card_insert_c1_timer.addEventListener(TimerEvent.TIMER_COMPLETE,card_insert_next_c1);
				card_insert_c1_timer.start();
				
				//入力失敗
			}else{
				se.card_in_error_mp3.play();
				magician_1p_label.visible=false;
				warrior_1p_label.visible=false;
				barcode_data_c1[0] = createCloneInstance(barcode_reader.barcode_data);
				barcode_data_c1[2] = createCloneInstance(barcode_reader.barcode_data);
				barcode_data_c1[4] = createCloneInstance(barcode_reader.barcode_data);
				card_insert_error_c1_timer = new Timer(150,6);
				card_insert_error_c1_timer.addEventListener(TimerEvent.TIMER,card_insert_error_animation_c1);
				card_insert_error_c1_timer.addEventListener(TimerEvent.TIMER_COMPLETE,card_insert_error_back_c1);
				card_insert_error_c1_timer.start();
			}
			break;
		
		//2枚目
		case 5:
			barcode_reader = new BarcodeRead();
			barcode = card_in.text;
			ret = barcode_reader.init(barcode,1,null,0,true,"magician");
			
			//入力成功
			if(ret){
				if(c1_world_data){
					c1_world_data.reset_world();
				}
				se.card_in_mp3.play();
				
				if(c1_world_data && c1_world_data.select_stage != 0){
					barcode_data_c1[1] = createCloneInstance(barcode_reader.barcode_data);
					var c1_passcode_number:int = c1_world_data.get_passcode_number(c1_world_data.select_stage - 1); 
					var c2_passcode:C2PassCode = new C2PassCode();
					barcode_data_c1[3] = c2_passcode.generate_passcode_barcode_data(createCloneInstance(barcode_data_c1[1]),c1_passcode_number);
					barcode_data_c1[5] = c2_passcode.generate_passcode_barcode_data(createCloneInstance(barcode_data_c1[1]),c1_passcode_number);
				}else{
					barcode_data_c1[1] = createCloneInstance(barcode_reader.barcode_data);
					barcode_data_c1[3] = createCloneInstance(barcode_reader.barcode_data);
					barcode_data_c1[5] = createCloneInstance(barcode_reader.barcode_data);
				}
				
				if(barcode_data_c1[1].job <= 6){
					warrior_2p_label.visible = true;
					magician_2p_label.visible = false;
				}else{
					warrior_2p_label.visible = false;
					magician_2p_label.visible = true;
				}
				
				card_input_label.visible = false;
				card_insert_c1_timer = new Timer(80,20);
				card_insert_c1_timer.addEventListener(TimerEvent.TIMER,card_insert_animation);
				card_insert_c1_timer.addEventListener(TimerEvent.TIMER_COMPLETE,card_insert_next_c1);
				card_insert_c1_timer.start();
				
				//入力失敗
			}else{
				se.card_in_error_mp3.play();
				magician_2p_label.visible=false;
				warrior_2p_label.visible=false;
				barcode_data_c1[1] = createCloneInstance(barcode_reader.barcode_data);
				barcode_data_c1[3] = createCloneInstance(barcode_reader.barcode_data);
				barcode_data_c1[5] = createCloneInstance(barcode_reader.barcode_data);
				
				card_insert_error_c1_timer = new Timer(150,6);
				card_insert_error_c1_timer.addEventListener(TimerEvent.TIMER,card_insert_error_animation_c1);
				card_insert_error_c1_timer.addEventListener(TimerEvent.TIMER_COMPLETE,card_insert_error_back_c1);
				card_insert_error_c1_timer.start();
			}
			break;
	}
}


//既に主人公をセット済みのときに入力する
private var card_insert_skip_timer:Timer;
private function card_insert_skip_c1(event:MouseEvent):void{

	switch(bb2_state){
		case 4:
			warrior_1p_label.visible=true;
			
			hp_1p.text = barcode_data_c1[2].hp;
			st_1p.text = barcode_data_c1[2].st;
			df_1p.text = barcode_data_c1[2].df;
			bb2_state = bb2_state + 1;
		break;
		
		case 5:
			set_button.removeEventListener(MouseEvent.CLICK,card_insert_skip_c1);
			
			card_input_label.visible=false;
			magician_2p_label.visible=true;
			
			hp_2p.text = barcode_data_c1[3].hp;
			st_2p.text = barcode_data_c1[3].st;
			df_2p.text = barcode_data_c1[3].df;
			bb2_state = bb2_state + 1;
			
			set_button.addEventListener(MouseEvent.CLICK,c1_stage_select_click);
		break;
	}
}

//カード入力完了→次のステータスへ
private var c1_world_data:C1WorldData = null;
private function card_insert_next_c1(event:Event):void{
	
	if(card_insert_c1_timer){
		card_insert_c1_timer.removeEventListener(TimerEvent.TIMER,card_insert_animation);
		card_insert_c1_timer.removeEventListener(TimerEvent.TIMER_COMPLETE,card_insert_next_c1);
		card_insert_c1_timer.stop();
		card_insert_c1_timer = null;
	}
	
	if(load_status_animation_timer){
		load_status_animation_timer.removeEventListener(TimerEvent.TIMER,load_status_animation);
		load_status_animation_timer.removeEventListener(TimerEvent.TIMER_COMPLETE,card_insert_next_c1);
		load_status_animation_timer.stop();
		load_status_animation_timer = null;
	}
	
	switch(bb2_state){
		
		//1枚目
		case 4:
			var bd:BarcodeData = barcode_data_c1[4];
			hp_1p.text = bd.hp;
			st_1p.text = (bd.st > 199)?199:bd.st;
			df_1p.text = (bd.df > 199)?199:bd.df;
			bb2_state = bb2_state + 1;
			card_reader_visible = false;
			init_card_reader(new MouseEvent(MouseEvent.CLICK));
			card_in_button.addEventListener(MouseEvent.CLICK,card_insert_c1);
			select_image_button.addEventListener(MouseEvent.CLICK,select_image);
			get_camera_button.addEventListener(MouseEvent.CLICK,get_camera);
			card_in.enabled = true;
			card_in_button.enabled=true;
			init_card_reader_button.enabled = true;
			card_insert_wait_c1();
			break;
		
		//2枚目
		case 5:
			bd = barcode_data_c1[5];
			hp_1p.text = barcode_data_c1[4].hp;
			st_1p.text = (barcode_data_c1[4].st > 199)?199:barcode_data_c1[4].st;
			df_1p.text = (barcode_data_c1[4].df > 199)?199:barcode_data_c1[4].df;
			hp_2p.text = bd.hp;
			st_2p.text = (bd.st > 199)?199:bd.st;
			df_2p.text = (bd.df > 199)?199:bd.df;
			bb2_state = bb2_state + 1;
			card_reader_visible = false;
			card_in.enabled = false;
			card_input_label.visible=false;
			
			if(!c1_world_data){
				c1_world_data = new C1WorldData();
				
				if(barcode_data_c1[4].barcode.length > 8){
					var checkdigit1:int = barcode_data_c1[4].barcode.charAt(12);
					var checkdigit2:int = barcode_data_c1[5].barcode.charAt(12);
				}else{
					var checkdigit1:int = barcode_data_c1[4].barcode.charAt(8);
					var checkdigit2:int = barcode_data_c1[5].barcode.charAt(8);
				}
					
				c1_world_data.init(checkdigit1,checkdigit2);
			}
			set_button.addEventListener(MouseEvent.CLICK,c1_stage_select_click);
			
			break;
		
		case 6:
			hp_label.visible = true;
			st_label.visible = true;
			df_label.visible = true;
			mp_label.visible = false;
			pp_label.visible = false;
			item_label.visible =false;
			card_input_label.visible=false;
			
			if(c1_world_data.key_number() > 0){
				key_label.visible = true;
			}
			
			if(friend_select_state_c1 == 1){
				bd = barcode_data_c1[4];
			}else{
				bd = barcode_data_c1[5];
			}
			
			if(!fighting_data){
				fighting_data = new Array(2);
			}
			
			//入力なし
			if(!barcode_data_c1[6]){
				fighting_data[0] = new CreateFightingData().init(bd,null);
			}else{
				//1p(主人公)のFD作成
				fighting_data[0] = new CreateFightingData().init(bd,barcode_data_c1[6]);
			}
			
			//2p(敵)のFD作成
			fighting_data[1] = new CreateFightingData().init(barcode_data_enemy,null);
			fighting_data[1].cpu = true;
			
			if(fighting_data[0].job > 6){
				warrior_1p_label.visible=false;
				magician_1p_label.visible=true;
			}else{
				warrior_1p_label.visible=true;
				magician_1p_label.visible=false;
			}
			
			hp_2p.text = fighting_data[1].hp;
			st_2p.text = (fighting_data[1].st>199)?199:fighting_data[1].st;
			df_2p.text = (fighting_data[1].df>199)?199:fighting_data[1].df;
			if(fighting_data[1].job > 6){
				magician_2p_label.visible = true;
				warrior_2p_label.visible = false;
			}else{
				magician_2p_label.visible = false;
				warrior_2p_label.visible = true;
			}
			
			hp_1p.text = fighting_data[0].hp;
			st_1p.text = (fighting_data[0].st>199)?199:fighting_data[0].st;
			df_1p.text = (fighting_data[0].df>199)?199:fighting_data[0].df;
			
			bb2_state = bb2_state + 1;
			
			card_reader_visible = false;
			card_in.enabled = false;
			card_in_button.enabled=false;
			init_card_reader_button.enabled = false;
			
			//ダウン系特殊能力処理へ
			fighting_calc.fighting_data = fighting_data;
			special_down();
			
		break;
		
	}
}

//カード入力失敗アニメーション
private function card_insert_error_animation_c1(event:TimerEvent):void{
	
	var count:int = event.currentTarget.currentCount%2;	
	switch(bb2_state){
		
		//1枚目	
		case 4:
			if(count == 1){
				//アイテムなら
				if(barcode_data_c1[0]!= null && barcode_data_c1[0].race > 4){
					card_input_label.visible = true;
					item_label.visible = true;
					miss_label.visible = false;
					//job
				}else if(barcode_data_c1[0]!= null && barcode_data_c1[0].race <= 4){
					if(barcode_data_c1[0].job >=7){
						warrior_1p_label.visible = false;
						magician_1p_label.visible = true;
					}else{
						warrior_1p_label.visible = true;
						magician_1p_label.visible = false;
					}
					miss_label.visible = false;
					//カード入力ミス
				}else{
					card_input_label.visible = true;
					miss_label.visible = false;
				}
				
			}else{
				if(barcode_data_c1[0]!= null && barcode_data_c1[0].race > 4){
					card_input_label.visible = true;
					item_label.visible = false;
					miss_label.visible = true;
				}else if(barcode_data_c1[0]!= null && barcode_data_c1[0].race <= 4){
					warrior_1p_label.visible = false;
					magician_1p_label.visible=false;
					miss_label.visible = true;
					//job
					//カード入力ミス
				}else{
					card_input_label.visible = false;
					miss_label.visible = true;
				}
			}
			break;
		
		//2枚目
		case 5:
			if(count == 1){
				//アイテムなら
				if(barcode_data_c1[1]!= null && barcode_data_c1[1].race > 4){
					card_input_label.visible = true;
					item_label.visible = true;
					miss_label.visible = false;
					//job
				}else if(barcode_data_c1[1].race <= 4){
					if(barcode_data_c1[1].job >=7){
						warrior_2p_label.visible = false;
						magician_2p_label.visible = true;						
					}else{
						warrior_2p_label.visible = true;
						magician_2p_label.visible = false;
					}
					miss_label.visible = false;
					//カード入力ミス
				}else{
					card_input_label.visible = true;
					miss_label.visible = false;
				}
				
			}else{
				if(barcode_data_c1[1]!= null && barcode_data_c1[1].race > 4){
					card_input_label.visible = true;
					item_label.visible = false;
					miss_label.visible = true;
				}else if(barcode_data_c1[1]!= null && barcode_data_c1[1].race <= 4){
					warrior_2p_label.visible=false;
					magician_2p_label.visible = false;
					miss_label.visible = true;
					//job
					//カード入力ミス
				}else{
					card_input_label.visible = false;
					miss_label.visible = true;
				}
			}
			break;
		//アイテム
		case 6:
			if(count == 1){
				//アイテムなら
				if(barcode_data_c1[6]!= null && barcode_data_c1[6].race > 4){
					card_input_label.visible = true;
					item_label.visible = true;
					miss_label.visible = false;
					//job
				}else if(barcode_data_c1[6].race <= 4){
					if(barcode_data_c1[6].job >=7){
						warrior_2p_label.visible = false;
						magician_2p_label.visible = true;						
					}else{
						warrior_2p_label.visible = true;
						magician_2p_label.visible = false;
					}
					miss_label.visible = false;
					//カード入力ミス
				}else{
					card_input_label.visible = true;
					miss_label.visible = false;
				}
				
			}else{
				if(barcode_data_c1[6]!= null && barcode_data_c1[6].race > 4){
					card_input_label.visible = true;
					item_label.visible = false;
					miss_label.visible = true;
				}else if(barcode_data_c1[6]!= null && barcode_data_c1[6].race <= 4){
					warrior_2p_label.visible=false;
					magician_2p_label.visible = false;
					miss_label.visible = true;
					//job
					//カード入力ミス
				}else{
					card_input_label.visible = false;
					miss_label.visible = true;
				}
			}
			break;
			
	}
}


//カード入力失敗
private function card_insert_error_back_c1(event:TimerEvent):void{
	
	if(card_insert_error_c1_timer){
		card_insert_error_c1_timer.removeEventListener(TimerEvent.TIMER,card_insert_error_animation_c1);
		card_insert_error_c1_timer.removeEventListener(TimerEvent.TIMER_COMPLETE,card_insert_error_back_c1);
		card_insert_error_c1_timer.stop();
		card_insert_error_c1_timer = null;
	}
	
	item_label.visible = false;
	card_input_label.visible = false;
	miss_label.visible = false;
	
	card_reader_visible = false;
	init_card_reader(new MouseEvent(MouseEvent.CLICK));
	card_in_button.addEventListener(MouseEvent.CLICK,card_insert_c1);
	select_image_button.addEventListener(MouseEvent.CLICK,select_image);
	get_camera_button.addEventListener(MouseEvent.CLICK,get_camera);
	card_in.enabled = true;
	card_in_button.enabled=true;
	init_card_reader_button.enabled = true;
	
	if(bb2_state < 6){
		card_insert_wait_c1();
	}else{
		set_friend_state_c1(new MouseEvent(MouseEvent.CLICK));
	}
}

public function c1_stage_select_click(event:Event):void{
	if(c1_passcode_error_animation_timer){
		c1_passcode_error_animation_timer.removeEventListener(TimerEvent.TIMER,c1_passcode_error_animation);
		c1_passcode_error_animation_timer.removeEventListener(TimerEvent.TIMER_COMPLETE,c1_stage_select_click);
		c1_passcode_error_animation_timer.stop();
		c1_passcode_error_animation_timer = null;
	}

	if(display_mp_pp_c1_timer){
		display_mp_pp_c1_timer.removeEventListener(TimerEvent.TIMER,display_mp_pp_c1);
		display_mp_pp_c1_timer.removeEventListener(TimerEvent.TIMER_COMPLETE,c1_stage_select_click);
		display_mp_pp_c1_timer.stop();
		display_mp_pp_c1_timer = null;
	}
	
	if(battle_get_animation_timer){
		battle_get_animation_timer.removeEventListener(TimerEvent.TIMER,battle_get_animation_c1);
		battle_get_animation_timer.stop();
		battle_get_animation_timer = null;
	}
	
	if(escape_from_battle_animation_timer){
		escape_from_battle_animation_timer.removeEventListener(TimerEvent.TIMER,escape_from_battle_animation);
		escape_from_battle_animation_timer.removeEventListener(TimerEvent.TIMER_COMPLETE,c1_stage_select_click);
		escape_from_battle_animation_timer.stop();
		escape_from_battle_animation_timer = null;
	}
	
	escape_label.visible=false;
	friend_select_state_c1=0;
	bb2_state = 6;
	
	r_power.removeEventListener(MouseEvent.CLICK,escape_from_battle);
	select_button.removeEventListener(MouseEvent.CLICK,add_friend_state_c1);
	set_button.removeEventListener(MouseEvent.CLICK,card_insert_wait_c1_back);
	select_button.removeEventListener(MouseEvent.CLICK,c1_stage_select_click);
	set_button.removeEventListener(MouseEvent.CLICK,c1_stage_select_click);
	c1_stage_select();
}


//C1のステージセレクト
public var select_stage_enemy_animation_timer:Timer;
public function c1_stage_select():void{
	se.critical_mp3.play();

	//ラベルリセット
	battle_label.visible=false;
	card_input_label.visible=false;
	escape_label.visible=false;
	power_label.visible=false;
	critical_label.visible=false;
	miss_label.visible=false;
	magician_1p_label.visible=false;
	warrior_1p_label.visible=false;
	key_label.visible=false;
	item_label.visible=false;
	infomation_label.visible=false;
	warrior_2p_label.visible=false;
	magician_2p_label.visible=false;
	hp_label.visible=false;
	damage_label.visible=false;
	st_label.visible=false;
	mp_label.visible=false;
	df_label.visible=false;
	pp_label.visible=false;
	
	//最初のステージをセット
	c1_world_data.set_start_world();
	
	//E1～E6
	hp_1p.text = c1_world_data.stage[c1_world_data.select_stage];
	st_1p.text = "";
	df_1p.text = "";
	
	//L1～LH
	hp_2p.text = c1_world_data.world[c1_world_data.select_world];
	st_2p.text = "";
	df_2p.text = "";
	
	//01～HH
	//c1_world_data.select_enemy+1;
	
	if(!select_stage_enemy_animation_timer){
		select_stage_enemy_animation_timer = new Timer(150);
		select_stage_enemy_animation_timer.addEventListener(TimerEvent.TIMER,stage_enemy_animation);
		select_stage_enemy_animation_timer.start();
	}
	
	//セーブ
	call_save_function = c1_stage_select_click;
	r_battle.addEventListener(MouseEvent.CLICK,save);
	
	c1_stage_select_flag = false;
	select_button.addEventListener(MouseEvent.CLICK,c1_stage_enemy_select);
	set_button.addEventListener(MouseEvent.CLICK,c1_stage_enemy_set);
	l_power.addEventListener(MouseEvent.CLICK,card_insert_retry_c1);
	l_battle.addEventListener(MouseEvent.CLICK,c1_input_passcode);
}


public function c1_stage_select_from_escape():void{
	
	//ラベルリセット
	battle_label.visible=false;
	card_input_label.visible=false;
	escape_label.visible=false;
	power_label.visible=false;
	critical_label.visible=false;
	miss_label.visible=false;
	magician_1p_label.visible=false;
	warrior_1p_label.visible=false;
	key_label.visible=false;
	item_label.visible=false;
	infomation_label.visible=false;
	warrior_2p_label.visible=false;
	magician_2p_label.visible=false;
	hp_label.visible=false;
	damage_label.visible=false;
	st_label.visible=false;
	mp_label.visible=false;
	df_label.visible=false;
	pp_label.visible=false;
	
	//E1～E6
	hp_1p.text = c1_world_data.stage[c1_world_data.select_stage];
	st_1p.text = "";
	df_1p.text = "";
	
	//L1～LH
	hp_2p.text = c1_world_data.world[c1_world_data.select_world];
	st_2p.text = "";
	df_2p.text = "";
	
	//01～HH
	//c1_world_data.select_enemy+1;
	
	if(!select_stage_enemy_animation_timer){
		select_stage_enemy_animation_timer = new Timer(150);
		select_stage_enemy_animation_timer.addEventListener(TimerEvent.TIMER,stage_enemy_animation);
		select_stage_enemy_animation_timer.start();
	}
	c1_stage_select_flag = false;
}


//ステージ・敵セレクトアニメーション
public function stage_enemy_animation(event:TimerEvent):void{
	var count:int = event.currentTarget.currentCount%2;	
	if(count == 1){
		//L-1～L-H
		hp_2p.text = c1_world_data.world[c1_world_data.select_world];
	}else{
		//l- ～L-
		hp_2p.text = String(c1_world_data.world[c1_world_data.select_world]).substr(0,2);
	}
}

//ステージ・敵セレクト
public var c1_stage_select_flag:Boolean=false;
public function c1_stage_enemy_select(event:MouseEvent):void{
	se.select_mp3.play();
	
	c1_world_data.select_world = c1_world_data.select_world + 1;
	if(c1_world_data.select_world >= c1_world_data.world.length){
		c1_world_data.select_world = 0;
	}
	
	while(!c1_world_data.is_world()){
		c1_world_data.select_world = c1_world_data.select_world + 1;
		if(c1_world_data.select_world >= c1_world_data.world.length){
			c1_world_data.select_world = 0;
		}
	}
}

public function c1_stage_select_set(event:Event):void{
	c1_stage_select_from_escape();
	c1_stage_enemy_set(new Event(Event.CHANGE));
}

//ステージ・敵セット
public function c1_stage_enemy_set(event:Event):void{
	se.decide_mp3.play();
	
	select_button.removeEventListener(MouseEvent.CLICK,c1_stage_enemy_select);
	set_button.removeEventListener(MouseEvent.CLICK,c1_stage_enemy_set);
	l_power.removeEventListener(MouseEvent.CLICK,card_insert_retry_c1);
	l_battle.removeEventListener(MouseEvent.CLICK,c1_input_passcode);
	r_battle.removeEventListener(MouseEvent.CLICK,save);
	
	if(escape_from_battle_animation_timer){
		escape_from_battle_animation_timer.removeEventListener(TimerEvent.TIMER,escape_from_battle_animation);
		escape_from_battle_animation_timer.removeEventListener(TimerEvent.TIMER_COMPLETE,c1_stage_enemy_set);
		escape_from_battle_animation_timer.stop();
		escape_from_battle_animation_timer = null;
	}
	
	if(!c1_stage_select_flag){
		c1_stage_select_flag = true;
		
		if(select_stage_enemy_animation_timer){
			select_stage_enemy_animation_timer.removeEventListener(TimerEvent.TIMER,stage_enemy_animation);
			select_stage_enemy_animation_timer.stop();
			select_stage_enemy_animation_timer = null;
		}
		c1_world_data.select_enemy = c1_world_data.select_enemy_number();
		call_enemy();
	}
}

//敵セレクト
public var call_enemy_animation_timer:Timer;
public function call_enemy():void{

	hp_2p.text = c1_world_data.world[c1_world_data.select_world];
	st_2p.text = " " + c1_world_data.enemy[c1_world_data.get_world_number()][c1_world_data.select_enemy];
	
	if(!call_enemy_animation_timer){
		call_enemy_animation_timer = new Timer(120,15);
		call_enemy_animation_timer.addEventListener(TimerEvent.TIMER,call_enemy_animation);
		call_enemy_animation_timer.addEventListener(TimerEvent.TIMER_COMPLETE,appear_enemy);
		call_enemy_animation_timer.start();
	}
}

//敵セレクトアニメーション
public function call_enemy_animation(event:TimerEvent):void{
	var count:int = event.currentTarget.currentCount%2;
	if(count == 1){
		st_2p.text = " " + c1_world_data.enemy[c1_world_data.get_world_number()][c1_world_data.select_enemy];
	}else{
		st_2p.text = "";
	}
}

//敵データ読み込み
public var appear_enemy_timer:Timer;
public var barcode_data_enemy:BarcodeData;
public function appear_enemy(event:TimerEvent):void{
	if(call_enemy_animation_timer){
		call_enemy_animation_timer.removeEventListener(TimerEvent.TIMER,call_enemy_animation);
		call_enemy_animation_timer.removeEventListener(TimerEvent.TIMER_COMPLETE,appear_enemy);
		call_enemy_animation_timer.stop();
		call_enemy_animation_timer = null;
	}
	
	barcode_data_enemy = c1_world_data.generate_enemy_paramater();
	se.card_in_mp3.play();
	
	hp_1p.text = "";
	st_1p.text = "";
	df_1p.text = "";
	if(!appear_enemy_timer){
		appear_enemy_timer = new Timer(80,20);
		appear_enemy_timer.addEventListener(TimerEvent.TIMER,appear_enemy_animation_c1);
		appear_enemy_timer.addEventListener(TimerEvent.TIMER_COMPLETE,select_friend_c1);
		appear_enemy_timer.start();
	}
	
}


public function appear_enemy_animation_c1(event:TimerEvent):void{
	var count:int = event.currentTarget.currentCount%2;
	if(count == 1){
		hp_2p.text = " ==";
		st_2p.text = " ==";
		df_2p.text = " ==";
	}else{
		hp_2p.text = "";
		st_2p.text = "";
		df_2p.text = "";
	}
	
}

public var select_friend_timer:Timer;
public function select_friend_c1(event:TimerEvent):void{
	r_power.removeEventListener(MouseEvent.CLICK,escape);
	
	if(appear_enemy_timer){
		appear_enemy_timer.removeEventListener(TimerEvent.TIMER,appear_enemy_animation_c1);
		appear_enemy_timer.removeEventListener(TimerEvent.TIMER_COMPLETE,select_friend_c1);
		appear_enemy_timer.stop();
		appear_enemy_timer = null;
	}
	
	hp_1p.text = " ==";
	st_1p.text = " ==";
	df_1p.text = " ==";
	hp_2p.text = barcode_data_enemy.hp;
	st_2p.text = barcode_data_enemy.st;
	df_2p.text = barcode_data_enemy.df;
	if(barcode_data_enemy.job > 6){
		warrior_2p_label.visible=false;
		magician_2p_label.visible=true;
	}else{
		warrior_2p_label.visible=true;
		magician_2p_label.visible=false;
	}
	
	if(!friend_select_animation_c1_timer){
		friend_select_animation_c1_timer = new Timer(300);
		friend_select_animation_c1_timer.addEventListener(TimerEvent.TIMER,friend_select_animation_c1);
		friend_select_animation_c1_timer.start();
	}
	
	r_power.addEventListener(MouseEvent.CLICK,escape_from_battle);
	select_button.addEventListener(MouseEvent.CLICK,add_friend_state_c1);
}

//敵から逃げる
public var escape_from_battle_animation_timer:Timer;
public var escape_from_battle_failed_animaton_timer:Timer;
public function escape_from_battle(event:MouseEvent):void{
	r_power.removeEventListener(MouseEvent.CLICK,escape_from_battle);
	escape_label.visible=true;
	
	if(friend_select_animation_c1_timer){
		friend_select_animation_c1_timer.removeEventListener(TimerEvent.TIMER,friend_select_animation_c1);
		friend_select_animation_c1_timer.stop();
		friend_select_animation_c1_timer = null;
	}
	
	var rand:int = Math.floor(Math.random() * 3);
	if(rand >= 1){
		if(!escape_from_battle_animation_timer){
			se.status_down_mp3.play();
			escape_from_battle_animation_timer = new Timer(150,15);
			escape_from_battle_animation_timer.addEventListener(TimerEvent.TIMER,escape_from_battle_animation);
			escape_from_battle_animation_timer.addEventListener(TimerEvent.TIMER_COMPLETE,c1_stage_select_click);
			escape_from_battle_animation_timer.start();
		}
	}else{
		if(!escape_from_battle_failed_animaton_timer){
			se.card_in_error_mp3.play();
			escape_from_battle_failed_animaton_timer = new Timer(100,8);
			escape_from_battle_failed_animaton_timer.addEventListener(TimerEvent.TIMER,escape_from_battle_failed_animaton);
			escape_from_battle_failed_animaton_timer.addEventListener(TimerEvent.TIMER_COMPLETE,escape_from_battle_failed_animaton_complete);
			escape_from_battle_failed_animaton_timer.start();
		}
	}
}

//敵から逃げるの失敗
public function escape_from_battle_failed_animaton(event:TimerEvent):void{
	var count:int = event.currentTarget.currentCount%2;
	if(count == 1){
		escape_label.visible=true;
		miss_label.visible=false;
	}else{
		escape_label.visible=false;
		miss_label.visible=true;
	}
}

//敵から逃げるの失敗終了
public function escape_from_battle_failed_animaton_complete(event:TimerEvent):void{
	escape_label.visible=false;
	miss_label.visible=false;
	
	if(escape_from_battle_failed_animaton_timer){
		escape_from_battle_failed_animaton_timer.removeEventListener(TimerEvent.TIMER,escape_from_battle_failed_animaton);
		escape_from_battle_failed_animaton_timer.removeEventListener(TimerEvent.TIMER,escape_from_battle_failed_animaton_complete);
		escape_from_battle_failed_animaton_timer.stop();
		escape_from_battle_failed_animaton_timer = null;
	}
	
	if(!friend_select_animation_c1_timer){
		friend_select_animation_c1_timer = new Timer(300);
		friend_select_animation_c1_timer.addEventListener(TimerEvent.TIMER,friend_select_animation_c1);
		friend_select_animation_c1_timer.start();
	}
}

//敵から逃げるアニメーション
public function escape_from_battle_animation(event:TimerEvent):void{
	warrior_1p_label.visible=false;
	magician_1p_label.visible=false;
	key_label.visible=false;
	var count:int = event.currentTarget.currentCount%2;
	
	if(count == 1){
		hp_1p.text=" ==";
		st_1p.text=" ==";
		df_1p.text=" ==";
	}else{
		hp_1p.text="";
		st_1p.text="";
		df_1p.text="";
	}
	
}


//味方(戦士/魔法使い)選択アニメーション
public var friend_select_animation_c1_timer:Timer;
public var friend_select_state_c1:int; //0未選択 1戦士 2魔法使い
public function friend_select_animation_c1(event:TimerEvent):void{
	var count:int = event.currentTarget.currentCount%2;	
	
	switch(friend_select_state_c1){
		case 0:
			if(count == 1){
				if(barcode_data_c1[4].live){
					warrior_1p_label.visible=true;
				}else{
					warrior_1p_label.visible=false;
				}
				
				if(barcode_data_c1[5].live){
					magician_1p_label.visible=true;
				}else{
					magician_1p_label.visible=false;
				}
			}else{
				warrior_1p_label.visible=false;
				magician_1p_label.visible=false;
			}		
			break;
		
		case 1:
			if(count == 1){
				warrior_1p_label.visible=true;
			}else{
				warrior_1p_label.visible=false;
			}
			magician_1p_label.visible=false;
			
			hp_1p.text=barcode_data_c1[4].hp;
			st_1p.text=barcode_data_c1[4].st;
			df_1p.text=barcode_data_c1[4].df;
			break;
		
		case 2:
			if(count == 1){
				magician_1p_label.visible=true;
			}else{
				magician_1p_label.visible=false;
			}
			warrior_1p_label.visible=false;
			
			hp_1p.text=barcode_data_c1[5].hp;
			st_1p.text=barcode_data_c1[5].st;
			df_1p.text=barcode_data_c1[5].df;
			break;
	}
}

public function add_friend_state_c1(event:MouseEvent):void{
	se.select_mp3.play();
	r_power.removeEventListener(MouseEvent.CLICK,escape_from_battle);
	switch(friend_select_state_c1){
		case 0:
			if(barcode_data_c1[4].live){
				friend_select_state_c1=1;
			}else{
				friend_select_state_c1=2;
			}
			break;
		
		case 1:
			if(barcode_data_c1[5].live){
				friend_select_state_c1=2;
			}else{
				friend_select_state_c1=1;
			}
			break;
		
		case 2:
			if(barcode_data_c1[4].live){
				friend_select_state_c1=1;
			}else{
				friend_select_state_c1=2;
			}
			break;
	}
	
	set_button.addEventListener(MouseEvent.CLICK,set_friend_state_c1);
}

public function set_friend_state_c1(event:MouseEvent):void{
	se.decide_mp3.play();
	r_power.removeEventListener(MouseEvent.CLICK,escape_from_battle);
	select_button.removeEventListener(MouseEvent.CLICK,add_friend_state_c1);
	set_button.removeEventListener(MouseEvent.CLICK,set_friend_state_c1);	
	
	if(friend_select_animation_c1_timer){
		friend_select_animation_c1_timer.removeEventListener(TimerEvent.TIMER,friend_select_animation_c1);
		friend_select_animation_c1_timer.stop();
		friend_select_animation_c1_timer = null;
	}
	
	if(!set_friend_item_c1_timer){
		set_friend_item_c1_timer = new Timer(200);
		set_friend_item_c1_timer.addEventListener(TimerEvent.TIMER,set_friend_item_animation_c1);
		set_friend_item_c1_timer.start();
	}
	
	bb2_state = 6;
	
	//カード入力
	card_in_button.addEventListener(MouseEvent.CLICK,card_item_insert_c1);
	select_image_button.addEventListener(MouseEvent.CLICK,select_image);
	get_camera_button.addEventListener(MouseEvent.CLICK,get_camera);
	
	//カードスキップ
	set_button.addEventListener(MouseEvent.CLICK,card_insert_next_set_c1);
	
	card_in.enabled = true;
	card_in_button.enabled=true;
	init_card_reader_button.enabled = true;
	
}

//カードスキップ
public function card_insert_next_set_c1(event:MouseEvent):void{
	se.decide_mp3.play();
	set_button.removeEventListener(MouseEvent.CLICK,card_insert_next_set_c1);
	card_in_button.removeEventListener(MouseEvent.CLICK,card_item_insert_c1);
	select_image_button.removeEventListener(MouseEvent.CLICK,select_image);
	get_camera_button.removeEventListener(MouseEvent.CLICK,get_camera);
	barcode_data_c1[6] = null;
	
	if(set_friend_item_c1_timer){
		set_friend_item_c1_timer.removeEventListener(TimerEvent.TIMER,set_friend_item_animation_c1);
		set_friend_item_c1_timer.stop();
		set_friend_item_c1_timer = null;
	}
	
	card_insert_next_c1(new MouseEvent(MouseEvent.CLICK));
}


public var set_friend_item_c1_timer:Timer;
public function set_friend_item_animation_c1(event:TimerEvent):void{
	var count:int = event.currentTarget.currentCount%2;
	
	switch(friend_select_state_c1){
		case 1:
			if(count == 1){
				item_label.visible=true;
				warrior_1p_label.visible=true;
				card_input_label.visible=true;
			}else{
				item_label.visible=false;
				warrior_1p_label.visible=false;
				card_input_label.visible=false;
			}
			magician_1p_label.visible=false;
			break;
		
		case 2:
			if(count == 1){
				item_label.visible=true;
				magician_1p_label.visible=true;
				card_input_label.visible=true;
			}else{
				item_label.visible=false;
				magician_1p_label.visible=false;
				card_input_label.visible=false;
			}
			warrior_1p_label.visible=false;
			break;
		
	}
	
}

public function card_item_insert_c1(event:MouseEvent):void{
	card_in_button.removeEventListener(MouseEvent.CLICK,card_item_insert_c1);
	set_button.removeEventListener(MouseEvent.CLICK,card_insert_next_set_c1);
	select_image_button.removeEventListener(MouseEvent.CLICK,select_image);
	get_camera_button.removeEventListener(MouseEvent.CLICK,get_camera);
	
	if(set_friend_item_c1_timer){
		set_friend_item_c1_timer.removeEventListener(TimerEvent.TIMER,set_friend_item_animation_c1);
		set_friend_item_c1_timer.stop();
		set_friend_item_c1_timer = null;
	}
	
	var barcode_reader:BarcodeRead = new BarcodeRead();
	var barcode:String = card_in.text;
	
	if(friend_select_state_c1 == 1){
		var bd:BarcodeData = barcode_data_c1[4];
	}else{
		bd = barcode_data_c1[5];
	}
	
	//アイテムのみ入力
	var ret:Boolean = barcode_reader.init(barcode,2,bd,0,false,null,true,true);
	//情報カードチェック
	if(barcode_reader.barcode_data.race == 9 && (barcode_reader.barcode_data.job == 5 || barcode_reader.barcode_data.job == 6)){
		if(c1_world_data.key_number() == 3){
			ret = false;
		}else{
			if(barcode_reader.barcode_data.job == 5){
				if(c1_world_data.infomation_flag_a){
					ret = false;
				}else{
					c1_world_data.infomation_flag_a = true;
				}
			}else{
				if(c1_world_data.infomation_flag_b){
					ret = false;
				}else{
					c1_world_data.infomation_flag_b = true;
				}
			}
		}
	}
	
	
	//入力成功
	if(ret){
		se.card_in_mp3.play();
		barcode_data_c1[6] = barcode_reader.barcode_data;
		if(barcode_data_c1[6].job <= 6){
			warrior_2p_label.visible = true;
			magician_2p_label.visible = false;
		}else{
			warrior_2p_label.visible = false;
			magician_2p_label.visible = true;
		}
		if(friend_select_state_c1 == 1){
			warrior_1p_label.visible=true;
		}else{
			magician_1p_label.visible=true;
		}
		hp_label.visible=true;
		st_label.visible=true;
		df_label.visible=true;
		
		card_input_label.visible = false;
		card_insert_c1_timer = new Timer(80,40);
		card_insert_c1_timer.addEventListener(TimerEvent.TIMER,card_insert_animation_c1);
		card_insert_c1_timer.addEventListener(TimerEvent.TIMER_COMPLETE,card_insert_next_c1);
		card_insert_c1_timer.start();
		
		//入力失敗
	}else{
		se.card_in_error_mp3.play();
		magician_1p_label.visible=false;
		warrior_1p_label.visible=false;
		hp_label.visible=true;
		st_label.visible=true;
		df_label.visible=true;
		barcode_data_c1[6] = barcode_reader.barcode_data;
		card_insert_error_c1_timer = new Timer(150,6);
		card_insert_error_c1_timer.addEventListener(TimerEvent.TIMER,card_insert_error_animation_c1);
		card_insert_error_c1_timer.addEventListener(TimerEvent.TIMER_COMPLETE,card_insert_error_back_c1);
		card_insert_error_c1_timer.start();
	}
}



//C1パスコード入力
public var c1_input_passcode_animation_timer:Timer;
public function c1_input_passcode(event:MouseEvent){
	select_button.removeEventListener(MouseEvent.CLICK,c1_stage_enemy_select);
	set_button.removeEventListener(MouseEvent.CLICK,c1_stage_enemy_set);
	l_power.removeEventListener(MouseEvent.CLICK,card_insert_retry_c1);
	l_battle.removeEventListener(MouseEvent.CLICK,c1_input_passcode);
	r_battle.removeEventListener(MouseEvent.CLICK,save);
	
	if(select_stage_enemy_animation_timer){
		select_stage_enemy_animation_timer.removeEventListener(TimerEvent.TIMER,stage_enemy_animation);
		select_stage_enemy_animation_timer.stop();
		select_stage_enemy_animation_timer = null;
	}
	
	//ラベルリセット
	battle_label.visible=false;
	card_input_label.visible=false;
	escape_label.visible=false;
	power_label.visible=false;
	critical_label.visible=false;
	miss_label.visible=false;
	magician_1p_label.visible=false;
	warrior_1p_label.visible=false;
	key_label.visible=false;
	item_label.visible=false;
	infomation_label.visible=false;
	warrior_2p_label.visible=false;
	magician_2p_label.visible=false;
	hp_label.visible=false;
	damage_label.visible=false;
	st_label.visible=false;
	mp_label.visible=false;
	df_label.visible=false;
	pp_label.visible=false;	
	
	hp_1p.text = " F-";
	st_1p.text = "";
	df_1p.text = "";
	hp_2p.text = "000"
	st_2p.text = ""
	df_2p.text = "";
	
	if(!c1_input_passcode_animation_timer){
		c1_input_passcode_animation_timer = new Timer(100);
		c1_input_passcode_animation_timer.addEventListener(TimerEvent.TIMER,c1_input_animation);
		c1_input_passcode_animation_timer.start();
	}
	c1_passcode_state = 0;
	c1_passcode = "000";
	select_button.addEventListener(MouseEvent.CLICK,c1_input_add_passcode);
	set_button.addEventListener(MouseEvent.CLICK,c1_input_set_passcode);
	
}

//C1パスコード入力アニメーション
public var c1_passcode_state:int = 0;
public var c1_passcode:String= "000";
public function c1_input_animation(event:TimerEvent):void{
	var count:int = event.currentTarget.currentCount%2;
	
	switch(c1_passcode_state){
		case 0:
			if(count == 1){
				hp_2p.text = c1_passcode;
			}else{
				hp_2p.text = " "+c1_passcode.charAt(1)+c1_passcode.charAt(2);
			}
		break;
		
		case 1:
			if(count == 1){
				hp_2p.text = c1_passcode;
			}else{
				hp_2p.text = c1_passcode.charAt(0)+" "+c1_passcode.charAt(2);
			}
		break;
		
		case 2:
			if(count == 1){
				hp_2p.text = c1_passcode;
			}else{
				hp_2p.text = c1_passcode.charAt(0)+c1_passcode.charAt(1)+" ";
			}
		break;
	}
}

//パスコード加算
public function c1_input_add_passcode(event:MouseEvent):void{
	
	se.select_mp3.play();
	var add_passcode:int;
	switch(c1_passcode_state){
		case 0:
			add_passcode = int(c1_passcode.charAt(0)) + 1;
			if(add_passcode >9){
				add_passcode = add_passcode -10;
			}
			c1_passcode = add_passcode.toString() + c1_passcode.charAt(1) + c1_passcode.charAt(2); 
			break;
		
		case 1:
			add_passcode = int(c1_passcode.charAt(1)) + 1;
			c1_passcode = c1_passcode.charAt(0)+add_passcode.toString() + c1_passcode.charAt(2);
			break;
		
		case 2:
			add_passcode = int(c1_passcode.charAt(2)) + 1;
			c1_passcode = c1_passcode.charAt(0) + c1_passcode.charAt(1)+add_passcode.toString();
			break;
	}
}

//パスコードセット
public function c1_input_set_passcode(event:MouseEvent):void{
	se.decide_mp3.play();
	c1_passcode_state = c1_passcode_state + 1;
	if(c1_passcode_state == 3){
		if(c1_input_passcode_animation_timer){
			c1_input_passcode_animation_timer.removeEventListener(TimerEvent.TIMER,c1_input_animation);
			c1_input_passcode_animation_timer.stop();
			c1_input_passcode_animation_timer = null;
		}
		select_button.removeEventListener(MouseEvent.CLICK,c1_input_add_passcode);
		set_button.removeEventListener(MouseEvent.CLICK,c1_input_set_passcode);
		execute_c1_passcode();
	}
}

//パスコードチェック
public var passcode_power_up_c1_timer:Timer;
public function execute_c1_passcode():void{
	hp_2p.text = c1_passcode;
	
	//E1のときだけ実行
	if(c1_world_data.select_stage ==0){	
		//パワーアップ
		if(c1_world_data.c1_powerup_passcode(c1_passcode)){
			
			//cloneしてコピー(配列は参照渡しになるので防止)
			barcode_data_c1[2] = createCloneInstance(barcode_data_c1[4]);
			barcode_data_c1[3] = createCloneInstance(barcode_data_c1[5]);
			barcode_data_c1[4] = c1_world_data.generate_passcode_barcode_data(createCloneInstance(barcode_data_c1[0]),c1_passcode);
			barcode_data_c1[5] = c1_world_data.generate_passcode_barcode_data(createCloneInstance(barcode_data_c1[1]),c1_passcode);
			
			hp_label.visible=true;
			st_label.visible=true;
			df_label.visible=true;
			se.card_in_mp3.play();
			
			if(!passcode_power_up_c1_timer){
				passcode_power_up_c1_timer = new Timer(60,70);
				passcode_power_up_c1_timer.addEventListener(TimerEvent.TIMER,passcode_power_up_animation_c1);
				passcode_power_up_c1_timer.addEventListener(TimerEvent.TIMER_COMPLETE,passcode_power_up_complete);
				passcode_power_up_c1_timer.start();
			}
			
			return;
			
		//ステージジャンプ(E5,E6)
		}else if(c1_world_data.jump_stage_passcode(c1_passcode)){
			
			//E5
			if(c1_passcode.charAt(0)+c1_passcode.charAt(1)=="31"){
				
				var c1_passcode_number:int = c1_world_data.get_passcode_number(3);
				c1_world_data.select_stage = 4; 
				c1_world_data.reset_world();
				c1_world_data.reset_key();
				var c2_passcode:C2PassCode = new C2PassCode();
				c2_passcode.init(barcode_data_c1[0],barcode_data_c1[1]);
				barcode_data_c1[4] = c2_passcode.generate_passcode_barcode_data(createCloneInstance(barcode_data_c1[0]),c1_passcode_number);
				barcode_data_c1[5] = c2_passcode.generate_passcode_barcode_data(createCloneInstance(barcode_data_c1[1]),c1_passcode_number);
				barcode_data_c1[2] = createCloneInstance(barcode_data_c1[4]);
				barcode_data_c1[3] = createCloneInstance(barcode_data_c1[5]);
				
				//次ワールド実行
				c1_stage_select_click(new Event(Event.CHANGE));
				
			//E6
			}else if(c1_passcode.charAt(0)+c1_passcode.charAt(1)=="38"){
				var c1_passcode_number:int = c1_world_data.get_passcode_number(4);
				c1_world_data.select_stage = 5; 
				c1_world_data.reset_world();
				c1_world_data.reset_key();
				var c2_passcode:C2PassCode = new C2PassCode();
				c2_passcode.init(barcode_data_c1[0],barcode_data_c1[1]);
				barcode_data_c1[4] = c2_passcode.generate_passcode_barcode_data(createCloneInstance(barcode_data_c1[0]),c1_passcode_number);
				barcode_data_c1[5] = c2_passcode.generate_passcode_barcode_data(createCloneInstance(barcode_data_c1[1]),c1_passcode_number);
				barcode_data_c1[2] = createCloneInstance(barcode_data_c1[4]);
				barcode_data_c1[3] = createCloneInstance(barcode_data_c1[5]);
				
				//次ワールド実行
				c1_stage_select_click(new Event(Event.CHANGE));
			}
			
			return;	
		}
	}
	
	//エラー
	hp_2p.text = c1_passcode;
	se.card_in_error_mp3.play();
	if(!c1_passcode_error_animation_timer){
		c1_passcode_error_animation_timer = new Timer(150,10);
		c1_passcode_error_animation_timer.addEventListener(TimerEvent.TIMER,c1_passcode_error_animation);
		c1_passcode_error_animation_timer.addEventListener(TimerEvent.TIMER_COMPLETE,c1_stage_select_click);
		c1_passcode_error_animation_timer.start();
	}
}


//パスコード入力成功アニメーション
private function passcode_power_up_animation_c1(event:TimerEvent):void{
	var current_count:int = event.currentTarget.currentCount;
	var count:int = event.currentTarget.currentCount%2;
	
	if(current_count <=30){
		if(count == 1){
			hp_1p.text = barcode_data_c1[2].hp;
			st_1p.text = barcode_data_c1[2].st;
			df_1p.text = barcode_data_c1[2].df;
			hp_2p.text = barcode_data_c1[3].hp;
			st_2p.text = barcode_data_c1[3].st;
			df_2p.text = barcode_data_c1[3].df;
			warrior_1p_label.visible = true;
			magician_2p_label.visible = true;
		}else{
			hp_1p.text = "";
			st_1p.text = "";
			df_1p.text = "";
			hp_2p.text = "";
			st_2p.text = "";
			df_2p.text = "";
			warrior_1p_label.visible = false;
			magician_2p_label.visible = false;
		}
	}else{
		hp_1p.text = barcode_data_c1[4].hp;
		st_1p.text = barcode_data_c1[4].st;
		df_1p.text = barcode_data_c1[4].df;
		hp_2p.text = barcode_data_c1[5].hp;
		st_2p.text = barcode_data_c1[5].st;
		df_2p.text = barcode_data_c1[5].df;
		warrior_1p_label.visible = true;
		magician_2p_label.visible = true;
	}
	
}

public function passcode_power_up_complete(event:TimerEvent):void{

	if(passcode_power_up_c1_timer){
		passcode_power_up_c1_timer.removeEventListener(TimerEvent.TIMER,passcode_power_up_animation_c1);
		passcode_power_up_c1_timer.removeEventListener(TimerEvent.TIMER_COMPLETE,passcode_power_up_complete);
		passcode_power_up_c1_timer.stop();
		passcode_power_up_c1_timer = null;
	}
	
	if(c1_passcode_error_animation_timer){
		c1_passcode_error_animation_timer.removeEventListener(TimerEvent.TIMER,c1_passcode_error_animation);
		c1_passcode_error_animation_timer.removeEventListener(TimerEvent.TIMER_COMPLETE,c1_stage_select_click);
		c1_passcode_error_animation_timer.stop();
		c1_passcode_error_animation_timer = null;
	}
	c1_stage_select();
}



//パスコード入力エラー
public var c1_passcode_error_animation_timer:Timer;
public function c1_passcode_error_animation(event:TimerEvent):void{
	var count:int = event.currentTarget.currentCount%2;
	if(count == 1){
		miss_label.visible=true;
	}else{
		miss_label.visible=false;
	}
}

//敵カード/アイテムカード入力アニメーション
public function card_insert_animation_c1(event:TimerEvent):void{
	
	var currentCount:int = event.currentTarget.currentCount;
	var count:int = event.currentTarget.currentCount%2;	
	
	switch(bb2_state){
		case 6:
			//点滅表示
			if(currentCount <= 20){
				//薬草アップ,MPアップ
				if(barcode_data_c1[6].race==9 && barcode_data_c1[6].job > 6){
					hp_label.visible = true;
					st_label.visible = false;
					df_label.visible = false;
					mp_label.visible = true;
					pp_label.visible = true;
					
					if(friend_select_state_c1 == 1){
						st_1p.mp_text = barcode_data_c1[4].mp;
						df_1p.pp_text = barcode_data_c1[4].pp;
					}else{
						st_1p.mp_text = barcode_data_c1[5].mp;
						df_1p.pp_text = barcode_data_c1[5].pp;
					}
				//情報カード
				}else if(barcode_data_c1[6].race==9 && (barcode_data_c1[6].job == 5 ||barcode_data_c1[6].job == 6 )){
					hp_1p.text = "";
					st_1p.text = "";
					df_1p.text = "";
					warrior_1p_label.visible=false;
					magician_1p_label.visible=false;
					
					hp_label.visible = false;
					st_label.visible = false;
					df_label.visible = false;
					mp_label.visible = false;
					pp_label.visible = false;
				}else{
					hp_label.visible = true;
					st_label.visible = true;
					df_label.visible = true;
					mp_label.visible = false;
					pp_label.visible = false;
				}
				
				if(barcode_data_c1[6].race <=4){
					if(barcode_data_c1[6].job > 6){
						warrior_2p_label.enabled = false;
						magician_2p_label.enabled = true;
					}else{
						warrior_2p_label.enabled = true;
						magician_2p_label.enabled = false;
					}
				}else{
					warrior_2p_label.visible=false;
					magician_2p_label.visible=false;
					item_label.visible=true;
				}
				
				if(count == 1){
					hp_2p.text = " ==";
					st_2p.text = " ==";
					df_2p.text = " ==";
				}else{
					hp_2p.text = "";
					st_2p.text = "";
					df_2p.text = "";
				}
				//入力パラメータ表示
			}else{
				//薬草アップ,MPアップ
				if(barcode_data_c1[6].race==9 && barcode_data_c1[6].job > 6){
					hp_2p.text = "";
					if(barcode_data_c1[6].mp  > 0){
						st_2p.mp_text = barcode_data_c1[6].mp;
					}else{
						st_2p.text = "";
					}
					if(barcode_data_c1[6].pp  > 0){
						df_2p.pp_text = barcode_data_c1[6].pp;
					}else{
						df_2p.text = "";
					}
				//情報カード
				}else if(barcode_data_c1[6].race==9 && (barcode_data_c1[6].job == 5 ||barcode_data_c1[6].job == 6 )){
					if(currentCount % 8 >= 4){
						infomation_label.visible=true;
						key_label.visible=true;
						hp_2p.text = "L-"+c1_world_data.infomation_key().substr(1,1);
						if(barcode_data_c1[6].job == 6){
							st_2p.text = " 0"+c1_world_data.infomation_key().substr(-1,1);
						}else{
							st_2p.text = "";
						}
						df_2p.text = "";
					}else{
						infomation_label.visible=false;
						key_label.visible=false;
					}
				}else{
					if(barcode_data_c1[6].hp > 0){
						hp_2p.text = barcode_data_c1[6].hp;
					}else{
						hp_2p.text = "";
					}
					if(barcode_data_c1[6].st > 0){
						st_2p.text = (barcode_data_c1[6].st>199)?199:barcode_data_c1[6].st;
					}else{
						st_2p.text = "";
					}
					if(barcode_data_c1[6].df > 0){
						df_2p.text = (barcode_data_c1[6].df>199)?199:barcode_data_c1[6].df;
					}else{
						df_2p.text = "";
					}
				}
			}
			break;
		
	}
	
}


//所持キーの数
var had_key_number:int;
//増加後キーの数
var has_key_number:int;
public var rebirth_animation_timer:Timer;
public var enemy_infomation_animation_timer:Timer;
public function battle_end_c1(event:Event):void{
	l_power.removeEventListener(MouseEvent.MOUSE_UP,battle_end_c1);
	l_power.removeEventListener(MouseEvent.MOUSE_OUT,battle_end_c1);
	
	if(battle_end_animation_timer){
		battle_end_animation_timer.removeEventListener(TimerEvent.TIMER,battle_end_animation);
		battle_end_animation_timer.removeEventListener(TimerEvent.TIMER_COMPLETE,battle_end_c1);
		battle_end_animation_timer.stop();
		battle_end_animation_timer =  null;
	}
	
	if(get_key_animation_timer){
		get_key_animation_timer.removeEventListener(TimerEvent.TIMER,get_key_animation);
		get_key_animation_timer.removeEventListener(TimerEvent.TIMER_COMPLETE,battle_end_c1);
		get_key_animation_timer.stop();
		get_key_animation_timer = null;
	}
	
	//敵を倒した場合
	if(barcode_data_enemy.hp <=0){
		
		//敵にキーがあれば先に取得処理を行う
		if(c1_world_data.is_key()){
			if(!get_key_animation_timer){
				//現時点のキーの数を取得
				had_key_number = c1_world_data.key_number();
				//敵のキーを削除
				c1_world_data.delete_key();
				//新しいキーの数を取得
				has_key_number = c1_world_data.key_number();
				
				//キーの数が初めて3個になったとき
				if(has_key_number == 3){
					//L-Hに進入可にする
					c1_world_data.world.push("L-H");
				}
				
				//ラベルリセット
				battle_label.visible=false;
				card_input_label.visible=false;
				escape_label.visible=false;
				power_label.visible=false;
				critical_label.visible=false;
				miss_label.visible=false;
				magician_1p_label.visible=false;
				warrior_1p_label.visible=false;
				key_label.visible=false;
				item_label.visible=false;
				infomation_label.visible=false;
				warrior_2p_label.visible=false;
				magician_2p_label.visible=false;
				hp_label.visible=false;
				damage_label.visible=false;
				st_label.visible=false;
				mp_label.visible=false;
				df_label.visible=false;
				pp_label.visible=false;	
				hp_1p.text = "";
				st_1p.text = "";
				df_1p.text = "";
				hp_2p.text = "";
				st_2p.text = "";
				df_2p.text = "";
				
				//鍵を表示
				key_label.visible = true;
				
				//キー取得アニメーション
				if(!get_key_animation_timer){
					se.status_down_mp3.play();
					get_key_animation_timer = new Timer(150,20);
					get_key_animation_timer.addEventListener(TimerEvent.TIMER,get_key_animation);
					get_key_animation_timer.addEventListener(TimerEvent.TIMER_COMPLETE,battle_end_c1);
					get_key_animation_timer.start();
				}
			}
		//敵のキーがなくなった場合
		}else{
			
			if(!battle_get_animation_timer){
				battle_get_animation_timer = new Timer(120);
				battle_get_animation_timer.addEventListener(TimerEvent.TIMER,battle_get_animation_c1);
				battle_get_animation_timer.start();
			}
			
			//LXH-HH ボス撃破
			if(c1_world_data.get_world_number() == 5 && c1_world_data.get_enemy_number() == 4 ){
				//ボス撃破処理へ
				if(battle_get_animation_timer){
					battle_get_animation_timer.removeEventListener(TimerEvent.TIMER,battle_get_animation_c1);
					battle_get_animation_timer.stop();
					battle_get_animation_timer= null;
				}
				
				defeat_boss(new MouseEvent(MouseEvent.CLICK));
			}else{
				call_save_function = battle_end_c1;
				r_battle.addEventListener(MouseEvent.CLICK,save);
				l_power.addEventListener(MouseEvent.CLICK,battle_end_l_power);
				select_magic_pp_use = false;
				select_button.addEventListener(MouseEvent.CLICK,select_end_state);
				set_button.addEventListener(MouseEvent.CLICK,get_mp_pp_c1);
			}
		}
		
	//やられた場合
	}else{
		
		//現時点のキーの数を取得
		had_key_number = c1_world_data.key_number();
		
		//敵に鍵がない場合でキーがある場合でボスやHワールド以外のは渡す
		if(!c1_world_data.is_key() && c1_world_data.get_world_number() != 5 　&& c1_world_data.get_enemy_number() !=4 && had_key_number > 0){
			//敵のキーを追加
			c1_world_data.add_key();
			//新しいキーの数を取得
			has_key_number = c1_world_data.key_number();
			
			//ラベルリセット
			battle_label.visible=false;
			card_input_label.visible=false;
			escape_label.visible=false;
			power_label.visible=false;
			critical_label.visible=false;
			miss_label.visible=false;
			magician_1p_label.visible=false;
			warrior_1p_label.visible=false;
			key_label.visible=false;
			item_label.visible=false;
			infomation_label.visible=false;
			warrior_2p_label.visible=false;
			magician_2p_label.visible=false;
			hp_label.visible=false;
			damage_label.visible=false;
			st_label.visible=false;
			mp_label.visible=false;
			df_label.visible=false;
			pp_label.visible=false;	
			hp_1p.text = "";
			st_1p.text = "";
			df_1p.text = "";
			hp_2p.text = "";
			st_2p.text = "";
			df_2p.text = "";

			//キー取得アニメーション
			if(!get_key_animation_timer){
				se.status_down_mp3.play();
				get_key_animation_timer = new Timer(150,20);
				get_key_animation_timer.addEventListener(TimerEvent.TIMER,get_key_animation);
				get_key_animation_timer.addEventListener(TimerEvent.TIMER_COMPLETE,battle_end_c1);
				get_key_animation_timer.start();
			}
			
		}else{
			hp_1p.text = "";
			st_1p.text = "";
			df_1p.text = "";
			hp_2p.text = barcode_data_enemy.hp;
			st_2p.text = barcode_data_enemy.st;
			df_2p.text = barcode_data_enemy.df;
			hp_label.visible=true;
			st_label.visible=true;
			df_label.visible=true;
			
			if(c1_world_data.key_number() == 0){
				key_label.visible=false;
			}else{
				key_label.visible=true;
			}
			
			if(barcode_data_enemy.job > 6){
				magician_2p_label.visible=true;
			}else{
				warrior_2p_label.visible=true;
			}
			
			select_button.addEventListener(MouseEvent.CLICK,c1_stage_select_click);
			set_button.addEventListener(MouseEvent.CLICK,card_insert_wait_c1_back);
		}
	}
}

//ボス撃破処理
public var defeat_boss_animation_timer:Timer
public function defeat_boss(event:MouseEvent):void{
	//ラベルリセット
	battle_label.visible=false;
	card_input_label.visible=false;
	escape_label.visible=false;
	power_label.visible=false;
	critical_label.visible=false;
	miss_label.visible=false;
	magician_1p_label.visible=false;
	warrior_1p_label.visible=false;
	key_label.visible=false;
	item_label.visible=false;
	infomation_label.visible=false;
	warrior_2p_label.visible=false;
	magician_2p_label.visible=false;
	hp_label.visible=false;
	damage_label.visible=false;
	st_label.visible=false;
	mp_label.visible=false;
	df_label.visible=false;
	pp_label.visible=false;	
	
	if(c1_world_data.select_stage <= 2){
		hp_1p.text = c1_world_data.stage[c1_world_data.select_stage];
	}else{
		hp_1p.text = "fin";
	}
	st_1p.text = " go";
	df_1p.text = "";
	hp_2p.text = "";
	st_2p.text = " od";
	df_2p.text = "";
	
	if(!defeat_boss_animation_timer){
		defeat_boss_animation_timer = new Timer(300);
		defeat_boss_animation_timer.addEventListener(TimerEvent.TIMER,defeat_boss_animation);
		defeat_boss_animation_timer.start();
	}
	
	if(c1_world_data.select_stage <= 2){
		set_button.addEventListener(MouseEvent.CLICK,defeat_boss_animation_complete);
	}
	
	l_power.addEventListener(MouseEvent.CLICK,show_passcode_c1);
	l_power.addEventListener(MouseEvent.MOUSE_UP,defeat_boss);
	l_power.addEventListener(MouseEvent.MOUSE_OUT,defeat_boss);
}

//パスコード表示(C1)
public function show_passcode_c1(event:MouseEvent):void{
	se.passcode_mp3.play();
	
	if(defeat_boss_animation_timer){
		defeat_boss_animation_timer.removeEventListener(TimerEvent.TIMER,defeat_boss_animation);
		defeat_boss_animation_timer.stop();
		defeat_boss_animation_timer = null;
	}
	
	set_button.removeEventListener(MouseEvent.CLICK,defeat_boss_animation_complete);
	l_power.removeEventListener(MouseEvent.CLICK,show_passcode_c1);
	
	var c1_passcode_number:int = c1_world_data.get_passcode_number();
	var c2_passcode:C2PassCode = new C2PassCode();
	c2_passcode.init(barcode_data_c1[0],barcode_data_c1[1]);
	var c1_passcode:String = c2_passcode.generate_passcode_from_passcode_number(c1_passcode_number);
	
	//パスコード表示
	hp_1p.text = "p"+c1_passcode.charAt(0)+c1_passcode.charAt(1);
	hp_2p.text = c1_passcode.charAt(2)+c1_passcode.charAt(3)+c1_passcode.charAt(4);
	st_1p.text = "";
	st_2p.text = "";
	df_1p.text = "";
	df_2p.text = "";
	warrior_1p_label.visible=false;
	warrior_2p_label.visible=false;
	magician_1p_label.visible=false;
	magician_2p_label.visible=false;
	
	hp_label.visible=false;
	st_label.visible=false;
	df_label.visible=false;
	mp_label.visible=false;
	pp_label.visible=false;
}

//ボス撃破アニメーション
public function defeat_boss_animation(event:TimerEvent):void{
	var count:int = event.currentTarget.currentCount%2;	
	if(count == 1){
		if(c1_world_data.select_stage <= 2){
			hp_1p.text = c1_world_data.stage[c1_world_data.select_stage];
		}else{
			hp_1p.text = "fin";
		}
		st_1p.text = " go";
		df_1p.text = "";
		hp_2p.text = "";
		st_2p.text = " od";
		df_2p.text = "";
	}else{
		if(c1_world_data.select_stage <= 2){
			hp_1p.text = c1_world_data.stage[c1_world_data.select_stage];
		}else{
			hp_1p.text = "fin";
		}
		st_1p.text = "";
		df_1p.text = "";
		hp_2p.text = "";
		st_2p.text = "";
		df_2p.text = "";
	}
		
}

//ボス撃破後処理
public function defeat_boss_animation_complete(event:MouseEvent):void{
	
	set_button.removeEventListener(MouseEvent.CLICK,defeat_boss_animation_complete);
	l_power.removeEventListener(MouseEvent.CLICK,show_passcode_c1);
	l_power.removeEventListener(MouseEvent.MOUSE_UP,defeat_boss);
	l_power.removeEventListener(MouseEvent.MOUSE_OUT,defeat_boss);
	if(defeat_boss_animation_timer){
		defeat_boss_animation_timer.removeEventListener(TimerEvent.TIMER,defeat_boss_animation);
		defeat_boss_animation_timer.stop();
		defeat_boss_animation_timer = null;
	}
	
	//E1-E3
	if(c1_world_data.select_stage <= 2){
		
		var c1_passcode_number:int = c1_world_data.get_passcode_number();
		c1_world_data.select_stage = c1_world_data.select_stage + 1; 
		c1_world_data.reset_world();
		c1_world_data.reset_key();
		var c2_passcode:C2PassCode = new C2PassCode();
		c2_passcode.init(barcode_data_c1[0],barcode_data_c1[1]);
		barcode_data_c1[4] = c2_passcode.generate_passcode_barcode_data(createCloneInstance(barcode_data_c1[0]),c1_passcode_number);
		barcode_data_c1[5] = c2_passcode.generate_passcode_barcode_data(createCloneInstance(barcode_data_c1[1]),c1_passcode_number);
		barcode_data_c1[2] = createCloneInstance(barcode_data_c1[4]);
		barcode_data_c1[3] = createCloneInstance(barcode_data_c1[5]);
		
		//次ワールド実行
		c1_stage_select_click(new Event(Event.CHANGE));
	}
}




public var call_save_function:Function;
public var save_animation_timer:Timer;
public function save(event:MouseEvent):void{
	r_battle.removeEventListener(MouseEvent.CLICK,save);
	se.card_in_mp3.play();
	
	if(battle_get_animation_timer){
		battle_get_animation_timer.removeEventListener(TimerEvent.TIMER,battle_get_animation_c1);
		battle_get_animation_timer.stop();
		battle_get_animation_timer = null;
	}
	l_power.removeEventListener(MouseEvent.CLICK,battle_end_l_power);
	select_button.removeEventListener(MouseEvent.CLICK,select_end_state);
	set_button.removeEventListener(MouseEvent.CLICK,get_mp_pp_c1);
	
	if(select_stage_enemy_animation_timer){
		select_stage_enemy_animation_timer.removeEventListener(TimerEvent.TIMER,stage_enemy_animation);
		select_stage_enemy_animation_timer.stop();
		select_stage_enemy_animation_timer = null;
	}
	
	c1_stage_select_flag = false;
	select_button.removeEventListener(MouseEvent.CLICK,c1_stage_enemy_select);
	set_button.removeEventListener(MouseEvent.CLICK,c1_stage_enemy_set);
	l_power.removeEventListener(MouseEvent.CLICK,card_insert_retry_c1);
	l_battle.removeEventListener(MouseEvent.CLICK,c1_input_passcode);
	
	warrior_1p_label.visible=false;
	warrior_2p_label.visible=false;
	magician_1p_label.visible=false;
	magician_2p_label.visible=false;
	card_input_label.visible=false;
	hp_label.visible=false;
	st_label.visible=false;
	mp_label.visible=false;
	df_label.visible=false;
	pp_label.visible=false;
	
	if(!save_animation_timer){
		save_animation_timer = new Timer(200);
		save_animation_timer.addEventListener(TimerEvent.TIMER,save_animation);
		save_animation_timer.start();
	}
	
}

//Saveアニメーション
public function save_animation(event:TimerEvent):void{
	var currentCount:int = event.currentTarget.currentCount;
	var count:int = event.currentTarget.currentCount%2;	
	
	hp_1p.text = " sa";
	hp_2p.text = " ve";
	
	if(currentCount <= 10){
		if(count == 1){
			st_1p.text = " oo";
			st_2p.text = " oo";
			df_1p.text = " qq";
			df_2p.text = " qq";
		}else{
			st_1p.text = " qq";
			st_2p.text = " qq";
			df_1p.text = " oo";
			df_2p.text = " oo";
		}
	}
	
	if(currentCount == 10){
		se.decide_mp3.play();
		set_button.addEventListener(MouseEvent.CLICK,save_animation_complete);
		st_1p.text = "";
		st_2p.text = "";
		df_1p.text = "";
		df_2p.text = "";
	}
	
	if(currentCount >= 10){
		if(currentCount % 4 >= 2){
			df_1p.text = "  e";
			df_2p.text = " nd";
		}else{
			df_1p.text = "";
			df_2p.text = "";
		}
	}
	
}

//セーブ処理実行
public function save_animation_complete(event:MouseEvent):void{
	set_button.removeEventListener(MouseEvent.CLICK,save_animation_complete);
	if(save_animation_timer){
		save_animation_timer.removeEventListener(TimerEvent.TIMER,save_animation);
		save_animation_timer.stop();
		save_animation_timer = null;
	}
	
	registerClassAlias("C1WorldData", C1WorldData); 
	registerClassAlias("BarcodeData",BarcodeData);	
	var bb2_simulator:SharedObject = SharedObject.getLocal("bb2_simulator");
	bb2_simulator.data.c1_world_data =   c1_world_data;
	bb2_simulator.data.barcode_data_c1 = barcode_data_c1; 
	
	//元の関数に戻る
	call_save_function(new Event(Event.CHANGE));
}

public var load_animation_timer:Timer;
public function load(event:MouseEvent):void{
	r_battle.removeEventListener(MouseEvent.CLICK,load);
	se.card_in_mp3.play();
	
	if(card_insert_wait_c1_timer){
		card_insert_wait_c1_timer.removeEventListener(TimerEvent.TIMER,card_insert_wait_animation_c1);
		card_insert_wait_c1_timer.stop();
		card_insert_wait_c1_timer = null;
	}
	card_in_button.removeEventListener(MouseEvent.CLICK,card_insert_c1);
	select_image_button.removeEventListener(MouseEvent.CLICK,select_image);
	get_camera_button.removeEventListener(MouseEvent.CLICK,get_camera);
	
	warrior_1p_label.visible=false;
	warrior_2p_label.visible=false;
	magician_1p_label.visible=false;
	magician_2p_label.visible=false;
	card_input_label.visible=false;
	hp_label.visible=false;
	st_label.visible=false;
	mp_label.visible=false;
	df_label.visible=false;
	pp_label.visible=false;
	
	if(!load_animation_timer){
		load_animation_timer = new Timer(200);
		load_animation_timer.addEventListener(TimerEvent.TIMER,load_animation);
		load_animation_timer.start();
	}
	
}

//ロードアニメーション
public function load_animation(event:TimerEvent):void{
	var currentCount:int = event.currentTarget.currentCount;
	var count:int = event.currentTarget.currentCount%2;	
	
	hp_1p.text = " lo";
	hp_2p.text = " ad";
	
	if(currentCount <= 10){
		if(count == 1){
			st_1p.text = " oo";
			st_2p.text = " oo";
			df_1p.text = " qq";
			df_2p.text = " qq";
		}else{
			st_1p.text = " qq";
			st_2p.text = " qq";
			df_1p.text = " oo";
			df_2p.text = " oo";
		}
	}
	
	if(currentCount == 10){
		se.decide_mp3.play();
		set_button.addEventListener(MouseEvent.CLICK,load_animation_complete);
		st_1p.text = "";
		st_2p.text = "";
		df_1p.text = "";
		df_2p.text = "";
	}
	
	if(currentCount >= 10){
		if(currentCount % 4 >= 2){
			df_1p.text = "  e";
			df_2p.text = " nd";
		}else{
			df_1p.text = "";
			df_2p.text = "";
		}
	}
}

//ロード処理実行
public var load_status_animation_timer:Timer;
public function load_animation_complete(event:MouseEvent):void{
	set_button.removeEventListener(MouseEvent.CLICK,load_animation_complete);
	
	if(load_animation_timer){
		load_animation_timer.removeEventListener(TimerEvent.TIMER,load_animation);
		load_animation_timer.stop();
		load_animation_timer = null;
	}
	
	registerClassAlias("C1WorldData", C1WorldData); 
	registerClassAlias("BarcodeData",BarcodeData);	
	
	//ロード
	var bb2_simulator:SharedObject = SharedObject.getLocal("bb2_simulator");
	c1_world_data = null;
	c1_world_data = bb2_simulator.data.c1_world_data as C1WorldData;
	barcode_data_c1 = null;
	barcode_data_c1 = bb2_simulator.data.barcode_data_c1 as Array;
	
	//カード2枚入力中
	bb2_state = 5;
	
	se.card_in_mp3.play();
	//ステータス表示アニメーションへ
	if(!load_status_animation_timer){
		load_status_animation_timer = new Timer(80,20);
		load_status_animation_timer.addEventListener(TimerEvent.TIMER,load_status_animation);
		load_status_animation_timer.addEventListener(TimerEvent.TIMER_COMPLETE,card_insert_next_c1);
		load_status_animation_timer.start();
	}
}

public function load_status_animation(event:TimerEvent):void{
	var currentCount:int = event.currentTarget.currentCount;
	var count:int = event.currentTarget.currentCount%2;
	
	hp_label.visible=true;
	st_label.visible=true;
	mp_label.visible=false;
	df_label.visible=true;
	pp_label.visible=false;
	warrior_1p_label.visible=true;
	magician_2p_label.visible=true;
	
	if(count == 1){
		hp_1p.text = " ==";
		st_1p.text = " ==";
		df_1p.text = " ==";
		hp_2p.text = " ==";
		st_2p.text = " ==";
		df_2p.text = " ==";
	}else{
		hp_1p.text = "";
		st_1p.text = "";
		df_1p.text = "";
		hp_2p.text = "";
		st_2p.text = "";
		df_2p.text = "";
	}
	
}


public function battle_end_l_power(event:MouseEvent):void{
	l_power.removeEventListener(MouseEvent.CLICK,battle_end_l_power);
	select_button.removeEventListener(MouseEvent.CLICK,select_end_state);
	set_button.removeEventListener(MouseEvent.CLICK,get_mp_pp_c1);
	r_battle.removeEventListener(MouseEvent.CLICK,save);
	
	if(battle_get_animation_timer){
		battle_get_animation_timer.removeEventListener(TimerEvent.TIMER,battle_get_animation_c1);
		battle_get_animation_timer.stop();
		battle_get_animation_timer = null;
	}

	
	
	//ボス以外で1/2の確率
	switch(c1_world_data.get_enemy_number()){
		//魔法使い(復活)
		case 0:
		case 2:
			if(Math.floor(Math.random() * 2) == 1){
				if(!rebirth_animation_timer && (!barcode_data_c1[4].live || !barcode_data_c1[5].live)){
					rebirth_animation_timer = new Timer(150,20);
					rebirth_animation_timer.addEventListener(TimerEvent.TIMER,rebirth_animation);
					rebirth_animation_timer.addEventListener(TimerEvent.TIMER_COMPLETE,rebirth_end);
					rebirth_animation_timer.start();
				}else{
					rebirth_end(new TimerEvent(TimerEvent.TIMER_COMPLETE));
				}
			}else{
				battle_end_c1(new Event(Event.CHANGE));
				l_power.removeEventListener(MouseEvent.CLICK,battle_end_l_power);
			}
		break;
		
		//L-2戦士(情報カード1)
		case 1:
			if(Math.floor(Math.random() * 2) == 1){
				if(!enemy_infomation_animation_timer && c1_world_data.key_number() != 3 ){
					enemy_infomation_animation_timer = new Timer(80,70);
					enemy_infomation_animation_timer.addEventListener(TimerEvent.TIMER,enemy_infomaiton);
					enemy_infomation_animation_timer.addEventListener(TimerEvent.TIMER_COMPLETE,enemy_infomation_end);
					enemy_infomation_animation_timer.start();
				}
			}else{
				battle_end_c1(new Event(Event.CHANGE));
				l_power.removeEventListener(MouseEvent.CLICK,battle_end_l_power);
			}
		break;
		
		//L-4戦士(情報カード2)
		case 3:
			if(Math.floor(Math.random() * 2) == 1){
				if(!enemy_infomation_animation_timer && c1_world_data.key_number() != 3){
					enemy_infomation_animation_timer = new Timer(80,70);
					enemy_infomation_animation_timer.addEventListener(TimerEvent.TIMER,enemy_infomaiton);
					enemy_infomation_animation_timer.addEventListener(TimerEvent.TIMER_COMPLETE,enemy_infomation_end);
					enemy_infomation_animation_timer.start();
				}
			}else{
				battle_end_c1(new Event(Event.CHANGE));
				l_power.removeEventListener(MouseEvent.CLICK,battle_end_l_power);
			}
		break;
		
		default:
			battle_end_c1(new Event(Event.CHANGE));
			l_power.removeEventListener(MouseEvent.CLICK,battle_end_l_power);
	}
}

public function rebirth_animation(event:TimerEvent):void{
	var currentCount:int = event.currentTarget.currentCount;
	var count:int = event.currentTarget.currentCount%2;	
	
	hp_label.visible=true;
	st_label.visible=true;
	mp_label.visible=false;
	df_label.visible=true;
	pp_label.visible=false;
	warrior_1p_label.visible=false;
	magician_1p_label.visible=false;
	
	if(currentCount <= 10){
		if(friend_select_state_c1 == 1){
			//魔法使い復活アニメーション
			if(count == 1){
				hp_1p.text = "";
				st_1p.text = "";
				df_1p.text = "";
				hp_2p.text = " ==";
				st_2p.text = " ==";
				df_2p.text = " ==";
				warrior_2p_label.visible=false;
				magician_2p_label.visible=true;
			}else{
				hp_2p.text = "";
				st_2p.text = "";
				df_2p.text = "";
			}
		}else{
			//戦士復活アニメーション
			if(count  ==1){
				hp_2p.text = " ";
				st_2p.text = " ";
				df_2p.text = " ";
			}else{
				hp_2p.text = "";
				st_2p.text = "";
				df_2p.text = "";
			}
		}
	}else{
		if(friend_select_state_c1 == 1){
			//魔法使い復活
			hp_2p.text = barcode_data_c1[3].hp;
			st_2p.text = barcode_data_c1[3].st;
			df_2p.text = barcode_data_c1[3].df;
		}else{
			//戦士復活
			hp_2p.text = barcode_data_c1[2].hp;
			st_2p.text = barcode_data_c1[2].st;
			df_2p.text = barcode_data_c1[2].df;
		}
	}
}

public function rebirth_end(event:TimerEvent):void{
	if(rebirth_animation_timer){
		rebirth_animation_timer.removeEventListener(TimerEvent.TIMER,rebirth_animation);
		rebirth_animation_timer.removeEventListener(TimerEvent.TIMER_COMPLETE,rebirth_end);
		rebirth_animation_timer.stop();
		rebirth_animation_timer = null;
	}
	
	if(friend_select_state_c1 == 1){
		//魔法使い復活
		barcode_data_c1[5] = createCloneInstance(barcode_data_c1[3]);
	}else{
		//戦士復活
		barcode_data_c1[4] = createCloneInstance(barcode_data_c1[2]);
	}
	
	if(!battle_get_animation_timer){
		battle_get_animation_timer = new Timer(120);
		battle_get_animation_timer.addEventListener(TimerEvent.TIMER,battle_get_animation_c1);
		battle_get_animation_timer.start();
	}
	
	select_button.addEventListener(MouseEvent.CLICK,select_end_state);
	set_button.addEventListener(MouseEvent.CLICK,get_mp_pp_c1);
}


public function enemy_infomaiton(event:TimerEvent):void{
	var currentCount:int = event.currentTarget.currentCount;
	var count:int = event.currentTarget.currentCount%2;	
	
	hp_label.visible=false;
	st_label.visible=false;
	mp_label.visible=false;
	df_label.visible=false;
	pp_label.visible=false;
	warrior_1p_label.visible=false;
	magician_1p_label.visible=false;
	warrior_2p_label.visible=false;
	magician_2p_label.visible=false;
	
	if(currentCount <= 20){
		//情報
		if(count == 1){
			hp_1p.text = "";
			st_1p.text = "";
			df_1p.text = "";
			hp_2p.text = " ==";
			st_2p.text = " ==";
			df_2p.text = " ==";
		}else{
			hp_2p.text = "";
			st_2p.text = "";
			df_2p.text = "";
		}
	}else{
		hp_2p.text = "L-"+c1_world_data.infomation_key().substr(1,1);
		if(c1_world_data.get_enemy_number() == 3){
			st_2p.text = " 0"+c1_world_data.infomation_key().substr(-1,1);
		}else{
			st_2p.text = "";
		}
		df_2p.text = "";
		
		if(currentCount % 8 >= 4){
			infomation_label.visible=true;
			key_label.visible=true;
		}else{
			infomation_label.visible=false;
			key_label.visible=false;
		}
	}
	
}

public function enemy_infomation_end(event:TimerEvent):void{
	if(enemy_infomation_animation_timer){
		enemy_infomation_animation_timer.removeEventListener(TimerEvent.TIMER,enemy_infomaiton);
		enemy_infomation_animation_timer.removeEventListener(TimerEvent.TIMER_COMPLETE,rebirth_end);
		enemy_infomation_animation_timer.stop();
	}
	
	if(!battle_get_animation_timer){
		battle_get_animation_timer = new Timer(120);
		battle_get_animation_timer.addEventListener(TimerEvent.TIMER,battle_get_animation_c1);
		battle_get_animation_timer.start();
	}
	
	
	select_button.addEventListener(MouseEvent.CLICK,select_end_state);
	set_button.addEventListener(MouseEvent.CLICK,get_mp_pp_c1);
}


public var get_key_animation_timer:Timer;
private function get_key_animation(event:TimerEvent):void{
	var count:int = event.currentTarget.currentCount%2;
	var currentCount:int = event.currentTarget.currentCount;
	
	hp_1p.text = "";
	st_1p.text = "";
	df_1p.text = "";
	hp_label.visible=false;
	st_label.visible=false;
	mp_label.visible=false;
	df_label.visible=false;
	pp_label.visible=false;
	key_label.visible=true;
	
	if(currentCount <= 10){
		if(count == 1){
			hp_1p.pp_text = had_key_number + "  ";
		}else{
			hp_1p.text = "";
		}
	}else{
		hp_1p.pp_text = has_key_number + "  ";
		
	}
}


private function card_insert_wait_c1_back(event:MouseEvent):void{
	select_button.removeEventListener(MouseEvent.CLICK,c1_stage_select_click);
	set_button.removeEventListener(MouseEvent.CLICK,card_insert_wait_c1_back);
	
	if(friend_select_state_c1==1){
		friend_select_state_c1=2;
	}else{
		friend_select_state_c1=1;
	}
	bb2_state = 7;
	
	se.card_in_mp3.play();
	
	if(battle_get_animation_timer){
		battle_get_animation_timer.removeEventListener(TimerEvent.TIMER,battle_get_animation_c1);
		battle_get_animation_timer.stop();
		battle_get_animation_timer = null;
	}
	
	if(!friend_select_animation_c1_timer){
		friend_select_animation_c1_timer = new Timer(80,20);
		friend_select_animation_c1_timer.addEventListener(TimerEvent.TIMER,friend_animation_c1);
		friend_select_animation_c1_timer.addEventListener(TimerEvent.TIMER_COMPLETE,friend_animation_c1_complete);
		friend_select_animation_c1_timer.start();
	}
}

public function battle_get_animation_c1(event:TimerEvent):void{
	if(c1_world_data.key_number() > 0){
		key_label.visible=true;
	}else{
		key_label.visible=false;
	}
	infomation_label.visible=false;
	
	var count:int = event.currentTarget.currentCount%2;
	
	var bd:BarcodeData;
	if(friend_select_state_c1 == 1){
		bd = barcode_data_c1[4];
	}else{
		bd = barcode_data_c1[5];
	}
	
	hp_1p.text = bd.hp;
	hp_label.visible=true;
	
	if(count == 1){
		//ボス
		if(c1_world_data.generate_boss_energy() != -1){
			hp_2p.text = c1_world_data.generate_boss_energy();
			st_2p.text = c1_world_data.generate_st_df();
			st_1p.text = bd.st;
			st_label.visible=true;
			mp_label.visible=false;
			df_2p.text = c1_world_data.generate_st_df();
			df_1p.text = bd.df;
			df_label.visible=true;
			pp_label.visible=false;
		}else{
			if(barcode_data_enemy.job <= 6){
				//ST＋PP
				hp_2p.text = "";
				st_2p.text = c1_world_data.generate_st_df();
				st_1p.text = bd.st;
				st_label.visible=true;
				mp_label.visible=false;
				df_2p.pp_text = 5;
				df_1p.pp_text = bd.pp;
				df_label.visible=false;
				pp_label.visible=true;
				
			}else{
				//MP+DF
				if(bd.job > 6){
					hp_2p.text = "";
					st_2p.mp_text = 5;
					st_1p.mp_text = bd.mp;
					st_label.visible=false;
					mp_label.visible=true;
					df_2p.text = c1_world_data.generate_st_df();
					df_1p.text = bd.df;
					df_label.visible=true;
					pp_label.visible=false;
				//DF
				}else{
					hp_2p.text = "";
					st_2p.text = "";
					st_1p.text = bd.st;
					st_label.visible=true;
					mp_label.visible=false;
					df_2p.text = c1_world_data.generate_st_df();
					df_1p.text = bd.df;
					df_label.visible=true;
					pp_label.visible=false;
				}
			}
		}
	}else{
		hp_2p.text = "";
		st_2p.text = "";
		df_2p.text = "";
	}
}


public function friend_animation_c1(event:TimerEvent):void{
	
	var currentCount:int = event.currentTarget.currentCount;
	var count:int = event.currentTarget.currentCount%2;	
	
	if(friend_select_state_c1 == 1){
		warrior_1p_label.visible=true;
		magician_1p_label.visible=false;
	}else{
		warrior_1p_label.visible=false;
		magician_1p_label.visible=true;
	}
	
	if(currentCount < 20){
		if(count == 1){
			hp_1p.text = " ==";
			st_1p.text = " ==";
			df_1p.text = " ==";
		}else{
			hp_1p.text = "";
			st_1p.text = "";
			df_1p.text = "";
		}		
	}else{
		if(friend_select_state_c1 == 1){
			hp_1p.text = barcode_data_c1[4].hp;
			st_1p.text = barcode_data_c1[4].st;
			df_1p.text = barcode_data_c1[4].df; 
		}else{
			hp_1p.text = barcode_data_c1[5].hp;
			st_1p.text = barcode_data_c1[5].st;
			df_1p.text = barcode_data_c1[5].df;
		}
	}	
	
}

public function friend_animation_c1_complete(event:TimerEvent):void{
	select_button.removeEventListener(MouseEvent.CLICK,add_friend_state_c1);
	set_button.removeEventListener(MouseEvent.CLICK,set_friend_state_c1);	
	
	if(friend_select_animation_c1_timer){
		friend_select_animation_c1_timer.removeEventListener(TimerEvent.TIMER,friend_select_animation_c1);
		friend_select_animation_c1_timer.removeEventListener(TimerEvent.TIMER_COMPLETE,friend_animation_c1_complete);
		friend_select_animation_c1_timer.stop();
		friend_select_animation_c1_timer = null;
	}
	
	set_friend_item_c1_timer = new Timer(200);
	set_friend_item_c1_timer.addEventListener(TimerEvent.TIMER,set_friend_item_animation_c1);
	set_friend_item_c1_timer.start();
	
	bb2_state = 6;
	
	//カード入力
	card_in_button.addEventListener(MouseEvent.CLICK,card_item_insert_c1);
	select_image_button.addEventListener(MouseEvent.CLICK,select_image);
	get_camera_button.addEventListener(MouseEvent.CLICK,get_camera);
	
	//カードスキップ
	set_button.addEventListener(MouseEvent.CLICK,card_insert_next_set_c1);
	
	card_in.enabled = true;
	card_in_button.enabled=true;
	init_card_reader_button.enabled = true;
}

public var display_mp_pp_c1_timer:Timer; 
public function get_mp_pp_c1(event:MouseEvent):void{
	se.decide_mp3.play();
	
	l_power.removeEventListener(MouseEvent.CLICK,battle_end_l_power);
	select_button.removeEventListener(MouseEvent.CLICK,select_end_state);
	set_button.removeEventListener(MouseEvent.CLICK,get_mp_pp_c1);
	r_battle.removeEventListener(MouseEvent.CLICK,save);
	
	if(battle_get_animation_timer){
		battle_get_animation_timer.removeEventListener(TimerEvent.TIMER,battle_get_animation_c1);
		battle_get_animation_timer.stop();
		battle_get_animation_timer = null;
	}

	
	//ボス
	if(c1_world_data.generate_boss_energy() != -1){
		if(friend_select_state_c1 == 1){
			barcode_data_c1[4].hp = barcode_data_c1[4].hp + c1_world_data.generate_boss_energy();
			barcode_data_c1[4].st = barcode_data_c1[4].st + c1_world_data.generate_st_df(); 
			barcode_data_c1[4].df = barcode_data_c1[4].df + c1_world_data.generate_st_df();	
		}else{
			barcode_data_c1[5].hp = barcode_data_c1[5].hp + c1_world_data.generate_boss_energy();
			barcode_data_c1[5].st = barcode_data_c1[5].st + c1_world_data.generate_st_df(); 
			barcode_data_c1[5].df = barcode_data_c1[5].df + c1_world_data.generate_st_df();
		}
	}else{
		if(barcode_data_enemy.job <= 6){
			//ST＋PP
			if(friend_select_state_c1 == 1){
				barcode_data_c1[4].st = barcode_data_c1[4].st + c1_world_data.generate_st_df();
				barcode_data_c1[4].pp = barcode_data_c1[4].pp + 5;
			}else{
				barcode_data_c1[5].st = barcode_data_c1[5].st + c1_world_data.generate_st_df();
				barcode_data_c1[5].pp = barcode_data_c1[5].pp + 5;
			}
		}else{
			//MP+DF
			if(friend_select_state_c1 == 1){
				barcode_data_c1[4].df = barcode_data_c1[4].df + c1_world_data.generate_st_df();
			}else{
				barcode_data_c1[5].mp = barcode_data_c1[5].mp + 5;
				barcode_data_c1[5].df = barcode_data_c1[5].df + c1_world_data.generate_st_df();
			}
		}
	}		
	
	
	if(barcode_data_c1[4].hp > 999){
		barcode_data_c1[4].hp = 999;
	}
	if(barcode_data_c1[4].st > 199){
		barcode_data_c1[4].st = 199;
	}
	if(barcode_data_c1[4].df > 199){
		barcode_data_c1[4].df = 199;
	}
	if(barcode_data_c1[4].pp > 99){
		barcode_data_c1[4].pp = 99;
	}
	if(barcode_data_c1[5].hp > 999){
		barcode_data_c1[5].hp = 999;
	}
	if(barcode_data_c1[5].st > 199){
		barcode_data_c1[5].st = 199;
	}
	if(barcode_data_c1[5].df > 199){
		barcode_data_c1[5].df = 199;
	}
	if(barcode_data_c1[5].mp > 99){
		barcode_data_c1[5].mp = 99;
	}
	if(barcode_data_c1[5].pp > 99){
		barcode_data_c1[5].pp = 99;
	}

	
	if(!display_mp_pp_c1_timer){
		display_mp_pp_c1_timer = new Timer(100,20);
		display_mp_pp_c1_timer.addEventListener(TimerEvent.TIMER,display_mp_pp_c1);
		display_mp_pp_c1_timer.addEventListener(TimerEvent.TIMER_COMPLETE,display_mp_pp_c1_complete);
		display_mp_pp_c1_timer.start();
	}
}


public function display_mp_pp_c1_complete(event:TimerEvent):void{
	//取得完了のときに敵削除処理を行う
	c1_world_data.delete_enemy();
	c1_stage_select_click(new MouseEvent(MouseEvent.CLICK));
}

public function display_mp_pp_c1(event:TimerEvent):void{
	
	var bd:BarcodeData;
	if(friend_select_state_c1 == 1){
		bd = barcode_data_c1[4];
	}else{
		bd = barcode_data_c1[5];
	}
	
	if(c1_world_data.generate_boss_energy() != -1){
		hp_1p.text = bd.hp;
		mp_label.visible=false;
		st_label.visible=true;
		st_1p.text = bd.st;
		pp_label.visible=false;
		df_label.visible=true;
		df_1p.text = bd.df;
	}else{
		if(barcode_data_enemy.job > 6){
			if(bd.job > 6){
				hp_1p.text = bd.hp;
				mp_label.visible=true;
				st_label.visible=false;
				st_1p.mp_text = bd.mp;
				pp_label.visible=false;
				df_label.visible=true;
				df_1p.text = bd.df;
			}else{
				hp_1p.text = bd.hp;
				mp_label.visible=false;
				st_label.visible=true;
				st_1p.text = bd.st;
				pp_label.visible=false;
				df_label.visible=true;
				df_1p.text = bd.df;
			}
		}else{
			hp_1p.text = bd.hp;
			mp_label.visible=false;
			st_label.visible=true;
			st_1p.text = bd.st;
			pp_label.visible=true;
			df_label.visible=false;
			df_1p.pp_text = bd.pp;
		}	
	}

	hp_2p.text = "";
	st_2p.text = "";
	df_2p.text = "";
}

public static function createCloneInstance(pobjInstance:*):*
{	
	if(pobjInstance == null){
		return null;
	}
	
	var className:String = getQualifiedClassName(pobjInstance);
	var clazz:Class = getDefinitionByName(className) as Class;
	
	var o:Object = ObjectUtil.getClassInfo(pobjInstance);
	var ins:* = new ClassFactory(clazz).newInstance();
	
	for each (var q:QName in o.properties)
	{
		try
		{
			if (ins.hasOwnProperty(q.localName))
			{
				ins[q.localName] = pobjInstance[q.localName];
			}
		}
		catch (e:Error)
		{
			//privateのものはｾｯﾄできないためとりあえずtry catchで除外
		}
	}
	return ins;
}
