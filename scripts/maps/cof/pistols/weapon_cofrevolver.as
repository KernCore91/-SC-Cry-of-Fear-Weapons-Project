// Author: KernCore

#include "../base"

enum CoFREVOLVERAnimations_e
{
	CoFREVOLVER_IDLE = 0,
	CoFREVOLVER_DRAW,
	CoFREVOLVER_HOLSTER,
	CoFREVOLVER_SHOOT1,
	CoFREVOLVER_RELOAD_START,
	CoFREVOLVER_RELOAD_INSERT1,
	CoFREVOLVER_RELOAD_INSERT2,
	CoFREVOLVER_RELOAD_INSERT3,
	CoFREVOLVER_RELOAD_INSERT4,
	CoFREVOLVER_RELOAD_INSERT5,
	CoFREVOLVER_RELOAD_END,
	CoFREVOLVER_SHOOT_NOSHOOT,
	CoFREVOLVER_SPRINT_TO,
	CoFREVOLVER_SPRINT_IDLE,
	CoFREVOLVER_SPRINT_FROM,
	CoFREVOLVER_IRON_TO,
	CoFREVOLVER_IRON_IDLE,
	CoFREVOLVER_IRON_FROM,
	CoFREVOLVER_IRON_SHOOT,
	CoFREVOLVER_IRON_SHOOT_EMPTY,
	CoFREVOLVER_MELEE,
	CoFREVOLVER_SUICIDE
};

enum CoFREVOLVERBodyGroups_e
{
	CoFREVOLVERBG_SHELL0 = 0,
	CoFREVOLVERBG_SHELL1,
	CoFREVOLVERBG_SHELL2,
	CoFREVOLVERBG_SHELL3,
	CoFREVOLVERBG_SHELL4,
	CoFREVOLVERBG_SHELL5
};

namespace CoFREVOLVER
{
	//models
	string REVOLVER_W_MODEL   	= "models/cof/revolver/wrd.mdl";
	string REVOLVER_V_MODEL   	= "models/cof/revolver/vwm.mdl";
	string REVOLVER_P_MODEL   	= "models/cof/revolver/plr.mdl";
	string REVOLVER_A_MODEL   	= "models/cof/revolver/box.mdl";
	//sounds
	const string REVOLVER_SHOOT_SOUND 	= "cof/guns/revolver/shoot.ogg";
	const string REVOLVER_SHOOT_EMPTY 	= "cof/guns/revolver/empty.ogg";
	//weapon information
	const int REVOLVER_MAX_CARRY 	= (p_Customizable) ? 50 : 36;
	const int REVOLVER_MAX_CLIP  	= 5;
	const int REVOLVER_DEFAULT_GIVE	= REVOLVER_MAX_CLIP * 4;
	const int REVOLVER_WEIGHT    	= 5;
	uint REVOLVER_DAMAGE          	= 40;
	//iSlot and iPosition in the Hud
	uint SLOT     	= 1;
	uint POSITION 	= 7;
}

class weapon_cofrevolver : ScriptBasePlayerWeaponEntity, weapon_base
{
	private CBasePlayer@ m_pPlayer
	{
		get const 	{ return cast<CBasePlayer@>( self.m_hPlayer.GetEntity() ); }
		set       	{ self.m_hPlayer = EHandle( @value ); }
	}
	//for weapon functions/modes
	float m_flNextReload;
	bool m_fRevolverReload;
	int m_AmmoCount;
	int iSaveAmmo;

	// Other Sounds
	private array<string> revolverSounds = {
		"cof/guns/revolver/close.ogg",
		"cof/guns/revolver/open.ogg",
		"cof/guns/revolver/insert.ogg",
		"cof/guns/revolver/shell.ogg"
	};

	void Spawn()
	{
		Precache();
		g_EntityFuncs.SetModel( self, CoFREVOLVER::REVOLVER_W_MODEL );

		iAnimation  = CoFREVOLVER_MELEE;
		iAnimation2 = CoFREVOLVER_MELEE;
		m_AmmoCount = CoFREVOLVER::REVOLVER_MAX_CLIP;
		g_iMode_ironsights = CoF_MODE_NOTAIMED;
		iSaveAmmo = 0;
		self.m_iDefaultAmmo = CoFREVOLVER::REVOLVER_DEFAULT_GIVE;

		self.FallInit();
	}

	void Precache()
	{
		self.PrecacheCustomModels();
		g_Game.PrecacheModel( CoFREVOLVER::REVOLVER_W_MODEL );
		g_Game.PrecacheModel( CoFREVOLVER::REVOLVER_V_MODEL );
		g_Game.PrecacheModel( CoFREVOLVER::REVOLVER_P_MODEL );
		g_Game.PrecacheModel( CoFREVOLVER::REVOLVER_A_MODEL );
		g_Game.PrecacheModel( g_watersplash_spr );
		m_iShell = g_Game.PrecacheModel( mShellModel[1] ); //38 special

		CommonPrecache(); //Common sounds to all weapons
		PrecacheSound( revolverSounds );

		g_SoundSystem.PrecacheSound( CoFREVOLVER::REVOLVER_SHOOT_SOUND );
		g_SoundSystem.PrecacheSound( CoFREVOLVER::REVOLVER_SHOOT_EMPTY );
		g_Game.PrecacheGeneric( "sound/" + CoFREVOLVER::REVOLVER_SHOOT_SOUND );
		g_Game.PrecacheGeneric( "sound/" + CoFREVOLVER::REVOLVER_SHOOT_EMPTY );

		g_Game.PrecacheModel( "sprites/cof/wpn_sel03.spr" );
		g_Game.PrecacheGeneric( "sprites/" + "cof/wpn_sel03.spr" );
		g_Game.PrecacheGeneric( "sprites/" + "cof/revolver/weapon_cofrevolver.txt" );
	}

	bool GetItemInfo( ItemInfo& out info )
	{
		info.iMaxAmmo1 	= CoFREVOLVER::REVOLVER_MAX_CARRY;
		info.iMaxAmmo2 	= -1;
		info.iMaxClip 	= CoFREVOLVER::REVOLVER_MAX_CLIP;
		info.iSlot   	= CoFREVOLVER::SLOT;
		info.iPosition 	= CoFREVOLVER::POSITION;
		info.iId     	= g_ItemRegistry.GetIdForName( self.pev.classname );
		info.iFlags  	= ITEM_FLAG_NOAUTORELOAD | ITEM_FLAG_NOAUTOSWITCHEMPTY | ITEM_FLAG_SELECTONEMPTY;
		info.iWeight 	= CoFREVOLVER::REVOLVER_WEIGHT;

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

	int getBodygroup()
	{
		if( m_AmmoCount == 0 )
			return CoFREVOLVERBG_SHELL0;
		else if( m_AmmoCount == 1 )
			return CoFREVOLVERBG_SHELL1;
		else if( m_AmmoCount == 2 )
			return CoFREVOLVERBG_SHELL2;
		else if( m_AmmoCount == 3 )
			return CoFREVOLVERBG_SHELL3;
		else if( m_AmmoCount == 4 )
			return CoFREVOLVERBG_SHELL4;
		else
			return CoFREVOLVERBG_SHELL5;
	}

	bool PlayEmptySound()
	{
		if( self.m_bPlayEmptySound )
		{
			self.m_bPlayEmptySound = false;
			g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_AUTO, CoFREVOLVER::REVOLVER_SHOOT_EMPTY, 0.9, ATTN_NORM, 0, PITCH_NORM );
		}
		return false;
	}

	bool Deploy()
	{
		bool bResult;
		{
			bResult = Deploy( CoFREVOLVER::REVOLVER_V_MODEL, CoFREVOLVER::REVOLVER_P_MODEL, CoFREVOLVER_DRAW, "python", getBodygroup() );
			DeploySleeve();

			float deployTime = 1.0f;
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
		m_fRevolverReload = false;
		EffectsFOVOFF();
		canReload = false;
		SetThink( null );

		BaseClass.Holster( skipLocal );
	}

	void PrimaryAttack()
	{
		if( ( m_pPlayer.m_afButtonPressed & IN_ATTACK == 0 ) )
			return;

		if( self.m_iClip <= 0 || m_pPlayer.pev.waterlevel == WATERLEVEL_HEAD )
		{
			self.PlayEmptySound();
			self.m_flNextPrimaryAttack = WeaponTimeBase() + 0.5f;
			self.SendWeaponAnim( (g_iMode_ironsights == CoF_MODE_AIMED) ? CoFREVOLVER_IRON_SHOOT_EMPTY : CoFREVOLVER_SHOOT_NOSHOOT, 0, getBodygroup() );
			return;
		}

		self.m_flNextPrimaryAttack = WeaponTimeBase() + 0.3;
		self.m_flNextSecondaryAttack = WeaponTimeBase() + 0.2;
		self.m_flNextTertiaryAttack = WeaponTimeBase() + 0.3;

		//Play it before the punchangle, so the accuracy doesn't get screwed
		Vector vecCone;
		if( m_pPlayer.pev.velocity == g_vecZero ) // Player is not moving
		{
			vecCone = (g_iMode_ironsights == CoF_MODE_AIMED) ? g_vecZero : VECTOR_CONE_3DEGREES;
		}
		else if( m_pPlayer.pev.velocity != g_vecZero ) // Player is moving
		{
			vecCone = (g_iMode_ironsights == CoF_MODE_AIMED) ? VECTOR_CONE_1DEGREES : VECTOR_CONE_4DEGREES;
		}

		FireTrueBullet( CoFREVOLVER::REVOLVER_SHOOT_SOUND, false, CoFREVOLVER::REVOLVER_DAMAGE, vecCone, 8192, false, DMG_GENERIC );

		float m_iPunchAngle;
		if( (m_pPlayer.pev.flags & FL_DUCKING != 0) ) // Player is ducking
		{
			m_iPunchAngle = (g_iMode_ironsights == CoF_MODE_AIMED) ? Math.RandomFloat( -4.50f, -3.50f ) : Math.RandomFloat( -5.00f, -3.00f );
		}
		else if( !(m_pPlayer.pev.flags & FL_DUCKING != 0) ) // Player is not ducking
		{
			m_iPunchAngle = (g_iMode_ironsights == CoF_MODE_AIMED) ? Math.RandomFloat( -5.25f, -4.75f ) : Math.RandomFloat( -7.00f, -6.00f );
		}
		punchangle( m_iPunchAngle, Math.RandomFloat( -0.5, 0.5 ), Math.RandomFloat( -0.4, 0.4 ) );
		//AngleRecoil( Math.RandomFloat( -0.5f, -0.1f ), Math.RandomFloat( -0.05f, 0.05f ) );

		if( g_iMode_ironsights == CoF_MODE_AIMED )
		{
			self.SendWeaponAnim( CoFREVOLVER_IRON_SHOOT, 0, getBodygroup() );
		}
		else if( g_iMode_ironsights == CoF_MODE_NOTAIMED )
		{
			self.SendWeaponAnim( CoFREVOLVER_SHOOT1, 0, getBodygroup() );
		}

		if( self.m_iClip != 0 )
			self.m_flTimeWeaponIdle = WeaponTimeBase() + 3.0;
		else
			self.m_flNextPrimaryAttack = self.m_flTimeWeaponIdle = WeaponTimeBase() + 0.2;
	}

	void SecondaryAttack()
	{
		self.m_flTimeWeaponIdle = self.m_flNextSecondaryAttack = WeaponTimeBase() + 0.2;
		self.m_flNextPrimaryAttack = WeaponTimeBase() + 0.13;
		g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_ITEM, CoFCOMMON::DEPLOY_SLEEVE3, 0.9, ATTN_NORM, 0, PITCH_NORM );

		switch( g_iMode_ironsights )
		{
			case CoF_MODE_NOTAIMED:
			{
				self.SendWeaponAnim( CoFREVOLVER_IRON_TO, 0, getBodygroup() );
				EffectsFOVON( 40 );
				break;
			}
			case CoF_MODE_AIMED:
			{
				self.SendWeaponAnim( CoFREVOLVER_IRON_FROM, 0, getBodygroup() );
				EffectsFOVOFF();
				break;
			}
		}
	}

	void ItemPreFrame()
	{
		if( m_reloadTimer < g_Engine.time && canReload )
			self.Reload();

		BaseClass.ItemPreFrame();
	}

	void Reload()
	{
		int iAmmo = m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType );

		if( iAmmo <= 0 || self.m_iClip == CoFREVOLVER::REVOLVER_MAX_CLIP )
			return;

		if( g_iMode_ironsights == CoF_MODE_AIMED )
		{
			self.SendWeaponAnim( CoFREVOLVER_IRON_FROM, 0, getBodygroup() );
			m_reloadTimer = g_Engine.time + 0.2;
			m_pPlayer.m_flNextAttack = 0.2;
			EffectsFOVOFF();
			canReload = true;
		}

		if( m_reloadTimer < g_Engine.time )
		{
			if( m_flNextReload >  WeaponTimeBase() )
				return;

			// don't reload until recoil is done
			if( self.m_flNextPrimaryAttack > WeaponTimeBase() && !m_fRevolverReload )
			{
				m_fRevolverReload = false;
				return;
			}
			// check to see if we're ready to reload
			if( !m_fRevolverReload )
			{
				self.SendWeaponAnim( CoFREVOLVER_RELOAD_START, 0, getBodygroup() );
				canReload = false;
				// Take whatever value m_iClip has, save it and add it to reserve ammo, so no ammo is wasted :D
				m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType, m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType ) + self.m_iClip );
	
				iSaveAmmo = m_AmmoCount; // Also save ammo here for the Think Function
				self.pev.nextthink = WeaponTimeBase() + 1.0f;
				SetThink( ThinkFunction( EjectClipThink ) );
	
				m_pPlayer.m_flNextAttack 	= 1.33;	//Always uses a relative time due to prediction
				self.m_flTimeWeaponIdle     	= WeaponTimeBase() + 1.33;
				self.m_flNextPrimaryAttack  	= WeaponTimeBase() + 1.33;
				self.m_flNextSecondaryAttack 	= WeaponTimeBase() + 1.33;
				self.m_flNextTertiaryAttack 	= WeaponTimeBase() + 1.33;
				m_AmmoCount = 0;
				self.m_iClip = 0;
				m_fRevolverReload = true;
				return;
			}
			else if( m_fRevolverReload )
			{
				if( self.m_flTimeWeaponIdle > WeaponTimeBase() )
					return;

				if( self.m_iClip == CoFREVOLVER::REVOLVER_MAX_CLIP )
				{
					m_fRevolverReload = false;
					return;
				}

				self.SendWeaponAnim( (self.m_iClip < 5) ? CoFREVOLVER_RELOAD_INSERT1 + self.m_iClip : CoFREVOLVER_RELOAD_INSERT5, 0, (m_AmmoCount <= 5) ? CoFREVOLVERBG_SHELL1 + self.m_iClip : CoFREVOLVERBG_SHELL5 );
				// Add Bullets to count the Bodygroups
				m_AmmoCount += 1;
				m_flNextReload              	= WeaponTimeBase() + 0.75;
				self.m_flNextPrimaryAttack  	= self.m_flNextSecondaryAttack = self.m_flNextTertiaryAttack = self.m_flTimeWeaponIdle = WeaponTimeBase() + 0.75;
				
				// Add them to the clip
				self.m_iClip += 1;
				iAmmo -= 1;
			}
		}

		m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType, iAmmo );
		BaseClass.Reload();
	}

	void EjectClipThink()
	{
		Vector vecVelocity = m_pPlayer.pev.view_ofs + g_Engine.v_right * Math.RandomLong( -16, 16 ) + g_Engine.v_up * Math.RandomLong( 16, 32 ) + g_Engine.v_forward * Math.RandomLong( -36, -28 );
		ClipCasting( m_pPlayer.pev.origin, vecVelocity, m_iShell, true, iSaveAmmo );
	}

	void ItemPostFrame()
	{
		// Checks if the player pressed one of the attack buttons, stops the reload and then attack
		if( CheckButton() && m_fRevolverReload && m_flNextReload <= g_Engine.time )
		{
			self.SendWeaponAnim( CoFREVOLVER_RELOAD_END, 0, getBodygroup() );
			self.m_flTimeWeaponIdle = self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = self.m_flNextTertiaryAttack = g_Engine.time + 1.0f;
			m_fRevolverReload = false;
		}
		BaseClass.ItemPostFrame();
	}

	void WeaponIdle()
	{
		self.ResetEmptySound();
		m_pPlayer.GetAutoaimVector( AUTOAIM_10DEGREES );

		if( self.m_flTimeWeaponIdle < g_Engine.time )
		{
			if( self.m_iClip == 0 && !m_fRevolverReload && m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType ) != 0 )
			{
				//self.Reload();
			}
			else if( m_fRevolverReload )
			{
				if( self.m_iClip != CoFREVOLVER::REVOLVER_MAX_CLIP && m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType ) > 0 )
				{
					self.Reload();
				}
				else
				{
					// reload debounce has timed out
					self.SendWeaponAnim( CoFREVOLVER_RELOAD_END, 0, getBodygroup() );

					m_fRevolverReload = false;
					self.m_flTimeWeaponIdle = self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = self.m_flNextTertiaryAttack = g_Engine.time + 1.0f;
				}
			}
			else
			{
				int iAnim;
				switch( g_PlayerFuncs.SharedRandomLong( m_pPlayer.random_seed, 0, 0 ) )
				{
					case 0:
						iAnim = (g_iMode_ironsights == CoF_MODE_AIMED) ? CoFREVOLVER_IRON_IDLE : CoFREVOLVER_IDLE;
						self.m_flTimeWeaponIdle = g_Engine.time + (60.0/12.0);
					break;
				}
				self.SendWeaponAnim( iAnim, 0, getBodygroup() );
			}
		}
	}

	void TertiaryAttack()
	{
		if( !Swing( 1, 37, (m_AmmoCount < 5) ? CoFREVOLVERBG_SHELL0 + m_AmmoCount : CoFREVOLVERBG_SHELL5, 1.0f, 22, false ) )
		{
			SetThink( ThinkFunction( this.SwingAgain ) );
			self.pev.nextthink = g_Engine.time + 0.1;
		}
	}

	void SwingAgain()
	{
		Swing( 0, 37, (m_AmmoCount < 5) ? CoFREVOLVERBG_SHELL0 + m_AmmoCount : CoFREVOLVERBG_SHELL5, 1.0f, 22, false );
	}
}

class Special38 : ScriptBasePlayerAmmoEntity, ammo_base
{
	void Spawn()
	{
		Precache();
		g_EntityFuncs.SetModel( self, CoFREVOLVER::REVOLVER_A_MODEL );
		BaseClass.Spawn();
	}
	
	void Precache()
	{
		g_Game.PrecacheModel( CoFREVOLVER::REVOLVER_A_MODEL );
		g_SoundSystem.PrecacheSound( CoFCOMMON::ITEM_SOUND_PICK );
	}

	bool AddAmmo( CBaseEntity@ pOther )
	{
		return CommonAddAmmo( pOther, CoFREVOLVER::REVOLVER_MAX_CLIP, CoFREVOLVER::REVOLVER_MAX_CARRY, (p_Customizable) ? "ammo_38special" : "357" );
	}
}

string CoFREVOLVERAmmoName()
{
	return "ammo_38special";
}

string CoFREVOLVERName()
{
	return "weapon_cofrevolver";
}

void RegisterCoFREVOLVER()
{
	g_CustomEntityFuncs.RegisterCustomEntity( CoFREVOLVERName(), CoFREVOLVERName() );
	g_CustomEntityFuncs.RegisterCustomEntity( "Special38", CoFREVOLVERAmmoName() );
	g_ItemRegistry.RegisterWeapon( CoFREVOLVERName(), "cof/revolver", (p_Customizable) ? "ammo_38special" : "357", "", CoFREVOLVERAmmoName() );
}