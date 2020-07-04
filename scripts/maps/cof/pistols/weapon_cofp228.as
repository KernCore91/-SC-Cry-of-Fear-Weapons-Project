// Author: KernCore

#include "../base"

enum CoFP228Animations_e
{
	CoFP228_IDLE = 0,
	CoFP228_IDLE_EMPTY,
	CoFP228_DRAW,
	CoFP228_DRAW_EMPTY,
	CoFP228_HOLSTER,
	CoFP228_HOLSTER_EMPTY,
	CoFP228_SHOOT1,
	CoFP228_SHOOT2,
	CoFP228_SHOOT_LAST,
	CoFP228_RELOAD,
	CoFP228_RELOAD_EMPTY,
	CoFP228_IDLE_IRON,
	CoFP228_IDLE_EMPTY_IRON,
	CoFP228_SHOOT_IRON,
	CoFP228_SHOOT_LAST_IRON,
	CoFP228_TO_IRON,
	CoFP228_TO_IRON_EMPTY,
	CoFP228_FROM_IRON,
	CoFP228_FROM_IRON_EMPTY,
	CoFP228_MELEE,
	CoFP228_MELEE_EMPTY
};

namespace CoFP228
{
	//models
	string P228_W_MODEL     	= "models/cof/p228/wrd.mdl";
	string P228_V_MODEL     	= "models/cof/p228/vwm.mdl";
	string P228_P_MODEL     	= "models/cof/p228/plr.mdl";
	string P228_A_MODEL     	= "models/cof/p228/mag.mdl";
	string P228_MAGEMPTY_MODEL 	= "models/cof/p228/mag_e.mdl";
	//sounds
	const string P228_SHOOT_SOUND	= "cof/guns/p228/shoot.ogg";
	//weapon information
	const int P228_MAX_CARRY 	= (p_Customizable) ? 360 : 250;
	const int P228_MAX_CLIP  	= 13;
	const int P228_DEFAULT_GIVE	= P228_MAX_CLIP * 2;
	const int P228_WEIGHT    	= 20;
	uint P228_DAMAGE         	= 17;
	//iSlot and iPosition in the Hud
	uint SLOT     	= 1;
	uint POSITION 	= 8;
}

class weapon_cofp228 : ScriptBasePlayerWeaponEntity, weapon_base
{
	private CBasePlayer@ m_pPlayer
	{
		get const 	{ return cast<CBasePlayer@>( self.m_hPlayer.GetEntity() ); }
		set       	{ self.m_hPlayer = EHandle( @value ); }
	}
	//for weapon functions/modes
	int m_iP228MagEmpty;
	int mag_counter;

	// Other Sounds
	private array<string> p228Sounds = {
		"cof/guns/p228/magin.ogg",
		"cof/guns/p228/magin_p.ogg",
		"cof/guns/p228/magout.ogg",
		"cof/guns/p228/magout_e.ogg",
		"cof/guns/p228/sldback.ogg",
		"cof/guns/p228/sldfwrd.ogg"
	};

	void Spawn()
	{
		Precache();
		g_EntityFuncs.SetModel( self, CoFP228::P228_W_MODEL );
		
		self.m_iDefaultAmmo = CoFP228::P228_DEFAULT_GIVE;
		g_iMode_ironsights = CoF_MODE_NOTAIMED;
		mag_counter = CoFP228::P228_MAX_CLIP;

		iAnimation  = CoFP228_MELEE;
		iAnimation2 = CoFP228_MELEE_EMPTY;
		
		self.FallInit();
	}
	
	void Precache()
	{
		self.PrecacheCustomModels();
		g_Game.PrecacheModel( CoFP228::P228_W_MODEL );
		g_Game.PrecacheModel( CoFP228::P228_V_MODEL );
		g_Game.PrecacheModel( CoFP228::P228_P_MODEL );
		g_Game.PrecacheModel( CoFP228::P228_A_MODEL );

		g_Game.PrecacheModel( g_watersplash_spr );
		m_iP228MagEmpty	= g_Game.PrecacheModel( CoFP228::P228_MAGEMPTY_MODEL );
		m_iShell     	= g_Game.PrecacheModel( mShellModel[0] ); //9mm

		CommonPrecache(); //Common sounds to all weapons
		PrecacheSound( p228Sounds );

		g_SoundSystem.PrecacheSound( CoFP228::P228_SHOOT_SOUND );
		g_Game.PrecacheGeneric( "sound/" + CoFP228::P228_SHOOT_SOUND );

		g_Game.PrecacheModel( "sprites/cof/wpn_sel02.spr" );
		g_Game.PrecacheGeneric( "sprites/" + "cof/wpn_sel02.spr" );
		g_Game.PrecacheGeneric( "sprites/" + "cof/pistol/weapon_cofp228.txt" );
	}
	
	bool GetItemInfo( ItemInfo& out info )
	{
		info.iMaxAmmo1 	= CoFP228::P228_MAX_CARRY;
		info.iMaxAmmo2 	= -1;
		info.iMaxClip 	= CoFP228::P228_MAX_CLIP;
		info.iSlot  	= CoFP228::SLOT;
		info.iPosition 	= CoFP228::POSITION;
		info.iId     	= g_ItemRegistry.GetIdForName( self.pev.classname );
		info.iFlags 	= ITEM_FLAG_NOAUTORELOAD | ITEM_FLAG_NOAUTOSWITCHEMPTY | ITEM_FLAG_SELECTONEMPTY;
		info.iWeight 	= CoFP228::P228_WEIGHT;

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
			bResult = Deploy( CoFP228::P228_V_MODEL, CoFP228::P228_P_MODEL, (self.m_iClip == 0) ? CoFP228_DRAW_EMPTY : CoFP228_DRAW, "onehanded", 1 );

			DeploySleeve();
			float deployTime = 0.6f;
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
		self.SendWeaponAnim( CoFP228_HOLSTER );
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
			return;
		}

		mag_counter--;
		self.m_flNextPrimaryAttack = WeaponTimeBase() + 0.127f;
		self.m_flNextSecondaryAttack = WeaponTimeBase() + 0.2f;
		self.m_flNextTertiaryAttack = WeaponTimeBase() + 0.3f;
		self.m_flTimeWeaponIdle = WeaponTimeBase() + 1.0f;

		//Play it before the punchangle, so the accuracy doesn't get screwed
		Vector vecCone;
		if( m_pPlayer.pev.velocity == g_vecZero ) // Player is not moving
		{
			vecCone = (g_iMode_ironsights == CoF_MODE_AIMED) ? VECTOR_CONE_1DEGREES : VECTOR_CONE_3DEGREES;
		}
		else if( m_pPlayer.pev.velocity != g_vecZero ) // Player is moving
		{
			vecCone = (g_iMode_ironsights == CoF_MODE_AIMED) ? VECTOR_CONE_2DEGREES : VECTOR_CONE_4DEGREES;
		}

		FireTrueBullet( CoFP228::P228_SHOOT_SOUND, false, CoFP228::P228_DAMAGE, vecCone, 8192, false, DMG_GENERIC );

		float m_iPunchAngle;
		if( (m_pPlayer.pev.flags & FL_DUCKING != 0) ) // Player is ducking
		{
			m_iPunchAngle = (g_iMode_ironsights == CoF_MODE_AIMED) ? Math.RandomFloat( -1.30f, -1.15f ) : Math.RandomFloat( -2.25f, -2.00f );
		}
		else if( !(m_pPlayer.pev.flags & FL_DUCKING != 0) ) // Player is not ducking
		{
			m_iPunchAngle = (g_iMode_ironsights == CoF_MODE_AIMED) ? Math.RandomFloat( -2.30f, -2.15f ) : Math.RandomFloat( -3.00f, -2.75f );
		}
		punchangle( m_iPunchAngle, Math.RandomFloat( -0.5, 0.5 ), Math.RandomFloat( 0.35, 0.65 ) );

		if( g_iMode_ironsights == CoF_MODE_AIMED )
		{
			self.SendWeaponAnim( (self.m_iClip > 0) ? CoFP228_SHOOT_IRON : CoFP228_SHOOT_LAST_IRON, 0, 1 );
		}
		else if( g_iMode_ironsights == CoF_MODE_NOTAIMED )
		{
			self.SendWeaponAnim( (self.m_iClip > 0) ? CoFP228_SHOOT1 + Math.RandomLong( 0, 1 ) : CoFP228_SHOOT_LAST, 0, 1 );
		}

		Vector vecShellVelocity, vecShellOrigin;

		if( g_iMode_ironsights == CoF_MODE_NOTAIMED )
			CoFGetDefaultShellInfo( m_pPlayer, vecShellVelocity, vecShellOrigin, 24, 4.5, -6, false, false );
		else
			CoFGetDefaultShellInfo( m_pPlayer, vecShellVelocity, vecShellOrigin, 24, 0.5, -1.25, false, false );

		vecShellVelocity.y *= 1;
		g_EntityFuncs.EjectBrass( vecShellOrigin, vecShellVelocity, m_pPlayer.pev.angles[ 1 ], m_iShell, TE_BOUNCE_SHELL );
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
				self.SendWeaponAnim( (self.m_iClip > 0) ? CoFP228_TO_IRON : CoFP228_TO_IRON_EMPTY, 0, 1 );
				EffectsFOVON( 45 );
				break;
			}
			case CoF_MODE_AIMED:
			{
				self.SendWeaponAnim( (self.m_iClip > 0) ? CoFP228_FROM_IRON : CoFP228_FROM_IRON_EMPTY, 0, 1 );
				EffectsFOVOFF();
				break;
			}
		}
	}

	void TertiaryAttack()
	{
		if( !Swing( 1, 37, 1, 1.0f, 22, false ) )
		{
			SetThink( ThinkFunction(this.SwingAgain) );
			self.pev.nextthink = g_Engine.time + 0.1;
		}
	}

	void SwingAgain()
	{
		Swing( 0, 37, 1, 1.0f, 22, false );
	}

	void ItemPreFrame()
	{
		if( m_reloadTimer < g_Engine.time && canReload )
			self.Reload();

		BaseClass.ItemPreFrame();
	}

	void Reload()
	{
		if( self.m_iClip == CoFP228::P228_MAX_CLIP || m_pPlayer.m_rgAmmo(self.m_iPrimaryAmmoType) <= 0 )
			return;
			
		if( g_iMode_ironsights == CoF_MODE_AIMED )
		{
			self.SendWeaponAnim( (self.m_iClip > 0) ? CoFP228_FROM_IRON : CoFP228_FROM_IRON_EMPTY, 0, 1 );
			m_reloadTimer = g_Engine.time + 0.2;
			m_pPlayer.m_flNextAttack = 0.2;
			canReload = true;
		}
		EffectsFOVOFF();

		if( m_reloadTimer < g_Engine.time )
		{
			(self.m_iClip == 0) ? Reload( CoFP228::P228_MAX_CLIP, CoFP228_RELOAD_EMPTY, 2.95f, 1 ) : Reload( CoFP228::P228_MAX_CLIP, CoFP228_RELOAD, 2.17f, 1 );
			canReload = false;
		}
		
		if( mag_counter <= 0 )
		{
			self.pev.nextthink = WeaponTimeBase() + 0.50f;
			SetThink( ThinkFunction( EjectClipThink ) );
		}

		BaseClass.Reload();
	}

	void EjectClipThink()
	{
		mag_counter = CoFP228::P228_MAX_CLIP;
		ClipCasting( m_pPlayer.pev.origin, m_pPlayer.pev.view_ofs + g_Engine.v_right * 8 + g_Engine.v_up * 16 + g_Engine.v_forward * 16, m_iP228MagEmpty, false, 0 );
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
			self.SendWeaponAnim( (self.m_iClip > 0) ? CoFP228_IDLE_IRON : CoFP228_IDLE_EMPTY_IRON, 0, 1 );
		}
		else if( g_iMode_ironsights == CoF_MODE_NOTAIMED )
		{
			self.SendWeaponAnim( (self.m_iClip > 0) ? CoFP228_IDLE : CoFP228_IDLE_EMPTY, 0, 1 );
		}

		self.m_flTimeWeaponIdle = WeaponTimeBase() + g_PlayerFuncs.SharedRandomFloat( m_pPlayer.random_seed,  5, 7 );
	}
}

class Parabellum9mm_P228 : ScriptBasePlayerAmmoEntity, ammo_base
{
	void Spawn()
	{
		Precache();
		g_EntityFuncs.SetModel( self, CoFP228::P228_A_MODEL );
		BaseClass.Spawn();
	}
	
	void Precache()
	{
		g_Game.PrecacheModel( CoFP228::P228_A_MODEL );
		g_SoundSystem.PrecacheSound( CoFCOMMON::ITEM_SOUND_PICK );
	}

	bool AddAmmo( CBaseEntity@ pOther )
	{
		return CommonAddAmmo( pOther, CoFP228::P228_MAX_CLIP, CoFP228::P228_MAX_CARRY, (p_Customizable) ? "ammo_9mmpara" : "9mm" );
	}
}

string CoFP228AmmoName()
{
	return "ammo_9mm_p228";
}

string CoFP228Name()
{
	return "weapon_cofp228";
}

void RegisterCoFP228()
{
	g_CustomEntityFuncs.RegisterCustomEntity( CoFP228Name(), CoFP228Name() );
	g_CustomEntityFuncs.RegisterCustomEntity( "Parabellum9mm_P228", CoFP228AmmoName() );
	g_ItemRegistry.RegisterWeapon( CoFP228Name(), "cof/pistol", (p_Customizable) ? "ammo_9mmpara" : "9mm", "", CoFP228AmmoName() );
}