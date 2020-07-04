// Author: KernCore

#include "../base"

enum CoFBERETTAAnimations_e
{
	CoFBERETTA_IDLE = 0,
	CoFBERETTA_DRAW_FIRST,
	CoFBERETTA_DRAW,
	CoFBERETTA_HOLSTER,
	CoFBERETTA_SHOOT1,
	CoFBERETTA_SHOOT2,
	CoFBERETTA_SHOOT3,
	CoFBERETTA_SHOOT_LAST,
	CoFBERETTA_SHOOT_EMPTY,
	CoFBERETTA_RELOAD,
	CoFBERETTA_RELOAD_EMPTY,
	CoFBERETTA_IDLE_EMPTY,
	CoFBERETTA_DRAW_EMPTY,
	CoFBERETTA_HOLSTER_EMPTY,
	CoFBERETTA_SHOOT1_IRON,
	CoFBERETTA_SHOOT2_IRON,
	CoFBERETTA_SHOOT3_IRON,
	CoFBERETTA_SHOOT_LAST_IRON,
	CoFBERETTA_SHOOT_EMPTY_IRON,
	CoFBERETTA_IDLE_IRON,
	CoFBERETTA_IDLE_EMPTY_IRON,
	CoFBERETTA_TO_IRON,
	CoFBERETTA_FROM_IRON,
	CoFBERETTA_TO_IRON_EMPTY,
	CoFBERETTA_FROM_IRON_EMPTY,
	CoFBERETTA_MELEE,
	CoFBERETTA_MELEE_EMPTY
};

namespace CoFBERETTA
{
	//models
	string BERETTA_W_MODEL      	= "models/cof/beretta/wrd.mdl";
	string BERETTA_V_MODEL      	= "models/cof/beretta/vwm.mdl";
	string BERETTA_P_MODEL      	= "models/cof/beretta/plr.mdl";
	string BERETTA_A_MODEL      	= "models/cof/beretta/mag.mdl";
	string BERETTA_MAGEMPTY_MODEL	= "models/cof/beretta/mag_e.mdl";
	//sounds
	const string BERETTA_SHOOT_SOUND  	= "cof/guns/beretta/shoot.ogg";
	const string BERETTA_EMPTY_SOUND  	= "cof/guns/beretta/empty.ogg";
	//weapon information
	const int BERETTA_MAX_CARRY   	= (p_Customizable) ? 360 : 250;
	const int BERETTA_MAX_CLIP    	= 15;
	const int BERETTA_DEFAULT_GIVE 	= BERETTA_MAX_CLIP * 2;
	const int BERETTA_WEIGHT      	= 20;
	uint BERETTA_DAMAGE            	= 13;
	//iSlot and iPosition in the Hud
	uint SLOT     	= 1;
	uint POSITION 	= 4;
}

class weapon_cofberetta : ScriptBasePlayerWeaponEntity, weapon_base
{
	private CBasePlayer@ m_pPlayer
	{
		get const 	{ return cast<CBasePlayer@>( self.m_hPlayer.GetEntity() ); }
		set       	{ self.m_hPlayer = EHandle( @value ); }
	}
	//for weapon functions/modes
	int m_iBerettaMagEmpty;
	int mag_counter;
	bool m_WasDrawn;

	// Other Sounds
	private array<string> berettaSounds = {
		CoFBERETTA::BERETTA_EMPTY_SOUND,
		"cof/guns/beretta/sldback.ogg",
		"cof/guns/beretta/sldrel.ogg",
		"cof/guns/beretta/maghit.ogg",
		"cof/guns/beretta/magin.ogg",
		"cof/guns/beretta/magout.ogg",
		"cof/guns/beretta/magrel.ogg"
	};

	void Spawn()
	{
		Precache();
		g_EntityFuncs.SetModel( self, CoFBERETTA::BERETTA_W_MODEL );
		
		self.m_iDefaultAmmo = CoFBERETTA::BERETTA_DEFAULT_GIVE;
		g_iMode_ironsights = CoF_MODE_NOTAIMED;
		mag_counter = CoFBERETTA::BERETTA_MAX_CLIP;
		m_WasDrawn = false;

		iAnimation  = CoFBERETTA_MELEE;
		iAnimation2 = CoFBERETTA_MELEE_EMPTY;
		
		self.FallInit();
	}
	
	void Precache()
	{
		self.PrecacheCustomModels();
		g_Game.PrecacheModel( CoFBERETTA::BERETTA_W_MODEL );
		g_Game.PrecacheModel( CoFBERETTA::BERETTA_V_MODEL );
		g_Game.PrecacheModel( CoFBERETTA::BERETTA_P_MODEL );
		g_Game.PrecacheModel( CoFBERETTA::BERETTA_A_MODEL );

		g_Game.PrecacheModel( g_watersplash_spr );
		m_iBerettaMagEmpty 	= g_Game.PrecacheModel( CoFBERETTA::BERETTA_MAGEMPTY_MODEL );
		m_iShell         	= g_Game.PrecacheModel( mShellModel[0] ); //9mm

		CommonPrecache(); //Common sounds to all weapons
		PrecacheSound( berettaSounds );

		g_SoundSystem.PrecacheSound( CoFBERETTA::BERETTA_SHOOT_SOUND );
		g_Game.PrecacheGeneric( "sound/" + CoFBERETTA::BERETTA_SHOOT_SOUND );

		g_Game.PrecacheModel( "sprites/cof/wpn_sel02.spr" );
		g_Game.PrecacheGeneric( "sprites/" + "cof/wpn_sel02.spr" );
		g_Game.PrecacheGeneric( "sprites/" + "cof/pistol/weapon_cofberetta.txt" );
	}
	
	bool GetItemInfo( ItemInfo& out info )
	{
		info.iMaxAmmo1 	= CoFBERETTA::BERETTA_MAX_CARRY;
		info.iMaxAmmo2 	= -1;
		info.iMaxClip 	= CoFBERETTA::BERETTA_MAX_CLIP;
		info.iSlot  	= CoFBERETTA::SLOT;
		info.iPosition 	= CoFBERETTA::POSITION;
		info.iId     	= g_ItemRegistry.GetIdForName( self.pev.classname );
		info.iFlags 	= ITEM_FLAG_NOAUTORELOAD | ITEM_FLAG_NOAUTOSWITCHEMPTY | ITEM_FLAG_SELECTONEMPTY;
		info.iWeight 	= CoFBERETTA::BERETTA_WEIGHT;

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
			g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_AUTO, CoFBERETTA::BERETTA_EMPTY_SOUND, 0.9, ATTN_NORM, 0, PITCH_NORM );
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
				bResult = Deploy( CoFBERETTA::BERETTA_V_MODEL, CoFBERETTA::BERETTA_P_MODEL, CoFANACONDA_DRAW_FIRST, "onehanded", 1 );
				deployTime = 1.26f;
				m_WasDrawn = true;
			}
			else if( m_WasDrawn == true )
			{
				bResult = Deploy( CoFBERETTA::BERETTA_V_MODEL, CoFBERETTA::BERETTA_P_MODEL, (self.m_iClip == 0) ? CoFBERETTA_DRAW_EMPTY : CoFBERETTA_DRAW, "onehanded", 1 );
				deployTime = 0.5f;
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
		self.SendWeaponAnim( CoFBERETTA_HOLSTER );
		canReload = false;
		SetThink( null );

		BaseClass.Holster( skipLocal );
	}
	
	void PrimaryAttack()
	{
		if( ( m_pPlayer.m_afButtonPressed & IN_ATTACK == 0 ) )
			return;

		if( self.m_iClip <= 0 )
		{
			self.PlayEmptySound();
			self.m_flNextPrimaryAttack = WeaponTimeBase() + 0.5f;
			self.SendWeaponAnim( (g_iMode_ironsights == CoF_MODE_AIMED) ? CoFBERETTA_SHOOT_EMPTY_IRON : CoFBERETTA_SHOOT_EMPTY, 0, 1 );
			return;
		}

		mag_counter--;
		self.m_flNextPrimaryAttack = (m_pPlayer.pev.waterlevel == WATERLEVEL_HEAD) ? WeaponTimeBase() + 0.175f : WeaponTimeBase() + 0.113f;
		self.m_flNextSecondaryAttack = WeaponTimeBase() + 0.201f;
		self.m_flNextTertiaryAttack = WeaponTimeBase() + 0.3f;
		self.m_flTimeWeaponIdle = WeaponTimeBase() + 1.0f;

		//Play it before the punchangle, so the accuracy doesn't get screwed
		Vector vecCone;
		if( m_pPlayer.pev.velocity == g_vecZero ) // Player is not moving
		{
			vecCone = (g_iMode_ironsights == CoF_MODE_AIMED) ? VECTOR_CONE_1DEGREES : VECTOR_CONE_2DEGREES;
		}
		else if( m_pPlayer.pev.velocity != g_vecZero ) // Player is moving
		{
			vecCone = (g_iMode_ironsights == CoF_MODE_AIMED) ? VECTOR_CONE_1DEGREES : VECTOR_CONE_3DEGREES;
		}

		FireTrueBullet( CoFBERETTA::BERETTA_SHOOT_SOUND, false, CoFBERETTA::BERETTA_DAMAGE, vecCone, (m_pPlayer.pev.waterlevel == WATERLEVEL_HEAD) ? 3072 : 8192, false, DMG_GENERIC );

		float m_iPunchAngle;
		if( (m_pPlayer.pev.flags & FL_DUCKING != 0) ) // Player is ducking
		{
			m_iPunchAngle = (g_iMode_ironsights == CoF_MODE_AIMED) ? Math.RandomFloat( -1.75f, -1.60f ) : Math.RandomLong( -2, -1 );
		}
		else if( !(m_pPlayer.pev.flags & FL_DUCKING != 0) ) // Player is not ducking
		{
			m_iPunchAngle = (g_iMode_ironsights == CoF_MODE_AIMED) ? Math.RandomFloat( -2.15f, -2.00f ) : Math.RandomLong( -2, -1 );
		}
		punchangle( m_iPunchAngle, Math.RandomFloat( -0.5, 0.5 ), Math.RandomFloat( -1, 1 ) );

		if( g_iMode_ironsights == CoF_MODE_AIMED )
		{
			self.SendWeaponAnim( (self.m_iClip > 0) ? CoFBERETTA_SHOOT1_IRON + Math.RandomLong( 0, 2 ) : CoFBERETTA_SHOOT_LAST_IRON, 0, 1 );
		}
		else if( g_iMode_ironsights == CoF_MODE_NOTAIMED )
		{
			self.SendWeaponAnim( (self.m_iClip > 0) ? CoFBERETTA_SHOOT1 + Math.RandomLong( 0, 2 ) : CoFBERETTA_SHOOT_LAST, 0, 1 );
		}

		Vector vecShellVelocity, vecShellOrigin;

		if( g_iMode_ironsights == CoF_MODE_NOTAIMED )
			CoFGetDefaultShellInfo( m_pPlayer, vecShellVelocity, vecShellOrigin, 23, 5, -7, false, false );
		else
			CoFGetDefaultShellInfo( m_pPlayer, vecShellVelocity, vecShellOrigin, 23, 0.45, -1.65, false, false );

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
				self.SendWeaponAnim( (self.m_iClip > 0) ? CoFBERETTA_TO_IRON : CoFBERETTA_TO_IRON_EMPTY, 0, 1 );
				EffectsFOVON( 45 );
				break;
			}
			case CoF_MODE_AIMED:
			{
				self.SendWeaponAnim( (self.m_iClip > 0) ? CoFBERETTA_FROM_IRON : CoFBERETTA_FROM_IRON_EMPTY, 0, 1 );
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
		if( self.m_iClip == CoFBERETTA::BERETTA_MAX_CLIP || m_pPlayer.m_rgAmmo(self.m_iPrimaryAmmoType) <= 0 )
			return;
			
		if( g_iMode_ironsights == CoF_MODE_AIMED )
		{
			self.SendWeaponAnim( (self.m_iClip > 0) ? CoFBERETTA_FROM_IRON : CoFBERETTA_FROM_IRON_EMPTY, 0, 1 );
			m_reloadTimer = g_Engine.time + 0.2;
			m_pPlayer.m_flNextAttack = 0.2;
			canReload = true;
		}
		EffectsFOVOFF();

		if( m_reloadTimer < g_Engine.time )
		{
			(self.m_iClip == 0) ? Reload( CoFBERETTA::BERETTA_MAX_CLIP, CoFBERETTA_RELOAD_EMPTY, 2.82f, 1 ) : Reload( CoFBERETTA::BERETTA_MAX_CLIP, CoFBERETTA_RELOAD, 2.65f, 1 );
			canReload = false;
		}
		
		if( mag_counter <= 0 )
		{
			self.pev.nextthink = WeaponTimeBase() + 0.9f;
			SetThink( ThinkFunction( EjectClipThink ) );
		}

		BaseClass.Reload();
	}

	void EjectClipThink()
	{
		mag_counter = CoFBERETTA::BERETTA_MAX_CLIP;
		ClipCasting( m_pPlayer.pev.origin, m_pPlayer.pev.view_ofs + g_Engine.v_right * -34 + g_Engine.v_up * 16 + g_Engine.v_forward * 16, m_iBerettaMagEmpty, false, 0 );
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
			self.SendWeaponAnim( (self.m_iClip > 0) ? CoFBERETTA_IDLE_IRON : CoFBERETTA_IDLE_EMPTY_IRON, 0, 1 );
		}
		else if( g_iMode_ironsights == CoF_MODE_NOTAIMED )
		{
			self.SendWeaponAnim( (self.m_iClip > 0) ? CoFBERETTA_IDLE : CoFBERETTA_IDLE_EMPTY, 0, 1 );
		}

		self.m_flTimeWeaponIdle = WeaponTimeBase() + g_PlayerFuncs.SharedRandomFloat( m_pPlayer.random_seed,  5, 7 );
	}
}

class Parabellum9mm_BERETTA : ScriptBasePlayerAmmoEntity, ammo_base
{
	void Spawn()
	{
		Precache();
		g_EntityFuncs.SetModel( self, CoFBERETTA::BERETTA_A_MODEL );
		BaseClass.Spawn();
	}
	
	void Precache()
	{
		g_Game.PrecacheModel( CoFBERETTA::BERETTA_A_MODEL );
		g_SoundSystem.PrecacheSound( CoFCOMMON::ITEM_SOUND_PICK );
	}

	bool AddAmmo( CBaseEntity@ pOther )
	{
		return CommonAddAmmo( pOther, CoFBERETTA::BERETTA_MAX_CLIP, CoFBERETTA::BERETTA_MAX_CARRY, (p_Customizable) ? "ammo_9mmpara" : "9mm" );
	}
}

string CoFBERETTAAmmoName()
{
	return "ammo_9mm_beretta";
}

string CoFBERETTAName()
{
	return "weapon_cofberetta";
}

void RegisterCoFBERETTA()
{
	g_CustomEntityFuncs.RegisterCustomEntity( CoFBERETTAName(), CoFBERETTAName() );
	g_CustomEntityFuncs.RegisterCustomEntity( "Parabellum9mm_BERETTA", CoFBERETTAAmmoName() );
	g_ItemRegistry.RegisterWeapon( CoFBERETTAName(), "cof/pistol", (p_Customizable) ? "ammo_9mmpara" : "9mm", "", CoFBERETTAAmmoName() );
}