// Author: KernCore

#include "../base"

enum CoFAXEAnimations_e
{
	CoFAXE_DRAW = 0,
	CoFAXE_IDLE,
	CoFAXE_ATTACK,
	CoFAXE_HOLSTER,
	CoFAXE_SPRINT_TO,
	CoFAXE_SPRINT_IDLE,
	CoFAXE_SPRINT_FROM
};

namespace CoFAXE
{
	// Models
	string AXE_W_MODEL  	= "models/cof/axe/wld.mdl";
	string AXE_V_MODEL  	= "models/cof/axe/vwm.mdl";
	string AXE_P_MODEL  	= "models/cof/axe/wld.mdl";
	// Sounds
	const string AXE_S_HIT  	= "cof/guns/axe/hitw.ogg";
	const string AXE_S_HITBD	= "cof/guns/axe/hitb.ogg";
	const string AXE_S_SWNG 	= "cof/guns/axe/swing.ogg";
	//weapon info
	const int AXE_WEIGHT 	= 20;
	uint AXE_DAMAGE     	= 115;
	//iSlot and iPosition in the Hud
	uint SLOT     	= 0;
	uint POSITION 	= 13;
}

class weapon_cofaxe : ScriptBasePlayerWeaponEntity, weapon_base
{
	private CBasePlayer@ m_pPlayer
	{
		get const 	{ return cast<CBasePlayer@>( self.m_hPlayer.GetEntity() ); }
		set       	{ self.m_hPlayer = EHandle( @value ); }
	}
	TraceResult m_trHit;

	// Other Sounds
	private array<string> axeSounds = {
		CoFAXE::AXE_S_HIT,
		CoFAXE::AXE_S_HITBD,
		CoFAXE::AXE_S_SWNG
	};

	void Spawn()
	{
		self.Precache();
		g_EntityFuncs.SetModel( self, self.GetW_Model( CoFAXE::AXE_W_MODEL ) );
		self.m_iClip    	= -1;
		self.m_flCustomDmg	= self.pev.dmg;
		m_bUseCustomScale = true;
		self.pev.scale = 1.3;

		self.FallInit();
	}
	
	void Precache()
	{
		self.PrecacheCustomModels();
		g_Game.PrecacheModel( CoFAXE::AXE_W_MODEL );
		g_Game.PrecacheModel( CoFAXE::AXE_V_MODEL );
		g_Game.PrecacheModel( CoFAXE::AXE_P_MODEL );

		CommonPrecache(); //Common sounds to all weapons
		PrecacheSound( axeSounds );

		g_Game.PrecacheModel( "sprites/cof/wpn_sel01.spr" );
		g_Game.PrecacheGeneric( "sprites/" + "cof/wpn_sel01.spr" );
		g_Game.PrecacheGeneric( "sprites/" + "cof/melee/weapon_cofaxe.txt" );
	}

	bool GetItemInfo( ItemInfo& out info )
	{
		info.iMaxAmmo1	= -1;
		info.iMaxAmmo2	= -1;
		info.iMaxClip	= WEAPON_NOCLIP;
		info.iSlot  	= CoFAXE::SLOT;
		info.iPosition	= CoFAXE::POSITION;
		info.iId     	= g_ItemRegistry.GetIdForName( self.pev.classname );
		info.iWeight	= CoFAXE::AXE_WEIGHT;
		return true;
	}

	bool Deploy()
	{
		bool bResult;
		{
			bResult = Deploy( CoFAXE::AXE_V_MODEL, CoFAXE::AXE_P_MODEL, CoFAXE_DRAW, "crowbar", 1 );
			DeploySleeve();
			float deployTime = 0.83f;
			self.m_flTimeWeaponIdle = self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = g_Engine.time + deployTime;
			return bResult;
		}
	}

	void WeaponIdle()
	{
		if( self.m_flTimeWeaponIdle > g_Engine.time )
			return;

		self.SendWeaponAnim( CoFAXE_IDLE, 0, 0 );
		self.m_flTimeWeaponIdle = g_Engine.time + g_PlayerFuncs.SharedRandomLong( m_pPlayer.random_seed, 4, 5 );
	}

	void Holster( int skipLocal = 0 )
	{
		self.m_fInReload = false;

		// This doesn't actually work, but someday it might
		self.SendWeaponAnim( CoFAXE_HOLSTER, 0, 0 );

		SetThink( null );
		m_IsPullingBack = false;

		BaseClass.Holster( skipLocal );
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
			self.SendWeaponAnim( CoFAXE_ATTACK, 0, 0 );
			//self.m_flNextPrimaryAttack = g_Engine.time + 0.9f;
			self.m_flTimeWeaponIdle = g_Engine.time + 1.0f;

			// Lets wait for the 'heavy smack'
			SetThink( ThinkFunction( this.DoHeavyAttack ) );
			self.pev.nextthink = g_Engine.time + 0.25f;
		}
	}

	void DoHeavyAttack()
	{
		m_pPlayer.m_szAnimExtension = "wrench";
		/* Params in order
		Distance;
		Attack Speed;
		Damage;
		Animation Timing;
		Hit Body sounds;
		Hit Wall sounds;
		Damage Bits.
		*/
		HeavySmack( 46.25, 0.7f, CoFAXE::AXE_DAMAGE, 1.0f - 0.25f, CoFAXE::AXE_S_HITBD, CoFAXE::AXE_S_HIT, DMG_CLUB | DMG_SLASH );
		g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_ITEM, CoFAXE::AXE_S_SWNG, 1, ATTN_NORM, 0, 94 + Math.RandomLong( 0,0xF ) );

		m_pPlayer.pev.punchangle.x = Math.RandomLong( 5, 6 );
		g_WeaponFuncs.DecalGunshot( m_trHit, BULLET_PLAYER_CROWBAR );
	}
}

string CoFAXEName()
{
	return "weapon_cofaxe";
}

void RegisterCoFAXE()
{
	g_CustomEntityFuncs.RegisterCustomEntity( CoFAXEName(), CoFAXEName() );
	g_ItemRegistry.RegisterWeapon( CoFAXEName(), "cof/melee" );
}