#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#define IsValidClient(%1)		(1 <= %1 <= MaxClients && IsClientInGame(%1))
#define QT		"\x03玩家\x04%N\x03抽到了\x01%s \x05→ \x02%s"
#define PIE	"\x04你抽中了\x01%s \x05→ \x02%s"
#define PH		"\x03玩家\x04%N\x03抽到了\x01%s \x05→ \x02%s"

#define DD		"buttons/button14.wav"

new Handle:hTimerAchieved[MAXPLAYERS+1];
new Handle:hTimerMiniFireworks[MAXPLAYERS+1];
new Handle:hTimerLoopEffect[MAXPLAYERS+1];
new bool:rolled[MAXPLAYERS+1];
new bool:sift[MAXPLAYERS+1];
new count[MAXPLAYERS+1];
new L[MAXPLAYERS+1];
new gain[MAXPLAYERS+1];
new prize1[MAXPLAYERS+1];
new prize2[MAXPLAYERS+1];
new prize3[MAXPLAYERS+1];
new prize4[MAXPLAYERS+1];
new prize5[MAXPLAYERS+1];
new prize6[MAXPLAYERS+1];
new Handle:StopTime[MAXPLAYERS+1]					= {	INVALID_HANDLE, ...};

new Handle:kills;
new Handle:infected_count;
new Handle:tank_count;
new Handle:LDW_MSG_time;

new Handle:timer_handle=INVALID_HANDLE;

public OnPluginStart()
{
	RegConsoleCmd("sm_ldw",LDW2);
	HookEvent("infected_death",		infected_death);
	HookEvent("player_death",		player_death);
	HookEvent("round_start", round_start);
	HookEvent("round_end",				Event_RoundEnd);
	HookEvent("finale_win", Event_RoundEnd);
	HookEvent("mission_lost", Event_RoundEnd);
	HookEvent("map_transition", Event_RoundEnd);
	
	kills = CreateConVar("common_kills", "50", "擊殺多少小僵屍可獲得一次抽獎機會", FCVAR_PLUGIN);
	infected_count = CreateConVar("infected_kill_counts", "1", "擊殺一個特感可獲得多少次抽獎機會", FCVAR_PLUGIN);
	tank_count = CreateConVar("tank_iskill_count", "2", "tank死亡時所有倖存者可獲得多少次抽獎機會", FCVAR_PLUGIN);
	LDW_MSG_time = CreateConVar("ldw_msg_time", "60.0", "抽獎系統公告多少時間(秒)播放一次", FCVAR_PLUGIN);
	AutoExecConfig(true, "L4D2_Lucky_Draw");
}

public OnMapStart()
{
	for(new i=1; i<=MaxClients; i++)
	{
		rolled[i]=false;
		sift[i]=true;
	}
	PrecacheSound("ui/littlereward.wav", true);
	PrecacheSound("level/gnomeftw.wav", true);
	PrecacheSound("npc/moustachio/strengthattract05.wav", true);
	PrecacheSound(DD, true);
}

public OnClientDisconnect(Client)
{
	if(!IsFakeClient(Client))
	{
		L[Client]=0;
		if (StopTime[Client] != INVALID_HANDLE) {
			KillTimer(StopTime[Client]);
			StopTime[Client] = INVALID_HANDLE;
		}
		PrintToServer("清除玩家%N的抽獎次數", Client);
	}
}

public Action:round_start(Handle:event, const String:name[], bool:dontBroadcast)
{
	 
	if(timer_handle != INVALID_HANDLE )
				{
					KillTimer(timer_handle);
					timer_handle=INVALID_HANDLE;
				}
	if(timer_handle == INVALID_HANDLE)
				{
					timer_handle=CreateTimer(GetConVarFloat(LDW_MSG_time), Msg, 0, TIMER_REPEAT);
				}
}

public Action:infected_death(Handle:event, String:event_name[], bool:dontBroadcast)
{
	new id = GetClientOfUserId(GetEventInt(event, "attacker"));
	
	if(IsValidClient(id))
	{
		if(GetClientTeam(id) == 2 && !IsFakeClient(id))
		{
			if(count[id]<GetConVarInt(kills))
			{
				count[id]+=1;
			} else 
			{
				count[id]=0;
				L[id]+=1;
				PrintHintText(id, "抽獎機會+1");
			}
		}
	}
}

public Action:player_death(Handle:event, String:event_name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "attacker"));
	new vic = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if(IsValidClient(client) && IsValidClient(vic))
	{
		if(IsClientInGame(vic) && IsClientInGame(client) && !IsFakeClient(client) && !(IsCommonInfected(vic) || IsWitch(vic)))
		{
			if(GetClientTeam(client) == 2 && GetClientTeam(vic) == 3)
			{
				if(GetEntProp(vic, Prop_Send, "m_zombieClass") != 8)
				{
					L[client]+=GetConVarInt(infected_count);
					PrintHintText(client, "抽獎機會+%d", GetConVarInt(infected_count));
				}
			}
		}
		
		if(!(IsCommonInfected(vic) || IsWitch(vic)))
		{
			if(GetClientTeam(vic) == 3 && GetEntProp(vic, Prop_Send, "m_zombieClass") == 8 && IsClientInGame(vic))
			{
				for (new i = 1; i <= MaxClients; i++)
				{
					if(IsClientInGame(i))
					{
						if(GetClientTeam(i) == 2)
						{
							L[i]+=GetConVarInt(tank_count);
							PrintHintText(i, "抽獎機會+%d", GetConVarInt(tank_count));
						}
					}
				}
			}
		}
	
		if(GetClientTeam(vic) == 2 && rolled[vic])
		{
			KillTimer(StopTime[vic]);
			rolled[vic]=false;
			sift[vic]=true;
			PrintToChat(vic, "\x04由於角色死亡,抽獎強制終止!");
			PrintCenterText(vic, "抽獎終止!");
		}
	}
}

public Action:Event_RoundEnd(Handle:event, String:event_name[], bool:dontBroadcast)
{
	for (new i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i))
		{
			KillTimer(StopTime[i]);
		}
	}
	
	if(timer_handle != INVALID_HANDLE )
				{
					KillTimer(timer_handle);
					timer_handle=INVALID_HANDLE;
				}
				
	for(new i=1; i<=MaxClients; i++)
	{
		if(IsClientInGame(i))
		{
			rolled[i]=false;
			sift[i]=true;
		}
	}
}

public Action:LDW2(Client, args)
{
	
	// when input !ld
	if(GetClientTeam(Client)==2)
	{
		//draw function
		if(!rolled[Client])
		{
			if(L[Client] > 0)
				{
						//must
					if(sift[Client])
					{
						sift_start1(Client);
						sift_start2(Client);
						sift_start3(Client);
						sift_start4(Client);
						sift_start5(Client);
						sift_start6(Client);
						sift[Client]=false;
					}
					//Award_List
					//Award_List(Client);
					//Start
						
					rolled[Client]=true;
					//return to draw function
					rolled[Client]=false;
					sift[Client]=true;

					// Award(Client);
					
					// for (new i = 1; i <= MaxClients; i++)
					// {
					// 	if(IsClientInGame(i))
					// 	{
					// 		if(GetClientTeam(i) == 2)
					// 		{
					// 			new MaxHP = GetEntProp(i, Prop_Data, "m_iMaxHealth");
					// 			SetEntProp(i, Prop_Data, "m_iHealth", MaxHP);
					// 		}
					// 	}
					// }

					// PrintToChatAll(PH,Client);

					// Format(hd, sizeof(hd), "所有倖存者加滿HP");
					Roll2(Client); //rolling
					decl String:ms[32];
					decl String:hd[32];
					if(gain[Client]==1)
					{
						if(prize1[Client]==1)
						{
							for (new i = 1; i <= MaxClients; i++)
							{
								if(IsClientInGame(i))
								{
									if(GetClientTeam(i) == 2)
									{
										new MaxHP = GetEntProp(i, Prop_Data, "m_iMaxHealth");
										SetEntProp(i, Prop_Data, "m_iHealth", MaxHP);
									}
								}
							}
							Format(hd, sizeof(hd), "所有倖存者加滿HP");
						} else if(prize1[Client]==2)
						{
							CheatCommand(Client, "ent_remove_all", "infected");
							Format(hd, sizeof(hd), "清除所有小僵屍");
						} else if(prize1[Client]==3)
						{
							SetEntProp(Client, Prop_Data, "m_takedamage", 0, 1);
							Format(hd, sizeof(hd), "他自己進入無敵狀態");
						} else if(prize1[Client]==4)
						{
							SetEntityGravity(Client, 0.1);
							Format(hd, sizeof(hd), "他自己的重力降到最低");
						} else if(prize1[Client]==5)
						{
							for (new i = 1; i <= MaxClients; i++)
							{
								if(IsClientInGame(i))
								{
									if(GetClientTeam(i) == 3)
									{
										ForcePlayerSuicide(i);
									}
								}
							}
							Format(hd, sizeof(hd), "處死所有特感");
						}
						Format(ms, sizeof(ms), "特等獎");
						PrintToChatAll(QT, Client, ms, hd);
						//PrintToChatAll(QT, Client);
						EmitSoundToClient(Client, "level/gnomeftw.wav");
						AttachParticle(Client, "achieved", 3.0);
					}
					if(gain[Client] == 2)
					{
						if(prize2[Client]==1)
						{
							CheatCommand(Client, "give", "rifle");
							Format(hd, sizeof(hd), "獲得M16");
						} else if(prize2[Client]==2)
						{
							CheatCommand(Client, "give", "rifle_ak47");
							Format(hd, sizeof(hd), "獲得AK47");
						} else if(prize2[Client]==3)
						{
							CheatCommand(Client, "give", "sniper_military");
							Format(hd, sizeof(hd), "獲得大型連狙");
						} else if(prize2[Client]==4)
						{
							CheatCommand(Client, "give", "hunting_rifle");
							Format(hd, sizeof(hd), "獲得小型連狙");
						} else if(prize2[Client]==5)
						{
							CheatCommand(Client, "give", "autoshotgun");
							Format(hd, sizeof(hd), "獲得自動散彈槍");
						} else if(prize2[Client]==6)
						{
							CheatCommand(Client, "give", "shotgun_spas");
							Format(hd, sizeof(hd), "獲得spas戰鬥散彈槍");
						} else if(prize2[Client]==7)
						{
							CheatCommand(Client, "give", "shotgun_chrome");
							Format(hd, sizeof(hd), "獲得鉻合金散彈槍");
						} else if(prize2[Client]==8)
						{
							CheatCommand(Client, "give", "pumpshotgun");
							Format(hd, sizeof(hd), "獲得泵動式散彈槍");
						} else if(prize2[Client]==9)
						{
							CheatCommand(Client, "give", " rifle_desert");
							Format(hd, sizeof(hd), "獲得突擊步槍");
						} else if(prize2[Client]==10)
						{
							CheatCommand(Client, "give", "grenade_launcher");
							Format(hd, sizeof(hd), "獲得榴彈槍");
						} else if(prize2[Client]==11)
						{
							CheatCommand(Client, "give", "smg");
							Format(hd, sizeof(hd), "獲得烏茲小衝鋒");
						} else if(prize2[Client]==12)
						{
							CheatCommand(Client, "give", "smg_silenced");
							Format(hd, sizeof(hd), "獲得消音小衝鋒");
						}
						Format(ms, sizeof(ms), "一等獎");
						PrintToChat(Client, PIE, ms, hd);
						EmitSoundToClient(Client, "level/gnomeftw.wav");
						AttachParticle(Client, "achieved", 3.0);
					}
					
					if(gain[Client]==3)
					{
						if(prize3[Client]==1)
						{
							CheatCommand(Client, "give", "first_aid_kit");
							Format(hd, sizeof(hd), "獲得醫藥包");
						} else if(prize3[Client]==2)
						{
							CheatCommand(Client, "give", "pain_pills");
							Format(hd, sizeof(hd), "獲得止痛藥");
						} else if(prize3[Client]==3)
						{
							CheatCommand(Client, "give", "adrenaline");
							Format(hd, sizeof(hd), "獲得腎上腺素");
						} else if(prize3[Client]==4)
						{
							CheatCommand(Client, "give", "defibrillator");
							Format(hd, sizeof(hd), "獲得電擊器");
						}
						Format(ms, sizeof(ms), "二等獎");
						PrintToChat(Client, PIE, ms, hd);
						EmitSoundToClient(Client, "level/gnomeftw.wav");
						AttachParticle(Client, "achieved", 3.0);
					}
					
					if(gain[Client]==4)
					{
						if(prize4[Client]==1)
						{
							CheatCommand(Client, "give", "pistol_magnum");
							Format(hd, sizeof(hd), "獲得馬格南手槍");
						} else if(prize4[Client]==2)
						{
							CheatCommand(Client, "give", "baseball_bat");
							Format(hd, sizeof(hd), "獲得棒球棒");
						} else if(prize4[Client]==3)
						{
							CheatCommand(Client, "give", "pipe_bomb");
							Format(hd, sizeof(hd), "獲得土制炸彈");
						} else if(prize4[Client]==4)
						{
							CheatCommand(Client, "give", "molotov");
							Format(hd, sizeof(hd), "獲得燃燒瓶");
						} else if(prize4[Client]==5)
						{
							CheatCommand(Client, "give", "vomitjar");
							Format(hd, sizeof(hd), "獲得膽汁炸彈");
						} else if(prize4[Client]==6)
						{
							CheatCommand(Client, "give", "rifle_m60");
							Format(hd, sizeof(hd), "獲得M60");
						}
						Format(ms, sizeof(ms), "三等獎");
						PrintToChat(Client, PIE, ms, hd);
						EmitSoundToClient(Client, "level/gnomeftw.wav");
						AttachParticle(Client, "achieved", 3.0);
					}
					
					if(gain[Client]==5)
					{
						if(prize5[Client]==1)
						{
							CheatCommand(Client, "give", "upgradepack_incendiary");
							Format(hd, sizeof(hd), "獲得燃燒彈盒");
						} else if(prize5[Client]==2)
						{
							CheatCommand(Client, "give", "upgradepack_explosive");
							Format(hd, sizeof(hd), "獲得高爆彈盒");
						} else if(prize5[Client]==3)
						{
							CheatCommand(Client, "give", "propanetank");
							Format(hd, sizeof(hd), "獲得煤氣罐");
						} else if(prize5[Client]==4)
						{
							CheatCommand(Client, "give", "gascan");
							Format(hd, sizeof(hd), "獲得汽油桶");
						} else if(prize5[Client]==5)
						{
							CheatCommand(Client, "give", "oxygentank");
							Format(hd, sizeof(hd), "獲得氧氣罐");
						}
						Format(ms, sizeof(ms), "安慰獎");
						PrintToChat(Client, PIE, ms, hd);
						EmitSoundToClient(Client, "level/gnomeftw.wav");
						AttachParticle(Client, "achieved", 3.0);
					}
					
					if(gain[Client]==6)
					{
						if(prize6[Client]==1)
						{
							CheatCommand(Client, "z_spawn", "witch");
							CheatCommand(Client, "z_spawn", "witch");
							Format(hd, sizeof(hd), "召喚兩隻Witch");
						} else if(prize6[Client]==2)
						{
							CheatCommand(Client, "z_spawn", "tank");
							Format(hd, sizeof(hd), "召喚一隻Tank");
						} else if(prize6[Client]==3)
						{
							//ForcePlayerSuicide(Client);
							//CheatCommand(Client, "fire");
							// ServerCommand("sm_burn \"%N\" \"%d\"", Client, 10);
							CheatCommand(Client, "z_spawn", "jockey");
							CheatCommand(Client, "z_spawn", "boomer");
							CheatCommand(Client, "z_spawn", "hunter");
							CheatCommand(Client, "z_spawn", "spitter");
							CheatCommand(Client, "z_spawn", "smoker");
							CheatCommand(Client, "z_spawn", "charger");
							CheatCommand(Client, "z_spawn", "tank");
							CheatCommand(Client, "z_spawn", "witch");
							CheatCommand(Client, "z_spawn", "mob");
							Format(hd, sizeof(hd), "九蓮寶燈!!!");
						} else if(prize6[Client]==4)
						{
							CheatCommand(Client, "z_spawn", "boomer");
							CheatCommand(Client, "z_spawn", "boomer");
							CheatCommand(Client, "z_spawn", "boomer");
							
							CheatCommand(Client, "z_spawn", "mob");
							CheatCommand(Client, "z_spawn", "mob");
							Format(hd, sizeof(hd), "召喚屍潮!");
						} else if(prize6[Client]==5)
						{
							//CheatCommand(Client, "warp_to_start_area");
							ServerCommand("sm_freeze \"%N\" \"%d\"", Client, 10);
							Format(hd, sizeof(hd), "冰凍十秒鐘");
							//Format(hd, sizeof(hd), "從頭再來，傳送至起點！");
						}
						Format(ms, sizeof(ms), "懲罰");
						PrintToChatAll(PH, Client, ms, hd);
						EmitSoundToClient(Client, "npc/moustachio/strengthattract05.wav");
					}

					L[Client]-=1;
				} 
					else
					{
						PrintToChat(Client, "\x04Sorry,你沒有抽獎機會!");
					}
		}
		else
		{
			//Stop
			rolled[Client]=false;
			sift[Client]=true;
			//Award(Client);
		}
	} else
	{
		PrintToChat(Client, "此功能只有倖存者可以使用!");
	}

	

}

public Action:Roll2(Client)
{
	decl String:show[32];
	new extract = GetRandomInt(1, 100);
	switch (extract)
	{
		case 1:
		{
			Format(show, sizeof(show), "特等獎");
			gain[Client]=1;
		}
		case 2:
		{
			Format(show, sizeof(show), "一等獎");
			gain[Client]=2;
		}
		case 3:
		{
			Format(show, sizeof(show), "一等獎");
			gain[Client]=2;
		}
		case 4:
		{
			Format(show, sizeof(show), "二等獎");
			gain[Client]=3;
		}
		case 5:
		{
			Format(show, sizeof(show), "二等獎");
			gain[Client]=3;
		}
		case 6:
		{
			Format(show, sizeof(show), "二等獎");
			gain[Client]=4;
		}
		case 7:
		{
			Format(show, sizeof(show), "三等獎");
			gain[Client]=4;
		}
		case 8:
		{
			Format(show, sizeof(show), "三等獎");
			gain[Client]=4;
		}
		case 9:
		{
			Format(show, sizeof(show), "三等獎");
			gain[Client]=4;
		}
		case 10:
		{
			Format(show, sizeof(show), "三等獎");
			gain[Client]=4;
		}
		case 11:
		{
			Format(show, sizeof(show), "三等獎");
			gain[Client]=4;
		}
		case 12:
		{
			Format(show, sizeof(show), "安慰獎");
			gain[Client]=5;
		}
		case 13:
		{
			Format(show, sizeof(show), "安慰獎");
			gain[Client]=5;
		}
		case 14:
		{
			Format(show, sizeof(show), "安慰獎");
			gain[Client]=5;
		}
		case 15:
		{
			Format(show, sizeof(show), "安慰獎");
			gain[Client]=5;
		}
		case 16:
		{
			Format(show, sizeof(show), "安慰獎");
			gain[Client]=5;
		}
		case 17:
		{
			Format(show, sizeof(show), "安慰獎");
			gain[Client]=5;
		}
		case 18:
		{
			Format(show, sizeof(show), "安慰獎");
			gain[Client]=5;
		}
		case 19:
		{
			Format(show, sizeof(show), "安慰獎");
			gain[Client]=5;
		}
		case 20:
		{
			Format(show, sizeof(show), "懲罰");
			gain[Client]=6;
		}
		case 21:
		{
			Format(show, sizeof(show), "特等獎");
			gain[Client]=1;
		}
		case 22:
		{
			Format(show, sizeof(show), "一等獎");
			gain[Client]=2;
		}
		case 23:
		{
			Format(show, sizeof(show), "一等獎");
			gain[Client]=2;
		}
		case 24:
		{
			Format(show, sizeof(show), "二等獎");
			gain[Client]=3;
		}
		case 25:
		{
			Format(show, sizeof(show), "二等獎");
			gain[Client]=3;
		}
		case 26:
		{
			Format(show, sizeof(show), "二等獎");
			gain[Client]=3;
		}
		case 27:
		{
			Format(show, sizeof(show), "三等獎");
			gain[Client]=4;
		}
		case 28:
		{
			Format(show, sizeof(show), "三等獎");
			gain[Client]=4;
		}
		case 29:
		{
			Format(show, sizeof(show), "三等獎");
			gain[Client]=4;
		}
		case 30:
		{
			Format(show, sizeof(show), "三等獎");
			gain[Client]=4;
		}
		case 31:
		{
			Format(show, sizeof(show), "三等獎");
			gain[Client]=4;
		}
		case 32:
		{
			Format(show, sizeof(show), "安慰獎");
			gain[Client]=5;
		}
		case 33:
		{
			Format(show, sizeof(show), "安慰獎");
			gain[Client]=5;
		}
		case 34:
		{
			Format(show, sizeof(show), "安慰獎");
			gain[Client]=5;
		}
		case 35:
		{
			Format(show, sizeof(show), "安慰獎");
			gain[Client]=5;
		}
		case 36:
		{
			Format(show, sizeof(show), "安慰獎");
			gain[Client]=5;
		}
		case 37:
		{
			Format(show, sizeof(show), "安慰獎");
			gain[Client]=5;
		}
		case 38:
		{
			Format(show, sizeof(show), "安慰獎");
			gain[Client]=5;
		}
		case 39:
		{
			Format(show, sizeof(show), "安慰獎");
			gain[Client]=5;
		}
		case 40:
		{
			Format(show, sizeof(show), "懲罰");
			gain[Client]=6;
		}
		case 41:
		{
			Format(show, sizeof(show), "特等獎");
			gain[Client]=1;
		}
		case 42:
		{
			Format(show, sizeof(show), "一等獎");
			gain[Client]=2;
		}
		case 43:
		{
			Format(show, sizeof(show), "一等獎");
			gain[Client]=2;
		}
		case 44:
		{
			Format(show, sizeof(show), "二等獎");
			gain[Client]=3;
		}
		case 45:
		{
			Format(show, sizeof(show), "二等獎");
			gain[Client]=3;
		}
		case 46:
		{
			Format(show, sizeof(show), "二等獎");
			gain[Client]=3;
		}
		case 47:
		{
			Format(show, sizeof(show), "三等獎");
			gain[Client]=4;
		}
		case 48:
		{
			Format(show, sizeof(show), "三等獎");
			gain[Client]=4;
		}
		case 49:
		{
			Format(show, sizeof(show), "三等獎");
			gain[Client]=4;
		}
		case 50:
		{
			Format(show, sizeof(show), "三等獎");
			gain[Client]=4;
		}
		case 51:
		{
			Format(show, sizeof(show), "三等獎");
			gain[Client]=4;
		}
		case 52:
		{
			Format(show, sizeof(show), "安慰獎");
			gain[Client]=5;
		}
		case 53:
		{
			Format(show, sizeof(show), "安慰獎");
			gain[Client]=5;
		}
		case 54:
		{
			Format(show, sizeof(show), "安慰獎");
			gain[Client]=5;
		}
		case 55:
		{
			Format(show, sizeof(show), "安慰獎");
			gain[Client]=5;
		}
		case 56:
		{
			Format(show, sizeof(show), "安慰獎");
			gain[Client]=5;
		}
		case 57:
		{
			Format(show, sizeof(show), "安慰獎");
			gain[Client]=5;
		}
		case 58:
		{
			Format(show, sizeof(show), "安慰獎");
			gain[Client]=5;
		}
		case 59:
		{
			Format(show, sizeof(show), "安慰獎");
			gain[Client]=5;
		}
		case 60:
		{
			Format(show, sizeof(show), "懲罰");
			gain[Client]=6;
		}
		case 61:
		{
			Format(show, sizeof(show), "特等獎");
			gain[Client]=1;
		}
		case 62:
		{
			Format(show, sizeof(show), "一等獎");
			gain[Client]=2;
		}
		case 63:
		{
			Format(show, sizeof(show), "一等獎");
			gain[Client]=2;
		}
		case 64:
		{
			Format(show, sizeof(show), "二等獎");
			gain[Client]=3;
		}
		case 65:
		{
			Format(show, sizeof(show), "二等獎");
			gain[Client]=3;
		}
		case 66:
		{
			Format(show, sizeof(show), "二等獎");
			gain[Client]=3;
		}
		case 67:
		{
			Format(show, sizeof(show), "三等獎");
			gain[Client]=4;
		}
		case 68:
		{
			Format(show, sizeof(show), "三等獎");
			gain[Client]=4;
		}
		case 69:
		{
			Format(show, sizeof(show), "三等獎");
			gain[Client]=4;
		}
		case 70:
		{
			Format(show, sizeof(show), "三等獎");
			gain[Client]=4;
		}
		case 71:
		{
			Format(show, sizeof(show), "三等獎");
			gain[Client]=4;
		}
		case 72:
		{
			Format(show, sizeof(show), "安慰獎");
			gain[Client]=5;
		}
		case 73:
		{
			Format(show, sizeof(show), "安慰獎");
			gain[Client]=5;
		}
		case 74:
		{
			Format(show, sizeof(show), "安慰獎");
			gain[Client]=5;
		}
		case 75:
		{
			Format(show, sizeof(show), "安慰獎");
			gain[Client]=5;
		}
		case 76:
		{
			Format(show, sizeof(show), "安慰獎");
			gain[Client]=5;
		}
		case 77:
		{
			Format(show, sizeof(show), "安慰獎");
			gain[Client]=5;
		}
		case 78:
		{
			Format(show, sizeof(show), "安慰獎");
			gain[Client]=5;
		}
		case 79:
		{
			Format(show, sizeof(show), "安慰獎");
			gain[Client]=5;
		}
		case 80:
		{
			Format(show, sizeof(show), "懲罰");
			gain[Client]=6;
		}
		case 81:
		{
			Format(show, sizeof(show), "特等獎");
			gain[Client]=1;
		}
		case 82:
		{
			Format(show, sizeof(show), "一等獎");
			gain[Client]=2;
		}
		case 83:
		{
			Format(show, sizeof(show), "一等獎");
			gain[Client]=2;
		}
		case 84:
		{
			Format(show, sizeof(show), "二等獎");
			gain[Client]=3;
		}
		case 85:
		{
			Format(show, sizeof(show), "二等獎");
			gain[Client]=3;
		}
		case 86:
		{
			Format(show, sizeof(show), "二等獎");
			gain[Client]=3;
		}
		case 87:
		{
			Format(show, sizeof(show), "三等獎");
			gain[Client]=4;
		}
		case 88:
		{
			Format(show, sizeof(show), "三等獎");
			gain[Client]=4;
		}
		case 89:
		{
			Format(show, sizeof(show), "三等獎");
			gain[Client]=4;
		}
		case 90:
		{
			Format(show, sizeof(show), "三等獎");
			gain[Client]=4;
		}
		case 91:
		{
			Format(show, sizeof(show), "三等獎");
			gain[Client]=4;
		}
		case 92:
		{
			Format(show, sizeof(show), "安慰獎");
			gain[Client]=5;
		}
		case 93:
		{
			Format(show, sizeof(show), "安慰獎");
			gain[Client]=5;
		}
		case 94:
		{
			Format(show, sizeof(show), "安慰獎");
			gain[Client]=5;
		}
		case 95:
		{
			Format(show, sizeof(show), "安慰獎");
			gain[Client]=5;
		}
		case 96:
		{
			Format(show, sizeof(show), "安慰獎");
			gain[Client]=5;
		}
		case 97:
		{
			Format(show, sizeof(show), "安慰獎");
			gain[Client]=5;
		}
		case 98:
		{
			Format(show, sizeof(show), "安慰獎");
			gain[Client]=5;
		}
		case 99:
		{
			Format(show, sizeof(show), "安慰獎");
			gain[Client]=5;
		}
		case 100:
		{
			Format(show, sizeof(show), "懲罰");
			gain[Client]=6;
		}
	}
	
	EmitSoundToClient(Client, "ui/littlereward.wav");
	return extract;
}











public Action:LDW(Client, args)
{
	if(GetClientTeam(Client)==2)
	{
		draw_function(Client);
	} else
	{
		PrintToChat(Client, "此功能只有倖存者可以使用!");
	}
}

public Action:draw_function(Client)
{
	decl String:line[256];
	new Handle:menu = CreatePanel();
	if(!rolled[Client])
	{
		Format(line, sizeof(line), "   -抽獎系統清單-");
		SetPanelTitle(menu, line);
		if(L[Client] > 0)
		{
			Format(line, sizeof(line), "你有%d次抽獎機會", L[Client]);
			DrawPanelText(menu, line);
			Format(line, sizeof(line), "【詳情請查看規則說明】");
			DrawPanelText(menu, line);
		} else
		{
			L[Client] = 0;
			Format(line, sizeof(line), "你暫時沒有抽獎機會");
			DrawPanelText(menu, line);
			Format(line, sizeof(line), "【詳情請查看規則說明】");
			DrawPanelText(menu, line);
		}
		
		Format(line, sizeof(line), "準備抽獎");
		DrawPanelItem(menu, line);
		Format(line, sizeof(line), "規則說明");
		DrawPanelItem(menu, line);
		Format(line, sizeof(line), "刷新列表");
		DrawPanelItem(menu, line);
		DrawPanelItem(menu, "Exit", ITEMDRAW_DISABLED);
		SendPanelToClient(menu, Client, MenuHandler, MENU_TIME_FOREVER);
		CloseHandle(menu);
	} else 
	{
		Format(line, sizeof(line), "  -祝您好運-");
		SetPanelTitle(menu, line);
		Format(line, sizeof(line), "~~~~~~~~~~~~~~", L[Client]);
		DrawPanelText(menu, line);
		Format(line, sizeof(line), "   抽獎中...  ", L[Client]);
		DrawPanelText(menu, line);
		Format(line, sizeof(line), "~~~~~~~~~~~~~~", L[Client]);
		DrawPanelText(menu, line);
		Format(line, sizeof(line), "-停-");
		DrawPanelItem(menu, line);
		DrawPanelItem(menu, "如果列表關閉,請再次打開,選擇:-停-", ITEMDRAW_DISABLED);
		SendPanelToClient(menu, Client, Stop, MENU_TIME_FOREVER);
		CloseHandle(menu);
	}
}

public MenuHandler(Handle:menu, MenuAction:action, Client, param)
{
	if (action == MenuAction_Select) {
		switch (param)
		{
			case 1:
			{
				if(L[Client] > 0)
				{
					if(sift[Client])
					{
						sift_start1(Client);
						sift_start2(Client);
						sift_start3(Client);
						sift_start4(Client);
						sift_start5(Client);
						sift_start6(Client);
						sift[Client]=false;
					}
					Award_List(Client);
				} else
				{
					PrintToChat(Client, "\x04Sorry,你沒有抽獎機會!");
				}
			}
			case 2:
			{
				Explain(Client);
			}
			case 3:
			{
				draw_function(Client);
				EmitSoundToClient(Client, DD);
			}
		}
	}
}

public Stop(Handle:menu, MenuAction:action, Client, param)
{
	if (action == MenuAction_Select) {
		switch (param)
		{
			case 1:
			{
				KillTimer(StopTime[Client]);
				rolled[Client]=false;
				sift[Client]=true;
				Award(Client);
			}
		}
	}
}

public Action:Explain(Client)//說明
{
	decl String:line[256];
	new Handle:menu = CreatePanel();
	Format(line, sizeof(line), "    -規則說明-");
	SetPanelTitle(menu, line);
	Format(line, sizeof(line), "請選擇你想瞭解的說明");
	DrawPanelText(menu, line);
	Format(line, sizeof(line), "操作說明");
	DrawPanelItem(menu, line);
	Format(line, sizeof(line), "抽獎機會獲得方法");
	DrawPanelItem(menu, line);
	Format(line, sizeof(line), "獎項出現概率");
	DrawPanelItem(menu, line);
	Format(line, sizeof(line), "返回");
	DrawPanelItem(menu, line);
	DrawPanelItem(menu, "Exit", ITEMDRAW_DISABLED);
	SendPanelToClient(menu, Client, Declare, MENU_TIME_FOREVER);
	CloseHandle(menu);
}

public Declare(Handle:menu, MenuAction:action, Client, param)
{
	if (action == MenuAction_Select) {
		switch (param)
		{
			case 1:
			{
				E1(Client);
			}
			case 2:
			{
				E2(Client);
			}
			case 3:
			{
				E3(Client);
			}
			case 4:
			{
				draw_function(Client);
			}
		}
	}
}

public Action:E1(Client)
{
	decl String:line[256];
	new Handle:menu = CreatePanel();
	Format(line, sizeof(line), "   -操作說明-");
	SetPanelTitle(menu, line);
	Format(line, sizeof(line), ">如果你有抽獎機會");
	DrawPanelText(menu, line);
	Format(line, sizeof(line), ">請點擊主菜單的 【準備抽獎】");
	DrawPanelText(menu, line);
	Format(line, sizeof(line), ">此時會出現一個清單,上面顯示你本次獎項的獎品");
	DrawPanelText(menu, line);
	Format(line, sizeof(line), ">然後選擇【開始抽獎】");
	DrawPanelText(menu, line);
	Format(line, sizeof(line), "下一頁");
	DrawPanelItem(menu, line);
	Format(line, sizeof(line), "返回");
	DrawPanelItem(menu, line);
	DrawPanelItem(menu, "Exit", ITEMDRAW_DISABLED);
	SendPanelToClient(menu, Client, Page1, MENU_TIME_FOREVER);
	CloseHandle(menu);
}

public Page1(Handle:menu, MenuAction:action, Client, param)
{
	if (action == MenuAction_Select) {
		switch (param)
		{
			case 1:
			{
				E1_1(Client);
			}
			case 2:
			{
				Explain(Client);
			}
		}
	}
}

public Action:E1_1(Client)
{
	decl String:line[256];
	new Handle:menu = CreatePanel();
	Format(line, sizeof(line), "   -操作說明-");
	SetPanelTitle(menu, line);
	Format(line, sizeof(line), ">此時你准心上方會出現一個跳動的獎項條");
	DrawPanelText(menu, line);
	Format(line, sizeof(line), ">當你選擇功能表中的【-停-】時,獎項條停止跳動");
	DrawPanelText(menu, line);
	Format(line, sizeof(line), ">你即可獲得獎項欄對應的獎品");
	DrawPanelText(menu, line);
	Format(line, sizeof(line), "上一頁");
	DrawPanelItem(menu, line);
	Format(line, sizeof(line), "返回");
	DrawPanelItem(menu, line);
	DrawPanelItem(menu, "Exit", ITEMDRAW_DISABLED);
	SendPanelToClient(menu, Client, Page2, MENU_TIME_FOREVER);
	CloseHandle(menu);
}

public Page2(Handle:menu, MenuAction:action, Client, param)
{
	if (action == MenuAction_Select) {
		switch (param)
		{
			case 1:
			{
				E1(Client);
			}
			case 2:
			{
				Explain(Client);
			}
		}
	}
}

public Action:E2(Client)
{
	decl String:line[256];
	new Handle:menu = CreatePanel();
	Format(line, sizeof(line), "  -抽獎機會獲得方法-");
	SetPanelTitle(menu, line);
	Format(line, sizeof(line), ">擊殺%d個小僵屍即可獲得1次抽獎機會", GetConVarInt(kills));
	DrawPanelText(menu, line);
	Format(line, sizeof(line), ">擊殺1個特感可以獲得%d次抽獎機會", GetConVarInt(infected_count));
	DrawPanelText(menu, line);
	Format(line, sizeof(line), ">Tank死亡時,所有倖存者可獲得%d次抽獎機會", GetConVarInt(tank_count));
	DrawPanelText(menu, line);
	Format(line, sizeof(line), "返回");
	DrawPanelItem(menu, line);
	DrawPanelItem(menu, "Exit", ITEMDRAW_DISABLED);
	SendPanelToClient(menu, Client, Back, MENU_TIME_FOREVER);
	CloseHandle(menu);
}

public Back(Handle:menu, MenuAction:action, Client, param)
{
	if (action == MenuAction_Select) {
		switch (param)
		{
			case 1:
			{
				Explain(Client);
			}
		}
	}
}

public Action:E3(Client)
{
	decl String:line[256];
	new Handle:menu = CreatePanel();
	Format(line, sizeof(line), "   -獎項出現概率-");
	SetPanelTitle(menu, line);
	Format(line, sizeof(line), "以下為獎項條跳動時,各類獎項出現概率:");
	DrawPanelText(menu, line);
	Format(line, sizeof(line), ">特等獎5％出現");
	DrawPanelText(menu, line);
	Format(line, sizeof(line), ">一等獎10％出現");
	DrawPanelText(menu, line);
	Format(line, sizeof(line), ">二等獎15％出現");
	DrawPanelText(menu, line);
	Format(line, sizeof(line), ">三等獎25％出現");
	DrawPanelText(menu, line);
	Format(line, sizeof(line), ">安慰獎40％出現");
	DrawPanelText(menu, line);
	Format(line, sizeof(line), ">懲罰5％出現");
	DrawPanelText(menu, line);
	Format(line, sizeof(line), "返回");
	DrawPanelItem(menu, line);
	DrawPanelItem(menu, "Exit", ITEMDRAW_DISABLED);
	SendPanelToClient(menu, Client, Back, MENU_TIME_FOREVER);
	CloseHandle(menu);
}


public Action:Award(Client)//** 發放獎品 **//
{
	decl String:ms[32];
	decl String:hd[32];
	if(gain[Client]==1)
	{
		if(prize1[Client]==1)
		{
			for (new i = 1; i <= MaxClients; i++)
			{
				if(IsClientInGame(i))
				{
					if(GetClientTeam(i) == 2)
					{
						new MaxHP = GetEntProp(i, Prop_Data, "m_iMaxHealth");
						SetEntProp(i, Prop_Data, "m_iHealth", MaxHP);
					}
				}
			}
			Format(hd, sizeof(hd), "所有倖存者加滿HP");
		} else if(prize1[Client]==2)
		{
			CheatCommand(Client, "ent_remove_all", "infected");
			Format(hd, sizeof(hd), "清除所有小僵屍");
		} else if(prize1[Client]==3)
		{
			SetEntProp(Client, Prop_Data, "m_takedamage", 0, 1);
			Format(hd, sizeof(hd), "他自己進入無敵狀態");
		} else if(prize1[Client]==4)
		{
			SetEntityGravity(Client, 0.1);
			Format(hd, sizeof(hd), "他自己的重力降到最低");
		} else if(prize1[Client]==5)
		{
			for (new i = 1; i <= MaxClients; i++)
			{
				if(IsClientInGame(i))
				{
					if(GetClientTeam(i) == 3)
					{
						ForcePlayerSuicide(i);
					}
				}
			}
			Format(hd, sizeof(hd), "處死所有特感");
		}
		Format(ms, sizeof(ms), "特等獎");
		PrintToChatAll(QT, Client, ms, hd);
		EmitSoundToClient(Client, "level/gnomeftw.wav");
		AttachParticle(Client, "achieved", 3.0);
	}
	
	if(gain[Client] == 2)
	{
		if(prize2[Client]==1)
		{
			CheatCommand(Client, "give", "rifle");
			Format(hd, sizeof(hd), "獲得M16");
		} else if(prize2[Client]==2)
		{
			CheatCommand(Client, "give", "rifle_ak47");
			Format(hd, sizeof(hd), "獲得AK47");
		} else if(prize2[Client]==3)
		{
			CheatCommand(Client, "give", "sniper_military");
			Format(hd, sizeof(hd), "獲得大型連狙");
		} else if(prize2[Client]==4)
		{
			CheatCommand(Client, "give", "hunting_rifle");
			Format(hd, sizeof(hd), "獲得小型連狙");
		} else if(prize2[Client]==5)
		{
			CheatCommand(Client, "give", "autoshotgun");
			Format(hd, sizeof(hd), "獲得自動散彈槍");
		} else if(prize2[Client]==6)
		{
			CheatCommand(Client, "give", "shotgun_spas");
			Format(hd, sizeof(hd), "獲得spas戰鬥散彈槍");
		} else if(prize2[Client]==7)
		{
			CheatCommand(Client, "give", "shotgun_chrome");
			Format(hd, sizeof(hd), "獲得鉻合金散彈槍");
		} else if(prize2[Client]==8)
		{
			CheatCommand(Client, "give", "pumpshotgun");
			Format(hd, sizeof(hd), "獲得泵動式散彈槍");
		} else if(prize2[Client]==9)
		{
			CheatCommand(Client, "give", " rifle_desert");
			Format(hd, sizeof(hd), "獲得突擊步槍");
		} else if(prize2[Client]==10)
		{
			CheatCommand(Client, "give", "grenade_launcher");
			Format(hd, sizeof(hd), "獲得榴彈槍");
		} else if(prize2[Client]==11)
		{
			CheatCommand(Client, "give", "smg");
			Format(hd, sizeof(hd), "獲得烏茲小衝鋒");
		} else if(prize2[Client]==12)
		{
			CheatCommand(Client, "give", "smg_silenced");
			Format(hd, sizeof(hd), "獲得消音小衝鋒");
		}
		Format(ms, sizeof(ms), "一等獎");
		PrintToChat(Client, PIE, ms, hd);
		EmitSoundToClient(Client, "level/gnomeftw.wav");
		AttachParticle(Client, "achieved", 3.0);
	}
	
	if(gain[Client]==3)
	{
		if(prize3[Client]==1)
		{
			CheatCommand(Client, "give", "first_aid_kit");
			Format(hd, sizeof(hd), "獲得醫藥包");
		} else if(prize3[Client]==2)
		{
			CheatCommand(Client, "give", "pain_pills");
			Format(hd, sizeof(hd), "獲得止痛藥");
		} else if(prize3[Client]==3)
		{
			CheatCommand(Client, "give", "adrenaline");
			Format(hd, sizeof(hd), "獲得腎上腺素");
		} else if(prize3[Client]==4)
		{
			CheatCommand(Client, "give", "defibrillator");
			Format(hd, sizeof(hd), "獲得電擊器");
		}
		Format(ms, sizeof(ms), "二等獎");
		PrintToChat(Client, PIE, ms, hd);
		EmitSoundToClient(Client, "level/gnomeftw.wav");
		AttachParticle(Client, "achieved", 3.0);
	}
	
	if(gain[Client]==4)
	{
		if(prize4[Client]==1)
		{
			CheatCommand(Client, "give", "pistol_magnum");
			Format(hd, sizeof(hd), "獲得馬格南手槍");
		} else if(prize4[Client]==2)
		{
			CheatCommand(Client, "give", "baseball_bat");
			Format(hd, sizeof(hd), "獲得棒球棒");
		} else if(prize4[Client]==3)
		{
			CheatCommand(Client, "give", "pipe_bomb");
			Format(hd, sizeof(hd), "獲得土制炸彈");
		} else if(prize4[Client]==4)
		{
			CheatCommand(Client, "give", "molotov");
			Format(hd, sizeof(hd), "獲得燃燒瓶");
		} else if(prize4[Client]==5)
		{
			CheatCommand(Client, "give", "vomitjar");
			Format(hd, sizeof(hd), "獲得膽汁炸彈");
		} else if(prize4[Client]==6)
		{
			CheatCommand(Client, "give", "rifle_m60");
			Format(hd, sizeof(hd), "獲得M60");
		}
		Format(ms, sizeof(ms), "三等獎");
		PrintToChat(Client, PIE, ms, hd);
		EmitSoundToClient(Client, "level/gnomeftw.wav");
		AttachParticle(Client, "achieved", 3.0);
	}
	
	if(gain[Client]==5)
	{
		if(prize5[Client]==1)
		{
			CheatCommand(Client, "give", "upgradepack_incendiary");
			Format(hd, sizeof(hd), "獲得燃燒彈盒");
		} else if(prize5[Client]==2)
		{
			CheatCommand(Client, "give", "upgradepack_explosive");
			Format(hd, sizeof(hd), "獲得高爆彈盒");
		} else if(prize5[Client]==3)
		{
			CheatCommand(Client, "give", "propanetank");
			Format(hd, sizeof(hd), "獲得煤氣罐");
		} else if(prize5[Client]==4)
		{
			CheatCommand(Client, "give", "gascan");
			Format(hd, sizeof(hd), "獲得汽油桶");
		} else if(prize5[Client]==5)
		{
			CheatCommand(Client, "give", "oxygentank");
			Format(hd, sizeof(hd), "獲得氧氣罐");
		}
		Format(ms, sizeof(ms), "安慰獎");
		PrintToChat(Client, PIE, ms, hd);
		EmitSoundToClient(Client, "level/gnomeftw.wav");
		AttachParticle(Client, "achieved", 3.0);
	}
	
	if(gain[Client]==6)
	{
		if(prize6[Client]==1)
		{
			CheatCommand(Client, "z_spawn", "witch");
			CheatCommand(Client, "z_spawn", "witch");
			Format(hd, sizeof(hd), "召喚兩隻Witch");
		} else if(prize6[Client]==2)
		{
			CheatCommand(Client, "z_spawn", "tank");
			Format(hd, sizeof(hd), "召喚一隻Tank");
		} else if(prize6[Client]==3)
		{
			ForcePlayerSuicide(Client);
			Format(hd, sizeof(hd), "自殺!!!");
		} else if(prize6[Client]==4)
		{
			CheatCommand(Client, "z_spawn", "mob");
			CheatCommand(Client, "z_spawn", "mob");
			Format(hd, sizeof(hd), "召喚屍潮!");
		} else if(prize6[Client]==5)
		{
			ServerCommand("sm_freeze \"%N\" \"%d\"", Client, 10);
			//CheatCommand(Client, warp_to_start_area);
			Format(hd, sizeof(hd), "從頭再來，傳送至起點！");
		}
		Format(ms, sizeof(ms), "懲罰");
		PrintToChatAll(PH, Client, ms, hd);
		EmitSoundToClient(Client, "npc/moustachio/strengthattract05.wav");
	}
	
}

public Action:sift_start1(Client)//特殊獎品
{
	new diceNum = GetRandomInt(1, 5);
	switch (diceNum)
	{
		case 1:
		{
			prize1[Client]=1;
		}
		case 2:
		{
			prize1[Client]=2;
		}
		case 3:
		{
			prize1[Client]=3;
		}
		case 4:
		{
			prize1[Client]=4;
		}
		case 5:
		{
			prize1[Client]=5;
		}
	}
}

public Action:sift_start2(Client)//主武器
{
	new diceNum2 = GetRandomInt(1, 12);
	switch (diceNum2)
	{
		case 1:
		{
			prize2[Client]=1;
		}
		case 2:
		{
			prize2[Client]=2;
		}
		case 3:
		{
			prize2[Client]=3;
		}
		case 4:
		{
			prize2[Client]=4;
		}
		case 5:
		{
			prize2[Client]=5;
		}
		case 6:
		{
			prize2[Client]=6;
		}
		case 7:
		{
			prize2[Client]=7;
		}
		case 8:
		{
			prize2[Client]=8;
		}
		case 9:
		{
			prize2[Client]=9;
		}
		case 10:
		{
			prize2[Client]=10;
		}
		case 11:
		{
			prize2[Client]=11;
		}
		case 12:
		{
			prize2[Client]=12;
		}
	}
}

public Action:sift_start3(Client)//醫藥品
{
	new diceNum3 = GetRandomInt(1, 4);
	switch (diceNum3)
	{
		case 1:
		{
			prize3[Client]=1;
		}
		case 2:
		{
			prize3[Client]=2;
		}
		case 3:
		{
			prize3[Client]=3;
		}
		case 4:
		{
			prize3[Client]=4;
		}
	}
}

public Action:sift_start4(Client)//投擲&棒球棒&馬格南
{
	new diceNum4 = GetRandomInt(1, 6);
	switch (diceNum4)
	{
		case 1:
		{
			prize4[Client]=1;
		}
		case 2:
		{
			prize4[Client]=2;
		}
		case 3:
		{
			prize4[Client]=3;
		}
		case 4:
		{
			prize4[Client]=4;
		}
		case 5:
		{
			prize4[Client]=5;
		}
		case 6:
		{
			prize4[Client]=6;
		}
	}
}

public Action:sift_start5(Client)//爆炸品
{
	new diceNum5 = GetRandomInt(1, 5);
	switch (diceNum5)
	{
		case 1:
		{
			prize5[Client]=1;
		}
		case 2:
		{
			prize5[Client]=2;
		}
		case 3:
		{
			prize5[Client]=3;
		}
		case 4:
		{
			prize5[Client]=4;
		}
		case 5:
		{
			prize5[Client]=5;
		}
	}
}

public Action:sift_start6(Client)//懲罰
{
	new diceNum6 = GetRandomInt(1, 5);
	switch (diceNum6)
	{
		case 1:
		{
			prize6[Client]=1;
		}
		case 2:
		{
			prize6[Client]=2;
		}
		case 3:
		{
			prize6[Client]=3;
		}
		case 4:
		{
			prize6[Client]=4;
		}
		case 5:
		{
			prize6[Client]=5;
		}
	}
}

public Action:Award_List(Client)
{
	decl String:line[256];
	new Handle:menu = CreatePanel();
	Format(line, sizeof(line), "-本次獎品-");
	SetPanelTitle(menu, line);
	if(prize1[Client]==1)
	{
		Format(line, sizeof(line), "【特等獎】:加滿所有倖存者的HP");
		DrawPanelText(menu, line);
	} else if(prize1[Client]==2)
	{
		Format(line, sizeof(line), "【特等獎】:清除所有小僵屍");
		DrawPanelText(menu, line);
	} else if(prize1[Client]==3)
	{
		Format(line, sizeof(line), "【特等獎】:自己進入無敵狀態");
		DrawPanelText(menu, line);
	} else if(prize1[Client]==4)
	{
		Format(line, sizeof(line), "【特等獎】:自己重力降到最低");
		DrawPanelText(menu, line);
	} else if(prize1[Client]==5)
	{
		Format(line, sizeof(line), "【特等獎】:處死所有特感");
		DrawPanelText(menu, line);
	}
	
	if(prize2[Client]==1)
	{
		Format(line, sizeof(line), "【一等獎】:獲得M16步槍");
		DrawPanelText(menu, line);
	} else if(prize2[Client]==2)
	{
		Format(line, sizeof(line), "【一等獎】:獲得AK47");
		DrawPanelText(menu, line);
	} else if(prize2[Client]==3)
	{
		Format(line, sizeof(line), "【一等獎】:獲得大型連狙");
		DrawPanelText(menu, line);
	} else if(prize2[Client]==4)
	{
		Format(line, sizeof(line), "【一等獎】:獲得小型連狙");
		DrawPanelText(menu, line);
	} else if(prize2[Client]==5)
	{
		Format(line, sizeof(line), "【一等獎】:獲得自動散彈槍");
		DrawPanelText(menu, line);
	} else if(prize2[Client]==6)
	{
		Format(line, sizeof(line), "【一等獎】:獲得spas戰鬥散彈槍");
		DrawPanelText(menu, line);
	} else if(prize2[Client]==7)
	{
		Format(line, sizeof(line), "【一等獎】:獲得鉻合金散彈槍");
		DrawPanelText(menu, line);
	} else if(prize2[Client]==8)
	{
		Format(line, sizeof(line), "【一等獎】:獲得泵動式散彈槍");
		DrawPanelText(menu, line);
	} else if(prize2[Client]==9)
	{
		Format(line, sizeof(line), "【一等獎】:獲得突擊步槍");
		DrawPanelText(menu, line);
	} else if(prize2[Client]==10)
	{
		Format(line, sizeof(line), "【一等獎】:獲得榴彈槍");
		DrawPanelText(menu, line);
	} else if(prize2[Client]==11)
	{
		Format(line, sizeof(line), "【一等獎】:獲得烏茲小衝鋒");
		DrawPanelText(menu, line);
	} else if(prize2[Client]==12)
	{
		Format(line, sizeof(line), "【一等獎】:獲得消音小衝鋒");
		DrawPanelText(menu, line);
	}
	
	if(prize3[Client]==1)
	{
		Format(line, sizeof(line), "【二等獎】:獲得醫藥包");
		DrawPanelText(menu, line);
	} else if(prize3[Client]==2)
	{
		Format(line, sizeof(line), "【二等獎】:獲得止痛藥");
		DrawPanelText(menu, line);
	} else if(prize3[Client]==3)
	{
		Format(line, sizeof(line), "【二等獎】:獲得腎上腺素");
		DrawPanelText(menu, line);
	} else if(prize3[Client]==4)
	{
		Format(line, sizeof(line), "【二等獎】:獲得電擊器");
		DrawPanelText(menu, line);
	}
	
	if(prize4[Client]==1)
	{
		Format(line, sizeof(line), "【三等獎】:獲得馬格南手槍");
		DrawPanelText(menu, line);
	} else if(prize4[Client]==2)
	{
		Format(line, sizeof(line), "【三等獎】:獲得棒球棒");
		DrawPanelText(menu, line);
	} else if(prize4[Client]==3)
	{
		Format(line, sizeof(line), "【三等獎】:獲得土制炸彈");
		DrawPanelText(menu, line);
	} else if(prize4[Client]==4)
	{
		Format(line, sizeof(line), "【三等獎】:獲得燃燒瓶");
		DrawPanelText(menu, line);
	} else if(prize4[Client]==5)
	{
		Format(line, sizeof(line), "【三等獎】:獲得膽汁炸彈");
		DrawPanelText(menu, line);
	} else if(prize4[Client]==6)
	{
		Format(line, sizeof(line), "【三等獎】:獲得M60");
		DrawPanelText(menu, line);
	}
	
	if(prize5[Client]==1)
	{
		Format(line, sizeof(line), "【安慰獎】:獲得燃燒彈盒");
		DrawPanelText(menu, line);
	} else if(prize5[Client]==2)
	{
		Format(line, sizeof(line), "【安慰獎】:獲得高爆彈盒");
		DrawPanelText(menu, line);
	} else if(prize5[Client]==3)
	{
		Format(line, sizeof(line), "【安慰獎】:獲得煤氣罐");
		DrawPanelText(menu, line);
	} else if(prize5[Client]==4)
	{
		Format(line, sizeof(line), "【安慰獎】:獲得汽油桶");
		DrawPanelText(menu, line);
	} else if(prize5[Client]==5)
	{
		Format(line, sizeof(line), "【安慰獎】:獲得氧氣罐");
		DrawPanelText(menu, line);
	}
	
	if(prize6[Client]==1)
	{
		Format(line, sizeof(line), "【懲罰】:召喚兩隻Witch");
		DrawPanelText(menu, line);
	} else if(prize6[Client]==2)
	{
		Format(line, sizeof(line), "【懲罰】:召喚一隻Tank");
		DrawPanelText(menu, line);
	} else if(prize6[Client]==3)
	{
		Format(line, sizeof(line), "【懲罰】:自殺!!!");
		DrawPanelText(menu, line);
	} else if(prize6[Client]==4)
	{
		Format(line, sizeof(line), "【懲罰】:召喚屍潮!");
		DrawPanelText(menu, line);
	} else if(prize6[Client]==5)
	{
		Format(line, sizeof(line), "【懲罰】:被冰凍10秒");
		DrawPanelText(menu, line);
	}
	Format(line, sizeof(line), "開始抽獎");
	DrawPanelItem(menu, line);
	Format(line, sizeof(line), "返回");
	DrawPanelItem(menu, line);
	DrawPanelItem(menu, "Exit", ITEMDRAW_DISABLED);
	SendPanelToClient(menu, Client, Start, 3); //edit
	//Start2(Client);
	CloseHandle(menu);
}
	
public Start2(Client)
{
	rolled[Client]=true;
	draw_function(Client);
	L[Client]-=1;
}

public Start(Handle:menu, MenuAction:action, Client, param)
{
	if (action == MenuAction_Select) {
		switch (param)
		{
			case -5: 
			{
				StopTime[Client] = CreateTimer(0.04, Roll, Client, TIMER_REPEAT);
				rolled[Client]=true;
				draw_function(Client);
				L[Client]-=1;
			}
			case 1: 
			{
				StopTime[Client] = CreateTimer(0.04, Roll, Client, TIMER_REPEAT);
				rolled[Client]=true;
				draw_function(Client);
				L[Client]-=1;
			}
			case 2:
			{
				draw_function(Client);
			}
		}
	}
}

public Action:Roll(Handle:timer, any:Client)
{
	decl String:show[32];
	new extract = GetRandomInt(1, 20);
	switch (extract)
	{
		case 1:
		{
			Format(show, sizeof(show), "特等獎");
			gain[Client]=1;
		}
		case 2:
		{
			Format(show, sizeof(show), "一等獎");
			gain[Client]=2;
		}
		case 3:
		{
			Format(show, sizeof(show), "一等獎");
			gain[Client]=2;
		}
		case 4:
		{
			Format(show, sizeof(show), "二等獎");
			gain[Client]=3;
		}
		case 5:
		{
			Format(show, sizeof(show), "二等獎");
			gain[Client]=3;
		}
		case 6:
		{
			Format(show, sizeof(show), "二等獎");
			gain[Client]=4;
		}
		case 7:
		{
			Format(show, sizeof(show), "三等獎");
			gain[Client]=4;
		}
		case 8:
		{
			Format(show, sizeof(show), "三等獎");
			gain[Client]=4;
		}
		case 9:
		{
			Format(show, sizeof(show), "三等獎");
			gain[Client]=4;
		}
		case 10:
		{
			Format(show, sizeof(show), "三等獎");
			gain[Client]=5;
		}
		case 11:
		{
			Format(show, sizeof(show), "三等獎");
			gain[Client]=5;
		}
		case 12:
		{
			Format(show, sizeof(show), "安慰獎");
			gain[Client]=5;
		}
		case 13:
		{
			Format(show, sizeof(show), "安慰獎");
			gain[Client]=5;
		}
		case 14:
		{
			Format(show, sizeof(show), "安慰獎");
			gain[Client]=6;
		}
		case 15:
		{
			Format(show, sizeof(show), "安慰獎");
			gain[Client]=6;
		}
		case 16:
		{
			Format(show, sizeof(show), "安慰獎");
			gain[Client]=6;
		}
		case 17:
		{
			Format(show, sizeof(show), "安慰獎");
			gain[Client]=6;
		}
		case 18:
		{
			Format(show, sizeof(show), "安慰獎");
			gain[Client]=6;
		}
		case 19:
		{
			Format(show, sizeof(show), "安慰獎");
			gain[Client]=6;
		}
		case 20:
		{
			Format(show, sizeof(show), "懲罰");
			gain[Client]=6;
		}
	}
	PrintCenterText(Client, "★抽獎中★     → %s     請在列表中選擇: -停- ", show);
	EmitSoundToClient(Client, "ui/littlereward.wav");
}

stock CheatCommand(Client, const String:command[], const String:arguments[])
{
    if (!Client) return;
    new admindata = GetUserFlagBits(Client);
    SetUserFlagBits(Client, ADMFLAG_ROOT);
    new flags = GetCommandFlags(command);
    SetCommandFlags(command, flags & ~FCVAR_CHEAT);
    FakeClientCommand(Client, "%s %s", command, arguments);
    SetCommandFlags(command, flags);
    SetUserFlagBits(Client, admindata);
}

Handle:AttachParticle(ent, String:particleType[], Float:time=10.0)
{
	if (ent < 1)
	{
		return INVALID_HANDLE;
	}

	new particle = CreateEntityByName("info_particle_system");

	if (IsValidEdict(particle))
	{
		decl String:tName[32];
		new Float:pos[3];

		GetEntPropVector(ent, Prop_Send, "m_vecOrigin", pos);
		pos[2] += 60;

		Format(tName, sizeof(tName), "target%i", ent);
		DispatchKeyValue(ent, "targetname", tName);

		DispatchKeyValue(particle, "targetname", "tf2particle");
		DispatchKeyValue(particle, "parentname", tName);
		DispatchKeyValue(particle, "effect_name", particleType);
		if (DispatchSpawn(particle))
		{
			TeleportEntity(particle, pos, NULL_VECTOR, NULL_VECTOR);
			SetVariantString(tName);
			AcceptEntityInput(particle, "SetParent", particle, particle, 0);
			
			SetVariantString("OnUser1 !self,Start,,0.0,-1");
			AcceptEntityInput(particle, "AddOutput");
			SetVariantString("OnUser2 !self,Stop,,4.0,-1");
			AcceptEntityInput(particle, "AddOutput");
			ActivateEntity(particle);
			AcceptEntityInput(particle, "FireUser1");
			AcceptEntityInput(particle, "FireUser2");

			new Handle:pack;
			new Handle:hTimer;
			hTimer = CreateDataTimer(time, DeleteParticle, pack);
			WritePackCell(pack, particle); 
			WritePackString(pack, particleType);
			WritePackCell(pack, ent); 

			new Handle:packLoop;
			hTimerLoopEffect[ent] = CreateDataTimer(4.2, LoopParticleEffect, packLoop, TIMER_REPEAT);
			WritePackCell(packLoop, particle); 
			WritePackCell(packLoop, ent);

			return hTimer;
		} 
		else 
		{
			if (IsValidEdict(particle))
			{
				RemoveEdict(particle);
			}
			return INVALID_HANDLE;
		}
	}
	return INVALID_HANDLE;
}

public Action:DeleteParticle(Handle:timer, Handle:pack)
{
	decl String:particleType[32];

	ResetPack(pack);
	new particle = ReadPackCell(pack);
	ReadPackString(pack, particleType, sizeof(particleType));
	new client = ReadPackCell(pack); 

	if (hTimerLoopEffect[client] != INVALID_HANDLE)
	{
		KillTimer(hTimerLoopEffect[client]);
		hTimerLoopEffect[client] = INVALID_HANDLE;
	}

	if (IsValidEntity(particle))
	{
		decl String:classname[128];
		GetEdictClassname(particle, classname, sizeof(classname));
		if (StrEqual(classname, "info_particle_system", false))
		{
			RemoveEdict(particle);
		}
	}

	if (StrEqual(particleType, "achieved", true))
	{
		hTimerAchieved[client] = INVALID_HANDLE;
	} 
	else if (StrEqual(particleType, "mini_fireworks", true)) 
	{
		hTimerMiniFireworks[client] = INVALID_HANDLE;
	}
}

public Action:LoopParticleEffect(Handle:timer, Handle:pack)
{

	ResetPack(pack);
	new particle = ReadPackCell(pack);
	new client = ReadPackCell(pack);

	if (IsValidEntity(particle))
	{
		decl String:classname[128];
		GetEdictClassname(particle, classname, sizeof(classname));
		if (StrEqual(classname, "info_particle_system", false))
		{
			AcceptEntityInput(particle, "FireUser1");
			AcceptEntityInput(particle, "FireUser2");
			return Plugin_Continue;
		}
	}
	hTimerLoopEffect[client] = INVALID_HANDLE;
	return Plugin_Stop;
}

public Action:Msg(Handle:timer, any:data)
{
	PrintToChatAll("\x03想試試你的臭手氣嗎? 聊天框輸入 \x04!ldw \x03打開 \x01【\x04抽獎系統\x01】");

}

stock bool:IsCommonInfected(iEntity)
{
	if(iEntity > 0 && IsValidEntity(iEntity) && IsValidEdict(iEntity))
	{
		decl String:strClassName[64];
		GetEdictClassname(iEntity, strClassName, sizeof(strClassName));
		return StrEqual(strClassName, "infected");
	}
	return false;
}

stock bool:IsWitch(iEntity)
{
	if(iEntity > 0 && IsValidEntity(iEntity) && IsValidEdict(iEntity))
	{
		decl String:strClassName[64];
		GetEdictClassname(iEntity, strClassName, sizeof(strClassName));
		return StrEqual(strClassName, "witch");
	}
	return false;
}
