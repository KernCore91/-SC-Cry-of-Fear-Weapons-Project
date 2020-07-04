// Author: KernCore

#include "../base"

enum CoFMP5KAnimations_e
{
	CoFMP5K_IDLE = 0,
	CoFMP5K_DRAW_FIRST,
	CoFMP5K_DRAW,
	CoFMP5K_HOLSTER,
	CoFMP5K_SHOOT1,
	CoFMP5K_SHOOT_EMPTY,
	CoFMP5K_RELOAD,
	CoFMP5K_RELOAD_EMPTY,
	CoFMP5K_IRON_IDLE,
	CoFMP5K_IRON_SHOOT,
	CoFMP5K_IRON_SHOOT_EMPTY,
	CoFMP5K_IRON_TO,
	CoFMP5K_IRON_FROM,
	CoFMP5K_MELEE
};

namespace CoFMP5K
{
	//models
	string MP5K_W_MODEL     	= "models/cof/mp5k/wrd.mdl";
	string MP5K_V_MODEL     	= "models/cof/mp5k/vwm.mdl";
	string MP5K_P_MODEL     	= "models/cof/mp5k/plr.mdl";
	string MP5K_A_MODEL     	= "models/cof/mp5k/mag.mdl";
	string MP5K_MAGEMPTY_MODEL 	= "models/cof/mp5k/mag_e.mdl";
	//sounds
	const string MP5K_SHOOT_SOUND 	= "cof/guns/mp5k/shoot.ogg";
	//weapon info
	const int MP5K_MAX_CARRY 	= (p_Customizable) ? 360 : 250;
	const int MP5K_MAX_CLIP  	= 30;
	const int MP5K_DEFAULT_GIVE	= MP5K_MAX_CLIP * 2;
	const int MP5K_WEIGHT    	= 15;
	uint MP5K_DAMAGE          	= 13;
	//iSlot and iPosition in the Hud
	uint SLOT     	= 2;
	uint POSITION 	= 7;
}

class weapon_cofmp5k : ScriptBasePlayerWeaponEntity, weapon_base
{
	private CBasePlayer@ m_pPlayer
	{
		get const 	{ return cast<CBasePlayer@>( self.m_hPlayer.GetEntity() ); }
		set       	{ self.m_hPlayer = EHandle( @value ); }
	}
	//for weapon functions/modes
	private int m_iMp5MagEmpty, mag_counter;
	bool m_WasDrawn;

	// Other Sounds
	private array<string> mp5kSounds = {
		"cof/guns/mp5k/bltback.ogg",
		"cof/guns/mp5k/bltlock.ogg",
		"cof/guns/mp5k/bltrel.ogg",
		"cof/guns/mp5k/magin.ogg",
		"cof/guns/mp5k/magout.ogg",
		"cof/guns/mp5k/magrel.ogg"
	};

	void Spawn()
	{
		Precache();
		g_EntityFuncs.SetModel( self, CoFMP5K::MP5K_W_MODEL );

		iAnimation  = CoFMP5K_MELEE;
		iAnimation2 = CoFMP5K_MELEE;
		self.m_iDefaultAmmo = CoFMP5K::MP5K_DEFAULT_GIVE;
		g_iMode_ironsights  = CoF_MODE_NOTAIMED;
		mag_counter = CoFMP5K::MP5K_MAX_CLIP;
		m_WasDrawn = false;

		self.FallInit();
	}

	void Precache()
	{
		self.PrecacheCustomModels();
		g_Game.PrecacheModel( CoFMP5K::MP5K_W_MODEL );
		g_Game.PrecacheModel( CoFMP5K::MP5K_V_MODEL );
		g_Game.PrecacheModel( CoFMP5K::MP5K_P_MODEL );
		g_Game.PrecacheModel( CoFMP5K::MP5K_A_MODEL );

		g_Game.PrecacheModel( g_watersplash_spr );
		m_iMp5MagEmpty	= g_Game.PrecacheModel( CoFMP5K::MP5K_MAGEMPTY_MODEL );
		m_iShell    	= g_Game.PrecacheModel( mShellModel[0] ); //9mm

		CommonPrecache(); //Common sounds to all weapons

		PrecacheSound( mp5kSounds );

		g_SoundSystem.PrecacheSound( CoFMP5K::MP5K_SHOOT_SOUND );
		g_SoundSystem.PrecacheSound( EMPTY_SHOOT_SOUND );
		g_Game.PrecacheGeneric( "sound/" + CoFMP5K::MP5K_SHOOT_SOUND );
		g_Game.PrecacheGeneric( "sound/" + EMPTY_SHOOT_SOUND );

		g_Game.PrecacheModel( "sprites/cof/wpn_sel02.spr" );
		g_Game.PrecacheGeneric( "events/" + "muzzle_cofMP5.txt" );
		g_Game.PrecacheGeneric( "sprites/" + "cof/wpn_sel02.spr" );
		g_Game.PrecacheGeneric( "sprites/" + "cof/smg/weapon_cofmp5k.txt" );
	}

	bool GetItemInfo( ItemInfo& out info )
	{
		info.iMaxAmmo1 	= CoFMP5K::MP5K_MAX_CARRY;
		info.iMaxAmmo2 	= -1;
		info.iMaxClip 	= CoFMP5K::MP5K_MAX_CLIP;
		info.iSlot  	= CoFMP5K::SLOT;
		info.iPosition 	= CoFMP5K::POSITION;
		info.iId     	= g_ItemRegistry.GetIdForName( self.pev.classname );
		info.iFlags 	= ITEM_FLAG_NOAUTORELOAD | ITEM_FLAG_NOAUTOSWITCHEMPTY | ITEM_FLAG_SELECTONEMPTY;
		info.iWeight 	= CoFMP5K::MP5K_WEIGHT;

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
			float deployTime;
			if( m_WasDrawn == false )
			{
				bResult = Deploy( CoFMP5K::MP5K_V_MODEL, CoFMP5K::MP5K_P_MODEL, CoFMP5K_DRAW_FIRST, "mp5", 0 );
				deployTime = 1.4f;
				m_WasDrawn = true;
			}
			else if( m_WasDrawn == true )
			{
				bResult = Deploy( CoFMP5K::MP5K_V_MODEL, CoFMP5K::MP5K_P_MODEL, CoFMP5K_DRAW, "mp5", 0 );
				deployTime = 0.64f;
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

		BaseClass.Holster( skipLocal );
	}

	void PrimaryAttack()
	{
		if( m_pPlayer.pev.waterlevel == WATERLEVEL_HEAD || self.m_iClip <= 0 )
		{
			if( ( m_pPlayer.m_afButtonPressed & IN_ATTACK == 0 ) )
				return;

			self.PlayEmptySound();
			self.m_flNextPrimaryAttack = WeaponTimeBase() + 0.43f;
			self.SendWeaponAnim( (g_iMode_ironsights == CoF_MODE_NOTAIMED) ? CoFMP5K_SHOOT_EMPTY : CoFMP5K_IRON_SHOOT_EMPTY, 0, 0 );
			return;
		}
		
		mag_counter--;
		self.m_flNextPrimaryAttack = WeaponTimeBase() + GetFireRate( 900 );
		self.m_flNextSecondaryAttack = WeaponTimeBase() + 0.15;
		self.m_flNextTertiaryAttack = WeaponTimeBase() + 0.2;
		self.m_flTimeWeaponIdle = WeaponTimeBase() + 1.0f;
		
		if( g_iMode_ironsights == CoF_MODE_NOTAIMED )
		{
			self.SendWeaponAnim( CoFMP5K_SHOOT1, 0, 0 );
		}
		else if( g_iMode_ironsights == CoF_MODE_AIMED )
		{
			self.SendWeaponAnim( CoFMP5K_IRON_SHOOT, 0, 0 );
		}

		//Play it before the punchangle, so the accuracy doesn't get screwed
		Vector vecCone;
		if( m_pPlayer.pev.velocity == g_vecZero ) // Player is not moving
		{
			vecCone = (g_iMode_ironsights == CoF_MODE_AIMED) ? VECTOR_CONE_2DEGREES : VECTOR_CONE_3DEGREES;
		}
		else if( m_pPlayer.pev.velocity != g_vecZero ) // Player is moving
		{
			vecCone = (g_iMode_ironsights == CoF_MODE_AIMED) ? VECTOR_CONE_3DEGREES : VECTOR_CONE_4DEGREES;
		}

		FireTrueBullet( CoFMP5K::MP5K_SHOOT_SOUND, false, CoFMP5K::MP5K_DAMAGE, vecCone, 9216, false, DMG_GENERIC );

		float m_iPunchAngle;

		if( (m_pPlayer.pev.flags & FL_DUCKING != 0) ) // Player is ducking
		{
			m_iPunchAngle = (g_iMode_ironsights == CoF_MODE_AIMED) ? Math.RandomFloat( -1.75f, -1.50f ) : Math.RandomFloat( -2.25f, -2.75f );
		}
		else if( !(m_pPlayer.pev.flags & FL_DUCKING != 0) ) // Player is not ducking
		{
			m_iPunchAngle = (g_iMode_ironsights == CoF_MODE_AIMED) ? Math.RandomFloat( -2.50f, -2.00f ) : Math.RandomFloat( -3.15f, -3.0f );
		}
		punchangle( m_iPunchAngle, Math.RandomFloat( -0.75f, 0.75f ), Math.RandomFloat( -0.75f, 0.75f ) );

		Vector vecShellVelocity, vecShellOrigin;

		if( g_iMode_ironsights == CoF_MODE_NOTAIMED )
			CoFGetDefaultShellInfo( m_pPlayer, vecShellVelocity, vecShellOrigin, 18.5, 6.5, -7.1, false, false );
		else
			CoFGetDefaultShellInfo( m_pPlayer, vecShellVelocity, vecShellOrigin, 18.5, 1.6, -3.55, false, false );

		vecShellVelocity.y *= 1;
		
		g_EntityFuncs.EjectBrass( vecShellOrigin, vecShellVelocity, m_pPlayer.pev.angles[ 1 ], m_iShell, TE_BOUNCE_SHELL );
	}

	void SecondaryAttack()
	{
		self.m_flTimeWeaponIdle = self.m_flNextSecondaryAttack = WeaponTimeBase() + 0.23;
		self.m_flNextPrimaryAttack = WeaponTimeBase() + 0.2;
		g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_ITEM, CoFCOMMON::DEPLOY_SLEEVE3, 0.9, ATTN_NORM, 0, PITCH_NORM );
		
		switch( g_iMode_ironsights )
		{
			case CoF_MODE_NOTAIMED:
			{
				self.SendWeaponAnim( CoFMP5K_IRON_TO, 0, 0 );
				EffectsFOVON( 40 );
				break;
			}
			case CoF_MODE_AIMED:
			{
				self.SendWeaponAnim( CoFMP5K_IRON_FROM, 0, 0 );
				EffectsFOVOFF();
				break;
			}
		}
	}

	void TertiaryAttack()
	{
		if( !Swing( 1, 37, 0, 1.0f, 22, true ) )
		{
			SetThink( ThinkFunction( this.SwingAgain ) );
			self.pev.nextthink = g_Engine.time + 0.1;
		}
	}

	void SwingAgain()
	{
		Swing( 0, 37, 0, 1.0f, 22, true );
	}

	void ItemPreFrame()
	{
		if( m_iDroppedClip == 1 )
			m_iDroppedClip = 0;

		if( m_reloadTimer < g_Engine.time && canReload )
			self.Reload();

		BaseClass.ItemPreFrame();
	}

	void Reload()
	{
		if( self.m_iClip == CoFMP5K::MP5K_MAX_CLIP || m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType ) <= 0 )
			return;

		if( g_iMode_ironsights == CoF_MODE_AIMED )
		{
			self.SendWeaponAnim( CoFMP5K_IRON_FROM, 0, 0 );
			m_reloadTimer = g_Engine.time + 0.2;
			m_pPlayer.m_flNextAttack = 0.2;
			canReload = true;
		}
		EffectsFOVOFF();

		if( m_reloadTimer < g_Engine.time )
		{
			(self.m_iClip == 0) ? Reload( CoFMP5K::MP5K_MAX_CLIP, CoFMP5K_RELOAD_EMPTY, 3.63f, 0 ) : Reload( CoFMP5K::MP5K_MAX_CLIP, CoFMP5K_RELOAD, 2.55f, 0 );
			canReload = false;
		}

		if( mag_counter <= 0 )
		{
			self.pev.nextthink = (self.m_iClip == 0) ? WeaponTimeBase() + 1.48f : WeaponTimeBase() + 0.89f;
			SetThink( ThinkFunction( EjectClipThink ) );
		}

		BaseClass.Reload();
	}

	void EjectClipThink()
	{
		mag_counter = CoFMP5K::MP5K_MAX_CLIP;
		Vector vecVelocity = m_pPlayer.pev.view_ofs + g_Engine.v_right * Math.RandomLong( -50, -16 ) + g_Engine.v_up * 16 + g_Engine.v_forward * Math.RandomLong( 16, 50 );
		ClipCasting( m_pPlayer.pev.origin, vecVelocity, m_iMp5MagEmpty, false, 0 );
	}
	
	void WeaponIdle()
	{
		self.ResetEmptySound();
		m_pPlayer.GetAutoaimVector( AUTOAIM_10DEGREES );

		if( self.m_flTimeWeaponIdle > WeaponTimeBase() )
			return;

		self.SendWeaponAnim( (g_iMode_ironsights == CoF_MODE_AIMED) ? CoFMP5K_IRON_IDLE : CoFMP5K_IDLE, 0, 0 );

		self.m_flTimeWeaponIdle = WeaponTimeBase() + g_PlayerFuncs.SharedRandomFloat( m_pPlayer.random_seed,  5, 7 );
	}
}

class Parabellum9mm_MP5K : ScriptBasePlayerAmmoEntity, ammo_base
{
	void Spawn()
	{
		Precache();
		g_EntityFuncs.SetModel( self, CoFMP5K::MP5K_A_MODEL );
		BaseClass.Spawn();
	}
	
	void Precache()
	{
		g_Game.PrecacheModel( CoFMP5K::MP5K_A_MODEL );
		g_SoundSystem.PrecacheSound( CoFCOMMON::ITEM_SOUND_PICK );
	}

	bool AddAmmo( CBaseEntity@ pOther )
	{
		return CommonAddAmmo( pOther, CoFMP5K::MP5K_MAX_CLIP, CoFMP5K::MP5K_MAX_CARRY, (p_Customizable) ? "ammo_9mmpara" : "9mm" );
	}
}

string CoFMP5KAmmoName()
{
	return "ammo_9mm_mp5k";
}

string CoFMP5KName()
{
	return "weapon_cofmp5k";
}

void RegisterCoFMP5K()
{
	g_CustomEntityFuncs.RegisterCustomEntity( CoFMP5KName(), CoFMP5KName() );
	g_CustomEntityFuncs.RegisterCustomEntity( "Parabellum9mm_MP5K", CoFMP5KAmmoName() );
	g_ItemRegistry.RegisterWeapon( CoFMP5KName(), "cof/smg", (p_Customizable) ? "ammo_9mmpara" : "9mm", "", CoFMP5KAmmoName() );
}