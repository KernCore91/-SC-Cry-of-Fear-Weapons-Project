// Author: KernCore

#include "../base"

enum CoFM76Animations_e
{
	CoFM76_IDLE = 0,
	CoFM76_IDLE_EMPTY,
	CoFM76_DRAW,
	CoFM76_DRAW_EMPTY,
	CoFM76_DRAW_FIRST,
	CoFM76_HOLSTER,
	CoFM76_HOLSTER_EMPTY,
	CoFM76_SHOOT1,
	CoFM76_SHOOT2,
	CoFM76_SHOOT3,
	CoFM76_SHOOT_LAST,
	CoFM76_SHOOT_EMPTY,
	CoFM76_RELOAD,
	CoFM76_RELOAD_EMPTY,
	CoFM76_IRON_IDLE,
	CoFM76_IRON_IDLE_EMPTY,
	CoFM76_IRON_SHOOT1,
	CoFM76_IRON_SHOOT2,
	CoFM76_IRON_SHOOT3,
	CoFM76_IRON_SHOOT_LAST,
	CoFM76_IRON_SHOOT_EMPTY,
	CoFM76_IRON_TO,
	CoFM76_IRON_TO_EMPTY,
	CoFM76_IRON_FROM,
	CoFM76_IRON_FROM_EMPTY,
	CoFM76_MELEE,
	CoFM76_MELEE_EMPTY
};

namespace CoFM76
{
	//models
	string M76_W_MODEL      	= "models/cof/m76/wrd.mdl";
	string M76_V_MODEL      	= "models/cof/m76/vwm.mdl";
	string M76_P_MODEL      	= "models/cof/m76/plr.mdl";
	string M76_A_MODEL      	= "models/cof/m76/mag.mdl";
	string M76_MAGEMPTY_MODEL	= "models/cof/m76/mag_e.mdl";
	//sounds
	const string M76_SHOOT_SOUND 	= "cof/guns/m76/shoot.ogg";
	//weapon info
	const int M76_MAX_CARRY   	= (p_Customizable) ? 360 : 250;
	const int M76_MAX_CLIP    	= 36;
	const int M76_DEFAULT_GIVE 	= M76_MAX_CLIP * 2;
	const int M76_WEIGHT      	= 15;
	uint M76_DAMAGE          	= 13;
	//iSlot and iPosition in the Hud
	uint SLOT     	= 2;
	uint POSITION 	= 10;
}

class weapon_cofm76 : ScriptBasePlayerWeaponEntity, weapon_base
{
	private CBasePlayer@ m_pPlayer
	{
		get const 	{ return cast<CBasePlayer@>( self.m_hPlayer.GetEntity() ); }
		set       	{ self.m_hPlayer = EHandle( @value ); }
	}
	//for weapon functions/modes
	private int m_iM76MagEmpty, mag_counter;
	bool m_WasDrawn;

	// Other Sounds
	private array<string> m76Sounds = {
		"cof/guns/m76/bltback.ogg",
		"cof/guns/m76/bltrel.ogg",
		"cof/guns/m76/magin.ogg",
		"cof/guns/m76/magout.ogg"
	};

	void Spawn()
	{
		Precache();
		g_EntityFuncs.SetModel( self, CoFM76::M76_W_MODEL );

		iAnimation  = CoFM76_MELEE;
		iAnimation2 = CoFM76_MELEE_EMPTY;
		self.m_iDefaultAmmo = CoFM76::M76_DEFAULT_GIVE;
		g_iMode_ironsights  = CoF_MODE_NOTAIMED;
		mag_counter = CoFM76::M76_MAX_CLIP;
		m_WasDrawn = false;
		//m_iShotsFired = 0;

		self.FallInit();
	}

	void Precache()
	{
		self.PrecacheCustomModels();
		g_Game.PrecacheModel( CoFM76::M76_W_MODEL );
		g_Game.PrecacheModel( CoFM76::M76_V_MODEL );
		g_Game.PrecacheModel( CoFM76::M76_P_MODEL );
		g_Game.PrecacheModel( CoFM76::M76_A_MODEL );

		g_Game.PrecacheModel( g_watersplash_spr );
		m_iM76MagEmpty 	= g_Game.PrecacheModel( CoFM76::M76_MAGEMPTY_MODEL );
		m_iShell    	= g_Game.PrecacheModel( mShellModel[0] ); //9mm

		CommonPrecache(); //Common sounds to all weapons

		PrecacheSound( m76Sounds );

		g_SoundSystem.PrecacheSound( CoFM76::M76_SHOOT_SOUND );
		g_SoundSystem.PrecacheSound( EMPTY_SHOOT_SOUND );
		g_Game.PrecacheGeneric( "sound/" + CoFM76::M76_SHOOT_SOUND );
		g_Game.PrecacheGeneric( "sound/" + EMPTY_SHOOT_SOUND );

		g_Game.PrecacheModel( "sprites/cof/wpn_sel02.spr" );
		g_Game.PrecacheGeneric( "events/" + "muzzle_cofMP5.txt" );
		g_Game.PrecacheGeneric( "sprites/" + "cof/wpn_sel02.spr" );
		g_Game.PrecacheGeneric( "sprites/" + "cof/smg/weapon_cofm76.txt" );
	}

	bool GetItemInfo( ItemInfo& out info )
	{
		info.iMaxAmmo1 	= CoFM76::M76_MAX_CARRY;
		info.iMaxAmmo2 	= -1;
		info.iMaxClip 	= CoFM76::M76_MAX_CLIP;
		info.iSlot  	= CoFM76::SLOT;
		info.iPosition 	= CoFM76::POSITION;
		info.iId     	= g_ItemRegistry.GetIdForName( self.pev.classname );
		info.iFlags 	= ITEM_FLAG_NOAUTORELOAD | ITEM_FLAG_NOAUTOSWITCHEMPTY | ITEM_FLAG_SELECTONEMPTY;
		info.iWeight 	= CoFM76::M76_WEIGHT;

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
				bResult = Deploy( CoFM76::M76_V_MODEL, CoFM76::M76_P_MODEL, CoFM76_DRAW_FIRST, "mp5", 0 );
				deployTime = 2.5f;
				m_WasDrawn = true;
			}
			else if( m_WasDrawn == true )
			{
				bResult = Deploy( CoFM76::M76_V_MODEL, CoFM76::M76_P_MODEL, (self.m_iClip == 0) ? CoFM76_DRAW_EMPTY : CoFM76_DRAW, "mp5", 0 );
				deployTime = 1.01f;
			}

			//m_iShotsFired = 0;
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
		if( m_pPlayer.pev.waterlevel == WATERLEVEL_HEAD )
		{
			self.PlayEmptySound();
			self.m_flNextPrimaryAttack = WeaponTimeBase() + 0.43f;
			return;
		}

		if( self.m_iClip <= 0 )
		{
			if( ( m_pPlayer.m_afButtonPressed & IN_ATTACK == 0 ) )
				return;

			self.PlayEmptySound();
			self.m_flNextPrimaryAttack = WeaponTimeBase() + 0.43f;
			self.SendWeaponAnim( (g_iMode_ironsights == CoF_MODE_NOTAIMED) ? CoFM76_SHOOT_EMPTY : CoFM76_IRON_SHOOT_EMPTY, 0, 0 );
			return;
		}

		mag_counter--;
		//++m_iShotsFired;
		self.m_flNextPrimaryAttack = WeaponTimeBase() + GetFireRate( 580 );
		self.m_flNextSecondaryAttack = WeaponTimeBase() + 0.1;
		self.m_flNextTertiaryAttack = WeaponTimeBase() + 0.3;
		self.m_flTimeWeaponIdle = WeaponTimeBase() + 1.0f;

		//Play it before the punchangle, so the accuracy doesn't get screwed
		Vector vecCone;
		if( m_pPlayer.pev.velocity.Length2D() == 0 ) // Player is not moving
		{
			vecCone = (g_iMode_ironsights == CoF_MODE_AIMED) ? VECTOR_CONE_2DEGREES : VECTOR_CONE_3DEGREES;
		}
		else if( m_pPlayer.pev.velocity.Length2D() > 0 ) // Player is moving
		{
			vecCone = (g_iMode_ironsights == CoF_MODE_AIMED) ? VECTOR_CONE_3DEGREES : VECTOR_CONE_4DEGREES;
		}

		FireTrueBullet( CoFM76::M76_SHOOT_SOUND, false, CoFM76::M76_DAMAGE, vecCone, 9216, false, DMG_GENERIC );

		if( g_iMode_ironsights == CoF_MODE_NOTAIMED )
		{
			if( self.m_iClip <= 0 )
				self.SendWeaponAnim( CoFM76_SHOOT_LAST, 0, 0 );
			else
				self.SendWeaponAnim( CoFM76_SHOOT1 + Math.RandomLong( 0, 2 ), 0, 0 );
		}
		else if( g_iMode_ironsights == CoF_MODE_AIMED )
		{
			if( self.m_iClip <= 0 )
				self.SendWeaponAnim( CoFM76_IRON_SHOOT_LAST, 0, 0 );
			else
				self.SendWeaponAnim( CoFM76_IRON_SHOOT1 + Math.RandomLong( 0, 2 ), 0, 0 );
		}

		/*if( m_pPlayer.pev.velocity.Length2D() > 0 )
		{
			KickBack( 1.5, 0.45, 0.225, 0.05, 6.5, 2.5, 7 );
		}
		else if( !( m_pPlayer.pev.flags & FL_ONGROUND != 0 ) )
		{
			KickBack( 2.0, 1.0, 0.5, 0.35, 9.0, 6.0, 5 );
		}
		else if(m_pPlayer.pev.flags & FL_DUCKING != 0 )
		{
			KickBack( 0.9, 0.35, 0.15, 0.025, 5.5, 1.5, 9 );
		}
		else
		{
			KickBack( 1.0, 0.375, 0.175, 0.0375, 5.75, 1.75, 8 );
		}*/

		float m_iPunchAngle;

		if( (m_pPlayer.pev.flags & FL_DUCKING != 0) ) // Player is ducking
		{
			m_iPunchAngle = (g_iMode_ironsights == CoF_MODE_AIMED) ? Math.RandomFloat( -1.75f, -1.50f ) : Math.RandomFloat( -2.75f, -2.25f );
		}
		else if( !(m_pPlayer.pev.flags & FL_DUCKING != 0) ) // Player is not ducking
		{
			m_iPunchAngle = (g_iMode_ironsights == CoF_MODE_AIMED) ? Math.RandomFloat( -2.50f, -2.00f ) : Math.RandomFloat( -4.00f, -3.25f );
		}
		punchangle( m_iPunchAngle, Math.RandomFloat( -0.75, -0.15 ), Math.RandomFloat( -0.45f, -0.35f ) );

		Vector vecShellVelocity, vecShellOrigin;

		if( g_iMode_ironsights == CoF_MODE_NOTAIMED )
			CoFGetDefaultShellInfo( m_pPlayer, vecShellVelocity, vecShellOrigin, 26, 5, -6, false, false );
		else
			CoFGetDefaultShellInfo( m_pPlayer, vecShellVelocity, vecShellOrigin, 27, 1, -3.5, false, false );

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
				self.SendWeaponAnim( (self.m_iClip > 0) ? CoFM76_IRON_TO : CoFM76_IRON_TO_EMPTY, 0, 0 );
				EffectsFOVON( 40 );
				break;
			}
			case CoF_MODE_AIMED:
			{
				self.SendWeaponAnim( (self.m_iClip > 0) ? CoFM76_IRON_FROM : CoFM76_IRON_FROM_EMPTY, 0, 0 );
				EffectsFOVOFF();
				break;
			}
		}
	}

	void TertiaryAttack()
	{
		if( !Swing( 1, 37, 0, 0.95f, 22, true ) )
		{
			SetThink( ThinkFunction( this.SwingAgain ) );
			self.pev.nextthink = g_Engine.time + 0.1;
		}
	}

	void SwingAgain()
	{
		Swing( 0, 37, 0, 0.95f, 22, true );
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
		if( self.m_iClip == CoFM76::M76_MAX_CLIP || m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType ) <= 0 )
			return;

		if( g_iMode_ironsights == CoF_MODE_AIMED )
		{
			self.SendWeaponAnim( (self.m_iClip > 0) ? CoFM76_IRON_FROM : CoFM76_IRON_FROM_EMPTY, 0, 0 );
			m_reloadTimer = g_Engine.time + 0.2;
			m_pPlayer.m_flNextAttack = 0.2;
			canReload = true;
		}
		EffectsFOVOFF();
		//m_iShotsFired = 0;

		if( m_reloadTimer < g_Engine.time )
		{
			(self.m_iClip == 0) ? Reload( CoFM76::M76_MAX_CLIP, CoFM76_RELOAD_EMPTY, 4.35f, 0 ) : Reload( CoFM76::M76_MAX_CLIP, CoFM76_RELOAD, 2.85f, 0 );
			canReload = false;
		}

		if( mag_counter <= 0 )
		{
			self.pev.nextthink = WeaponTimeBase() + 1.16f;
			SetThink( ThinkFunction( EjectClipThink ) );
		}

		BaseClass.Reload();
	}

	void EjectClipThink()
	{
		mag_counter = CoFM76::M76_MAX_CLIP;
		Vector vecVelocity = m_pPlayer.pev.view_ofs + g_Engine.v_right * Math.RandomLong( -50, -16 ) + g_Engine.v_up * 16 + g_Engine.v_forward * Math.RandomLong( 16, 50 );
		ClipCasting( m_pPlayer.pev.origin, vecVelocity, m_iM76MagEmpty, false, 0 );
	}
	
	void WeaponIdle()
	{
		//if( self.m_flNextPrimaryAttack < g_Engine.time )
		//	m_iShotsFired = 0;

		self.ResetEmptySound();
		m_pPlayer.GetAutoaimVector( AUTOAIM_10DEGREES );

		if( self.m_flTimeWeaponIdle > WeaponTimeBase() )
			return;

		if( self.m_iClip <= 0 )
			self.SendWeaponAnim( (g_iMode_ironsights == CoF_MODE_AIMED) ? CoFM76_IRON_IDLE_EMPTY : CoFM76_IDLE_EMPTY, 0, 0 );
		else
			self.SendWeaponAnim( (g_iMode_ironsights == CoF_MODE_AIMED) ? CoFM76_IRON_IDLE : CoFM76_IDLE, 0, 0 );

		self.m_flTimeWeaponIdle = WeaponTimeBase() + g_PlayerFuncs.SharedRandomFloat( m_pPlayer.random_seed, 5, 7 );
	}
}

class Parabellum9mm_M76 : ScriptBasePlayerAmmoEntity, ammo_base
{
	void Spawn()
	{
		Precache();
		g_EntityFuncs.SetModel( self, CoFM76::M76_A_MODEL );
		BaseClass.Spawn();
	}
	
	void Precache()
	{
		g_Game.PrecacheModel( CoFM76::M76_A_MODEL );
		g_SoundSystem.PrecacheSound( CoFCOMMON::ITEM_SOUND_PICK );
	}

	bool AddAmmo( CBaseEntity@ pOther )
	{
		return CommonAddAmmo( pOther, CoFM76::M76_MAX_CLIP, CoFM76::M76_MAX_CARRY, (p_Customizable) ? "ammo_9mmpara" : "9mm" );
	}
}

string CoFM76AmmoName()
{
	return "ammo_9mm_m76";
}

string CoFM76Name()
{
	return "weapon_cofm76";
}

void RegisterCoFM76()
{
	g_CustomEntityFuncs.RegisterCustomEntity( CoFM76Name(), CoFM76Name() );
	g_CustomEntityFuncs.RegisterCustomEntity( "Parabellum9mm_M76", CoFM76AmmoName() );
	g_ItemRegistry.RegisterWeapon( CoFM76Name(), "cof/smg", (p_Customizable) ? "ammo_9mmpara" : "9mm", "", CoFM76AmmoName() );
}