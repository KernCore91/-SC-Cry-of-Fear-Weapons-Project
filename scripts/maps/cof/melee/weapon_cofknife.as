// Author: KernCore

#include "../base"

enum CoFKNIFEAnimations_e
{
	CoFKNIFE_IDLE = 0,
	CoFKNIFE_OVERHEAD,
	CoFKNIFE_SLASH1,
	CoFKNIFE_SLASH2,
	CoFKNIFE_DRAW_FIRST,
	CoFKNIFE_DRAW,
	CoFKNIFE_HOLSTER
};

namespace CoFKNIFE
{
	// Models
	string KNIFE_W_MODEL	= "models/cof/knife/wld.mdl";
	string KNIFE_V_MODEL	= "models/cof/knife/vwm.mdl";
	string KNIFE_P_MODEL	= "models/cof/knife/wld.mdl";
	// Sounds
	const string KNIFE_SWING_S	= "cof/guns/sblade/swing.ogg";
	//weapon info
	const int KNIFE_WEIGHT 	= 5;
	uint KNIFE_DAMAGE1    	= 25; // Slash
	uint KNIFE_DAMAGE2    	= KNIFE_DAMAGE1 * 2; // Powerfull slash
	//iSlot and iPosition in the Hud
	uint SLOT     	= 0;
	uint POSITION 	= 6;
}

class weapon_cofknife : ScriptBasePlayerWeaponEntity, weapon_base
{
	private CBasePlayer@ m_pPlayer
	{
		get const 	{ return cast<CBasePlayer@>( self.m_hPlayer.GetEntity() ); }
		set       	{ self.m_hPlayer = EHandle( @value ); }
	}
	// Weapon funcs
	bool m_WasDrawn;
	private array<string> knifeSounds = {
		"cof/guns/knife/hitb1.ogg",
		"cof/guns/knife/hitb2.ogg",
		"cof/guns/knife/hitb3.ogg",
		"cof/guns/knife/hitb4.ogg",
		"cof/guns/knife/hitw1.ogg",
		"cof/guns/knife/hitw2.ogg",
		"cof/guns/knife/hitw3.ogg",
		"cof/guns/knife/hitw4.ogg"
	};

	void Spawn()
	{
		self.Precache();
		g_EntityFuncs.SetModel( self, self.GetW_Model( CoFKNIFE::KNIFE_W_MODEL ) );
		self.m_iClip    	= -1;
		self.m_flCustomDmg	= self.pev.dmg;
		m_WasDrawn = false;
		m_bUseCustomScale = true;
		self.pev.scale = 1.3;

		self.FallInit();
	}
	
	void Precache()
	{
		self.PrecacheCustomModels();

		g_Game.PrecacheModel( CoFKNIFE::KNIFE_W_MODEL );
		g_Game.PrecacheModel( CoFKNIFE::KNIFE_V_MODEL );
		g_Game.PrecacheModel( CoFKNIFE::KNIFE_P_MODEL );

		CommonPrecache(); //Common sounds to all weapons
		PrecacheSound( knifeSounds );

		g_SoundSystem.PrecacheSound( CoFKNIFE::KNIFE_SWING_S );
		g_Game.PrecacheGeneric( "sound/" + CoFKNIFE::KNIFE_SWING_S );

		g_Game.PrecacheModel( "sprites/cof/wpn_sel01.spr" );
		g_Game.PrecacheGeneric( "sprites/" + "cof/wpn_sel01.spr" );
		g_Game.PrecacheGeneric( "sprites/" + "cof/melee/weapon_cofknife.txt" );
	}

	bool GetItemInfo( ItemInfo& out info )
	{
		info.iMaxAmmo1 	= -1;
		info.iMaxAmmo2 	= -1;
		info.iMaxClip 	= WEAPON_NOCLIP;
		info.iSlot    	= CoFKNIFE::SLOT;
		info.iPosition 	= CoFKNIFE::POSITION;
		info.iId     	= g_ItemRegistry.GetIdForName( self.pev.classname );
		info.iWeight  	= CoFKNIFE::KNIFE_WEIGHT;
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
			float deployTime;
			if( m_WasDrawn == false )
			{
				bResult = Deploy( CoFKNIFE::KNIFE_V_MODEL, CoFKNIFE::KNIFE_P_MODEL, CoFKNIFE_DRAW_FIRST, "crowbar", 1 );
				deployTime = 1.0f;
				m_WasDrawn = true;
			}
			else if( m_WasDrawn == true )
			{
				bResult = Deploy( CoFKNIFE::KNIFE_V_MODEL, CoFKNIFE::KNIFE_P_MODEL, CoFKNIFE_DRAW, "crowbar", 1 );
				deployTime = 0.85f;
			}

			bResult = Deploy( CoFKNIFE::KNIFE_V_MODEL, CoFKNIFE::KNIFE_P_MODEL, CoFKNIFE_DRAW, "crowbar", 0 );

			DeploySleeve();
			self.m_flTimeWeaponIdle = self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = g_Engine.time + deployTime;
			return bResult;
		}
	}

	void Holster( int skipLocal = 0 )
	{
		self.m_fInReload = false;// cancel any reload in progress.
		SetThink( null );

		m_pPlayer.pev.viewmodel = string_t();
		BaseClass.Holster( skipLocal );
	}

	void PrimaryAttack()
	{
		self.SendWeaponAnim( CoFKNIFE_SLASH1 + Math.RandomLong( 0, 1 ), 0, 0 );
		self.m_flTimeWeaponIdle = g_Engine.time + 1.0f;
		// Lets wait for the 'heavy smack'
		SetThink( ThinkFunction( this.DoLightAttack ) );
		self.pev.nextthink = g_Engine.time + 0.125f;
		self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = WeaponTimeBase() + 0.75f;
	}

	private string HitBodySounds()
	{
		string msz_Snd;
		switch( Math.RandomLong( 0, 3 ) )
		{
			case 0: msz_Snd = "cof/guns/knife/hitb1.ogg";
				break;
			case 1: msz_Snd = "cof/guns/knife/hitb2.ogg";
				break;
			case 2: msz_Snd = "cof/guns/knife/hitb3.ogg";
				break;
			case 3: msz_Snd = "cof/guns/knife/hitb4.ogg";
				break;
		}
		return msz_Snd;
	}

	private string HitWallSounds()
	{
		string msz_Snd;
		switch( Math.RandomLong( 0, 3 ) )
		{
			case 0: msz_Snd = "cof/guns/knife/hitw1.ogg";
				break;
			case 1: msz_Snd = "cof/guns/knife/hitw2.ogg";
				break;
			case 2: msz_Snd = "cof/guns/knife/hitw3.ogg";
				break;
			case 3: msz_Snd = "cof/guns/knife/hitw4.ogg";
				break;
		}
		return msz_Snd;
	}

	void DoLightAttack()
	{
		/* Params in order
		Distance;
		Attack Speed;
		Damage;
		Animation Timing;
		Hit Body sounds;
		Hit Wall sounds;
		Damage Bits.
		*/
		HeavySmack( 45, 0.37f, CoFKNIFE::KNIFE_DAMAGE1, 0.75 - 0.125f, HitBodySounds(), HitWallSounds(), DMG_SLASH | DMG_NEVERGIB );
		g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_ITEM, CoFKNIFE::KNIFE_SWING_S, 1, ATTN_NORM, 0, 94 + Math.RandomLong( 0,0xF ) );

		m_pPlayer.pev.punchangle.y = Math.RandomLong( 2, 4 );
		g_WeaponFuncs.DecalGunshot( m_trHit, BULLET_PLAYER_CROWBAR );
	}

	void SecondaryAttack()
	{
		self.SendWeaponAnim( CoFKNIFE_OVERHEAD, 0, 0 );
		self.m_flTimeWeaponIdle = g_Engine.time + 1.0f;
		// Lets wait for the 'heavy smack'
		SetThink( ThinkFunction( this.DoHeavyAttack ) );
		self.pev.nextthink = g_Engine.time + 0.125f;
		self.m_flNextSecondaryAttack = self.m_flNextPrimaryAttack = WeaponTimeBase() + 1.0f;
	}

	void DoHeavyAttack()
	{
		HeavySmack( 37, 0.60f, CoFKNIFE::KNIFE_DAMAGE2, 0.75 - 0.125f, HitBodySounds(), HitWallSounds(), DMG_SLASH | DMG_NEVERGIB );
		g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_ITEM, CoFKNIFE::KNIFE_SWING_S, 1, ATTN_NORM, 0, 94 + Math.RandomLong( 0,0xF ) );

		m_pPlayer.pev.punchangle.y = Math.RandomLong( 2, 4 );
		m_pPlayer.pev.punchangle.x -= Math.RandomLong( 2, 4 );
		g_WeaponFuncs.DecalGunshot( m_trHit, BULLET_PLAYER_CROWBAR );
	}
	
	void WeaponIdle()
	{
		if( self.m_flTimeWeaponIdle > g_Engine.time )
			return;

		self.SendWeaponAnim( CoFKNIFE_IDLE, 0, 0 );
		self.m_flTimeWeaponIdle = g_Engine.time + g_PlayerFuncs.SharedRandomLong( m_pPlayer.random_seed, 12, 13 );
	}
}

string CoFKNIFEName()
{
	return "weapon_cofknife";
}

void RegisterCoFKNIFE()
{
	g_CustomEntityFuncs.RegisterCustomEntity( CoFKNIFEName(), CoFKNIFEName() );
	g_ItemRegistry.RegisterWeapon( CoFKNIFEName(), "cof/melee" );
}