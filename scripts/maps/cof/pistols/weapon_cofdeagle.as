// Author: KernCore

#include "../base"

enum CoFDEAGLEAnimations_e
{
	CoFDEAGLE_IDLE = 0,
	CoFDEAGLE_IDLE_IRON,
	CoFDEAGLE_IDLE_EMPTY,
	CoFDEAGLE_IDLE_EMPTY_IRON,
	CoFDEAGLE_DRAW,
	CoFDEAGLE_DRAW_EMPTY,
	CoFDEAGLE_HOLSTER,
	CoFDEAGLE_HOLSTER_EMPTY,
	CoFDEAGLE_SHOOT1,
	CoFDEAGLE_SHOOT2,
	CoFDEAGLE_SHOOT3,
	CoFDEAGLE_SHOOT4,
	CoFDEAGLE_SHOOT_LAST,
	CoFDEAGLE_SHOOT_IRON,
	CoFDEAGLE_SHOOT_LAST_IRON,
	CoFDEAGLE_RELOAD,
	CoFDEAGLE_RELOAD_EMPTY,
	CoFDEAGLE_MELEE,
	CoFDEAGLE_MELEE_EMPTY,
	CoFDEAGLE_TO_IRON,
	CoFDEAGLE_TO_IRON_EMPTY,
	CoFDEAGLE_FROM_IRON,
	CoFDEAGLE_FROM_IRON_EMPTY
};

namespace CoFDEAGLE
{
	//models
	string DEAGLE_W_MODEL       	= "models/cof/deagle/wld.mdl";
	string DEAGLE_V_MODEL       	= "models/cof/deagle/vwm.mdl";
	string DEAGLE_P_MODEL       	= "models/cof/deagle/wld.mdl";
	string DEAGLE_A_MODEL       	= "models/cof/deagle/mag.mdl";
	string DEAGLE_MAGEMPTY_MODEL 	= "models/cof/deagle/mag_e.mdl";
	//sounds
	const string DEAGLE_SHOOT_SOUND  	= "cof/guns/deagle/shoot.ogg";
	const string DEAGLE_EMPTY_SOUND  	= "cof/guns/deagle/empty.ogg";
	//weapon information
	const int DEAGLE_MAX_CARRY   	= (p_Customizable) ? 70 : 36;
	const int DEAGLE_MAX_CLIP    	= 7;
	const int DEAGLE_DEFAULT_GIVE 	= DEAGLE_MAX_CLIP * 3;
	const int DEAGLE_WEIGHT      	= 20;
	uint DEAGLE_DAMAGE            	= 30;
	//iSlot and iPosition in the Hud
	uint SLOT     	= 1;
	uint POSITION 	= 11;
}

class weapon_cofdeagle : ScriptBasePlayerWeaponEntity, weapon_base
{
	private CBasePlayer@ m_pPlayer
	{
		get const 	{ return cast<CBasePlayer@>( self.m_hPlayer.GetEntity() ); }
		set       	{ self.m_hPlayer = EHandle( @value ); }
	}
	//for weapon functions/modes
	int m_iDEAGLEMagEmpty;
	int mag_counter;

	// Other Sounds
	private array<string> deagleSounds = {
		CoFDEAGLE::DEAGLE_EMPTY_SOUND,
		"cof/guns/deagle/magin.ogg",
		"cof/guns/deagle/magout.ogg",
		"cof/guns/deagle/magout_e.ogg",
		"cof/guns/deagle/sldrel.ogg"
	};

	void Spawn()
	{
		Precache();
		g_EntityFuncs.SetModel( self, CoFDEAGLE::DEAGLE_W_MODEL );
		
		self.m_iDefaultAmmo = CoFDEAGLE::DEAGLE_DEFAULT_GIVE;
		g_iMode_ironsights = CoF_MODE_NOTAIMED;
		mag_counter = CoFDEAGLE::DEAGLE_MAX_CLIP;

		iAnimation  = CoFDEAGLE_MELEE;
		iAnimation2 = CoFDEAGLE_MELEE_EMPTY;
		m_bUseCustomScale = true;
		self.pev.scale = 1.3;
		
		self.FallInit();
	}
	
	void Precache()
	{
		self.PrecacheCustomModels();
		g_Game.PrecacheModel( CoFDEAGLE::DEAGLE_W_MODEL );
		g_Game.PrecacheModel( CoFDEAGLE::DEAGLE_V_MODEL );
		g_Game.PrecacheModel( CoFDEAGLE::DEAGLE_P_MODEL );
		g_Game.PrecacheModel( CoFDEAGLE::DEAGLE_A_MODEL );

		g_Game.PrecacheModel( g_watersplash_spr );
		m_iDEAGLEMagEmpty 	= g_Game.PrecacheModel( CoFDEAGLE::DEAGLE_MAGEMPTY_MODEL );
		m_iShell          	= g_Game.PrecacheModel( mShellModel[8] ); //50 AE

		CommonPrecache(); //Common sounds to all weapons
		PrecacheSound( deagleSounds );

		g_SoundSystem.PrecacheSound( CoFDEAGLE::DEAGLE_SHOOT_SOUND );
		g_Game.PrecacheGeneric( "sound/" + CoFDEAGLE::DEAGLE_SHOOT_SOUND );

		g_Game.PrecacheModel( "sprites/cof/wpn_sel02.spr" );
		g_Game.PrecacheGeneric( "sprites/" + "cof/wpn_sel02.spr" );
		g_Game.PrecacheGeneric( "sprites/" + "cof/pistol/weapon_cofdeagle.txt" );
	}
	
	bool GetItemInfo( ItemInfo& out info )
	{
		info.iMaxAmmo1 	= CoFDEAGLE::DEAGLE_MAX_CARRY;
		info.iMaxAmmo2 	= -1;
		info.iMaxClip 	= CoFDEAGLE::DEAGLE_MAX_CLIP;
		info.iSlot  	= CoFDEAGLE::SLOT;
		info.iPosition 	= CoFDEAGLE::POSITION;
		info.iId     	= g_ItemRegistry.GetIdForName( self.pev.classname );
		info.iFlags 	= ITEM_FLAG_NOAUTORELOAD | ITEM_FLAG_NOAUTOSWITCHEMPTY | ITEM_FLAG_SELECTONEMPTY;
		info.iWeight 	= CoFDEAGLE::DEAGLE_WEIGHT;

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
			g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_AUTO, CoFDEAGLE::DEAGLE_EMPTY_SOUND, 0.9, ATTN_NORM, 0, PITCH_NORM );
		}
		
		return false;
	}
	
	bool Deploy()
	{
		bool bResult;
		{
			bResult = Deploy( CoFDEAGLE::DEAGLE_V_MODEL, CoFDEAGLE::DEAGLE_P_MODEL, (self.m_iClip == 0) ? CoFDEAGLE_DRAW_EMPTY : CoFDEAGLE_DRAW, "onehanded", 1 );

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
		EffectsFOVOFF();
		self.SendWeaponAnim( CoFDEAGLE_HOLSTER );
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
		self.m_flNextPrimaryAttack = WeaponTimeBase() + 0.2f;
		self.m_flNextSecondaryAttack = WeaponTimeBase() + 0.201f;
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
			vecCone = (g_iMode_ironsights == CoF_MODE_AIMED) ? VECTOR_CONE_3DEGREES : VECTOR_CONE_4DEGREES;
		}

		FireTrueBullet( CoFDEAGLE::DEAGLE_SHOOT_SOUND, false, CoFDEAGLE::DEAGLE_DAMAGE, vecCone, 8192, false, DMG_GENERIC );

		float m_iPunchAngle;
		if( (m_pPlayer.pev.flags & FL_DUCKING != 0) ) // Player is ducking
		{
			m_iPunchAngle = (g_iMode_ironsights == CoF_MODE_AIMED) ? Math.RandomFloat( -2.00f, -2.50f ) : Math.RandomFloat( -3, -4 );
		}
		else if( !(m_pPlayer.pev.flags & FL_DUCKING != 0) ) // Player is not ducking
		{
			m_iPunchAngle = (g_iMode_ironsights == CoF_MODE_AIMED) ? Math.RandomFloat( -3, -2 ) : Math.RandomFloat( -5, -4 );
		}
		punchangle( m_iPunchAngle, (RandomSeed() < 0.5) ? Math.RandomFloat( 0.50, 0.75 ) : Math.RandomFloat( -0.75, -0.50 ), Math.RandomFloat( -1, 1 ) );

		if( g_iMode_ironsights == CoF_MODE_AIMED )
		{
			self.SendWeaponAnim( (self.m_iClip > 0) ? CoFDEAGLE_SHOOT_IRON : CoFDEAGLE_SHOOT_LAST_IRON, 0, 1 );
		}
		else if( g_iMode_ironsights == CoF_MODE_NOTAIMED )
		{
			self.SendWeaponAnim( (self.m_iClip > 0) ? CoFDEAGLE_SHOOT1 + Math.RandomLong( 0, 3 ) : CoFDEAGLE_SHOOT_LAST, 0, 1 );
		}

		Vector vecShellVelocity, vecShellOrigin;

		if( g_iMode_ironsights == CoF_MODE_NOTAIMED )
			CoFGetDefaultShellInfo( m_pPlayer, vecShellVelocity, vecShellOrigin, 23, 5, -7, false, false );
		else
			CoFGetDefaultShellInfo( m_pPlayer, vecShellVelocity, vecShellOrigin, 23, 0, -1.5, false, false );

		vecShellVelocity.y *= 1;
		g_EntityFuncs.EjectBrass( vecShellOrigin, vecShellVelocity, m_pPlayer.pev.angles[ 1 ], m_iShell, TE_BOUNCE_SHELL );
		//AngleRecoil( Math.RandomFloat( -0.5f, -0.1f ), Math.RandomFloat( -0.05f, 0.05f ) );
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
				self.SendWeaponAnim( (self.m_iClip > 0) ? CoFDEAGLE_TO_IRON : CoFDEAGLE_TO_IRON_EMPTY, 0, 1 );
				EffectsFOVON( 45 );
				break;
			}
			case CoF_MODE_AIMED:
			{
				self.SendWeaponAnim( (self.m_iClip > 0) ? CoFDEAGLE_FROM_IRON : CoFDEAGLE_FROM_IRON_EMPTY, 0, 1 );
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
		if( self.m_iClip == CoFDEAGLE::DEAGLE_MAX_CLIP || m_pPlayer.m_rgAmmo(self.m_iPrimaryAmmoType) <= 0 )
			return;
			
		if( g_iMode_ironsights == CoF_MODE_AIMED )
		{
			self.SendWeaponAnim( (self.m_iClip > 0) ? CoFDEAGLE_FROM_IRON : CoFDEAGLE_FROM_IRON_EMPTY, 0, 1 );
			m_reloadTimer = g_Engine.time + 0.2;
			m_pPlayer.m_flNextAttack = 0.2;
			canReload = true;
		}
		EffectsFOVOFF();

		if( m_reloadTimer < g_Engine.time )
		{
			(self.m_iClip == 0) ? Reload( CoFDEAGLE::DEAGLE_MAX_CLIP, CoFDEAGLE_RELOAD_EMPTY, 3.133f, 1 ) : Reload( CoFDEAGLE::DEAGLE_MAX_CLIP, CoFDEAGLE_RELOAD, 2.66f, 1 );
			canReload = false;
		}
		
		if( mag_counter <= 0 )
		{
			self.pev.nextthink = WeaponTimeBase() + 0.85f;
			SetThink( ThinkFunction( EjectClipThink ) );
		}

		BaseClass.Reload();
	}

	void EjectClipThink()
	{
		mag_counter = CoFDEAGLE::DEAGLE_MAX_CLIP;
		ClipCasting( m_pPlayer.pev.origin, m_pPlayer.pev.view_ofs + g_Engine.v_right * -34 + g_Engine.v_up * 16 + g_Engine.v_forward * 16, m_iDEAGLEMagEmpty, false, 0 );
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
			self.SendWeaponAnim( (self.m_iClip > 0) ? CoFDEAGLE_IDLE_IRON : CoFDEAGLE_IDLE_EMPTY_IRON, 0, 1 );
		}
		else if( g_iMode_ironsights == CoF_MODE_NOTAIMED )
		{
			self.SendWeaponAnim( (self.m_iClip > 0) ? CoFDEAGLE_IDLE : CoFDEAGLE_IDLE_EMPTY, 0, 1 );
		}

		self.m_flTimeWeaponIdle = WeaponTimeBase() + g_PlayerFuncs.SharedRandomFloat( m_pPlayer.random_seed,  5, 7 );
	}
}

class Ae50 : ScriptBasePlayerAmmoEntity, ammo_base
{
	void Spawn()
	{
		Precache();
		g_EntityFuncs.SetModel( self, CoFDEAGLE::DEAGLE_A_MODEL );
		BaseClass.Spawn();
	}
	
	void Precache()
	{
		g_Game.PrecacheModel( CoFDEAGLE::DEAGLE_A_MODEL );
		g_SoundSystem.PrecacheSound( CoFCOMMON::ITEM_SOUND_PICK );
	}

	bool AddAmmo( CBaseEntity@ pOther )
	{
		return CommonAddAmmo( pOther, CoFDEAGLE::DEAGLE_MAX_CLIP, CoFDEAGLE::DEAGLE_MAX_CARRY, (p_Customizable) ? "ammo_50ae" : "357" );
	}
}

string CoFDEAGLEAmmoName()
{
	return "ammo_50ae";
}

string CoFDEAGLEName()
{
	return "weapon_cofdeagle";
}

void RegisterCoFDEAGLE()
{
	g_CustomEntityFuncs.RegisterCustomEntity( CoFDEAGLEName(), CoFDEAGLEName() );
	g_CustomEntityFuncs.RegisterCustomEntity( "Ae50", CoFDEAGLEAmmoName() );
	g_ItemRegistry.RegisterWeapon( CoFDEAGLEName(), "cof/pistol", (p_Customizable) ? "ammo_50ae" : "357", "", CoFDEAGLEAmmoName() );
}