// Author: KernCore

#include "../base"

enum CoFHAMMERAnimations_e
{
	CoFHAMMER_IDLE = 0,
	CoFHAMMER_FIDGET,
	CoFHAMMER_DRAW_FIRST,
	CoFHAMMER_DRAW,
	CoFHAMMER_HOLSTER,
	CoFHAMMER_ATTACK1,
	CoFHAMMER_ATTACK2,
	CoFHAMMER_BIGA_WIND,
	CoFHAMMER_BIGA_LOOP,
	CoFHAMMER_BIGA_MISS,
	CoFHAMMER_BIGA_HIT
};

namespace CoFHAMMER
{
	// Models
	string HAMMER_W_MODEL	= "models/cof/hammer/wld.mdl";
	string HAMMER_V_MODEL	= "models/cof/hammer/vwm.mdl";
	string HAMMER_P_MODEL	= "models/cof/hammer/wld.mdl";
	// Sounds
	const string HAMMER_SWING_S	= "cof/guns/hammer/swing.ogg";
	const string HAMMER_HIT1_S	= "cof/guns/hammer/hit1.ogg";
	const string HAMMER_HIT2_S	= "cof/guns/hammer/hit2.ogg";
	//weapon info
	const int HAMMER_WEIGHT	= 5;
	uint HAMMER_DAMAGE    	= 35; // Swing
	//iSlot and iPosition in the Hud
	uint SLOT     	= 0;
	uint POSITION 	= 8;
}

class weapon_cofhammer : ScriptBasePlayerWeaponEntity, weapon_base
{
	private CBasePlayer@ m_pPlayer
	{
		get const 	{ return cast<CBasePlayer@>( self.m_hPlayer.GetEntity() ); }
		set       	{ self.m_hPlayer = EHandle( @value ); }
	}
	// Weapon funcs
	bool m_WasDrawn;
	private float m_flBigSwingStart;
	private int m_iSwingMode;
	private bool isPullingBack;
	private int m_iSwing;

	private array<string> hammerSounds = {
		CoFHAMMER::HAMMER_SWING_S,
		CoFHAMMER::HAMMER_HIT1_S,
		CoFHAMMER::HAMMER_HIT2_S
	};

	void Spawn()
	{
		self.Precache();
		g_EntityFuncs.SetModel( self, self.GetW_Model( CoFHAMMER::HAMMER_W_MODEL ) );
		self.m_iClip = -1;
		m_WasDrawn = false;
		m_iSwingMode = 0;
		m_bUseCustomScale = true;
		self.pev.scale = 1.3;

		self.FallInit();
	}

	void Precache()
	{
		self.PrecacheCustomModels();

		g_Game.PrecacheModel( CoFHAMMER::HAMMER_W_MODEL );
		g_Game.PrecacheModel( CoFHAMMER::HAMMER_V_MODEL );
		g_Game.PrecacheModel( CoFHAMMER::HAMMER_P_MODEL );

		CommonPrecache(); //Common sounds to all weapons
		PrecacheSound( hammerSounds );

		g_Game.PrecacheModel( "sprites/cof/wpn_sel01.spr" );
		g_Game.PrecacheGeneric( "sprites/" + "cof/wpn_sel01.spr" );
		g_Game.PrecacheGeneric( "sprites/" + "cof/melee/weapon_cofhammer.txt" );
	}

	bool GetItemInfo( ItemInfo& out info )
	{
		info.iMaxAmmo1 	= -1;
		info.iMaxAmmo2 	= -1;
		info.iMaxClip 	= WEAPON_NOCLIP;
		info.iSlot    	= CoFHAMMER::SLOT;
		info.iPosition 	= CoFHAMMER::POSITION;
		info.iId     	= g_ItemRegistry.GetIdForName( self.pev.classname );
		info.iWeight  	= CoFHAMMER::HAMMER_WEIGHT;
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
				bResult = Deploy( CoFHAMMER::HAMMER_V_MODEL, CoFHAMMER::HAMMER_P_MODEL, CoFHAMMER_DRAW_FIRST, "crowbar", 1 );
				deployTime = 3.0f;
				m_WasDrawn = true;
			}
			else if( m_WasDrawn == true )
			{
				bResult = Deploy( CoFHAMMER::HAMMER_V_MODEL, CoFHAMMER::HAMMER_P_MODEL, CoFHAMMER_DRAW, "crowbar", 1 );
				deployTime = 0.75f;
			}

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
		int iAnim;
		switch( ( m_iSwing++ ) % 2 )
		{
			case 0: iAnim = CoFHAMMER_ATTACK1; break;
			case 1: iAnim = CoFHAMMER_ATTACK2; break;
		}
		self.SendWeaponAnim( iAnim, 0, 0 );
		self.m_flTimeWeaponIdle = g_Engine.time + 1.0f;
		// Lets wait for the 'heavy smack'
		SetThink( ThinkFunction( this.DoLightAttack ) );
		self.pev.nextthink = g_Engine.time + 0.325f;
		self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = WeaponTimeBase() + 0.75f;
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
		Damage Bits;
		Extra function: Repair friendly machinery
		*/
		HeavySmack( 37.5, 0.47f, CoFHAMMER::HAMMER_DAMAGE, 1.00 - 0.325f, CoFHAMMER::HAMMER_HIT1_S, CoFHAMMER::HAMMER_HIT1_S, DMG_CLUB | DMG_NEVERGIB, true );
		g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_ITEM, CoFHAMMER::HAMMER_SWING_S, 1, ATTN_NORM, 0, 94 + Math.RandomLong( 0,0xF ) );

		g_WeaponFuncs.DecalGunshot( g_Utility.GetGlobalTrace(), BULLET_PLAYER_CROWBAR );
		m_pPlayer.pev.punchangle.x = Math.RandomLong( 2, 4 );
	}

	void SecondaryAttack()
	{
		if( m_iSwingMode != 1 )
		{
			self.SendWeaponAnim( CoFHAMMER_BIGA_WIND, 0, 0 );
			m_flBigSwingStart = g_Engine.time;
			self.m_flTimeWeaponIdle = self.m_flNextSecondaryAttack = self.m_flNextPrimaryAttack = WeaponTimeBase() + 0.85;
			m_iSwingMode = 1;
			isPullingBack = true;
		}
		if( isPullingBack == true && self.m_flTimeWeaponIdle <= g_Engine.time )
		{
			// Manually set wrench windup loop animation
			m_pPlayer.m_Activity = ACT_RELOAD;
			m_pPlayer.pev.frame = 0;
			m_pPlayer.pev.sequence = 26;
			m_pPlayer.ResetSequenceInfo();
			self.m_flNextSecondaryAttack = g_Engine.time + 2.0f;
			self.SendWeaponAnim( CoFHAMMER_BIGA_LOOP, 0, 0 );
		}

		m_iSwingMode = 1;
	}

	private bool BigSwing()
	{
		bool fDidHit = false;

		TraceResult tr;
		Math.MakeVectors( m_pPlayer.pev.v_angle );
		Vector vecSrc	= m_pPlayer.GetGunPosition();
		Vector vecEnd	= vecSrc + g_Engine.v_forward * 35;

		g_Utility.TraceLine( vecSrc, vecEnd, dont_ignore_monsters, m_pPlayer.edict(), tr );
		if( tr.flFraction >= 1.0 )
		{
			g_Utility.TraceHull( vecSrc, vecEnd, dont_ignore_monsters, head_hull, m_pPlayer.edict(), tr );
			if( tr.flFraction < 1.0 )
			{
				EHandle hHit = g_EntityFuncs.Instance( tr.pHit );
				if( hHit.GetEntity() is null || hHit.GetEntity().IsBSPModel() )
					g_Utility.FindHullIntersection( vecSrc, tr, tr, VEC_DUCK_HULL_MIN, VEC_DUCK_HULL_MAX, m_pPlayer.edict() );

				vecEnd = tr.vecEndPos;
			}
		}
		g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_ITEM, CoFHAMMER::HAMMER_SWING_S, 1, ATTN_NORM, 0, 94 + Math.RandomLong( 0,0xF ) );
		m_pPlayer.m_szAnimExtension = "wrench";

		if( tr.flFraction >= 1.0 )
		{
			self.SendWeaponAnim( CoFHAMMER_BIGA_MISS, 0, 0 );
			self.m_flTimeWeaponIdle = self.m_flNextSecondaryAttack = self.m_flNextPrimaryAttack = g_Engine.time + 0.75;
			//Miss
			m_pPlayer.SetAnimation( PLAYER_ATTACK1 );
		}
		else
		{
			//Hit
			fDidHit = true;
			self.SendWeaponAnim( CoFHAMMER_BIGA_HIT, 0, 0 );
			m_pPlayer.SetAnimation( PLAYER_ATTACK1 );
			EHandle hEntity = g_EntityFuncs.Instance( tr.pHit );

			if( hEntity.GetEntity() !is null )
			{
				m_pPlayer.pev.punchangle.x = Math.RandomLong( 4, 6 );
				g_WeaponFuncs.ClearMultiDamage();
				float flDamage = (g_Engine.time - m_flBigSwingStart) * CoFHAMMER::HAMMER_DAMAGE + 25.0f;
				if( self.m_flNextSecondaryAttack + 1 < g_Engine.time )
				{
					hEntity.GetEntity().TraceAttack( m_pPlayer.pev, flDamage, g_Engine.v_forward, tr, DMG_CLUB | DMG_NEVERGIB );
				}
				else
				{
					hEntity.GetEntity().TraceAttack( m_pPlayer.pev, flDamage / 2, g_Engine.v_forward, tr, DMG_CLUB | DMG_NEVERGIB );
				}
				g_WeaponFuncs.ApplyMultiDamage( m_pPlayer.pev, m_pPlayer.pev );
			}

			// play thwack, smack, or dong sound
			float flVol = 1.0;
			bool fHitWorld = true;
			if( hEntity.GetEntity() !is null )
			{
				self.m_flTimeWeaponIdle = self.m_flNextSecondaryAttack = self.m_flNextPrimaryAttack = g_Engine.time + 0.64;
				if( hEntity.GetEntity().Classify() != CLASS_NONE && hEntity.GetEntity().Classify() != CLASS_MACHINE && hEntity.GetEntity().BloodColor() != DONT_BLEED )
				{
					if( hEntity.GetEntity().IsPlayer() ) // lets pull them
					{
						hEntity.GetEntity().pev.velocity = hEntity.GetEntity().pev.velocity + ( self.pev.origin - hEntity.GetEntity().pev.origin ).Normalize() * 120;
					}

					g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, CoFHAMMER::HAMMER_HIT1_S, 1.0, ATTN_NORM, 0, 98 + Math.RandomLong( 0, 3 ) );

					m_pPlayer.m_iWeaponVolume = 128;
					if( !hEntity.GetEntity().IsAlive() )
						return true;
					else
						flVol = 0.1;

					fHitWorld = false;
				}
			}

			if( fHitWorld == true )
			{
				float fvolbar = g_SoundSystem.PlayHitSound( tr, vecSrc, vecSrc + (vecEnd - vecSrc) * 2, BULLET_PLAYER_CROWBAR );

				// override the volume here, cause we don't play texture sounds in multiplayer, 
				// and fvolbar is going to be 0 from the above call.
				fvolbar = 1;
				g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, CoFHAMMER::HAMMER_HIT1_S, fvolbar, ATTN_NORM, 0, 98 + Math.RandomLong( 0, 3 ) );
			}
		}

		m_pPlayer.pev.punchangle.x = Math.RandomLong( 4, 6 );
		g_WeaponFuncs.DecalGunshot( g_Utility.GetGlobalTrace(), BULLET_PLAYER_CROWBAR );
		return fDidHit;
	}

	void WeaponIdle()
	{
		if( self.m_flTimeWeaponIdle > g_Engine.time )
			return;

		if( m_iSwingMode > 0 )
		{
			if( m_iSwingMode == 1 )
			{
				BigSwing();
				m_iSwingMode = 2;
				m_flBigSwingStart = 0;
				isPullingBack = false;
			}
			else
				m_iSwingMode = 0;
		}

		if( m_iSwingMode == 0 )
		{
			m_pPlayer.m_szAnimExtension = "crowbar";
			self.SendWeaponAnim( CoFHAMMER_IDLE + Math.RandomLong( 0, 1 ), 0, 0 );
			self.m_flTimeWeaponIdle = g_Engine.time + g_PlayerFuncs.SharedRandomLong( m_pPlayer.random_seed, 4, 5 );
		}
	}
}

string CoFHAMMERName()
{
	return "weapon_cofhammer";
}

void RegisterCoFHAMMER()
{
	g_CustomEntityFuncs.RegisterCustomEntity( CoFHAMMERName(), CoFHAMMERName() );
	g_ItemRegistry.RegisterWeapon( CoFHAMMERName(), "cof/melee" );
}