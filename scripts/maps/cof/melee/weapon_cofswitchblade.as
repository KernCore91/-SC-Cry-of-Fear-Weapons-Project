// Author: KernCore

#include "../base"

enum CoFSWITCHBLADEAnimations_e
{
	CoFSWITCHBLADE_M1_IDLE = 0,
	CoFSWITCHBLADE_M1_DRAW,
	CoFSWITCHBLADE_M1_HOLSTER,
	CoFSWITCHBLADE_M1_ATTACK1,
	CoFSWITCHBLADE_M1_TO_M2,
	CoFSWITCHBLADE_M2_IDLE,
	CoFSWITCHBLADE_M2_DRAW,
	CoFSWITCHBLADE_M2_HOLSTER,
	CoFSWITCHBLADE_M2_ATTACK1,
	CoFSWITCHBLADE_M2_TO_M1,
	CoFSWITCHBLADE_M1_SPRINT_TO,
	CoFSWITCHBLADE_M1_SPRINT_IDLE,
	CoFSWITCHBLADE_M1_SPRINT_FROM,
	CoFSWITCHBLADE_M2_SPRINT_TO,
	CoFSWITCHBLADE_M2_SPRINT_IDLE,
	CoFSWITCHBLADE_M2_SPRINT_FROM,
	CoFSWITCHBLADE_M1_ATTACK2,
	CoFSWITCHBLADE_M1_ATTACK3,
	CoFSWITCHBLADE_M2_ATTACK2,
	CoFSWITCHBLADE_M2_ATTACK3,
	CoFSWITCHBLADE_M1_FIDGET1,
	CoFSWITCHBLADE_M1_FIDGET2,
	CoFSWITCHBLADE_M1_FIDGET3,
	CoFSWITCHBLADE_M2_FIDGET1,
	CoFSWITCHBLADE_M2_FIDGET2,
	CoFSWITCHBLADE_M2_FIDGET3
};

enum CoFSTABMODE_e
{
	CoF_MODE_SLASH = 0,
	CoF_MODE_STAB
};

namespace CoFSB
{
	// Models
	string SWITCHBLADE_W_MODEL  	= "models/cof/sblade/wld.mdl";
	string SWITCHBLADE_V_MODEL  	= "models/cof/sblade/vwm.mdl";
	string SWITCHBLADE_P_MODEL  	= "models/cof/sblade/wld.mdl";
	// Sounds
	const string SWITCHBLADE_SWING_S	= "cof/guns/sblade/swing.ogg";
	const string SWITCHBLADE_HITB1_S	= "cof/guns/sblade/hitb1.ogg";
	const string SWITCHBLADE_HITB2_S	= "cof/guns/sblade/hitb2.ogg";
	const string SWITCHBLADE_HITW1_S	= "cof/guns/sblade/hitw1.ogg";
	const string SWITCHBLADE_HITW2_S	= "cof/guns/sblade/hitw2.ogg";
	const string SWITCHBLADE_DRAW1_S	= "cof/guns/sblade/draw.ogg";
	const string SWITCHBLADE_DRAW2_S	= "cof/guns/sblade/draw2.ogg";
	//weapon info
	const int SWITCHBLADE_WEIGHT 	= 5;
	uint SWITCHBLADE_DAMAGE1      	= 30; // Slash
	uint SWITCHBLADE_DAMAGE2      	= 45; // Stab
	//iSlot and iPosition in the Hud
	uint SLOT     	= 0;
	uint POSITION 	= 7;
}

class weapon_cofswitchblade : ScriptBasePlayerWeaponEntity, weapon_base
{
	private CBasePlayer@ m_pPlayer
	{
		get const 	{ return cast<CBasePlayer@>( self.m_hPlayer.GetEntity() ); }
		set       	{ self.m_hPlayer = EHandle( @value ); }
	}
	// Weapon funcs
	int g_iMode_stab;
	int m_iSwing;
	private uint SWITCHBLADE_DAMAGE = (g_iMode_stab == CoF_MODE_SLASH) ? CoFSB::SWITCHBLADE_DAMAGE1 : CoFSB::SWITCHBLADE_DAMAGE2;
	TraceResult m_trHit;

	// Other Sounds
	private array<string> switchbladeSounds = {
		CoFSB::SWITCHBLADE_SWING_S,
		CoFSB::SWITCHBLADE_HITB1_S,
		CoFSB::SWITCHBLADE_HITB2_S,
		CoFSB::SWITCHBLADE_HITW1_S,
		CoFSB::SWITCHBLADE_HITW2_S,
		CoFSB::SWITCHBLADE_DRAW1_S,
		CoFSB::SWITCHBLADE_DRAW2_S
	};
	
	void Spawn()
	{
		self.Precache();
		g_EntityFuncs.SetModel( self, self.GetW_Model( CoFSB::SWITCHBLADE_W_MODEL ) );
		self.m_iClip    	= -1;
		self.m_flCustomDmg	= self.pev.dmg;
		g_iMode_stab    	= CoF_MODE_SLASH;
		m_bUseCustomScale = true;
		self.pev.scale = 1.3;

		self.FallInit();
	}
	
	void Precache()
	{
		self.PrecacheCustomModels();

		g_Game.PrecacheModel( CoFSB::SWITCHBLADE_W_MODEL );
		g_Game.PrecacheModel( CoFSB::SWITCHBLADE_V_MODEL );
		g_Game.PrecacheModel( CoFSB::SWITCHBLADE_P_MODEL );

		CommonPrecache(); //Common sounds to all weapons
		PrecacheSound( switchbladeSounds );

		g_Game.PrecacheModel( "sprites/cof/wpn_sel01.spr" );
		g_Game.PrecacheGeneric( "sprites/" + "cof/wpn_sel01.spr" );
		g_Game.PrecacheGeneric( "sprites/" + "cof/melee/weapon_cofswitchblade.txt" );
	}
	
	bool GetItemInfo( ItemInfo& out info )
	{
		info.iMaxAmmo1		= -1;
		info.iMaxAmmo2		= -1;
		info.iMaxClip		= WEAPON_NOCLIP;
		info.iSlot			= CoFSB::SLOT;
		info.iPosition		= CoFSB::POSITION;
		info.iId     	= g_ItemRegistry.GetIdForName( self.pev.classname );
		info.iWeight		= CoFSB::SWITCHBLADE_WEIGHT;
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
			bResult = Deploy( CoFSB::SWITCHBLADE_V_MODEL, CoFSB::SWITCHBLADE_P_MODEL, (g_iMode_stab == CoF_MODE_SLASH) ? CoFSWITCHBLADE_M1_DRAW : CoFSWITCHBLADE_M2_DRAW, "crowbar", 1 );
			g_SoundSystem.EmitSound( m_pPlayer.edict(), CHAN_STATIC, (g_iMode_stab == CoF_MODE_SLASH) ? CoFSB::SWITCHBLADE_DRAW1_S : CoFSB::SWITCHBLADE_DRAW2_S, 1, ATTN_NORM );
			DeploySleeve();
			float deployTime = 1;
			self.m_flTimeWeaponIdle = self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = g_Engine.time + deployTime;
			return bResult;
		}
	}
	
	void WeaponIdle()
	{
		int iAnim;

		if( self.m_flTimeWeaponIdle > g_Engine.time )
			return;
		
		switch( g_PlayerFuncs.SharedRandomLong( m_pPlayer.random_seed, 0, 3 ) )
		{
			case 0:	iAnim = (g_iMode_stab == CoF_MODE_SLASH) ? CoFSWITCHBLADE_M1_FIDGET1 : CoFSWITCHBLADE_M2_FIDGET1;
			break;

			case 1: iAnim = (g_iMode_stab == CoF_MODE_SLASH) ? CoFSWITCHBLADE_M1_FIDGET2 : CoFSWITCHBLADE_M2_FIDGET2;
			break;

			case 2: iAnim = (g_iMode_stab == CoF_MODE_SLASH) ? CoFSWITCHBLADE_M1_FIDGET3 : CoFSWITCHBLADE_M2_FIDGET3;
			break;

			case 3: iAnim = (g_iMode_stab == CoF_MODE_SLASH) ? CoFSWITCHBLADE_M1_IDLE : CoFSWITCHBLADE_M2_IDLE;
			break;
		}

		self.SendWeaponAnim( iAnim, 0, 0 );
		self.m_flTimeWeaponIdle = g_Engine.time + g_PlayerFuncs.SharedRandomLong( m_pPlayer.random_seed, 5, 7 );
	}
	
	void Holster( int skipLocal = 0 )
	{
		self.m_fInReload = false;// cancel any reload in progress.
		m_iSwing = 0;
		SetThink( null );

		m_pPlayer.pev.viewmodel = string_t();
		//g_EngineFuncs.ClientPrintf( m_pPlayer, print_center, m_pPlayer.pev.viewmodel ); Debugg stuff
		BaseClass.Holster( skipLocal );
	}

	void PrimaryAttack()
	{
		if( !Swing( 1 ) )
		{
			SetThink( ThinkFunction( this.SwingAgain ) );
			self.pev.nextthink = g_Engine.time + 0.1;
		}
		// play wiff or swish sound
		g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_ITEM, CoFSB::SWITCHBLADE_SWING_S, 1, ATTN_NORM, 0, 94 + Math.RandomLong( 0,0xF ) );
	}

	void SecondaryAttack()
	{
		self.m_flTimeWeaponIdle = self.m_flNextSecondaryAttack = self.m_flNextPrimaryAttack = WeaponTimeBase() + 1.16f;
		switch( g_iMode_stab )
		{
			case CoF_MODE_SLASH:
			{
				self.SendWeaponAnim( CoFSWITCHBLADE_M1_TO_M2, 0, 0 );
				g_iMode_stab = CoF_MODE_STAB;
				break;
			}
			case CoF_MODE_STAB:
			{
				self.SendWeaponAnim( CoFSWITCHBLADE_M2_TO_M1, 0, 0 );
				g_iMode_stab = CoF_MODE_SLASH;
				break;
			}
		}
	}

	void Smack()
	{
		g_WeaponFuncs.DecalGunshot( m_trHit, BULLET_PLAYER_CROWBAR );
	}
	
	void SwingAgain()
	{
		Swing( 0 );
	}

	bool Swing( int fFirst )
	{
		bool fDidHit = false;
		int iAnim;
		TraceResult tr;

		Math.MakeVectors( m_pPlayer.pev.v_angle );
		Vector vecSrc	= m_pPlayer.GetGunPosition();
		Vector vecEnd	= vecSrc + g_Engine.v_forward * 37;

		g_Utility.TraceLine( vecSrc, vecEnd, dont_ignore_monsters, m_pPlayer.edict(), tr );

		if ( tr.flFraction >= 1.0 )
		{
			g_Utility.TraceHull( vecSrc, vecEnd, dont_ignore_monsters, head_hull, m_pPlayer.edict(), tr );
			if ( tr.flFraction < 1.0 )
			{
				// Calculate the point of intersection of the line (or hull) and the object we hit
				// This is and approximation of the "best" intersection
				CBaseEntity@ pHit = g_EntityFuncs.Instance( tr.pHit );
				if ( pHit is null || pHit.IsBSPModel() )
					g_Utility.FindHullIntersection( vecSrc, tr, tr, VEC_DUCK_HULL_MIN, VEC_DUCK_HULL_MAX, m_pPlayer.edict() );
				vecEnd = tr.vecEndPos;	// This is the point on the actual surface (the hull could have hit space)
			}
		}

		if ( tr.flFraction >= 1.0 )
		{
			if( fFirst != 0 )
			{
				// miss
				switch( g_PlayerFuncs.SharedRandomLong(m_pPlayer.random_seed, 0, 2) )
				{
					case 0: iAnim = (g_iMode_stab == CoF_MODE_SLASH) ? CoFSWITCHBLADE_M1_ATTACK1 : CoFSWITCHBLADE_M2_ATTACK1; break;
					case 1: iAnim = (g_iMode_stab == CoF_MODE_SLASH) ? CoFSWITCHBLADE_M1_ATTACK2 : CoFSWITCHBLADE_M2_ATTACK2; break;
					case 2: iAnim = (g_iMode_stab == CoF_MODE_SLASH) ? CoFSWITCHBLADE_M1_ATTACK3 : CoFSWITCHBLADE_M2_ATTACK3; break;
				}
				self.SendWeaponAnim( iAnim, 0, 0 );
				(g_iMode_stab == CoF_MODE_SLASH) ? m_pPlayer.pev.punchangle.y = Math.RandomLong( -3, -2 ) : m_pPlayer.pev.punchangle.x = Math.RandomLong( 2, 3 );

				self.m_flNextPrimaryAttack = (g_iMode_stab == CoF_MODE_SLASH) ? g_Engine.time + 0.45f : g_Engine.time + 0.70f;
				self.m_flTimeWeaponIdle = self.m_flNextSecondaryAttack = g_Engine.time + 1.0f;

				// player "shoot" animation
				m_pPlayer.SetAnimation( PLAYER_ATTACK1 );
			}
		}
		else
		{
			// hit
			fDidHit = true;
			
			CBaseEntity@ pEntity = g_EntityFuncs.Instance( tr.pHit );

			switch( g_PlayerFuncs.SharedRandomLong(m_pPlayer.random_seed, 0, 2) )
			{
				case 0: iAnim = (g_iMode_stab == CoF_MODE_SLASH) ? CoFSWITCHBLADE_M1_ATTACK1 : CoFSWITCHBLADE_M2_ATTACK1; break;
				case 1: iAnim = (g_iMode_stab == CoF_MODE_SLASH) ? CoFSWITCHBLADE_M1_ATTACK2 : CoFSWITCHBLADE_M2_ATTACK2; break;
				case 2: iAnim = (g_iMode_stab == CoF_MODE_SLASH) ? CoFSWITCHBLADE_M1_ATTACK3 : CoFSWITCHBLADE_M2_ATTACK3; break;
			}
			self.SendWeaponAnim( iAnim, 0, 0 );
			(g_iMode_stab == CoF_MODE_SLASH) ? m_pPlayer.pev.punchangle.y = Math.RandomLong( -3, -2 ) : m_pPlayer.pev.punchangle.x = Math.RandomLong( 2, 3 );
			
			// player "shoot" animation
			m_pPlayer.SetAnimation( PLAYER_ATTACK1 );

			if ( self.m_flCustomDmg > 0 )
				SWITCHBLADE_DAMAGE = uint(self.m_flCustomDmg);

			g_WeaponFuncs.ClearMultiDamage();
			if ( self.m_flNextPrimaryAttack + 0.45 < g_Engine.time )
			{
				// first swing does full damage
				pEntity.TraceAttack( m_pPlayer.pev, SWITCHBLADE_DAMAGE, g_Engine.v_forward, tr, DMG_SLASH );
			}
			else
			{
				// subsequent swings do 75% (Changed -Sniper/kerncore) (Half)
				pEntity.TraceAttack( m_pPlayer.pev, SWITCHBLADE_DAMAGE * 0.75, g_Engine.v_forward, tr, DMG_SLASH | DMG_NEVERGIB );
			}	
			g_WeaponFuncs.ApplyMultiDamage( m_pPlayer.pev, m_pPlayer.pev );

			// play thwack, smack, or dong sound
			float flVol = 1.0;
			bool fHitWorld = true;

			if( pEntity !is null )
			{
				self.m_flNextPrimaryAttack = (g_iMode_stab == CoF_MODE_SLASH) ?  g_Engine.time + 0.45f : g_Engine.time + 0.70f;
				self.m_flTimeWeaponIdle = self.m_flNextSecondaryAttack = g_Engine.time + 1.0f;

				if( pEntity.Classify() != CLASS_NONE && pEntity.Classify() != CLASS_MACHINE && pEntity.BloodColor() != DONT_BLEED )
				{
	// aone
					if( pEntity.IsPlayer() ) // lets pull them
					{
						pEntity.pev.velocity = pEntity.pev.velocity + ( self.pev.origin - pEntity.pev.origin ).Normalize() * 120;
					}
	// end aone
					switch( g_PlayerFuncs.SharedRandomLong(m_pPlayer.random_seed, 0, 1) )
					{
						case 0: g_SoundSystem.EmitSound( m_pPlayer.edict(), CHAN_WEAPON, CoFSB::SWITCHBLADE_HITB1_S, 1, ATTN_NORM ); break;
						case 1: g_SoundSystem.EmitSound( m_pPlayer.edict(), CHAN_WEAPON, CoFSB::SWITCHBLADE_HITB2_S, 1, ATTN_NORM ); break;
					}

					m_pPlayer.m_iWeaponVolume = 128;
					if( !pEntity.IsAlive() )
						return true;
					else
						flVol = 0.1;

					fHitWorld = false;
				}
			}

			// play texture hit sound
			// UNDONE: Calculate the correct point of intersection when we hit with the hull instead of the line

			if( fHitWorld == true )
			{
				float fvolbar = g_SoundSystem.PlayHitSound( tr, vecSrc, vecSrc + (vecEnd - vecSrc) * 2, BULLET_PLAYER_CROWBAR );
				
				(g_iMode_stab == CoF_MODE_SLASH) ? self.m_flNextPrimaryAttack = g_Engine.time + 0.45f : self.m_flNextPrimaryAttack = g_Engine.time + 0.70f;
				self.m_flTimeWeaponIdle = self.m_flNextSecondaryAttack = g_Engine.time + 1.0f;
				// override the volume here, cause we don't play texture sounds in multiplayer, 
				// and fvolbar is going to be 0 from the above call.
				fvolbar = 1;

				switch( g_PlayerFuncs.SharedRandomLong(m_pPlayer.random_seed, 0, 1) )
				{
					case 0: g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, CoFSB::SWITCHBLADE_HITW1_S, fvolbar, ATTN_NORM, 0, 98 + Math.RandomLong( 0, 3 ) ); break;
					case 1: g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, CoFSB::SWITCHBLADE_HITW2_S, fvolbar, ATTN_NORM, 0, 98 + Math.RandomLong( 0, 3 ) ); break;
				} 
			}

			// delay the decal a bit
			m_trHit = tr;
			SetThink( ThinkFunction( this.Smack ) );
			self.pev.nextthink = g_Engine.time + 0.1;

			m_pPlayer.m_iWeaponVolume = int( flVol * 512 ); 
		}
		return fDidHit;
	}
}

string CoFSWITCHBLADEName()
{
	return "weapon_cofswitchblade";
}

void RegisterCoFSWITCHBLADE()
{
	g_CustomEntityFuncs.RegisterCustomEntity( CoFSWITCHBLADEName(), CoFSWITCHBLADEName() );
	g_ItemRegistry.RegisterWeapon( CoFSWITCHBLADEName(), "cof/melee" );
}