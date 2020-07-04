// Author: KernCore

#include "../base"

enum CoFGLOCK18Animations_e
{
	CoFGLOCK18_IDLE = 0,
	CoFGLOCK18_IDLE_EMPTY,
	CoFGLOCK18_IDLE_IRON,
	CoFGLOCK18_IDLE_EMPTY_IRON,
	CoFGLOCK18_DRAW,
	CoFGLOCK18_DRAW_EMPTY,
	CoFGLOCK18_HOLSTER,
	CoFGLOCK18_HOLSTER_EMPTY,
	CoFGLOCK18_SHOOT1,
	CoFGLOCK18_SHOOT2,
	CoFGLOCK18_SHOOT_LAST,
	CoFGLOCK18_SHOOT_LAST_IRON,
	CoFGLOCK18_SHOOT_IRON,
	CoFGLOCK18_RELOAD,
	CoFGLOCK18_RELOAD_EMPTY,
	CoFGLOCK18_TO_IRON,
	CoFGLOCK18_FROM_IRON,
	CoFGLOCK18_TO_IRON_EMPTY,
	CoFGLOCK18_FROM_IRON_EMPTY,
	CoFGLOCK18_MELEE,
	CoFGLOCK18_MELEE_EMPTY,
	CoFGLOCK18_SEMITOAUTO,
	CoFGLOCK18_SEMITOAUTO_EMPTY,
	CoFGLOCK18_AUTOTOSEMI,
	CoFGLOCK18_AUTOTOSEMI_EMPTY,
	CoFGLOCK18_SEMITOAUTO_IRON,
	CoFGLOCK18_SEMITOAUTO_EMPTY_IRON,
	CoFGLOCK18_AUTOTOSEMI_IRON,
	CoFGLOCK18_AUTOTOSEMI_EMPTY_IRON
};

namespace CoFGLOCK18
{
	//models
	string GLOCK18_W_MODEL      	= "models/cof/glock18/wrd.mdl";
	string GLOCK18_V_MODEL      	= "models/cof/glock18/vwm.mdl";
	string GLOCK18_P_MODEL      	= "models/cof/glock18/plr.mdl";
	string GLOCK18_A_MODEL      	= "models/cof/glock18/mag.mdl";
	string GLOCK18_MAGEMPTY_MODEL	= "models/cof/glock18/mag_e.mdl";
	//sounds
	const string GLOCK18_SHOOT_SOUND 	= "cof/guns/glock18/shoot.ogg";
	//weapon information
	const int GLOCK18_MAX_CARRY  	= (p_Customizable) ? 360 : 250;
	const int GLOCK18_MAX_CLIP   	= 20;
	const int GLOCK18_DEFAULT_GIVE 	= GLOCK18_MAX_CLIP * 2;
	const int GLOCK18_WEIGHT     	= 45;
	uint GLOCK18_DAMAGE           	= 10;
	//iSlot and iPosition in the Hud
	uint SLOT     	= 1;
	uint POSITION 	= 10;
}

class weapon_cofglock18 : ScriptBasePlayerWeaponEntity, weapon_base
{
	private CBasePlayer@ m_pPlayer
	{
		get const 	{ return cast<CBasePlayer@>( self.m_hPlayer.GetEntity() ); }
		set       	{ self.m_hPlayer = EHandle( @value ); }
	}
	//for weapon functions/modes
	int m_iGlock18MagEmpty;
	int mag_counter;
	float e_usetimer;

	// Other Sounds
	private array<string> glock18Sounds = {
		"cof/guns/glock18/rof.ogg",
		"cof/guns/glock18/magin.ogg",
		"cof/guns/glock18/magout.ogg",
		"cof/guns/glock18/magout_e.ogg",
		"cof/guns/glock18/sldrel.ogg"
	};

	private int GetBodygroup()
	{
		if( g_iMode_burst == CoF_MODE_AUTO )
			return 1;
		else
			return 0;
	}

	void Spawn()
	{
		Precache();
		g_EntityFuncs.SetModel( self, CoFGLOCK18::GLOCK18_W_MODEL );
		
		self.m_iDefaultAmmo = CoFGLOCK18::GLOCK18_DEFAULT_GIVE;
		g_iMode_burst = CoF_MODE_SINGLE;
		e_usetimer = 0;
		g_iMode_ironsights = CoF_MODE_NOTAIMED;
		mag_counter = CoFGLOCK18::GLOCK18_MAX_CLIP;

		iAnimation  = CoFGLOCK18_MELEE;
		iAnimation2 = CoFGLOCK18_MELEE_EMPTY;
		
		self.FallInit();
	}
	
	void Precache()
	{
		self.PrecacheCustomModels();
		g_Game.PrecacheModel( CoFGLOCK18::GLOCK18_W_MODEL );
		g_Game.PrecacheModel( CoFGLOCK18::GLOCK18_V_MODEL );
		g_Game.PrecacheModel( CoFGLOCK18::GLOCK18_P_MODEL );
		g_Game.PrecacheModel( CoFGLOCK18::GLOCK18_A_MODEL );

		g_Game.PrecacheModel( g_watersplash_spr );
		m_iGlock18MagEmpty	= g_Game.PrecacheModel( CoFGLOCK18::GLOCK18_MAGEMPTY_MODEL );
		m_iShell         	= g_Game.PrecacheModel( mShellModel[0] ); //9mm

		CommonPrecache(); //Common sounds to all weapons
		PrecacheSound( glock18Sounds );

		g_SoundSystem.PrecacheSound( CoFGLOCK18::GLOCK18_SHOOT_SOUND );
		g_Game.PrecacheGeneric( "sound/" + CoFGLOCK18::GLOCK18_SHOOT_SOUND );

		g_Game.PrecacheModel( "sprites/cof/wpn_sel02.spr" );
		g_Game.PrecacheModel( "sprites/" + CoFCOMMON::FIREMODE_SPRT );

		g_Game.PrecacheGeneric( "sprites/" + CoFCOMMON::FIREMODE_SPRT );
		g_Game.PrecacheGeneric( "sprites/" + "cof/wpn_sel02.spr" );
		g_Game.PrecacheGeneric( "sprites/" + "cof/pistol/weapon_cofglock18.txt" );
	}
	
	bool GetItemInfo( ItemInfo& out info )
	{
		info.iMaxAmmo1 	= CoFGLOCK18::GLOCK18_MAX_CARRY;
		info.iMaxAmmo2 	= -1;
		info.iMaxClip 	= CoFGLOCK18::GLOCK18_MAX_CLIP;
		info.iSlot  	= CoFGLOCK18::SLOT;
		info.iPosition 	= CoFGLOCK18::POSITION;
		info.iId     	= g_ItemRegistry.GetIdForName( self.pev.classname );
		info.iFlags 	= ITEM_FLAG_NOAUTORELOAD | ITEM_FLAG_NOAUTOSWITCHEMPTY | ITEM_FLAG_SELECTONEMPTY;
		info.iWeight 	= CoFGLOCK18::GLOCK18_WEIGHT;

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
		bool bResult;
		{
			DisplayFiremodeSprite();

			bResult = Deploy( CoFGLOCK18::GLOCK18_V_MODEL, CoFGLOCK18::GLOCK18_P_MODEL, (self.m_iClip == 0) ? CoFGLOCK18_DRAW_EMPTY : CoFGLOCK18_DRAW, "onehanded", GetBodygroup() );
			DeploySleeve();

			float deployTime = 0.63f;
			self.m_flTimeWeaponIdle = self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = self.m_flNextTertiaryAttack = e_usetimer = g_Engine.time + deployTime;
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
		self.SendWeaponAnim( CoFGLOCK18_HOLSTER );
		canReload = false;
		SetThink( null );
		FiremodesSpr( FiremodesPos, 0, 0, 0 );

		BaseClass.Holster( skipLocal );
	}
	
	void PrimaryAttack()
	{
		if( self.m_iClip <= 0 )
		{
			self.PlayEmptySound();
			self.m_flNextPrimaryAttack = WeaponTimeBase() + 0.5f;
			return;
		}

		mag_counter--;
		if( g_iMode_burst == CoF_MODE_SINGLE )
		{
			if( ( m_pPlayer.m_afButtonPressed & IN_ATTACK == 0 ) )
				return;
			self.m_flNextPrimaryAttack = (m_pPlayer.pev.waterlevel == WATERLEVEL_HEAD) ? WeaponTimeBase() + 0.2f : WeaponTimeBase() + 0.1f;
		}
		else if( g_iMode_burst == CoF_MODE_AUTO )
		{
			self.m_flNextPrimaryAttack = (m_pPlayer.pev.waterlevel == WATERLEVEL_HEAD) ? WeaponTimeBase() + GetFireRate( 600 ) : WeaponTimeBase() + GetFireRate( 750 );
		}
		
		self.m_flNextSecondaryAttack = WeaponTimeBase() + 0.2f;
		self.m_flNextTertiaryAttack = e_usetimer = WeaponTimeBase() + 0.3f;
		self.m_flTimeWeaponIdle = WeaponTimeBase() + 1.0f;

		//Play it before the punchangle, so the accuracy doesn't get screwed
		Vector vecCone;
		if( m_pPlayer.pev.velocity == g_vecZero ) // Player is not moving
		{
			vecCone = (g_iMode_ironsights == CoF_MODE_AIMED) ? VECTOR_CONE_1DEGREES : VECTOR_CONE_3DEGREES;
		}
		else if( m_pPlayer.pev.velocity != g_vecZero ) // Player is moving
		{
			vecCone = (g_iMode_ironsights == CoF_MODE_AIMED) ? VECTOR_CONE_3DEGREES : VECTOR_CONE_4DEGREES;
		}

		FireTrueBullet( CoFGLOCK18::GLOCK18_SHOOT_SOUND, false, CoFGLOCK18::GLOCK18_DAMAGE, vecCone, (m_pPlayer.pev.waterlevel == WATERLEVEL_HEAD) ? 3072 : 8192, false, DMG_GENERIC );

		float m_iPunchAngle;
		if( (m_pPlayer.pev.flags & FL_DUCKING != 0) ) // Player is ducking
		{
			m_iPunchAngle = (g_iMode_ironsights == CoF_MODE_AIMED) ? Math.RandomFloat( -1.60f, -1.25f ) : Math.RandomFloat( -2.25f, -2.00f );
		}
		else if( !(m_pPlayer.pev.flags & FL_DUCKING != 0) ) // Player is not ducking
		{
			m_iPunchAngle = (g_iMode_ironsights == CoF_MODE_AIMED) ? Math.RandomFloat( -2.60f, -2.25f ) : Math.RandomFloat( -3.00f, -2.75f );
		}
		punchangle( m_iPunchAngle, Math.RandomFloat( -0.5, 0.5 ), Math.RandomFloat( -0.35, 0.35 ) );

		if( g_iMode_ironsights == CoF_MODE_AIMED )
		{
			self.SendWeaponAnim( (self.m_iClip > 0) ? CoFGLOCK18_SHOOT_IRON : CoFGLOCK18_SHOOT_LAST_IRON, 0, GetBodygroup() );
		}
		else if( g_iMode_ironsights == CoF_MODE_NOTAIMED )
		{
			self.SendWeaponAnim( (self.m_iClip > 0) ? CoFGLOCK18_SHOOT1 + Math.RandomLong( 0, 1 ) : CoFGLOCK18_SHOOT_LAST, 0, GetBodygroup() );
		}

		Vector vecShellVelocity, vecShellOrigin;

		if( g_iMode_ironsights == CoF_MODE_NOTAIMED )
			CoFGetDefaultShellInfo( m_pPlayer, vecShellVelocity, vecShellOrigin, 24.55, 5, -7, false, false );
		else
			CoFGetDefaultShellInfo( m_pPlayer, vecShellVelocity, vecShellOrigin, 24.55, 0.5, -1.5, false, false );

		vecShellVelocity.y *= 1;
		g_EntityFuncs.EjectBrass( vecShellOrigin, vecShellVelocity, m_pPlayer.pev.angles[ 1 ], m_iShell, TE_BOUNCE_SHELL );
	}

	void SecondaryAttack()
	{	
		self.m_flTimeWeaponIdle = self.m_flNextSecondaryAttack = e_usetimer = WeaponTimeBase() + 0.2;
		self.m_flNextPrimaryAttack = WeaponTimeBase() + 0.13;

		switch( g_iMode_ironsights )
		{
			case CoF_MODE_NOTAIMED:
			{
				self.SendWeaponAnim( (self.m_iClip > 0) ? CoFGLOCK18_TO_IRON : CoFGLOCK18_TO_IRON_EMPTY, 0, GetBodygroup() );
				EffectsFOVON( 45 );
				break;
			}
			case CoF_MODE_AIMED:
			{
				self.SendWeaponAnim( (self.m_iClip > 0) ? CoFGLOCK18_FROM_IRON : CoFGLOCK18_FROM_IRON_EMPTY, 0, GetBodygroup() );
				EffectsFOVOFF();
				break;
			}
		}
		g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_ITEM, CoFCOMMON::DEPLOY_SLEEVE3, 0.9, ATTN_NORM, 0, PITCH_NORM );
	}

	void TertiaryAttack()
	{
		if( !Swing( 1, 37, GetBodygroup(), 1.0f, 22, false ) )
		{
			SetThink( ThinkFunction(this.SwingAgain) );
			self.pev.nextthink = g_Engine.time + 0.1;
		}
	}

	void SwingAgain()
	{
		Swing( 0, 37, GetBodygroup(), 1.0f, 22, false );
	}

	void ChangeFirerate() // switch fire modes (support for only 2 modes)
	{
		if( m_pPlayer.pev.button & IN_USE == 0 || m_pPlayer.pev.button & IN_RELOAD == 0 )
			return;
		else if( (m_pPlayer.pev.button & IN_USE != 0) && (m_pPlayer.pev.button & IN_RELOAD != 0) )
		{
			if( e_usetimer < g_Engine.time )
			{
				if( g_iMode_burst == CoF_MODE_SINGLE )
				{
					if( g_iMode_ironsights == CoF_MODE_NOTAIMED )
						self.SendWeaponAnim( (self.m_iClip > 0) ? CoFGLOCK18_SEMITOAUTO : CoFGLOCK18_SEMITOAUTO_EMPTY, 0, 0 );
					else
						self.SendWeaponAnim( (self.m_iClip > 0) ? CoFGLOCK18_SEMITOAUTO_IRON : CoFGLOCK18_SEMITOAUTO_EMPTY_IRON, 0, 0 );

					g_iMode_burst = CoF_MODE_AUTO;
				}
				else if( g_iMode_burst == CoF_MODE_AUTO )
				{
					if( g_iMode_ironsights == CoF_MODE_NOTAIMED )
						self.SendWeaponAnim( (self.m_iClip > 0) ? CoFGLOCK18_AUTOTOSEMI : CoFGLOCK18_AUTOTOSEMI_EMPTY, 0, 0 );
					else
						self.SendWeaponAnim( (self.m_iClip > 0) ? CoFGLOCK18_AUTOTOSEMI_IRON : CoFGLOCK18_AUTOTOSEMI_EMPTY_IRON, 0, 0 );

					g_iMode_burst = CoF_MODE_SINGLE;
				}
				DisplayFiremodeSprite();
				e_usetimer = g_Engine.time + 0.5f;
				m_pPlayer.m_flNextAttack = 0.5f;
				self.m_flTimeWeaponIdle = self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = self.m_flNextTertiaryAttack = WeaponTimeBase() + 0.6f;
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
		ChangeFirerate();

		if( self.m_iClip == CoFGLOCK18::GLOCK18_MAX_CLIP || m_pPlayer.m_rgAmmo(self.m_iPrimaryAmmoType) <= 0 || m_pPlayer.pev.button & IN_USE != 0 )
			return;
			
		if( g_iMode_ironsights == CoF_MODE_AIMED )
		{
			self.SendWeaponAnim( (self.m_iClip > 0) ? CoFGLOCK18_FROM_IRON : CoFGLOCK18_FROM_IRON_EMPTY, 0, GetBodygroup() );
			m_reloadTimer = g_Engine.time + 0.2;
			m_pPlayer.m_flNextAttack = 0.2;
			canReload = true;
		}
		EffectsFOVOFF();

		if( m_reloadTimer < g_Engine.time )
		{
			(self.m_iClip == 0) ? Reload( CoFGLOCK18::GLOCK18_MAX_CLIP, CoFGLOCK18_RELOAD_EMPTY, 3.3f, GetBodygroup() ) : Reload( CoFGLOCK18::GLOCK18_MAX_CLIP, CoFGLOCK18_RELOAD, 2.93f, GetBodygroup() );
			canReload = false;
		}
		
		if( mag_counter <= 0 )
		{
			self.pev.nextthink = WeaponTimeBase() + 0.6f;
			SetThink( ThinkFunction( EjectClipThink ) );
		}

		BaseClass.Reload();
	}

	void EjectClipThink()
	{
		mag_counter = CoFGLOCK18::GLOCK18_MAX_CLIP;
		ClipCasting( m_pPlayer.pev.origin, m_pPlayer.pev.view_ofs + g_Engine.v_right * 8 + g_Engine.v_up * 16 + g_Engine.v_forward * 16, m_iGlock18MagEmpty, false, 0 );
	}
	
	void WeaponIdle()
	{
		if( m_iDroppedClip == 1 )
		{
			m_iDroppedClip = 0;
		}

		self.ResetEmptySound();
		m_pPlayer.GetAutoaimVector( AUTOAIM_10DEGREES );
		
		if( self.m_flTimeWeaponIdle > WeaponTimeBase() )
			return;

		int iAnim;

		if( g_iMode_ironsights == CoF_MODE_AIMED )
		{
			self.SendWeaponAnim( (self.m_iClip > 0) ? CoFGLOCK18_IDLE_IRON : CoFGLOCK18_IDLE_EMPTY_IRON, 0, GetBodygroup() );
		}
		else if( g_iMode_ironsights == CoF_MODE_NOTAIMED )
		{
			self.SendWeaponAnim( (self.m_iClip > 0) ? CoFGLOCK18_IDLE : CoFGLOCK18_IDLE_EMPTY, 0, GetBodygroup() );
		}

		self.m_flTimeWeaponIdle = WeaponTimeBase() + g_PlayerFuncs.SharedRandomFloat( m_pPlayer.random_seed,  5, 7 );
	}
}

class Parabellum9mm_GLOCK18 : ScriptBasePlayerAmmoEntity, ammo_base
{
	void Spawn()
	{
		Precache();
		g_EntityFuncs.SetModel( self, CoFGLOCK18::GLOCK18_A_MODEL );
		BaseClass.Spawn();
	}
	
	void Precache()
	{
		g_Game.PrecacheModel( CoFGLOCK18::GLOCK18_A_MODEL );
		g_SoundSystem.PrecacheSound( CoFCOMMON::ITEM_SOUND_PICK );
	}

	bool AddAmmo( CBaseEntity@ pOther )
	{
		return CommonAddAmmo( pOther, CoFGLOCK18::GLOCK18_MAX_CLIP, CoFGLOCK18::GLOCK18_MAX_CARRY, (p_Customizable) ? "ammo_9mmpara" : "9mm" );
	}
}

string CoFGLOCK18AmmoName()
{
	return "ammo_9mm_glock18";
}

string CoFGLOCK18Name()
{
	return "weapon_cofglock18";
}

void RegisterCoFGLOCK18()
{
	g_CustomEntityFuncs.RegisterCustomEntity( CoFGLOCK18Name(), CoFGLOCK18Name() );
	g_CustomEntityFuncs.RegisterCustomEntity( "Parabellum9mm_GLOCK18", CoFGLOCK18AmmoName() );
	g_ItemRegistry.RegisterWeapon( CoFGLOCK18Name(), "cof/pistol", (p_Customizable) ? "ammo_9mmpara" : "9mm", "", CoFGLOCK18AmmoName() );
}