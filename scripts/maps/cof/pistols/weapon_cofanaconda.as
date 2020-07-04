// Author: KernCore

#include "../base"

enum CoFANACONDAAnimations_e
{
	CoFANACONDA_IDLE = 0,
	CoFANACONDA_DRAW_FIRST,
	CoFANACONDA_DRAW,
	CoFANACONDA_HOLSTER,
	CoFANACONDA_SHOOT1,
	CoFANACONDA_SHOOT2,
	CoFANACONDA_SHOOT_EMPTY,
	CoFANACONDA_RELOAD,
	CoFANACONDA_IDLE_IRON,
	CoFANACONDA_SHOOT_IRON,
	CoFANACONDA_SHOOT_EMPTY_IRON,
	CoFANACONDA_TO_IRON,
	CoFANACONDA_FROM_IRON,
	CoFANACONDA_MELEE
};

namespace CoFANACONDA
{
	//models
	string ANACONDA_W_MODEL     	= "models/cof/anaconda/wrd.mdl";
	string ANACONDA_V_MODEL     	= "models/cof/anaconda/vwm.mdl";
	string ANACONDA_P_MODEL     	= "models/cof/anaconda/plr.mdl";
	string ANACONDA_A_MODEL     	= "models/cof/anaconda/mag.mdl";
	string ANACONDA_MAGEMPTY_MODEL 	= "models/cof/anaconda/mag_e.mdl";
	//sounds
	const string ANACONDA_SHOOT_SOUND 	= "cof/guns/anaconda/shoot.ogg";
	const string ANACONDA_EMPTY_SOUND 	= "cof/guns/anaconda/empty.ogg";
	//weapon information
	const int ANACONDA_MAX_CARRY 	= (p_Customizable) ? 60 : 36;
	const int ANACONDA_MAX_CLIP  	= 6;
	const int ANACONDA_DEFAULT_GIVE	= ANACONDA_MAX_CLIP * 3;
	const int ANACONDA_WEIGHT    	= 20;
	uint ANACONDA_DAMAGE          	= 35;
	//iSlot and iPosition in the Hud
	uint SLOT     	= 1;
	uint POSITION 	= 12;
}

class weapon_cofanaconda : ScriptBasePlayerWeaponEntity, weapon_base
{
	private CBasePlayer@ m_pPlayer
	{
		get const 	{ return cast<CBasePlayer@>( self.m_hPlayer.GetEntity() ); }
		set       	{ self.m_hPlayer = EHandle( @value ); }
	}
	//for weapon functions/modes
	//int m_iANACONDAMagEmpty;
	int mag_counter;
	bool m_WasDrawn;
	private int iBody;
	private int m_iCurBodyConfig = 0;

	// Other Sounds
	private array<string> anacondaSounds = {
		CoFANACONDA::ANACONDA_EMPTY_SOUND,
		"cof/guns/anaconda/close.ogg",
		"cof/guns/anaconda/cock.ogg",
		"cof/guns/anaconda/dump.ogg",
		"cof/guns/anaconda/open.ogg",
		"cof/guns/anaconda/speed.ogg"
	};

	private int GetBodygroup()
	{
		m_iCurBodyConfig = g_ModelFuncs.SetBodygroup( g_ModelFuncs.ModelIndex( CoFANACONDA::ANACONDA_V_MODEL ), m_iCurBodyConfig, 3, iBody );

		return m_iCurBodyConfig;
	}
	private int SetBodygroup()
	{
		if( self.m_iClip >= 6 )
			m_iCurBodyConfig = g_ModelFuncs.SetBodygroup( g_ModelFuncs.ModelIndex( CoFANACONDA::ANACONDA_V_MODEL ), m_iCurBodyConfig, 2, 6 );
		else if( self.m_iClip <= 0 )
			m_iCurBodyConfig = g_ModelFuncs.SetBodygroup( g_ModelFuncs.ModelIndex( CoFANACONDA::ANACONDA_V_MODEL ), m_iCurBodyConfig, 2, 0 );
		else
			m_iCurBodyConfig = g_ModelFuncs.SetBodygroup( g_ModelFuncs.ModelIndex( CoFANACONDA::ANACONDA_V_MODEL ), m_iCurBodyConfig, 2, self.m_iClip );

		if( m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType ) + self.m_iClip >= 6 )
		{
			iBody = 5;
			m_iCurBodyConfig = g_ModelFuncs.SetBodygroup( g_ModelFuncs.ModelIndex( CoFANACONDA::ANACONDA_V_MODEL ), m_iCurBodyConfig, 4, iBody );
		}
		else if( m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType ) + self.m_iClip <= 1 )
		{
			iBody = 0;
			m_iCurBodyConfig = g_ModelFuncs.SetBodygroup( g_ModelFuncs.ModelIndex( CoFANACONDA::ANACONDA_V_MODEL ), m_iCurBodyConfig, 4, iBody );
		}
		else
		{
			iBody = m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType ) + (self.m_iClip - 1);
			m_iCurBodyConfig = g_ModelFuncs.SetBodygroup( g_ModelFuncs.ModelIndex( CoFANACONDA::ANACONDA_V_MODEL ), m_iCurBodyConfig, 4, iBody );
		}

		return m_iCurBodyConfig;
	}

	void Spawn()
	{
		Precache();
		g_EntityFuncs.SetModel( self, CoFANACONDA::ANACONDA_W_MODEL );

		self.m_iDefaultAmmo = CoFANACONDA::ANACONDA_DEFAULT_GIVE;
		g_iMode_ironsights = CoF_MODE_NOTAIMED;
		m_WasDrawn = false;
		mag_counter = 0;
		iBody = 5;

		iAnimation  = CoFANACONDA_MELEE;
		iAnimation2 = CoFANACONDA_MELEE;

		self.FallInit();
	}
	
	void Precache()
	{
		self.PrecacheCustomModels();
		g_Game.PrecacheModel( CoFANACONDA::ANACONDA_W_MODEL );
		g_Game.PrecacheModel( CoFANACONDA::ANACONDA_V_MODEL );
		g_Game.PrecacheModel( CoFANACONDA::ANACONDA_P_MODEL );
		g_Game.PrecacheModel( CoFANACONDA::ANACONDA_A_MODEL );

		g_Game.PrecacheModel( g_watersplash_spr );
		m_iShell         	= g_Game.PrecacheModel( mShellModel[9] ); //.454 Casull

		CommonPrecache(); //Common sounds to all weapons
		PrecacheSound( anacondaSounds );

		g_SoundSystem.PrecacheSound( CoFANACONDA::ANACONDA_SHOOT_SOUND );
		g_Game.PrecacheGeneric( "sound/" + CoFANACONDA::ANACONDA_SHOOT_SOUND );

		g_Game.PrecacheModel( "sprites/cof/wpn_sel03.spr" );
		g_Game.PrecacheGeneric( "sprites/" + "cof/wpn_sel03.spr" );
		g_Game.PrecacheGeneric( "sprites/" + "cof/revolver/weapon_cofanaconda.txt" );
	}
	
	bool GetItemInfo( ItemInfo& out info )
	{
		info.iMaxAmmo1 	= CoFANACONDA::ANACONDA_MAX_CARRY;
		info.iMaxAmmo2 	= -1;
		info.iMaxClip 	= CoFANACONDA::ANACONDA_MAX_CLIP;
		info.iSlot  	= CoFANACONDA::SLOT;
		info.iPosition 	= CoFANACONDA::POSITION;
		info.iId     	= g_ItemRegistry.GetIdForName( self.pev.classname );
		info.iFlags 	= ITEM_FLAG_NOAUTORELOAD | ITEM_FLAG_NOAUTOSWITCHEMPTY | ITEM_FLAG_SELECTONEMPTY;
		info.iWeight 	= CoFANACONDA::ANACONDA_WEIGHT;

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
			g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_AUTO, CoFANACONDA::ANACONDA_EMPTY_SOUND, 0.9, ATTN_NORM, 0, PITCH_NORM );
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
				bResult = Deploy( CoFANACONDA::ANACONDA_V_MODEL, CoFANACONDA::ANACONDA_P_MODEL, CoFANACONDA_DRAW_FIRST, "python", GetBodygroup() );
				deployTime = 2.4f;
				m_WasDrawn = true;
			}
			else if( m_WasDrawn == true )
			{
				bResult = Deploy( CoFANACONDA::ANACONDA_V_MODEL, CoFANACONDA::ANACONDA_P_MODEL, CoFANACONDA_DRAW, "python", GetBodygroup() );
				deployTime = 0.68f;
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
		self.SendWeaponAnim( CoFANACONDA_HOLSTER );
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
			self.SendWeaponAnim( (g_iMode_ironsights == CoF_MODE_AIMED) ? CoFANACONDA_SHOOT_EMPTY_IRON : CoFANACONDA_SHOOT_EMPTY, 0, GetBodygroup() );
			return;
		}

		mag_counter++;
		self.m_flNextPrimaryAttack = WeaponTimeBase() + 0.25f;
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

		FireTrueBullet( CoFANACONDA::ANACONDA_SHOOT_SOUND, false, CoFANACONDA::ANACONDA_DAMAGE, vecCone, 8192, false, DMG_GENERIC );

		float m_iPunchAngle;
		if( (m_pPlayer.pev.flags & FL_DUCKING != 0) ) // Player is ducking
		{
			m_iPunchAngle = (g_iMode_ironsights == CoF_MODE_AIMED) ? Math.RandomFloat( -2.00f, -2.50f ) : Math.RandomFloat( -3, -4 );
		}
		else if( !(m_pPlayer.pev.flags & FL_DUCKING != 0) ) // Player is not ducking
		{
			m_iPunchAngle = (g_iMode_ironsights == CoF_MODE_AIMED) ? Math.RandomFloat( -3, -2 ) : Math.RandomFloat( -5, -4 );
		}
		punchangle( m_iPunchAngle, Math.RandomFloat( -0.5, 0.5 ), (RandomSeed() < 0.5) ? Math.RandomFloat( -1, -0.9 ) : Math.RandomFloat( 0.9, 1 ) );

		if( g_iMode_ironsights == CoF_MODE_AIMED )
		{
			self.SendWeaponAnim( CoFANACONDA_SHOOT_IRON, 0, GetBodygroup() );
		}
		else if( g_iMode_ironsights == CoF_MODE_NOTAIMED )
		{
			self.SendWeaponAnim( CoFANACONDA_SHOOT1 + Math.RandomLong( 0, 1 ), 0, GetBodygroup() );
		}

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
				self.SendWeaponAnim( CoFANACONDA_TO_IRON, 0, GetBodygroup() );
				EffectsFOVON( 40 );
				break;
			}
			case CoF_MODE_AIMED:
			{
				self.SendWeaponAnim( CoFANACONDA_FROM_IRON, 0, GetBodygroup() );
				EffectsFOVOFF();
				break;
			}
		}
	}

	void TertiaryAttack()
	{
		if( !Swing( 1, 37, GetBodygroup(), 1.0f, 22, false ) )
		{
			SetThink( ThinkFunction( this.SwingAgain ) );
			self.pev.nextthink = g_Engine.time + 0.1;
		}
	}

	void SwingAgain()
	{
		Swing( 0, 37, GetBodygroup(), 1.0f, 22, false );
	}

	void ItemPreFrame()
	{
		if( m_reloadTimer < g_Engine.time && canReload )
			self.Reload();

		BaseClass.ItemPreFrame();
	}

	void Reload()
	{
		if( self.m_iClip == CoFANACONDA::ANACONDA_MAX_CLIP || m_pPlayer.m_rgAmmo(self.m_iPrimaryAmmoType) <= 0 )
			return;
			
		if( g_iMode_ironsights == CoF_MODE_AIMED )
		{
			self.SendWeaponAnim( CoFANACONDA_FROM_IRON, 0, GetBodygroup() );
			m_reloadTimer = g_Engine.time + 0.2;
			m_pPlayer.m_flNextAttack = 0.2;
			canReload = true;
		}
		EffectsFOVOFF();

		if( m_reloadTimer < g_Engine.time )
		{
			Reload( CoFANACONDA::ANACONDA_MAX_CLIP, CoFANACONDA_RELOAD, 3.83f, SetBodygroup() );
			self.m_flTimeWeaponIdle = self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = self.m_flNextTertiaryAttack = g_Engine.time + (59.0/37.0) + (82.0/37.0);
			canReload = false;
		}
		
		if( mag_counter > 0 )
		{
			self.pev.nextthink = WeaponTimeBase() + (59.0/37.0);
			SetThink( ThinkFunction( this.EjectClipThink ) );
		}

		BaseClass.Reload();
	}

	void EjectClipThink()
	{
		SetThink( null );
		Vector vecVelocity = m_pPlayer.pev.view_ofs + g_Engine.v_right * Math.RandomLong( -16, 16 ) + g_Engine.v_up * Math.RandomLong( 16, 32 ) + g_Engine.v_forward * Math.RandomLong( -36, -28 );
		ClipCasting( m_pPlayer.pev.origin, vecVelocity, m_iShell, true, mag_counter );
		mag_counter = 0;
	}

	void WeaponIdle()
	{
		if( m_iDroppedClip == 1 )
			m_iDroppedClip = 0;

		self.ResetEmptySound();
		m_pPlayer.GetAutoaimVector( AUTOAIM_10DEGREES );

		if( self.m_flTimeWeaponIdle > WeaponTimeBase() )
			return;

		if( g_iMode_ironsights == CoF_MODE_AIMED )
			self.SendWeaponAnim( CoFANACONDA_IDLE_IRON, 0, GetBodygroup() );
		else
			self.SendWeaponAnim( CoFANACONDA_IDLE, 0, GetBodygroup() );

		self.m_flTimeWeaponIdle = WeaponTimeBase() + g_PlayerFuncs.SharedRandomFloat( m_pPlayer.random_seed, 5, 7 );
	}
}

class Casull454 : ScriptBasePlayerAmmoEntity, ammo_base
{
	void Spawn()
	{
		Precache();
		g_EntityFuncs.SetModel( self, CoFANACONDA::ANACONDA_A_MODEL );
		BaseClass.Spawn();
	}
	
	void Precache()
	{
		g_Game.PrecacheModel( CoFANACONDA::ANACONDA_A_MODEL );
		g_SoundSystem.PrecacheSound( CoFCOMMON::ITEM_SOUND_PICK );
	}

	bool AddAmmo( CBaseEntity@ pOther )
	{
		return CommonAddAmmo( pOther, CoFANACONDA::ANACONDA_MAX_CLIP, CoFANACONDA::ANACONDA_MAX_CARRY, (p_Customizable) ? "ammo_454casul" : "357" );
	}
}

string CoFANACONDAAmmoName()
{
	return "ammo_454casul";
}

string CoFANACONDAName()
{
	return "weapon_cofanaconda";
}

void RegisterCoFANACONDA()
{
	g_CustomEntityFuncs.RegisterCustomEntity( CoFANACONDAName(), CoFANACONDAName() );
	g_CustomEntityFuncs.RegisterCustomEntity( "Casull454", CoFANACONDAAmmoName() );
	g_ItemRegistry.RegisterWeapon( CoFANACONDAName(), "cof/revolver", (p_Customizable) ? "ammo_454casul" : "357", "", CoFANACONDAAmmoName() );
}