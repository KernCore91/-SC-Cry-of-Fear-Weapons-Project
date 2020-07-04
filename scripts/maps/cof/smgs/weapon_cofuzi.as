// Author: KernCore

#include "../base"

enum CoFUZIAnimations_e
{
	CoFUZI_IDLE = 0,
	CoFUZI_DRAW_FIRST,
	CoFUZI_DRAW,
	CoFUZI_HOLSTER,
	CoFUZI_SHOOT,
	CoFUZI_RELOAD,
	CoFUZI_RELOAD_EMPTY,
	CoFUZI_IRON_IDLE,
	CoFUZI_IRON_SHOOT,
	CoFUZI_IRON_TO,
	CoFUZI_IRON_FROM,
	CoFUZI_MELEE
};

namespace CoFUZI
{
	//models
	string UZI_W_MODEL      	= "models/cof/uzi/wrd.mdl";
	string UZI_V_MODEL      	= "models/cof/uzi/vwm.mdl";
	string UZI_P_MODEL      	= "models/cof/uzi/plr.mdl";
	string UZI_A_MODEL      	= "models/cof/uzi/mag.mdl";
	string UZI_MAGEMPTY_MODEL	= "models/cof/uzi/mag_e.mdl";
	//sounds
	const string UZI_SHOOT_SOUND  	= "cof/guns/uzi/shoot.ogg";
	//weapon information
	const int UZI_MAX_CARRY   	= (p_Customizable) ? 360 : 250;
	const int UZI_MAX_CLIP    	= 32;
	const int UZI_DEFAULT_GIVE 	= UZI_MAX_CLIP * 2;
	const int UZI_WEIGHT      	= 24;
	uint UZI_DAMAGE          	= 13;
	//iSlot and iPosition in the Hud
	uint SLOT     	= 2;
	uint POSITION 	= 8;
}

class weapon_cofuzi : ScriptBasePlayerWeaponEntity, weapon_base
{
	private CBasePlayer@ m_pPlayer
	{
		get const 	{ return cast<CBasePlayer@>( self.m_hPlayer.GetEntity() ); }
		set       	{ self.m_hPlayer = EHandle( @value ); }
	}
	//for weapon functions/modes
	bool m_WasDrawn;
	private int m_iUziMagEmpty, mag_counter;

	// Other Sounds
	private array<string> uziSounds = {
		"cof/guns/uzi/bltback.ogg",
		"cof/guns/uzi/bltfwrd.ogg",
		"cof/guns/uzi/magin.ogg",
		"cof/guns/uzi/magin_p.ogg",
		"cof/guns/uzi/magout.ogg",
		"cof/guns/uzi/magout_e.ogg",
		"cof/guns/uzi/magrel.ogg",
		"cof/guns/uzi/stock.ogg"
	};

	void Spawn()
	{
		Precache();
		g_EntityFuncs.SetModel( self, CoFUZI::UZI_W_MODEL );

		self.m_iDefaultAmmo	= CoFUZI::UZI_DEFAULT_GIVE;
		g_iMode_ironsights 	= CoF_MODE_NOTAIMED;
		m_WasDrawn = false;

		iAnimation  = CoFUZI_MELEE;
		iAnimation2 = CoFUZI_MELEE;

		mag_counter = CoFUZI::UZI_MAX_CLIP;

		self.FallInit();
	}

	void Precache()
	{
		self.PrecacheCustomModels();
		g_Game.PrecacheModel( CoFUZI::UZI_W_MODEL );
		g_Game.PrecacheModel( CoFUZI::UZI_V_MODEL );
		g_Game.PrecacheModel( CoFUZI::UZI_P_MODEL );
		g_Game.PrecacheModel( g_watersplash_spr );
		g_Game.PrecacheModel( CoFUZI::UZI_A_MODEL );
		m_iUziMagEmpty	= g_Game.PrecacheModel( CoFUZI::UZI_MAGEMPTY_MODEL );
		m_iShell    	= g_Game.PrecacheModel( mShellModel[0] ); //9mm

		CommonPrecache(); //Common sounds to all weapons
		PrecacheSound( uziSounds );

		g_SoundSystem.PrecacheSound( CoFUZI::UZI_SHOOT_SOUND );
		g_SoundSystem.PrecacheSound( EMPTY_SHOOT_SOUND );
		g_Game.PrecacheGeneric( "sound/" + CoFUZI::UZI_SHOOT_SOUND );
		g_Game.PrecacheGeneric( "sound/" + EMPTY_SHOOT_SOUND );

		g_Game.PrecacheModel( "sprites/cof/wpn_sel02.spr" );
		g_Game.PrecacheGeneric( "sprites/" + "cof/wpn_sel02.spr" );
		g_Game.PrecacheGeneric( "sprites/" + "cof/smg/weapon_cofuzi.txt" );
	}

	bool GetItemInfo( ItemInfo& out info )
	{
		info.iMaxAmmo1 	= CoFUZI::UZI_MAX_CARRY;
		info.iMaxAmmo2 	= -1;
		info.iMaxClip 	= CoFUZI::UZI_MAX_CLIP;
		info.iSlot  	= CoFUZI::SLOT;
		info.iPosition 	= CoFUZI::POSITION;
		info.iId     	= g_ItemRegistry.GetIdForName( self.pev.classname );
		info.iFlags 	= ITEM_FLAG_NOAUTORELOAD | ITEM_FLAG_NOAUTOSWITCHEMPTY | ITEM_FLAG_SELECTONEMPTY;
		info.iWeight 	= CoFUZI::UZI_WEIGHT;

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
				bResult = Deploy( CoFUZI::UZI_V_MODEL, CoFUZI::UZI_P_MODEL, CoFUZI_DRAW_FIRST, "onehanded", 1 );
				deployTime = 3.3f;
				m_WasDrawn = true;
			}
			else if( m_WasDrawn == true )
			{
				bResult = Deploy( CoFUZI::UZI_V_MODEL, CoFUZI::UZI_P_MODEL, CoFUZI_DRAW, "onehanded", 1 );
				deployTime = 1.0f;
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
		canReload = false;

		SetThink( null );

		BaseClass.Holster( skipLocal );
	}

	void PrimaryAttack()
	{
		if( self.m_iClip <= 0 || m_pPlayer.pev.waterlevel == WATERLEVEL_HEAD )
		{
			if( ( m_pPlayer.m_afButtonPressed & IN_ATTACK == 0 ) )
				return;

			self.PlayEmptySound();
			self.m_flNextPrimaryAttack = WeaponTimeBase() + 0.5f;
			return;
		}

		mag_counter--;
		self.m_flNextPrimaryAttack = WeaponTimeBase() + GetFireRate( 600 );
		self.m_flNextSecondaryAttack = WeaponTimeBase() + 0.17;
		self.m_flNextTertiaryAttack = WeaponTimeBase() + 0.3;
		self.m_flTimeWeaponIdle = WeaponTimeBase() + 1.0f;
		
		if( g_iMode_ironsights == CoF_MODE_AIMED )
		{
			self.SendWeaponAnim( CoFUZI_IRON_SHOOT, 0, 1 );
		}
		else if( g_iMode_ironsights == CoF_MODE_NOTAIMED )
		{
			self.SendWeaponAnim( CoFUZI_SHOOT, 0, 1 );
		}

		// Accuracy
		//Play it before the punchangle, so the accuracy doesn't get screwed
		Vector vecCone;
		if( m_pPlayer.pev.velocity == g_vecZero ) // Player is not moving
		{
			vecCone = (g_iMode_ironsights == CoF_MODE_AIMED) ? VECTOR_CONE_1DEGREES : VECTOR_CONE_2DEGREES;
		}
		else if( m_pPlayer.pev.velocity != g_vecZero ) // Player is moving
		{
			vecCone = (g_iMode_ironsights == CoF_MODE_AIMED) ? VECTOR_CONE_2DEGREES : VECTOR_CONE_3DEGREES;
		}
		// Fire the Bullet
		FireTrueBullet( CoFUZI::UZI_SHOOT_SOUND, false, CoFUZI::UZI_DAMAGE, vecCone, 8192, false, DMG_GENERIC );
		// Recoil
		float m_iPunchAngle;
		if( (m_pPlayer.pev.flags & FL_DUCKING != 0) ) // Player is ducking
		{
			m_iPunchAngle = (g_iMode_ironsights == CoF_MODE_AIMED) ? Math.RandomFloat( -1.75f, -1.50f ) : Math.RandomLong( -3, -1 );
		}
		else if( !(m_pPlayer.pev.flags & FL_DUCKING != 0) ) // Player is not ducking
		{
			m_iPunchAngle = (g_iMode_ironsights == CoF_MODE_AIMED) ? Math.RandomFloat( -2.25f, -2.0f ) : Math.RandomLong( -3, -2 );
		}
		punchangle( m_iPunchAngle, Math.RandomFloat( -0.65, 0.65 ), Math.RandomFloat( -0.5f, 0.5f ) );

		Vector vecShellVelocity, vecShellOrigin;
		
		if( g_iMode_ironsights == CoF_MODE_NOTAIMED )
			CoFGetDefaultShellInfo( m_pPlayer, vecShellVelocity, vecShellOrigin, 20, 7.5, -7, false, false );
		else
			CoFGetDefaultShellInfo( m_pPlayer, vecShellVelocity, vecShellOrigin, 20, 2, -3, false, false );

		vecShellVelocity.y *= 1;
		
		g_EntityFuncs.EjectBrass( vecShellOrigin, vecShellVelocity, m_pPlayer.pev.angles[ 1 ], m_iShell, TE_BOUNCE_SHELL );
	}

	void SecondaryAttack()
	{
		self.m_flNextSecondaryAttack = WeaponTimeBase() + 0.2;
		self.m_flNextPrimaryAttack = WeaponTimeBase() + 0.15;
		g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_ITEM, CoFCOMMON::DEPLOY_SLEEVE3, 0.9, ATTN_NORM, 0, PITCH_NORM );

		switch( g_iMode_ironsights )
		{
			case CoF_MODE_NOTAIMED:
			{
				self.SendWeaponAnim( CoFUZI_IRON_TO, 0, 1 );
				EffectsFOVON( 40 );
				break;
			}
			case CoF_MODE_AIMED:
			{
				self.SendWeaponAnim( CoFUZI_IRON_FROM, 0, 1 );
				EffectsFOVOFF();
				break;
			}
		}
	}

	void TertiaryAttack()
	{
		if( !Swing( 1, 37, 1, 1.0f, 22, true ) )
		{
			SetThink( ThinkFunction( this.SwingAgain ) );
			self.pev.nextthink = g_Engine.time + 0.1;
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
		if( self.m_iClip == CoFUZI::UZI_MAX_CLIP || m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType ) <= 0 )
			return;

		if( g_iMode_ironsights == CoF_MODE_AIMED )
		{
			self.SendWeaponAnim( CoFUZI_IRON_FROM, 0, 0 );
			m_reloadTimer = g_Engine.time + 0.18;
			m_pPlayer.m_flNextAttack = 0.18;
			canReload = true;
		}
		EffectsFOVOFF();

		if( m_reloadTimer < g_Engine.time )
		{
			(self.m_iClip == 0) ? Reload( CoFUZI::UZI_MAX_CLIP, CoFUZI_RELOAD_EMPTY, 3.56f, 1 ) : Reload( CoFUZI::UZI_MAX_CLIP, CoFUZI_RELOAD, 3.27f, 1 );
			canReload = false;
		}

		if( mag_counter <= 0 )
		{
			self.pev.nextthink = (self.m_iClip == 0) ? WeaponTimeBase() + 1.94f : WeaponTimeBase() + 1.57f;
			SetThink( ThinkFunction( EjectClipThink ) );
		}

		BaseClass.Reload();
	}

	void EjectClipThink()
	{
		mag_counter = CoFUZI::UZI_MAX_CLIP;
		ClipCasting( m_pPlayer.pev.origin, m_pPlayer.pev.view_ofs + g_Engine.v_right * -24 + g_Engine.v_up * 16 + g_Engine.v_forward * 8, m_iUziMagEmpty, false, 0 );
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

		if( g_iMode_ironsights == CoF_MODE_AIMED )
		{
			self.SendWeaponAnim( CoFUZI_IRON_IDLE, 0, 1 );
		}
		else if( g_iMode_ironsights == CoF_MODE_NOTAIMED )
		{
			self.SendWeaponAnim( CoFUZI_IDLE, 0, 1 );
		}

		self.m_flTimeWeaponIdle = WeaponTimeBase() + g_PlayerFuncs.SharedRandomFloat( m_pPlayer.random_seed,  5, 7 );
	}

	void SwingAgain()
	{
		Swing( 0, 37, 1, 1.0f, 22, true );
	}
}

class Parabellum9mm_UZI : ScriptBasePlayerAmmoEntity, ammo_base
{
	void Spawn()
	{
		Precache();
		g_EntityFuncs.SetModel( self, CoFUZI::UZI_A_MODEL );
		BaseClass.Spawn();
	}
	
	void Precache()
	{
		g_Game.PrecacheModel( CoFUZI::UZI_A_MODEL );
		g_SoundSystem.PrecacheSound( CoFCOMMON::ITEM_SOUND_PICK );
	}

	bool AddAmmo( CBaseEntity@ pOther )
	{
		return CommonAddAmmo( pOther, CoFUZI::UZI_MAX_CLIP, CoFUZI::UZI_MAX_CARRY, (p_Customizable) ? "ammo_9mmpara" : "9mm" );
	}
}

string CoFUZIAmmoName()
{
	return "ammo_9mm_uzi";
}

string CoFUZIName()
{
	return "weapon_cofuzi";
}

void RegisterCoFUZI()
{
	g_CustomEntityFuncs.RegisterCustomEntity( CoFUZIName(), CoFUZIName() );
	g_CustomEntityFuncs.RegisterCustomEntity( "Parabellum9mm_UZI", CoFUZIAmmoName() );
	g_ItemRegistry.RegisterWeapon( CoFUZIName(), "cof/smg", (p_Customizable) ? "ammo_9mmpara" : "9mm", "", CoFUZIAmmoName() );
}