// Author: KernCore

#include "../base"

enum CoFSLEDGEHAMMERAnimations_e
{
	CoFSLEDGEHAMMER_DRAW = 0,
	CoFSLEDGEHAMMER_ATTACK,
	CoFSLEDGEHAMMER_IDLE,
	CoFSLEDGEHAMMER_HOLSTER,
	CoFSLEDGEHAMMER_SPRINT_TO,
	CoFSLEDGEHAMMER_SPRINT_IDLE,
	CoFSLEDGEHAMMER_SPRINT_FROM
};

namespace CoFSH
{
	//models
	string SLEDGEHAMMER_W_MODEL 	= "models/cof/sledge/wld.mdl";
	string SLEDGEHAMMER_V_MODEL 	= "models/cof/sledge/vwm.mdl";
	string SLEDGEHAMMER_P_MODEL 	= "models/cof/sledge/wld.mdl";
	//sounds
	const string SLEDGEHAMMER_SWNG_S	= "cof/guns/sledge/swing.ogg";
	const string SLEDGEHAMMER_HITW_S 	= "cof/guns/sledge/hitw.ogg";
	const string SLEDGEHAMMER_HITB_S 	= "cof/guns/sledge/hitb.ogg";
	//weapon info
	const int SLEDGEHAMMER_WEIGHT 	= 20;
	uint SLEDGEHAMMER_DAMAGE    	= 90;
	//iSlot and iPosition in the Hud
	uint SLOT     	= 0;
	uint POSITION 	= 12;
}

class weapon_cofsledgehammer : ScriptBasePlayerWeaponEntity, weapon_base
{
	private CBasePlayer@ m_pPlayer
	{
		get const 	{ return cast<CBasePlayer@>( self.m_hPlayer.GetEntity() ); }
		set       	{ self.m_hPlayer = EHandle( @value ); }
	}
	private array<string> sledgehammerSounds = {
		CoFSH::SLEDGEHAMMER_SWNG_S,
		CoFSH::SLEDGEHAMMER_HITW_S,
		CoFSH::SLEDGEHAMMER_HITB_S,
		"cof/guns/sledge/grab.ogg"
	};

	void Spawn()
	{
		self.Precache();
		g_EntityFuncs.SetModel( self, self.GetW_Model( CoFSH::SLEDGEHAMMER_W_MODEL ) );
		self.m_iClip    	= -1;
		self.m_flCustomDmg 	= self.pev.dmg;
		m_bUseCustomScale = true;
		self.pev.scale = 1.3;

		self.FallInit();
	}

	void Precache()
	{
		self.PrecacheCustomModels();

		g_Game.PrecacheModel( CoFSH::SLEDGEHAMMER_W_MODEL );
		g_Game.PrecacheModel( CoFSH::SLEDGEHAMMER_V_MODEL );
		g_Game.PrecacheModel( CoFSH::SLEDGEHAMMER_P_MODEL );

		CommonPrecache(); //Common sounds to all weapons
		PrecacheSound( sledgehammerSounds );

		g_Game.PrecacheModel( "sprites/cof/wpn_sel01.spr" );
		g_Game.PrecacheGeneric( "sprites/" + "cof/wpn_sel01.spr" );
		g_Game.PrecacheGeneric( "sprites/" + "cof/melee/weapon_cofsledgehammer.txt" );
	}

	bool GetItemInfo( ItemInfo& out info )
	{
		info.iMaxAmmo1 	= -1;
		info.iMaxAmmo2 	= -1;
		info.iMaxClip 	= WEAPON_NOCLIP;
		info.iSlot   	= CoFSH::SLOT;
		info.iPosition 	= CoFSH::POSITION;
		info.iId     	= g_ItemRegistry.GetIdForName( self.pev.classname );
		info.iWeight 	= CoFSH::SLEDGEHAMMER_WEIGHT;
		return true;
	}

	bool AddToPlayer( CBasePlayer@ pPlayer )
	{
		return CommonAddToPlayer( pPlayer );
	}

	void Materialize()
	{
		BaseClass.Materialize();
		CommonMaterialize();
	}

	bool Deploy()
	{
		bool bResult;
		{
			bResult = Deploy( CoFSH::SLEDGEHAMMER_V_MODEL, CoFSH::SLEDGEHAMMER_P_MODEL, CoFSLEDGEHAMMER_DRAW, "crowbar", 1 );
			DeploySleeve();
			float deployTime = 1.6f;
			self.m_flTimeWeaponIdle = self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = g_Engine.time + deployTime;
			return bResult;
		}
	}

	void Holster( int skipLocal = 0 )
	{
		self.m_fInReload = false;// cancel any reload in progress.
		SetThink( null );
		m_IsPullingBack = false;

		m_pPlayer.pev.viewmodel = string_t();
		BaseClass.Holster( skipLocal );
	}

	void ItemPreFrame()
	{
		if( !m_IsPullingBack )
			m_pPlayer.m_szAnimExtension = "crowbar";

		BaseClass.ItemPreFrame();
	}

	void PrimaryAttack()
	{
		if( !m_IsPullingBack )
		{
			// We don't want the player to break/stop the animation or sequence.
			m_IsPullingBack = true;
			
			// We are pulling back our hammer
			self.SendWeaponAnim( CoFSLEDGEHAMMER_ATTACK, 0, 0 );

			self.m_flTimeWeaponIdle = g_Engine.time + 2.66f;
			// Lets wait for the 'heavy smack'
			SetThink( ThinkFunction( this.DoHeavyAttack ) );
			self.pev.nextthink = g_Engine.time + 0.9f;
		}
	}

	void DoHeavyAttack()
	{
		m_pPlayer.m_szAnimExtension = "wrench";
		/* Params in order
		Distance;
		Attack Speed;
		Damage;
		Animation Timing; (Should be anim frames/fps - initial thinktime)
		Hit Body sounds;
		Hit Wall sounds;
		Damage Bits.
		*/
		HeavySmack( 47, 1.67f, CoFSH::SLEDGEHAMMER_DAMAGE, 2.66f - 0.9f, CoFSH::SLEDGEHAMMER_HITB_S, CoFSH::SLEDGEHAMMER_HITW_S, DMG_CLUB | DMG_ALWAYSGIB );

		g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_ITEM, CoFSH::SLEDGEHAMMER_SWNG_S, 1, ATTN_NORM, 0, 94 + Math.RandomLong( 0,0xF ) );
		m_pPlayer.pev.punchangle.x = Math.RandomLong( 6, 8 );
		g_WeaponFuncs.DecalGunshot( m_trHit, BULLET_PLAYER_CROWBAR );
	}

	void WeaponIdle()
	{
		if( self.m_flTimeWeaponIdle > g_Engine.time )
			return;

		self.SendWeaponAnim( CoFSLEDGEHAMMER_IDLE, 0, 0 );

		self.m_flTimeWeaponIdle = g_Engine.time + g_PlayerFuncs.SharedRandomLong( m_pPlayer.random_seed, 4, 5 );
	}
}

string CoFSLEDGEHAMMERName()
{
	return "weapon_cofsledgehammer";
}

void RegisterCoFSLEDGEHAMMER()
{
	g_CustomEntityFuncs.RegisterCustomEntity( CoFSLEDGEHAMMERName(), CoFSLEDGEHAMMERName() );
	g_ItemRegistry.RegisterWeapon( CoFSLEDGEHAMMERName(), "cof/melee" );
}