// Author: KernCore

#include "../base"

enum CoFLANTERNAnimations_e
{
	CoFLANTERN_DRAW = 0,
	CoFLANTERN_SPRINT_IDLE,
	CoFLANTERN_IDLE,
	CoFLANTERN_PUNCH,
	CoFLANTERN_HOLSTER,
	CoFLANTERN_SPRINT_TO,
	CoFLANTERN_SPRINT_FROM,
	CoFLANTERN_PUNCH_MISS,
	CoFLANTERN_FIDGET1,
	CoFLANTERN_FIDGET2,
	CoFLANTERN_FIDGET3,
	CoFLANTERN_JUMP_TO,
	CoFLANTERN_JUMP_FROM
};

namespace CoFLANTERN
{
	//models
	string LANTERN_W_MODEL 	= "models/cof/lantern/wld.mdl";
	string LANTERN_V_MODEL 	= "models/cof/lantern/vwm.mdl";
	string LANTERN_P_MODEL 	= "models/cof/lantern/wld.mdl";
	//weapon info
	const int LANTERN_WEIGHT 	= 15;
	//iSlot and iPosition in the Hud
	uint SLOT    	= 4;
	uint POSITION 	= 4;
}

class weapon_coflantern : ScriptBasePlayerWeaponEntity, weapon_base
{
	private CScheduledFunction@ SelfLightSchedule = null;
	private CScheduledFunction@ PlayerLightSchedule = null;
	private CBasePlayer@ m_pPlayer
	{
		get const 	{ return cast<CBasePlayer@>( self.m_hPlayer.GetEntity() ); }
		set       	{ self.m_hPlayer = EHandle( @value ); }
	}

	void PreSpawn()
	{
		BaseClass.PreSpawn();
	}

	private void LanternDLight( Vector& in vecPos )
	{
		NetworkMessage LanternDL( MSG_ALL, NetworkMessages::SVC_TEMPENTITY, null );
			LanternDL.WriteByte( TE_DLIGHT );
			LanternDL.WriteCoord( vecPos.x );
			LanternDL.WriteCoord( vecPos.y );
			LanternDL.WriteCoord( vecPos.z );
			LanternDL.WriteByte( 22 ); //Radius
			LanternDL.WriteByte( int(150) ); //R
			LanternDL.WriteByte( int(150) ); //G
			LanternDL.WriteByte( int(150) ); //B
			LanternDL.WriteByte( 1 ); //Life
			LanternDL.WriteByte( 0 ); //Decay
		LanternDL.End();
	}

	void Spawn()
	{
		Precache();
		g_EntityFuncs.SetModel( self, CoFLANTERN::LANTERN_W_MODEL );
		self.KeyValue( "m_flCustomRespawnTime", 5 );
		iAnimation  	= CoFLANTERN_PUNCH;
		iAnimation2 	= CoFLANTERN_PUNCH_MISS;
		m_bUseCustomScale = true;
		self.pev.scale = 1.3;
		self.FallInit();
	}

	//Solokiller
	private void ClearThinkMethods()
	{
		g_Scheduler.RemoveTimer( SelfLightSchedule );
		@SelfLightSchedule = @null;
		g_Scheduler.RemoveTimer( PlayerLightSchedule );
		@PlayerLightSchedule = @null;
	}

	~weapon_coflantern()
	{
		ClearThinkMethods();
		//g_Log.PrintF("Lantern has been destroyed via ~ \n");
	}
	//Solokiller

	void OnDestroy()
	{
		ClearThinkMethods();
		//g_Log.PrintF("Lantern has been destroyed via OnDestroy \n");
	}

	void Materialize()
	{
		//g_Log.PrintF("\nLantern @owner Memory address: %1\n", @this);
		//g_Log.PrintF("\nLantern @player Memory: %1\n", @self);

		@SelfLightSchedule = @g_Scheduler.SetInterval( @this, "LightSelfThink", 0.099f, g_Scheduler.REPEAT_INFINITE_TIMES );

		BaseClass.Materialize();
		CommonMaterialize();
	}

	void LightSelfThink()
	{
		LanternDLight( self.Center() );
	}

	void LightPlayerThink()
	{
		LanternDLight( m_pPlayer.Center() );
	}

	void Precache()
	{
		self.PrecacheCustomModels();
		g_Game.PrecacheModel( CoFLANTERN::LANTERN_W_MODEL );
		g_Game.PrecacheModel( CoFLANTERN::LANTERN_V_MODEL );
		g_Game.PrecacheModel( CoFLANTERN::LANTERN_P_MODEL );

		CommonPrecache();

		g_Game.PrecacheModel( "sprites/cof/wpn_sel01.spr" );
		g_Game.PrecacheGeneric( "sprites/" + "cof/wpn_sel01.spr" );
		g_Game.PrecacheGeneric( "sprites/" + "cof/special/weapon_coflantern.txt" );
	}

	bool GetItemInfo( ItemInfo& out info )
	{
		info.iMaxAmmo1 	= -1;
		info.iMaxAmmo2 	= -1;
		info.iMaxClip 	= -1;
		info.iSlot   	= CoFLANTERN::SLOT;
		info.iPosition 	= CoFLANTERN::POSITION;
		info.iId     	= g_ItemRegistry.GetIdForName( self.pev.classname );
		info.iFlags  	= -1;
		info.iWeight 	= CoFLANTERN::LANTERN_WEIGHT;

		return true;
	}

	bool AddToPlayer( CBasePlayer@ pPlayer )
	{
		if( !BaseClass.AddToPlayer( pPlayer ) )
			return false;

		NetworkMessage coflantern( MSG_ONE, NetworkMessages::WeapPickup, pPlayer.edict() );
			coflantern.WriteLong( g_ItemRegistry.GetIdForName("weapon_coflantern") );
		coflantern.End();

		g_Scheduler.RemoveTimer( SelfLightSchedule );
		@SelfLightSchedule = @null;
		return true;
	}

	bool Deploy()
	{
		bool bResult;
		{
			bResult = Deploy( CoFLANTERN::LANTERN_V_MODEL, CoFLANTERN::LANTERN_P_MODEL, CoFLANTERN_DRAW, "hive", 1 );
			DeploySleeve();

			@PlayerLightSchedule = @g_Scheduler.SetInterval( @this, "LightPlayerThink", 0.1f, g_Scheduler.REPEAT_INFINITE_TIMES );

			float deployTime = 1.13f;
			self.m_flTimeWeaponIdle = self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = self.m_flNextTertiaryAttack = g_Engine.time + deployTime;
			return bResult;
		}
	}

	void Holster( int skipLocal = 0 )
	{
		SetThink( null );
		g_Scheduler.RemoveTimer( PlayerLightSchedule );
		@PlayerLightSchedule = @null;

		self.m_fInReload = false;

		//g_Log.PrintF("\nLantern @owner Memory: %1\n", @self.pev.owner);
		//g_Log.PrintF("\nLantern @player Memory: %1\n", @m_pPlayer.edict());

		BaseClass.Holster( skipLocal );
	}

	void ItemPreFrame()
	{
		BaseClass.ItemPreFrame();
	}

	void SecondaryAttack()
	{
		SetThink( null );
		if( !Swing( 1, 37, 1, 0.95f, 15, false ) )
		{
			SetThink( ThinkFunction( this.SwingAgain ) );
			self.pev.nextthink = g_Engine.time + 0.1;
		}
		// player "shoot" animation
		m_pPlayer.SetAnimation( PLAYER_ATTACK1 );
	}

	void SwingAgain()
	{
		Swing( 0, 37, 1, 0.95f, 15, false );
	}

	void WeaponIdle()
	{
		if( self.m_flTimeWeaponIdle > WeaponTimeBase() )
			return;

		int iAnim;
		switch( g_PlayerFuncs.SharedRandomLong( m_pPlayer.random_seed, 0, 3 ) )
		{
			case 0: iAnim = CoFLANTERN_IDLE; break;
			case 1: iAnim = CoFLANTERN_FIDGET1; break;
			case 2: iAnim = CoFLANTERN_FIDGET2; break;
			case 3: iAnim = CoFLANTERN_FIDGET3; break;
		}
		self.SendWeaponAnim( iAnim, 0, 0 );
		self.m_flTimeWeaponIdle = WeaponTimeBase() + g_PlayerFuncs.SharedRandomFloat( m_pPlayer.random_seed, 2, 5 );
	}

	void UpdateOnRemove()
	{
		BaseClass.UpdateOnRemove();
	}
}

string CoFLANTERNName()
{
	return "weapon_coflantern";
}

void RegisterCoFLANTERN()
{
	g_Scheduler.ClearTimerList();
	g_CustomEntityFuncs.RegisterCustomEntity( CoFLANTERNName(), CoFLANTERNName() );
	g_ItemRegistry.RegisterWeapon( CoFLANTERNName(), "cof/special" );
}