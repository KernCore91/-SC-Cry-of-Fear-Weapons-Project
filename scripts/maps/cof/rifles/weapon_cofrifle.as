// Author: KernCore

#include "../base"

enum CoFRIFLEAnimations_e
{
	CoFRIFLE_IDLE = 0,
	CoFRIFLE_DRAW,
	CoFRIFLE_HOLSTER,
	CoFRIFLE_SHOOT1,
	CoFRIFLE_RELOAD_START,
	CoFRIFLE_RELOAD_INSERT,
	CoFRIFLE_RELOAD_END,
	CoFRIFLE_SCOPE_TO,
	CoFRIFLE_SCOPE_FROM,
	CoFRIFLE_SPRINT_TO,
	CoFRIFLE_SPRINT_IDLE,
	CoFRIFLE_SPRINT_FROM,
	CoFRIFLE_MELEE,
	CoFRIFLE_ALIGN,
	CoFRIFLE_FIDGET1,
	CoFRIFLE_FIDGET2,
	CoFRIFLE_FIDGET3,
	CoFRIFLE_SUICIDE,
	CoFRIFLE_SHOOT_NOSHOOT,
	CoFRIFLE_DRAW_FIRST,
	CoFRIFLE_JUMP_TO,
	CoFRIFLE_JUMP_FROM
};

enum CoFSCOPEAnimations_e
{
	CoFSCOPE_IDLE = 0,
	CoFSCOPE_SHOOT
};

namespace CoFRIFLE
{
	// Models
	string RIFLE_W_MODEL  	= "models/cof/rifle/wrd.mdl";
	string RIFLE_V_MODEL  	= "models/cof/rifle/vwm.mdl";
	string RIFLE_S_MODEL  	= "models/cof/rifle/scp.mdl";
	string RIFLE_P_MODEL  	= "models/cof/rifle/plr.mdl";
	string RIFLE_A_MODEL  	= "models/cof/rifle/box.mdl";
	// Sounds
	const string RIFLE_SHOOT_SOUND 	= "cof/guns/rifle/shoot.ogg";
	// Weapon info
	const int RIFLE_MAX_CARRY    	= (p_Customizable) ? 50 : 15;
	const int RIFLE_MAX_CLIP     	= 5;
	const int RIFLE_DEFAULT_GIVE 	= RIFLE_MAX_CLIP * 3;
	const int RIFLE_WEIGHT       	= 60;
	uint RIFLE_DAMAGE             	= 40;
	//iSlot and iPosition in the Hud
	uint SLOT     	= 5;
	uint POSITION 	= 7;
}

class weapon_cofrifle : ScriptBasePlayerWeaponEntity, weapon_base
{
	private CBasePlayer@ m_pPlayer
	{
		get const 	{ return cast<CBasePlayer@>( self.m_hPlayer.GetEntity() ); }
		set       	{ self.m_hPlayer = EHandle( @value ); }
	}
	//for weapon functions/modes
	private float m_flNextReload;
	private bool m_fRifleReload, m_WasDrawn;
	Vector vecShellVelocity, vecShellOrigin;

	// Other Sounds
	private array<string> rifleSounds = {
		"cof/guns/rifle/bltback.ogg",
		"cof/guns/rifle/bltfwrd.ogg",
		"cof/guns/rifle/insert.ogg"
	};

	void Spawn()
	{
		Precache();
		g_EntityFuncs.SetModel( self, self.GetW_Model( CoFRIFLE::RIFLE_W_MODEL ) );

		self.m_iDefaultAmmo	= CoFRIFLE::RIFLE_DEFAULT_GIVE;
		g_iMode_ironsights 	= CoF_MODE_NOTAIMED;
		iAnimation      	= CoFRIFLE_MELEE;
		iAnimation2     	= CoFRIFLE_MELEE;
		m_WasDrawn      	= false;

		self.FallInit();
	}

	void Precache()
	{
		self.PrecacheCustomModels();
		g_Game.PrecacheModel( CoFRIFLE::RIFLE_W_MODEL );
		g_Game.PrecacheModel( CoFRIFLE::RIFLE_V_MODEL );
		g_Game.PrecacheModel( CoFRIFLE::RIFLE_S_MODEL );
		g_Game.PrecacheModel( CoFRIFLE::RIFLE_P_MODEL );
		g_Game.PrecacheModel( CoFRIFLE::RIFLE_A_MODEL );

		g_Game.PrecacheModel( g_watersplash_spr );
		m_iShell = g_Game.PrecacheModel( mShellModel[5] ); //303

		CommonPrecache(); //Common sounds to all weapons
		PrecacheSound( rifleSounds );

		g_SoundSystem.PrecacheSound( EMPTY_SHOOT_SOUND );
		g_SoundSystem.PrecacheSound( CoFRIFLE::RIFLE_SHOOT_SOUND );

		g_Game.PrecacheGeneric( "sound/" + EMPTY_SHOOT_SOUND );
		g_Game.PrecacheGeneric( "sound/" + CoFRIFLE::RIFLE_SHOOT_SOUND );

		g_Game.PrecacheModel( "sprites/cof/wpn_sel03.spr" );
		g_Game.PrecacheGeneric( "sprites/" + "cof/wpn_sel03.spr" );
		g_Game.PrecacheGeneric( "sprites/" + "cof/rifle/weapon_cofrifle.txt" );
	}

	bool GetItemInfo( ItemInfo& out info )
	{
		info.iMaxAmmo1 	= CoFRIFLE::RIFLE_MAX_CARRY;
		info.iMaxAmmo2 	= -1;
		info.iMaxClip 	= CoFRIFLE::RIFLE_MAX_CLIP;
		info.iSlot  	= CoFRIFLE::SLOT;
		info.iPosition 	= CoFRIFLE::POSITION;
		info.iId     	= g_ItemRegistry.GetIdForName( self.pev.classname );
		info.iFlags 	= ITEM_FLAG_NOAUTORELOAD | ITEM_FLAG_NOAUTOSWITCHEMPTY | ITEM_FLAG_SELECTONEMPTY;
		info.iWeight 	= CoFRIFLE::RIFLE_WEIGHT;

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

	bool PlayEmptySound()
	{
		if( self.m_bPlayEmptySound )
		{
			self.m_bPlayEmptySound = false;
			g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_AUTO, EMPTY_SHOOT_SOUND, 0.9, ATTN_NORM, 0, PITCH_NORM );
		}
		return false;
	}

	bool Deploy()
	{
		float deployTime;
		bool bResult;
		{
			if( m_WasDrawn == false )
			{
				bResult = Deploy( CoFRIFLE::RIFLE_V_MODEL, CoFRIFLE::RIFLE_P_MODEL, CoFRIFLE_DRAW_FIRST, "sniper", 1 );
				deployTime = 2.2f;
				m_WasDrawn = true;
			}
			else if( m_WasDrawn == true )
			{
				bResult = Deploy( CoFRIFLE::RIFLE_V_MODEL, CoFRIFLE::RIFLE_P_MODEL, CoFRIFLE_DRAW, "sniper", 1 );
				deployTime = 1;
			}

			DeploySleeve();

			self.m_flTimeWeaponIdle = self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = self.m_flNextTertiaryAttack = g_Engine.time + deployTime;
			return bResult;
		}
	}

	bool CanDeploy()
	{
		return true;
	}

	void Holster( int skipLocal = 0 )
	{
		self.m_fInReload = false;
		EffectsFOVOFF();

		SetThink( null );
		canReload = false;
		
		m_fRifleReload = false;
		BaseClass.Holster( skipLocal );
	}

	void PrimaryAttack()
	{
		if( ( m_pPlayer.m_afButtonPressed & IN_ATTACK == 0 ) )
			return;

		if( m_pPlayer.pev.waterlevel == WATERLEVEL_HEAD || self.m_iClip <= 0 )
		{
			self.PlayEmptySound();
			self.m_flNextPrimaryAttack = WeaponTimeBase() + 0.5f;
			self.SendWeaponAnim( CoFRIFLE_SHOOT_NOSHOOT, 0, 1 );
			return;
		}

		self.m_flNextPrimaryAttack = WeaponTimeBase() + 1.3f;
		self.m_flNextSecondaryAttack = WeaponTimeBase() + 1.0f;
		self.m_flTimeWeaponIdle = WeaponTimeBase() + 1.6f;

		if( g_iMode_ironsights == CoF_MODE_AIMED )
		{
			self.SendWeaponAnim( CoFSCOPE_SHOOT, 0, 0 );
		}
		else if( g_iMode_ironsights == CoF_MODE_NOTAIMED )
		{
			self.SendWeaponAnim( CoFRIFLE_SHOOT1, 0, 0 );
		}

		//self.m_flNextPrimaryAttack = self.m_flNextPrimaryAttack + 0.15f;
		if( self.m_flNextPrimaryAttack < WeaponTimeBase() )
			self.m_flNextPrimaryAttack = WeaponTimeBase() + 0.15f;

		//Play it before the punchangle, so the accuracy doesn't get screwed
		Vector vecCone;
		if( m_pPlayer.pev.velocity == g_vecZero ) // Player is not moving
		{
			vecCone = (g_iMode_ironsights == CoF_MODE_AIMED) ? g_vecZero : VECTOR_CONE_1DEGREES;
		}
		else if( m_pPlayer.pev.velocity != g_vecZero ) // Player is moving
		{
			vecCone = (g_iMode_ironsights == CoF_MODE_AIMED) ? VECTOR_CONE_2DEGREES : VECTOR_CONE_5DEGREES;
		}

		FireTrueBullet( CoFRIFLE::RIFLE_SHOOT_SOUND, true, CoFRIFLE::RIFLE_DAMAGE, vecCone, 16384, true, DMG_SNIPER | DMG_NEVERGIB );

		float m_iPunchAngle;
		if( (m_pPlayer.pev.flags & FL_DUCKING != 0) ) // Player is ducking
		{
			m_iPunchAngle = (g_iMode_ironsights == CoF_MODE_AIMED) ? Math.RandomLong( -4, -3 ) : Math.RandomLong( -6, -4 );
		}
		else if( !(m_pPlayer.pev.flags & FL_DUCKING != 0) ) // Player is not ducking
		{
			m_iPunchAngle = (g_iMode_ironsights == CoF_MODE_AIMED) ? Math.RandomLong( -5, -4 ) : Math.RandomLong( -8, -6 );
		}
		punchangle( m_iPunchAngle, Math.RandomLong( -1, 1 ), Math.RandomLong( -2, 2 ) );

		//AngleRecoil( Math.RandomLong( -3, -1 ), Math.RandomLong( -1, 1 ) );

		SetThink( ThinkFunction( EjectThink ) );
		self.pev.nextthink = WeaponTimeBase() + 0.83;
	}

	void SightThink()
	{
		EffectsFOVON( 19 );
		m_pPlayer.m_szAnimExtension = "sniperscope";
		m_pPlayer.pev.viewmodel = CoFRIFLE::RIFLE_S_MODEL;
	}

	void SecondaryAttack()
	{
		self.m_flNextSecondaryAttack = self.m_flNextPrimaryAttack = WeaponTimeBase() + 0.5;
		self.m_flTimeWeaponIdle = WeaponTimeBase() + 1.6f;
		g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_ITEM, CoFCOMMON::DEPLOY_SLEEVE3, 0.9, ATTN_NORM, 0, PITCH_NORM );

		switch( g_iMode_ironsights )
		{
			case CoF_MODE_NOTAIMED:
			{
				self.SendWeaponAnim( CoFRIFLE_SCOPE_TO, 0, 0 );
				SetThink( ThinkFunction( SightThink ) );
				self.pev.nextthink = WeaponTimeBase() + 0.4f;
				break;
			}
			case CoF_MODE_AIMED:
			{
				self.SendWeaponAnim( CoFRIFLE_SCOPE_FROM, 0, 0 );
				EffectsFOVOFF();
				m_pPlayer.pev.viewmodel = CoFRIFLE::RIFLE_V_MODEL;
				m_pPlayer.m_szAnimExtension = "sniper";
				break;
			}
		}
	}

	void Reload()
	{
		int iAmmo = m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType );

		if( iAmmo <= 0 || self.m_iClip == CoFRIFLE::RIFLE_MAX_CLIP )
			return;

		if( g_iMode_ironsights == CoF_MODE_AIMED )
		{
			m_pPlayer.pev.viewmodel = CoFRIFLE::RIFLE_V_MODEL;
			m_pPlayer.m_szAnimExtension = "sniper";
			self.SendWeaponAnim( CoFRIFLE_SCOPE_FROM, 0, 0 );
			m_reloadTimer = g_Engine.time + 0.5;
			m_pPlayer.m_flNextAttack = 0.5;
			EffectsFOVOFF();
			canReload = true;
		}

		if( m_reloadTimer < g_Engine.time )
		{
			if( m_flNextReload >  WeaponTimeBase() )
				return;

			// don't reload until recoil is done
			if( self.m_flNextPrimaryAttack > WeaponTimeBase() && !m_fRifleReload )
			{
				m_fRifleReload = false;
				return;
			}
			if( !m_fRifleReload )
			{
				self.SendWeaponAnim( CoFRIFLE_RELOAD_START, 0, 0 );
				canReload = false;
				// Take one bullet from the chamber, if the magazine is not 0, and save it in the ammo reserve
				if( self.m_iClip != 0 )
				{
					self.m_iClip -= 1;
					m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType, m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType ) + 1 );
					self.pev.nextthink = WeaponTimeBase() + 0.5;
					SetThink( ThinkFunction( EjectThink ) );
				}
				m_pPlayer.m_flNextAttack 	= 0.499;	//Always uses a relative time due to prediction
				self.m_flTimeWeaponIdle     	= WeaponTimeBase() + 0.6;
				self.m_flNextPrimaryAttack  	= WeaponTimeBase() + 0.6;
				self.m_flNextSecondaryAttack 	= WeaponTimeBase() + 0.6;
				self.m_flNextTertiaryAttack 	= WeaponTimeBase() + 0.6;

				m_fRifleReload = true;
				return;
			}
			else if( m_fRifleReload )
			{
				if( self.m_flTimeWeaponIdle > WeaponTimeBase() )
					return;

				if( self.m_iClip == CoFRIFLE::RIFLE_MAX_CLIP )
				{
					m_fRifleReload = false;
					return;
				}

				self.SendWeaponAnim( CoFRIFLE_RELOAD_INSERT, 0, 0 );
				m_flNextReload = WeaponTimeBase() + 0.78;
				self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = self.m_flNextTertiaryAttack = self.m_flTimeWeaponIdle = WeaponTimeBase() + 0.78;

				self.m_iClip += 1;
				iAmmo -= 1;
			}
		}
		m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType, iAmmo );
		BaseClass.Reload();
	}

	void ItemPreFrame()
	{
		CoFGetDefaultShellInfo( m_pPlayer, vecShellVelocity, vecShellOrigin, 15, 3, -6, false, false );
		vecShellVelocity.y *= 1;

		if( m_reloadTimer < g_Engine.time && canReload )
			self.Reload();
		
		BaseClass.ItemPreFrame();
	}

	void ItemPostFrame()
	{
		// Checks if the player pressed one of the attack buttons, stops the reload and then attack
		if( CheckButton() && m_fRifleReload && m_flNextReload <= g_Engine.time )
		{
			self.SendWeaponAnim( CoFRIFLE_RELOAD_END, 0, 0 );
			self.m_flTimeWeaponIdle = self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = self.m_flNextTertiaryAttack = g_Engine.time + 0.6f;
			m_fRifleReload = false;
		}
		BaseClass.ItemPostFrame();
	}

	void TertiaryAttack()
	{
		m_pPlayer.m_szAnimExtension = "sniper";
		m_pPlayer.pev.viewmodel = CoFRIFLE::RIFLE_V_MODEL;

		if( !Swing( 1, 37, 1, 1.16f, 23, true ) )
		{
			SetThink( ThinkFunction( this.SwingAgain ) );
			self.pev.nextthink = g_Engine.time + 0.1;
		}
	}

	void SwingAgain()
	{
		Swing( 0, 37, 1, 1.16f, 23, true );
	}

	void EjectThink()
	{
		g_EntityFuncs.EjectBrass( vecShellOrigin, vecShellVelocity, m_pPlayer.pev.angles[ 1 ], m_iShell, TE_BOUNCE_SHELL );
	}

	void WeaponIdle()
	{
		self.ResetEmptySound();
		m_pPlayer.GetAutoaimVector( AUTOAIM_10DEGREES );

		if( self.m_flTimeWeaponIdle < g_Engine.time )
		{
			if( self.m_iClip == 0 && !m_fRifleReload && m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType ) != 0 )
			{
				//self.Reload();
			}
			else if( m_fRifleReload )
			{
				if( self.m_iClip != CoFRIFLE::RIFLE_MAX_CLIP && m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType ) > 0 )
				{
					self.Reload();
				}
				else
				{
					// reload debounce has timed out
					self.SendWeaponAnim( CoFRIFLE_RELOAD_END, 0, 0 );

					m_fRifleReload = false;
					self.m_flTimeWeaponIdle = self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = self.m_flNextTertiaryAttack = g_Engine.time + 0.6;
				}
			}
			else
			{
				int iAnim;
				if( g_iMode_ironsights == CoF_MODE_NOTAIMED )
				{
					switch( g_PlayerFuncs.SharedRandomLong( m_pPlayer.random_seed, 0, 3 ) )
					{
						case 0: iAnim = CoFRIFLE_IDLE;
						self.m_flTimeWeaponIdle = WeaponTimeBase() + (60.0/12.0);
						break;
	
						case 1: iAnim = CoFRIFLE_FIDGET1;
						self.m_flTimeWeaponIdle = WeaponTimeBase() + (20.0/9.0);
						break;
	
						case 2: iAnim = CoFRIFLE_FIDGET2;
						self.m_flTimeWeaponIdle = WeaponTimeBase() + (20.0/9.0);
						break;
	
						case 3: iAnim = CoFRIFLE_FIDGET3;
						self.m_flTimeWeaponIdle = WeaponTimeBase() + (20.0/9.0);
						break;
					}
				}
				else if( g_iMode_ironsights == CoF_MODE_AIMED )
				{
					iAnim = CoFSCOPE_IDLE;
					self.m_flTimeWeaponIdle = WeaponTimeBase() + (20.0/9.0);
				}
				self.SendWeaponAnim( iAnim, 0, 0 );
			}
		}
	}
}

class British303 : ScriptBasePlayerAmmoEntity, ammo_base
{
	void Spawn()
	{
		Precache();
		g_EntityFuncs.SetModel( self, CoFRIFLE::RIFLE_A_MODEL );
		BaseClass.Spawn();
	}
	
	void Precache()
	{
		g_Game.PrecacheModel( CoFRIFLE::RIFLE_A_MODEL );
		g_SoundSystem.PrecacheSound( CoFCOMMON::ITEM_SOUND_PICK );
	}

	bool AddAmmo( CBaseEntity@ pOther )
	{
		return CommonAddAmmo( pOther, CoFRIFLE::RIFLE_MAX_CLIP, CoFRIFLE::RIFLE_MAX_CARRY, (p_Customizable) ? "ammo_303british" : "m40a1" );
	}
}

string CoFRIFLEAmmoName()
{
	return "ammo_303british";
}

string CoFRIFLEName()
{
	return "weapon_cofrifle";
}

void RegisterCoFRIFLE()
{
	g_CustomEntityFuncs.RegisterCustomEntity( CoFRIFLEName(), CoFRIFLEName() );
	g_CustomEntityFuncs.RegisterCustomEntity( "British303", CoFRIFLEAmmoName() );
	g_ItemRegistry.RegisterWeapon( CoFRIFLEName(), "cof/rifle", (p_Customizable) ? "ammo_303british" : "m40a1", "", CoFRIFLEAmmoName() );
}