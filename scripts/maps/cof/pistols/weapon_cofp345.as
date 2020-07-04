// Author: KernCore

#include "../base"

enum CoFP345Animations_e
{
	CoFP345_IDLE = 0,
	CoFP345_IDLE_NOSHOOT,
	CoFP345_SHOOT1,
	CoFP345_SHOOT1_EMPTY,
	CoFP345_RELOAD,
	CoFP345_RELOAD_NOSHOOT,
	CoFP345_DRAW,
	CoFP345_DRAW_NOSHOOT,
	CoFP345_HOLSTER,
	CoFP345_HOLSTER_NOSHOOT,
	CoFP345_SPRINT_TO,
	CoFP345_SPRINT_IDLE,
	CoFP345_SPRINT_FROM,
	CoFP345_SPRINT_TO_NOSHOOT,
	CoFP345_SPRINT_IDLE_NOSHOOT,
	CoFP345_SPRINT_FROM_NOSHOOT,
	CoFP345_SHOOT_NOSHOOT,
	CoFP345_MELEE,
	CoFP345_MELEE_NOSHOOT,
	CoFP345_IRON_TO,
	CoFP345_IRON_TO_NOSHOOT,
	CoFP345_IRON_IDLE,
	CoFP345_IRON_IDLE_NOSHOOT,
	CoFP345_IRON_FROM,
	CoFP345_IRON_FROM_NOSHOOT,
	CoFP345_IRON_SHOOT,
	CoFP345_IRON_SHOOT_EMPTY,
	CoFP345_IRON_SHOOT_NOSHOOT,
	CoFP345_FIDGET1,
	CoFP345_FIDGET1_NOSHOOT,
	CoFP345_FIDGET2,
	CoFP345_FIDGET2_NOSHOOT,
	CoFP345_FIDGET3,
	CoFP345_FIDGET3_NOSHOOT,
	CoFP345_SUICIDE,
	CoFP345_SUICIDE_NOSHOOT
};

namespace CoFP345
{
	//models
	string P345_W_MODEL       	= "models/cof/p345/wrd.mdl";
	string P345_V_MODEL       	= "models/cof/p345/vwm.mdl";
	string P345_P_MODEL       	= "models/cof/p345/plr.mdl";
	string P345_A_MODEL       	= "models/cof/p345/mag.mdl";
	string P345_MAGEMPTY_MODEL 	= "models/cof/p345/mag_e.mdl";
	//sounds
	const string P345_SHOOT_SOUND   	= "cof/guns/p345/shoot.ogg";
	const string P345_EMPTY_SOUND   	= "cof/guns/p345/empty.ogg";
	//weapon information
	const int P345_MAX_CARRY     	= (p_Customizable) ? 80 : 36;
	const int P345_MAX_CLIP      	= 8;
	const int P345_DEFAULT_GIVE  	= P345_MAX_CLIP * 3;
	const int P345_WEIGHT        	= 20;
	uint P345_DAMAGE              	= 25;
	//iSlot and iPosition in the Hud
	uint SLOT     	= 1;
	uint POSITION 	= 9;
}

class weapon_cofp345 : ScriptBasePlayerWeaponEntity, weapon_base
{
	private CBasePlayer@ m_pPlayer
	{
		get const 	{ return cast<CBasePlayer@>( self.m_hPlayer.GetEntity() ); }
		set       	{ self.m_hPlayer = EHandle( @value ); }
	}
	//for weapon functions/modes
	int m_iP345MagEmpty;
	int mag_counter;

	// Other Sounds
	private array<string> p345Sounds = {
		CoFP345::P345_EMPTY_SOUND,
		"cof/guns/p345/magin.ogg",
		"cof/guns/p345/magout.ogg",
		"cof/guns/p345/slide.ogg"
	};

	void Spawn()
	{
		Precache();
		g_EntityFuncs.SetModel( self, CoFP345::P345_W_MODEL );
		
		self.m_iDefaultAmmo = CoFP345::P345_DEFAULT_GIVE;
		g_iMode_ironsights = CoF_MODE_NOTAIMED;
		mag_counter = CoFP345::P345_MAX_CLIP;

		iAnimation  = CoFP345_MELEE;
		iAnimation2 = CoFP345_MELEE_NOSHOOT;
		
		self.FallInit();
	}
	
	void Precache()
	{
		self.PrecacheCustomModels();
		g_Game.PrecacheModel( CoFP345::P345_W_MODEL );
		g_Game.PrecacheModel( CoFP345::P345_V_MODEL );
		g_Game.PrecacheModel( CoFP345::P345_P_MODEL );
		g_Game.PrecacheModel( CoFP345::P345_A_MODEL );

		g_Game.PrecacheModel( g_watersplash_spr );
		m_iP345MagEmpty	= g_Game.PrecacheModel( CoFP345::P345_MAGEMPTY_MODEL );
		m_iShell    	= g_Game.PrecacheModel( mShellModel[2] ); //45acp

		CommonPrecache(); //Common sounds to all weapons
		PrecacheSound( p345Sounds );

		g_SoundSystem.PrecacheSound( CoFP345::P345_SHOOT_SOUND );
		g_Game.PrecacheGeneric( "sound/" + CoFP345::P345_SHOOT_SOUND );

		g_Game.PrecacheModel( "sprites/cof/wpn_sel02.spr" );
		g_Game.PrecacheGeneric( "sprites/" + "cof/wpn_sel02.spr" );
		g_Game.PrecacheGeneric( "sprites/" + "cof/pistol/weapon_cofp345.txt" );
	}
	
	bool GetItemInfo( ItemInfo& out info )
	{
		info.iMaxAmmo1 	= CoFP345::P345_MAX_CARRY;
		info.iMaxAmmo2 	= -1;
		info.iMaxClip 	= CoFP345::P345_MAX_CLIP;
		info.iSlot  	= CoFP345::SLOT;
		info.iPosition 	= CoFP345::POSITION;
		info.iId     	= g_ItemRegistry.GetIdForName( self.pev.classname );
		info.iFlags 	= ITEM_FLAG_NOAUTORELOAD | ITEM_FLAG_NOAUTOSWITCHEMPTY | ITEM_FLAG_SELECTONEMPTY;
		info.iWeight 	= CoFP345::P345_WEIGHT;

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
			g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_AUTO, CoFP345::P345_EMPTY_SOUND, 0.9, ATTN_NORM, 0, PITCH_NORM );
		}
		
		return false;
	}
	
	bool Deploy()
	{
		bool bResult;
		{
			bResult = Deploy( CoFP345::P345_V_MODEL, CoFP345::P345_P_MODEL, (self.m_iClip == 0) ? CoFP345_DRAW_NOSHOOT : CoFP345_DRAW, "onehanded", 1 );

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
		self.SendWeaponAnim( CoFP345_HOLSTER );
		canReload = false;
		SetThink( null );

		BaseClass.Holster( skipLocal );
	}
	
	void PrimaryAttack()
	{
		if( ( m_pPlayer.m_afButtonPressed & IN_ATTACK == 0 ) )
			return;

		if( m_pPlayer.pev.waterlevel == WATERLEVEL_HEAD )
		{
			self.PlayEmptySound();
			self.m_flNextPrimaryAttack = WeaponTimeBase() + 0.5f;
			return;
		}

		if( self.m_iClip <= 0 )
		{
			self.PlayEmptySound();
			self.m_flNextPrimaryAttack = WeaponTimeBase() + 0.5f;
			self.SendWeaponAnim( (g_iMode_ironsights == CoF_MODE_AIMED) ? CoFP345_IRON_SHOOT_NOSHOOT : CoFP345_SHOOT_NOSHOOT, 0, 1 );
			return;
		}

		mag_counter--;
		self.m_flNextPrimaryAttack = WeaponTimeBase() + 0.15;
		self.m_flNextSecondaryAttack = WeaponTimeBase() + 0.1;
		self.m_flNextTertiaryAttack = WeaponTimeBase() + 0.3;
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

		FireTrueBullet( CoFP345::P345_SHOOT_SOUND, false, CoFP345::P345_DAMAGE, vecCone, 8192, false, DMG_GENERIC );

		float m_iPunchAngle;
		if( (m_pPlayer.pev.flags & FL_DUCKING != 0) ) // Player is ducking
		{
			m_iPunchAngle = (g_iMode_ironsights == CoF_MODE_AIMED) ? Math.RandomFloat( -2.00f, -2.50f ) : Math.RandomFloat( -3.00f, -4.00f );
		}
		else if( !(m_pPlayer.pev.flags & FL_DUCKING != 0) ) // Player is not ducking
		{
			m_iPunchAngle = (g_iMode_ironsights == CoF_MODE_AIMED) ? Math.RandomFloat( -2.50f, -2.75f ) : Math.RandomFloat( -3.50f, -4.50f );
		}
		punchangle( m_iPunchAngle, Math.RandomFloat( -0.5, 0.5 ), Math.RandomFloat( -0.2, 0.2 ) );

		if( g_iMode_ironsights == CoF_MODE_AIMED )
		{
			self.SendWeaponAnim( (self.m_iClip > 0) ? CoFP345_IRON_SHOOT : CoFP345_IRON_SHOOT_EMPTY, 0, 1 );
		}
		else if( g_iMode_ironsights == CoF_MODE_NOTAIMED )
		{
			self.SendWeaponAnim( (self.m_iClip > 0) ? CoFP345_SHOOT1 : CoFP345_SHOOT1_EMPTY, 0, 1 );
		}

		Vector vecShellVelocity, vecShellOrigin;

		if( g_iMode_ironsights == CoF_MODE_NOTAIMED )
			CoFGetDefaultShellInfo( m_pPlayer, vecShellVelocity, vecShellOrigin, 23, 5, -7, false, false );
		else
			CoFGetDefaultShellInfo( m_pPlayer, vecShellVelocity, vecShellOrigin, 23, 0, -1.5, false, false );

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
				self.SendWeaponAnim( (self.m_iClip > 0) ? CoFP345_IRON_TO : CoFP345_IRON_TO_NOSHOOT, 0, 1 );
				EffectsFOVON( 45 );
				break;
			}
			case CoF_MODE_AIMED:
			{
				self.SendWeaponAnim( (self.m_iClip > 0) ? CoFP345_IRON_FROM : CoFP345_IRON_FROM_NOSHOOT, 0, 1 );
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
		if( self.m_iClip == CoFP345::P345_MAX_CLIP || m_pPlayer.m_rgAmmo(self.m_iPrimaryAmmoType) <= 0 )
			return;
			
		if( g_iMode_ironsights == CoF_MODE_AIMED )
		{
			self.SendWeaponAnim( (self.m_iClip > 0) ? CoFP345_IRON_FROM : CoFP345_IRON_FROM_NOSHOOT, 0, 1 );
			m_reloadTimer = g_Engine.time + 0.2;
			m_pPlayer.m_flNextAttack = 0.2;
			canReload = true;
		}
		EffectsFOVOFF();

		if( m_reloadTimer < g_Engine.time )
		{
			(self.m_iClip == 0) ? Reload( CoFP345::P345_MAX_CLIP, CoFP345_RELOAD_NOSHOOT, 3.16f, 1 ) : Reload( CoFP345::P345_MAX_CLIP, CoFP345_RELOAD, 2.6f, 1 );
			canReload = false;
		}
		
		if( mag_counter <= 0 )
		{
			self.pev.nextthink = WeaponTimeBase() + 0.7f;
			SetThink( ThinkFunction( EjectClipThink ) );
		}

		BaseClass.Reload();
	}

	void EjectClipThink()
	{
		mag_counter = CoFP345::P345_MAX_CLIP;
		ClipCasting( m_pPlayer.pev.origin, m_pPlayer.pev.view_ofs + g_Engine.v_right * -34 + g_Engine.v_up * 16 + g_Engine.v_forward * 16, m_iP345MagEmpty, false, 0 );
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
			self.SendWeaponAnim( (self.m_iClip > 0) ? CoFP345_IRON_IDLE : CoFP345_IRON_IDLE_NOSHOOT, 0, 1 );
		}
		else if( g_iMode_ironsights == CoF_MODE_NOTAIMED )
		{
			switch( g_PlayerFuncs.SharedRandomLong( m_pPlayer.random_seed,  0, 3 ) )
			{
				case 0:	iAnim = (self.m_iClip > 0) ? CoFP345_IDLE : CoFP345_IDLE_NOSHOOT;
				break;
			
				case 1: iAnim = (self.m_iClip > 0) ? CoFP345_FIDGET1 : CoFP345_FIDGET1_NOSHOOT;
				break;

				case 2: iAnim = (self.m_iClip > 0) ? CoFP345_FIDGET2 : CoFP345_FIDGET2_NOSHOOT;
				break;

				case 3: iAnim = (self.m_iClip > 0) ? CoFP345_FIDGET3 : CoFP345_FIDGET3_NOSHOOT;
				break;
			}

			self.SendWeaponAnim( iAnim, 0, 1 );
		}

		self.m_flTimeWeaponIdle = WeaponTimeBase() + g_PlayerFuncs.SharedRandomFloat( m_pPlayer.random_seed,  5, 7 );
	}
}

class Acp45 : ScriptBasePlayerAmmoEntity, ammo_base
{
	void Spawn()
	{
		Precache();
		g_EntityFuncs.SetModel( self, CoFP345::P345_A_MODEL );
		BaseClass.Spawn();
	}
	
	void Precache()
	{
		g_Game.PrecacheModel( CoFP345::P345_A_MODEL );
		g_SoundSystem.PrecacheSound( CoFCOMMON::ITEM_SOUND_PICK );
	}

	bool AddAmmo( CBaseEntity@ pOther )
	{
		return CommonAddAmmo( pOther, CoFP345::P345_MAX_CLIP, CoFP345::P345_MAX_CARRY, (p_Customizable) ? "ammo_45acp" : "357" );
	}
}

string CoFP345AmmoName()
{
	return "ammo_45acp";
}

string CoFP345Name()
{
	return "weapon_cofp345";
}

void RegisterCoFP345()
{
	g_CustomEntityFuncs.RegisterCustomEntity( CoFP345Name(), CoFP345Name() );
	g_CustomEntityFuncs.RegisterCustomEntity( "Acp45", CoFP345AmmoName() );
	g_ItemRegistry.RegisterWeapon( CoFP345Name(), "cof/pistol", (p_Customizable) ? "ammo_45acp" : "357", "", CoFP345AmmoName() );
}