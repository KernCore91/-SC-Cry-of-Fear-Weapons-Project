// Author: KernCore

#include "../base"

enum CoFVP70Animations_e
{
	CoFVP70_IDLE = 0,
	CoFVP70_DRAW,
	CoFVP70_DRAW_FIRST,
	CoFVP70_HOLSTER,
	CoFVP70_SHOOT,
	CoFVP70_SHOOT_NOSHOOT,
	CoFVP70_RELOAD,
	CoFVP70_RELOAD_NOSHOOT,
	CoFVP70_IRON_TO,
	CoFVP70_IRON_IDLE,
	CoFVP70_IRON_SHOOT,
	CoFVP70_IRON_SHOOT_NOSHOOT,
	CoFVP70_IRON_FROM,
	CoFVP70_SPRINT_TO,
	CoFVP70_SPRINT_IDLE,
	CoFVP70_SPRINT_FROM,
	CoFVP70_JUMP_TO,
	CoFVP70_JUMP_FROM,
	CoFVP70_FIDGET1,
	CoFVP70_FIDGET2,
	CoFVP70_FIDGET3,
	CoFVP70_MELEE,
	CoFVP70_SUICIDE
};

namespace CoFVP70
{
	//models
	string VP70_W_MODEL       	= "models/cof/vp70/wrd.mdl";
	string VP70_V_MODEL       	= "models/cof/vp70/vwm.mdl";
	string VP70_P_MODEL       	= "models/cof/vp70/plr.mdl";
	string VP70_A_MODEL       	= "models/cof/vp70/mag.mdl";
	string VP70_MAGEMPTY_MODEL	= "models/cof/vp70/mag_e.mdl";
	//sounds
	const string VP70_SHOOT_SOUND 	= "cof/guns/vp70/shoot.ogg";
	//weapon information
	const int VP70_MAX_CARRY     	= (p_Customizable) ? 360 : 250;
	const int VP70_MAX_CLIP      	= 18;
	const int VP70_DEFAULT_GIVE  	= VP70_MAX_CLIP * 2;
	const int VP70_WEIGHT        	= 14;
	uint VP70_DAMAGE              	= 13;
	//iSlot and iPosition in the Hud
	uint SLOT     	= 1;
	uint POSITION 	= 6;
}

class weapon_cofvp70 : ScriptBasePlayerWeaponEntity, weapon_base
{
	private CBasePlayer@ m_pPlayer
	{
		get const 	{ return cast<CBasePlayer@>( self.m_hPlayer.GetEntity() ); }
		set       	{ self.m_hPlayer = EHandle( @value ); }
	}
	//for weapon functions/modes
	bool m_WasDrawn;
	int m_iVp70MagEmpty;
	int m_iBurstLeft = 0;
	int m_iBurstCount = 0;
	float m_flNextBurstFireTime = 0;
	Vector vecShellVelocity, vecShellOrigin;
	float m_iPunchAngle;
	Vector vecCone;
	int mag_counter;

	// Other Sounds
	private array<string> vp70Sounds = {
		"cof/guns/vp70/sldrel.ogg",
		"cof/guns/vp70/magin.ogg",
		"cof/guns/vp70/magout.ogg"
	};

	void Spawn()
	{
		Precache();
		g_EntityFuncs.SetModel( self, CoFVP70::VP70_W_MODEL );

		self.m_iDefaultAmmo = CoFVP70::VP70_DEFAULT_GIVE;
		g_iMode_ironsights = CoF_MODE_NOTAIMED;
		m_WasDrawn = false;
		mag_counter = CoFVP70::VP70_MAX_CLIP;

		iAnimation	= CoFVP70_MELEE;
		iAnimation2	= CoFVP70_MELEE;

		self.FallInit();
	}

	void Precache()
	{
		self.PrecacheCustomModels();
		g_Game.PrecacheModel( CoFVP70::VP70_W_MODEL );
		g_Game.PrecacheModel( CoFVP70::VP70_V_MODEL );
		g_Game.PrecacheModel( CoFVP70::VP70_P_MODEL );
		g_Game.PrecacheModel( CoFVP70::VP70_A_MODEL );
		g_Game.PrecacheModel( g_watersplash_spr );
		m_iVp70MagEmpty	= g_Game.PrecacheModel( CoFVP70::VP70_MAGEMPTY_MODEL );
		m_iShell    	= g_Game.PrecacheModel( mShellModel[0] ); //9mm

		CommonPrecache(); //Common sounds to all weapons
		PrecacheSound( vp70Sounds );

		g_SoundSystem.PrecacheSound( CoFVP70::VP70_SHOOT_SOUND );
		g_SoundSystem.PrecacheSound( EMPTY_SHOOT_SOUND );
		g_Game.PrecacheGeneric( "sound/" + CoFVP70::VP70_SHOOT_SOUND );
		g_Game.PrecacheGeneric( "sound/" + EMPTY_SHOOT_SOUND );

		g_Game.PrecacheModel( "sprites/cof/wpn_sel02.spr" );
		g_Game.PrecacheGeneric( "sprites/" + "cof/wpn_sel02.spr" );
		g_Game.PrecacheGeneric( "sprites/" + "cof/pistol/weapon_cofvp70.txt" );
	}

	bool GetItemInfo( ItemInfo& out info )
	{
		info.iMaxAmmo1 	= CoFVP70::VP70_MAX_CARRY;
		info.iMaxAmmo2 	= -1;
		info.iMaxClip 	= CoFVP70::VP70_MAX_CLIP;
		info.iSlot  	= CoFVP70::SLOT;
		info.iPosition 	= CoFVP70::POSITION;
		info.iId     	= g_ItemRegistry.GetIdForName( self.pev.classname );
		info.iFlags 	= ITEM_FLAG_NOAUTORELOAD | ITEM_FLAG_NOAUTOSWITCHEMPTY | ITEM_FLAG_SELECTONEMPTY;
		info.iWeight 	= CoFVP70::VP70_WEIGHT;

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
				bResult = Deploy( CoFVP70::VP70_V_MODEL, CoFVP70::VP70_P_MODEL, CoFVP70_DRAW_FIRST, "onehanded", 1 );
				deployTime = 3.5f;
				m_WasDrawn = true;
			}
			else if( m_WasDrawn == true )
			{
				bResult = Deploy( CoFVP70::VP70_V_MODEL, CoFVP70::VP70_P_MODEL, CoFVP70_DRAW, "onehanded", 1 );
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
		m_iBurstLeft = 0;
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
			self.SendWeaponAnim( (g_iMode_ironsights == CoF_MODE_AIMED) ? CoFVP70_IRON_SHOOT_NOSHOOT : CoFVP70_SHOOT_NOSHOOT, 0, 1 ) ;
			return;
		}
		
		//Fire at most 3 bullets.
		m_iBurstCount = Math.min( 3, self.m_iClip );
		m_iBurstLeft = m_iBurstCount - 1;

		m_flNextBurstFireTime = WeaponTimeBase() + 0.035;
		//Prevent primary attack before burst finishes. Might need to be finetuned.
		self.m_flNextPrimaryAttack = WeaponTimeBase() + 0.45;
		self.m_flNextTertiaryAttack = self.m_flNextSecondaryAttack = WeaponTimeBase() + 0.35;

		FirstAttackCommon();
	}

	private void FirstAttackCommon()
	{
		self.SendWeaponAnim( (g_iMode_ironsights == CoF_MODE_AIMED) ? CoFVP70_IRON_SHOOT : CoFVP70_SHOOT, 0, 1 );

		// Accuracy Checks
		if( m_pPlayer.pev.velocity == g_vecZero ) // Player is not moving
			vecCone = (g_iMode_ironsights == CoF_MODE_AIMED) ? g_vecZero : VECTOR_CONE_2DEGREES;
		else if( m_pPlayer.pev.velocity != g_vecZero ) // Player is moving
			vecCone = (g_iMode_ironsights == CoF_MODE_AIMED) ? VECTOR_CONE_1DEGREES : VECTOR_CONE_3DEGREES;

		FireTrueBullet( CoFVP70::VP70_SHOOT_SOUND, false, 13, vecCone, 8192, false, DMG_GENERIC, true );
		mag_counter--;

		if( g_iMode_ironsights == CoF_MODE_NOTAIMED )
			CoFGetDefaultShellInfo( m_pPlayer, vecShellVelocity, vecShellOrigin, 22, 5, -7, false, false );
		else
			CoFGetDefaultShellInfo( m_pPlayer, vecShellVelocity, vecShellOrigin, 22, 0, -2, false, false );

		vecShellVelocity.y *= 1;
		g_EntityFuncs.EjectBrass( vecShellOrigin, vecShellVelocity, m_pPlayer.pev.angles[ 1 ], m_iShell, TE_BOUNCE_SHELL );

		if( (m_pPlayer.pev.flags & FL_DUCKING != 0) ) // Player is ducking
			m_iPunchAngle = (g_iMode_ironsights == CoF_MODE_AIMED) ? Math.RandomFloat( -1.1f, -0.95f ) : Math.RandomLong( -2, -1 );
		else if( !(m_pPlayer.pev.flags & FL_DUCKING != 0) ) // Player is not ducking
			m_iPunchAngle = (g_iMode_ironsights == CoF_MODE_AIMED) ? Math.RandomFloat( -1.7f, -1.55f ) : Math.RandomLong( -3, -1 );

		punchangle( m_iPunchAngle, Math.RandomFloat( -0.5, 0.5 ), Math.RandomFloat( -0.2, 0.2 ), true );
	}

	void SecondaryAttack()
	{
		self.m_flNextSecondaryAttack = self.m_flTimeWeaponIdle = WeaponTimeBase() + 0.2;
		self.m_flNextPrimaryAttack = self.m_flNextTertiaryAttack = WeaponTimeBase() + 0.15;
		g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_ITEM, CoFCOMMON::DEPLOY_SLEEVE3, 0.9, ATTN_NORM, 0, PITCH_NORM );
		
		switch( g_iMode_ironsights )
		{
			case CoF_MODE_NOTAIMED:
			{
				self.SendWeaponAnim( CoFVP70_IRON_TO, 0, 1 );
				EffectsFOVON( 40 );
				break;
			}
			case CoF_MODE_AIMED:
			{
				self.SendWeaponAnim( CoFVP70_IRON_FROM, 0, 1 );
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

	//Overridden to prevent WeaponIdle from being blocked by holding down buttons.
	void ItemPostFrame()
	{
		//If firing bursts, handle next shot.
		if( m_iBurstLeft > 0 )
		{
			if( m_flNextBurstFireTime < WeaponTimeBase() )
			{
				if( self.m_iClip <= 0 )
				{
					m_iBurstLeft = 0;
					return;
				}
				else
				{
					--m_iBurstLeft;
				}

				FirstAttackCommon();

				if( m_iBurstLeft > 0 )
					m_flNextBurstFireTime = WeaponTimeBase() + 0.06;
				else
					m_flNextBurstFireTime = 0;
			}

			//While firing a burst, don't allow reload or any other weapon actions. Might be best to let some things run though.
			return;
		}

		BaseClass.ItemPostFrame();
	}

	void TertiaryAttack()
	{
		if( !Swing( 1, 37, 1, 1.0f, 21, false ) )
		{
			SetThink( ThinkFunction( this.SwingAgain ) );
			self.pev.nextthink = g_Engine.time + 0.1;
		}
	}

	void SwingAgain()
	{
		Swing( 0, 37, 1, 1.0f, 21, false );
	}

	void Reload()
	{
		if( self.m_iClip == CoFVP70::VP70_MAX_CLIP || m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType ) == 0 )
			return;

		if( g_iMode_ironsights == CoF_MODE_AIMED )
		{
			self.SendWeaponAnim( CoFVP70_IRON_FROM, 0, 1 );
			m_reloadTimer = g_Engine.time + 0.2;
			m_pPlayer.m_flNextAttack = 0.2;
			canReload = true;
		}
		EffectsFOVOFF();
		
		if( m_reloadTimer < g_Engine.time )
		{
			(self.m_iClip == 0) ? Reload( CoFVP70::VP70_MAX_CLIP, CoFVP70_RELOAD_NOSHOOT, 3.66f, 1 ) : Reload( CoFVP70::VP70_MAX_CLIP, CoFVP70_RELOAD, 2.53f, 1 );
			canReload = false;
		}

		if( mag_counter <= 0 )
		{
			self.pev.nextthink = WeaponTimeBase() + 0.73f;
			SetThink( ThinkFunction( EjectClipThink ) );
		}

		BaseClass.Reload();
	}

	void EjectClipThink()
	{
		mag_counter = CoFVP70::VP70_MAX_CLIP;
		ClipCasting( m_pPlayer.pev.origin, m_pPlayer.pev.view_ofs + g_Engine.v_right * -56 + g_Engine.v_up * 16 + g_Engine.v_forward * 16, m_iVp70MagEmpty, false, 0 );
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
			self.SendWeaponAnim( CoFVP70_IRON_IDLE, 0, 1 );
		}
		else if( g_iMode_ironsights == CoF_MODE_NOTAIMED )
		{
			switch( g_PlayerFuncs.SharedRandomLong( m_pPlayer.random_seed,  0, 3 ) )
			{
				case 0:	iAnim = CoFVP70_IDLE;
				break;
			
				case 1: iAnim = CoFVP70_FIDGET1;
				break;

				case 2: iAnim = CoFVP70_FIDGET2;
				break;

				case 3: iAnim = CoFVP70_FIDGET3;
				break;
			}
			self.SendWeaponAnim( iAnim, 0, 1 );
		}

		self.m_flTimeWeaponIdle = WeaponTimeBase() + g_PlayerFuncs.SharedRandomFloat( m_pPlayer.random_seed,  5, 7 );
	}
}

class Parabellum9mm_VP70 : ScriptBasePlayerAmmoEntity, ammo_base
{
	void Spawn()
	{
		Precache();
		g_EntityFuncs.SetModel( self, CoFVP70::VP70_A_MODEL );
		BaseClass.Spawn();
	}
	
	void Precache()
	{
		g_Game.PrecacheModel( CoFVP70::VP70_A_MODEL );
		g_SoundSystem.PrecacheSound( CoFCOMMON::ITEM_SOUND_PICK );
	}

	bool AddAmmo( CBaseEntity@ pOther )
	{
		return CommonAddAmmo( pOther, CoFVP70::VP70_MAX_CLIP, CoFVP70::VP70_MAX_CARRY, (p_Customizable) ? "ammo_9mmpara" : "9mm" );
	}
}

string CoFVP70AmmoName()
{
	return "ammo_9mm_vp70";
}

string CoFVP70Name()
{
	return "weapon_cofvp70";
}

void RegisterCoFVP70()
{
	g_CustomEntityFuncs.RegisterCustomEntity( CoFVP70Name(), CoFVP70Name() );
	g_CustomEntityFuncs.RegisterCustomEntity( "Parabellum9mm_VP70", CoFVP70AmmoName() );
	g_ItemRegistry.RegisterWeapon( CoFVP70Name(), "cof/pistol", (p_Customizable) ? "ammo_9mmpara" : "9mm", "", CoFVP70AmmoName() );
}