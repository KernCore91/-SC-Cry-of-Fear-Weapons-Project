// Author: KernCore

#include "../base"

/*
* This is the "Out of it" custom Ak weapon, it has been
* properly updated for custom animations and
* higher quality
*/
enum CoFAK74Animations_e
{
	CoFAK74_IDLE = 0,
	CoFAK74_DRAW_FIRST,
	CoFAK74_DRAW,
	CoFAK74_SHOOT1,
	CoFAK74_SHOOT2,
	CoFAK74_SHOOT3,
	CoFAK74_SHOOT_EMPTY,
	CoFAK74_IRON_TO,
	CoFAK74_IRON_FROM,
	CoFAK74_IRON_IDLE,
	CoFAK74_IRON_SHOOT1,
	CoFAK74_IRON_SHOOT2,
	CoFAK74_IRON_SHOOT3,
	CoFAK74_IRON_SHOOT_EMPTY,
	CoFAK74_RELOAD,
	CoFAK74_RELOAD_EMPTY_1,
	CoFAK74_RELOAD_EMPTY_2,
	CoFAK74_MELEE
};

namespace CoFAK74
{
	//models
	string AK74_W_MODEL        	= "models/cof/ak74/wrd.mdl";
	string AK74_V_MODEL        	= "models/cof/ak74/vwm.mdl";
	string AK74_P_MODEL        	= "models/cof/ak74/plr.mdl";
	string AK74_A_MODEL        	= "models/cof/ak74/mag.mdl";
	string AK74_MAGEMPTY_MODEL 	= "models/cof/ak74/mag_e.mdl";
	//sound
	const string AK74_SHOOT_SOUND    	= "cof/guns/ak74/shoot.ogg";
	const string AK74_EMPTY_SOUND    	= "cof/guns/ak74/empty.ogg";
	//weapon information
	const int AK74_MAX_CARRY 	= (p_Customizable) ? 500 : 600;
	const int AK74_MAX_CLIP  	= 30;
	const int AK74_DEFAULT_GIVE	= AK74_MAX_CLIP * 3;
	const int AK74_WEIGHT    	= 35;
	uint AK74_DAMAGE          	= 22;
	//iSlot and iPosition in the Hud
	uint SLOT     	= 5;
	uint POSITION 	= 9;
}

class weapon_cofak74 : ScriptBasePlayerWeaponEntity, weapon_base
{
	private CBasePlayer@ m_pPlayer
	{
		get const 	{ return cast<CBasePlayer@>( self.m_hPlayer.GetEntity() ); }
		set       	{ self.m_hPlayer = EHandle( @value ); }
	}
	bool m_WasDrawn;
	int m_iAk74MagEmpty;
	int mag_counter;
	// Other Sounds
	private array<string> ak74Sounds = {
		"cof/guns/ak74/magrel.ogg",
		"cof/guns/ak74/magout.ogg",
		"cof/guns/ak74/magout_r.ogg",
		"cof/guns/ak74/magin.ogg",
		"cof/guns/ak74/bltback.ogg",
		"cof/guns/ak74/bltrel.ogg",
		"cof/guns/ak74/safe.ogg",
		"cof/guns/ak74/stock.ogg"
	};

	void Spawn()
	{
		Precache();
		g_EntityFuncs.SetModel( self, self.GetW_Model( CoFAK74::AK74_W_MODEL ) );

		m_WasDrawn = false;
		self.m_iDefaultAmmo	= CoFAK74::AK74_DEFAULT_GIVE;
		mag_counter = CoFAK74::AK74_MAX_CLIP;
		iAnimation = CoFAK74_MELEE;
		iAnimation2 = CoFAK74_MELEE;

		self.FallInit();
	}

	void Precache()
	{
		self.PrecacheCustomModels();
		g_Game.PrecacheModel( CoFAK74::AK74_W_MODEL );
		g_Game.PrecacheModel( CoFAK74::AK74_V_MODEL );
		g_Game.PrecacheModel( CoFAK74::AK74_P_MODEL );
		g_Game.PrecacheModel( CoFAK74::AK74_A_MODEL );
		m_iAk74MagEmpty	= g_Game.PrecacheModel( CoFAK74::AK74_MAGEMPTY_MODEL );
		m_iShell     	= g_Game.PrecacheModel( mShellModel[7] ); //545

		CommonPrecache(); //Common sounds to all weapons
		PrecacheSound( ak74Sounds );

		g_SoundSystem.PrecacheSound( CoFAK74::AK74_SHOOT_SOUND );
		g_SoundSystem.PrecacheSound( CoFAK74::AK74_EMPTY_SOUND );
		g_Game.PrecacheGeneric( "sound/" + CoFAK74::AK74_SHOOT_SOUND );
		g_Game.PrecacheGeneric( "sound/" + CoFAK74::AK74_EMPTY_SOUND );

		g_Game.PrecacheModel( "sprites/cof/wpn_sel02.spr" );
		g_Game.PrecacheGeneric( "sprites/" + "cof/wpn_sel02.spr" );
		g_Game.PrecacheGeneric( "sprites/" + "cof/arifle/weapon_cofak74.txt" );
	}

	bool GetItemInfo( ItemInfo& out info )
	{
		info.iMaxAmmo1 	= CoFAK74::AK74_MAX_CARRY;
		info.iMaxAmmo2 	= -1;
		info.iMaxClip 	= CoFAK74::AK74_MAX_CLIP;
		info.iSlot   	= CoFAK74::SLOT;
		info.iPosition 	= CoFAK74::POSITION;
		info.iId     	= g_ItemRegistry.GetIdForName( self.pev.classname );
		info.iFlags  	= ITEM_FLAG_NOAUTORELOAD | ITEM_FLAG_NOAUTOSWITCHEMPTY | ITEM_FLAG_SELECTONEMPTY;
		info.iWeight 	= CoFAK74::AK74_WEIGHT;

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
				bResult = Deploy( CoFAK74::AK74_V_MODEL, CoFAK74::AK74_P_MODEL, CoFAK74_DRAW_FIRST, "m16", 0 );
				deployTime = 2.33f;
				m_WasDrawn = true;
			}
			else if( m_WasDrawn == true )
			{
				bResult = Deploy( CoFAK74::AK74_V_MODEL, CoFAK74::AK74_P_MODEL, CoFAK74_DRAW, "m16", 0 );
				deployTime = 1.75f;
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

	bool PlayEmptySound()
	{
		if( self.m_bPlayEmptySound )
		{
			self.m_bPlayEmptySound = false;
			g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_AUTO, CoFAK74::AK74_EMPTY_SOUND, 0.9, ATTN_NORM, 0, PITCH_NORM );
		}
		return false;
	}

	void Holster( int skipLocal = 0 )
	{
		self.m_fInReload = false;
		EffectsFOVOFF();
		canReload = false;

		SetThink( null );

		BaseClass.Holster( skipLocal );
	}

	void PrimaryAttack()
	{
		if( self.m_iClip <= 0 )
		{
			if( ( m_pPlayer.m_afButtonPressed & IN_ATTACK == 0 ) )
				return;

			self.PlayEmptySound();
			self.m_flNextPrimaryAttack = WeaponTimeBase() + 0.33f;
			self.SendWeaponAnim( (g_iMode_ironsights == CoF_MODE_NOTAIMED) ? CoFAK74_SHOOT_EMPTY : CoFAK74_IRON_SHOOT_EMPTY, 0, 0 );
			return;
		}

		mag_counter--;
		self.m_flNextPrimaryAttack = WeaponTimeBase() + GetFireRate( (m_pPlayer.pev.waterlevel == WATERLEVEL_HEAD) ? Math.RandomLong( 450, 500 ) : Math.RandomLong( 600, 625 ) );
		self.m_flNextSecondaryAttack = WeaponTimeBase() + 0.1;
		self.m_flNextTertiaryAttack = WeaponTimeBase() + 0.3;
		self.m_flTimeWeaponIdle = WeaponTimeBase() + 1.0f;

		self.SendWeaponAnim( (g_iMode_ironsights == CoF_MODE_NOTAIMED) ? CoFAK74_SHOOT1 + Math.RandomLong( 0, 2 ) : CoFAK74_IRON_SHOOT1 + Math.RandomLong( 0, 2 ), 0, 0 );

		//Play it before the punchangle, so the accuracy doesn't get screwed
		Vector vecCone;
		if( m_pPlayer.pev.velocity == g_vecZero ) // Player is not moving
		{
			vecCone = (g_iMode_ironsights == CoF_MODE_AIMED) ? VECTOR_CONE_1DEGREES : VECTOR_CONE_3DEGREES;
		}
		else if( m_pPlayer.pev.velocity != g_vecZero ) // Player is moving
		{
			vecCone = (g_iMode_ironsights == CoF_MODE_AIMED) ? VECTOR_CONE_3DEGREES : VECTOR_CONE_5DEGREES;
		}

		FireTrueBullet( CoFAK74::AK74_SHOOT_SOUND, true, CoFAK74::AK74_DAMAGE, vecCone, (m_pPlayer.pev.waterlevel == WATERLEVEL_HEAD) ? 4096 : 9216, false, DMG_GENERIC );

		float m_iPunchAngle;

		if( (m_pPlayer.pev.flags & FL_DUCKING != 0) ) // Player is ducking
		{
			m_iPunchAngle = (g_iMode_ironsights == CoF_MODE_AIMED) ? Math.RandomFloat( -2.00f, -1.75f ) : Math.RandomFloat( -2.50f, -2.25f );
		}
		else if( !(m_pPlayer.pev.flags & FL_DUCKING != 0) ) // Player is not ducking
		{
			m_iPunchAngle = (g_iMode_ironsights == CoF_MODE_AIMED) ? Math.RandomFloat( -2.75f, -2.50f ) : Math.RandomFloat( -3.75f, -3.50f );
		}
		punchangle( m_iPunchAngle, Math.RandomFloat( -0.75, 0.50f ), Math.RandomFloat( -0.5f, -0.1f ) );

		Vector vecShellVelocity, vecShellOrigin;

		if( g_iMode_ironsights == CoF_MODE_NOTAIMED )
			CoFGetDefaultShellInfo( m_pPlayer, vecShellVelocity, vecShellOrigin, 21, 6, -7.1, false, false );
		else
			CoFGetDefaultShellInfo( m_pPlayer, vecShellVelocity, vecShellOrigin, 21, 1.5, -2, false, false );

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
				self.SendWeaponAnim( CoFAK74_IRON_TO, 0, 0 );
				EffectsFOVON( 40 );
				break;
			}
			case CoF_MODE_AIMED:
			{
				self.SendWeaponAnim( CoFAK74_IRON_FROM, 0, 0 );
				EffectsFOVOFF();
				break;
			}
		}
	}

	void TertiaryAttack()
	{
		if( !Swing( 1, 37, 1, 1.0f, 23, true ) )
		{
			SetThink( ThinkFunction( this.SwingAgain ) );
			self.pev.nextthink = g_Engine.time + 0.1;
		}
	}

	void SwingAgain()
	{
		Swing( 0, 37, 1, 1.1f, 22, true );
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
		if( self.m_iClip == CoFAK74::AK74_MAX_CLIP || m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType ) == 0 )
			return;

		if( g_iMode_ironsights == CoF_MODE_AIMED )
		{
			self.SendWeaponAnim( CoFAK74_IRON_FROM, 0, 1 );
			m_reloadTimer = g_Engine.time + 0.175f;
			m_pPlayer.m_flNextAttack = 0.175;
			canReload = true;
		}
		EffectsFOVOFF();

		if( m_reloadTimer < g_Engine.time )
		{
			if( self.m_iClip == 0 )
			{
				switch( g_PlayerFuncs.SharedRandomLong( m_pPlayer.random_seed, 0, 1 ) )
				{
					case 0: Reload( CoFAK74::AK74_MAX_CLIP, CoFAK74_RELOAD_EMPTY_2, 4.45f, 1 ); break;
					case 1: Reload( CoFAK74::AK74_MAX_CLIP, CoFAK74_RELOAD_EMPTY_1, 4.77f, 1 ); break;
				}
			}
			else
				Reload( CoFAK74::AK74_MAX_CLIP, CoFAK74_RELOAD, 2.275f, 1 );

			canReload = false;
		}
		if( mag_counter <= 0 )
		{
			self.pev.nextthink = WeaponTimeBase() + 1.14f;
			SetThink( ThinkFunction( EjectClipThink ) );
		}
		BaseClass.Reload();
	}

	void EjectClipThink()
	{
		mag_counter = CoFAK74::AK74_MAX_CLIP;
		ClipCasting( m_pPlayer.pev.origin, m_pPlayer.pev.view_ofs + g_Engine.v_right * -48 + g_Engine.v_up * 16 + g_Engine.v_forward * 8, m_iAk74MagEmpty, false, 0 );
	}

	void WeaponIdle()
	{
		self.ResetEmptySound();
		m_pPlayer.GetAutoaimVector( AUTOAIM_10DEGREES );

		if( self.m_flTimeWeaponIdle > WeaponTimeBase() )
			return;

		self.SendWeaponAnim( (g_iMode_ironsights == CoF_MODE_AIMED) ? CoFAK74_IRON_IDLE : CoFAK74_IDLE, 0, 0 );
		self.m_flTimeWeaponIdle = WeaponTimeBase() + g_PlayerFuncs.SharedRandomFloat( m_pPlayer.random_seed, 5, 7 );
	}
}

class Soviet545 : ScriptBasePlayerAmmoEntity, ammo_base
{
	void Spawn()
	{
		Precache();
		g_EntityFuncs.SetModel( self, CoFAK74::AK74_A_MODEL );
		BaseClass.Spawn();
	}
	
	void Precache()
	{
		g_Game.PrecacheModel( CoFAK74::AK74_A_MODEL );
		g_SoundSystem.PrecacheSound( CoFCOMMON::ITEM_SOUND_PICK );
	}

	bool AddAmmo( CBaseEntity@ pOther )
	{
		return CommonAddAmmo( pOther, CoFAK74::AK74_MAX_CLIP, CoFAK74::AK74_MAX_CARRY, (p_Customizable) ? "ammo_545mm" : "556" );
	}
}

string CoFAK74AmmoName()
{
	return "ammo_545mm";
}

string CoFAK74Name()
{
	return "weapon_cofak74";
}

void RegisterCoFAK74()
{
	g_CustomEntityFuncs.RegisterCustomEntity( CoFAK74Name(), CoFAK74Name() );
	g_CustomEntityFuncs.RegisterCustomEntity( "Soviet545", CoFAK74AmmoName() );
	g_ItemRegistry.RegisterWeapon( CoFAK74Name(), "cof/arifle", (p_Customizable) ? "ammo_545mm" : "556", "", CoFAK74AmmoName() );
}