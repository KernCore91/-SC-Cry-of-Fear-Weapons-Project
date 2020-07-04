// Author: KernCore

#include "../base"

enum CoFGEWEHRAnimations_e
{
	CoFGEWEHR_DRAW = 0,
	CoFGEWEHR_DRAW_EMPTY,
	CoFGEWEHR_SHOOT_EMPTY,
	CoFGEWEHR_SHOOT_LAST,
	CoFGEWEHR_SHOOT1,
	CoFGEWEHR_SHOOT2,
	CoFGEWEHR_SHOOT3,
	CoFGEWEHR_HOLSTER,
	CoFGEWEHR_HOLSTER_EMPTY,
	CoFGEWEHR_IDLE,
	CoFGEWEHR_IDLE_EMPTY,
	CoFGEWEHR_IRON_SHOOT_EMPTY,
	CoFGEWEHR_IRON_SHOOT_LAST,
	CoFGEWEHR_IRON_SHOOT1,
	CoFGEWEHR_IRON_SHOOT2,
	CoFGEWEHR_IRON_SHOOT3,
	CoFGEWEHR_IRON_FROM,
	CoFGEWEHR_IRON_FROM_EMPTY,
	CoFGEWEHR_IRON_IDLE,
	CoFGEWEHR_IRON_IDLE_EMPTY,
	CoFGEWEHR_IRON_TO,
	CoFGEWEHR_IRON_TO_EMPTY,
	CoFGEWEHR_JUMP_FROM,
	CoFGEWEHR_JUMP_FROM_EMPTY,
	CoFGEWEHR_JUMP_TO,
	CoFGEWEHR_JUMP_TO_EMPTY,
	CoFGEWEHR_MELEE,
	CoFGEWEHR_MELEE_EMPTY,
	CoFGEWEHR_RELOAD_EMPTY,
	CoFGEWEHR_RELOAD,
	CoFGEWEHR_SPRINT_IDLE,
	CoFGEWEHR_SPRINT_IDLE_EMPTY,
	CoFGEWEHR_SPRINT_FROM,
	CoFGEWEHR_SPRINT_FROM_EMPTY,
	CoFGEWEHR_SPRINT_TO,
	CoFGEWEHR_SPRINT_TO_EMPTY,
	CoFGEWEHR_SUICIDE,
	CoFGEWEHR_SUICIDE_EMPTY
};

namespace CoFG43
{
	//models
	string GEWEHR_W_MODEL       	= "models/cof/g43/wrd.mdl";
	string GEWEHR_V_MODEL       	= "models/cof/g43/vwm.mdl";
	string GEWEHR_P_MODEL       	= "models/cof/g43/plr.mdl";
	string GEWEHR_A_MODEL       	= "models/cof/g43/mag.mdl";
	string GEWEHR_MAGEMPTY_MODEL 	= "models/cof/g43/mag_e.mdl";
	//sounds
	const string GEWEHR_SHOOT_SOUND 	= "cof/guns/g43/shoot.ogg";
	//weapon info
	const int GEWEHR_MAX_CARRY   	= (p_Customizable) ? 100 : 50;
	const int GEWEHR_MAX_CLIP    	= 10;
	const int GEWEHR_DEFAULT_GIVE 	= GEWEHR_MAX_CLIP * 3;
	const int GEWEHR_WEIGHT      	= 45;
	uint GEWEHR_DAMAGE            	= 30;
	//iSlot and iPosition in the Hud
	uint SLOT     	= 5;
	uint POSITION 	= 10;
}

class weapon_cofg43 : ScriptBasePlayerWeaponEntity, weapon_base
{
	private CBasePlayer@ m_pPlayer
	{
		get const 	{ return cast<CBasePlayer@>( self.m_hPlayer.GetEntity() ); }
		set       	{ self.m_hPlayer = EHandle( @value ); }
	}
	//weapon funcs
	int m_iG43MagEmpty;
	int mag_counter;

	// Other Sounds
	private array<string> g43Sounds = {
		"cof/guns/g43/bltrel.ogg",
		"cof/guns/g43/magin.ogg",
		"cof/guns/g43/magout.ogg"
	};

	void Spawn()
	{
		Precache();
		g_EntityFuncs.SetModel( self, self.GetW_Model( CoFG43::GEWEHR_W_MODEL ) );
		
		self.m_iDefaultAmmo	= CoFG43::GEWEHR_DEFAULT_GIVE;
		g_iMode_ironsights	= CoF_MODE_NOTAIMED;

		iAnimation      	= CoFGEWEHR_MELEE;
		iAnimation2     	= CoFGEWEHR_MELEE_EMPTY;
		mag_counter = CoFG43::GEWEHR_MAX_CLIP;
		
		self.FallInit();
	}

	void Precache()
	{
		self.PrecacheCustomModels();
		g_Game.PrecacheModel( CoFG43::GEWEHR_W_MODEL );
		g_Game.PrecacheModel( CoFG43::GEWEHR_V_MODEL );
		g_Game.PrecacheModel( CoFG43::GEWEHR_P_MODEL );
		g_Game.PrecacheModel( CoFG43::GEWEHR_A_MODEL );
		g_Game.PrecacheModel( g_watersplash_spr );
		m_iG43MagEmpty	= g_Game.PrecacheModel( CoFG43::GEWEHR_MAGEMPTY_MODEL );
		m_iShell    	= g_Game.PrecacheModel( mShellModel[4] ); //792

		CommonPrecache(); //Common sounds to all weapons
		PrecacheSound( g43Sounds );

		g_SoundSystem.PrecacheSound( CoFG43::GEWEHR_SHOOT_SOUND );
		g_SoundSystem.PrecacheSound( EMPTY_SHOOT_SOUND );
		g_Game.PrecacheGeneric( "sound/" + CoFG43::GEWEHR_SHOOT_SOUND );
		g_Game.PrecacheGeneric( "sound/" + EMPTY_SHOOT_SOUND );

		g_Game.PrecacheModel( "sprites/cof/wpn_sel03.spr" );
		g_Game.PrecacheGeneric( "sprites/" + "cof/wpn_sel03.spr" );
		g_Game.PrecacheGeneric( "sprites/" + "cof/rifle/weapon_cofg43.txt" );
	}

	bool GetItemInfo( ItemInfo& out info )
	{
		info.iMaxAmmo1 	= CoFG43::GEWEHR_MAX_CARRY;
		info.iMaxAmmo2 	= -1;
		info.iMaxClip 	= CoFG43::GEWEHR_MAX_CLIP;
		info.iSlot  	= CoFG43::SLOT;
		info.iPosition 	= CoFG43::POSITION;
		info.iId     	= g_ItemRegistry.GetIdForName( self.pev.classname );
		info.iFlags 	= ITEM_FLAG_NOAUTORELOAD | ITEM_FLAG_NOAUTOSWITCHEMPTY | ITEM_FLAG_SELECTONEMPTY;
		info.iWeight 	= CoFG43::GEWEHR_WEIGHT;

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
			bResult = Deploy( CoFG43::GEWEHR_V_MODEL, CoFG43::GEWEHR_P_MODEL, (self.m_iClip == 0) ? CoFGEWEHR_DRAW_EMPTY : CoFGEWEHR_DRAW, "sniper", 0 );

			DeploySleeve();

			float deployTime = 1.13f;
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
			self.SendWeaponAnim( (g_iMode_ironsights == CoF_MODE_AIMED) ? CoFGEWEHR_IRON_SHOOT_EMPTY: CoFGEWEHR_SHOOT_EMPTY, 0, 1 );
			return;
		}
		
		mag_counter--;
		self.m_flNextPrimaryAttack = WeaponTimeBase() + 0.31f;
		self.m_flNextSecondaryAttack = WeaponTimeBase() + 0.1;
		self.m_flNextTertiaryAttack = WeaponTimeBase() + 0.3;
		self.m_flTimeWeaponIdle = WeaponTimeBase() + 1.0f;

		//self.m_flNextPrimaryAttack = self.m_flNextPrimaryAttack + 0.15f;
		if( self.m_flNextPrimaryAttack < WeaponTimeBase() )
			self.m_flNextPrimaryAttack = WeaponTimeBase() + 0.15f;
		
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

		FireTrueBullet( CoFG43::GEWEHR_SHOOT_SOUND, true, CoFG43::GEWEHR_DAMAGE, vecCone, 16384, true, DMG_SNIPER | DMG_NEVERGIB );

		float m_iPunchAngle;
		if( (m_pPlayer.pev.flags & FL_DUCKING != 0) ) // Player is ducking
		{
			m_iPunchAngle = (g_iMode_ironsights == CoF_MODE_AIMED) ? Math.RandomLong( -5, -3 ) : Math.RandomLong( -6, -4 );
		}
		else if( !(m_pPlayer.pev.flags & FL_DUCKING != 0) ) // Player is not ducking
		{
			m_iPunchAngle = (g_iMode_ironsights == CoF_MODE_AIMED) ? Math.RandomLong( -5, -4 ) : Math.RandomLong( -8, -6 );
		}
		punchangle( m_iPunchAngle, Math.RandomFloat( -0.5, 0.5 ), Math.RandomFloat( -0.75f, -0.5f ) );
		//AngleRecoil( Math.RandomFloat( -0.2f, -0.1f ), Math.RandomFloat( -0.05f, 0.05f ) );

		if( g_iMode_ironsights == CoF_MODE_AIMED )
		{
			if( self.m_iClip > 0 )
				self.SendWeaponAnim( CoFGEWEHR_IRON_SHOOT1 + Math.RandomLong( 0, 2 ) );
			else
				self.SendWeaponAnim( CoFGEWEHR_IRON_SHOOT_LAST, 0, 0 );
		}
		else
		{
			if( self.m_iClip > 0 )
				self.SendWeaponAnim( CoFGEWEHR_SHOOT1 + Math.RandomLong( 0, 2 ) );
			else
				self.SendWeaponAnim( CoFGEWEHR_SHOOT_LAST, 0, 0 );
		}

		Vector vecShellVelocity, vecShellOrigin;

		if( g_iMode_ironsights == CoF_MODE_NOTAIMED )
			CoFGetDefaultShellInfo( m_pPlayer, vecShellVelocity, vecShellOrigin, 23, 2, -7, false, false );
		else
			CoFGetDefaultShellInfo( m_pPlayer, vecShellVelocity, vecShellOrigin, 23, -1, -4.5, false, false );

		vecShellVelocity.y *= 1;
		g_EntityFuncs.EjectBrass( vecShellOrigin, vecShellVelocity, m_pPlayer.pev.angles[ 1 ], m_iShell, TE_BOUNCE_SHELL );
	}

	void SecondaryAttack()
	{
		self.m_flNextSecondaryAttack = self.m_flTimeWeaponIdle = WeaponTimeBase() + 0.3;
		self.m_flNextPrimaryAttack = WeaponTimeBase() + 0.15f;
		g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_ITEM, CoFCOMMON::DEPLOY_SLEEVE3, 0.9, ATTN_NORM, 0, PITCH_NORM );
		
		switch( g_iMode_ironsights )
		{
			case CoF_MODE_NOTAIMED:
			{
				self.SendWeaponAnim( (self.m_iClip > 0) ? CoFGEWEHR_IRON_TO : CoFGEWEHR_IRON_TO_EMPTY, 0, 1 );
				EffectsFOVON( 35 );
				m_pPlayer.m_szAnimExtension = "sniperscope";
				break;
			}
			case CoF_MODE_AIMED:
			{
				self.SendWeaponAnim( (self.m_iClip > 0) ? CoFGEWEHR_IRON_FROM : CoFGEWEHR_IRON_FROM_EMPTY, 0, 1 );
				EffectsFOVOFF();
				m_pPlayer.m_szAnimExtension = "sniper";
				break;
			}
		}
	}

	void TertiaryAttack()
	{
		if( !Swing( 1, 37, 1, 1.1f, 24, true ) )
		{
			SetThink( ThinkFunction( this.SwingAgain ) );
			self.pev.nextthink = g_Engine.time + 0.1;
		}
	}

	void SwingAgain()
	{
		Swing( 0, 37, 1, 1.1f, 24, true );
	}

	void ItemPreFrame()
	{
		if( m_reloadTimer < g_Engine.time && canReload )
			self.Reload();

		BaseClass.ItemPreFrame();
	}

	void Reload()
	{
		if( self.m_iClip == CoFG43::GEWEHR_MAX_CLIP || m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType ) <= 0)
			return;

		m_pPlayer.m_szAnimExtension = "sniper";
		if( g_iMode_ironsights == CoF_MODE_AIMED )
		{
			self.SendWeaponAnim( (self.m_iClip > 0) ? CoFGEWEHR_IRON_FROM : CoFGEWEHR_IRON_FROM_EMPTY, 0, 1 );
			m_reloadTimer = g_Engine.time + 0.275f;
			m_pPlayer.m_flNextAttack = 0.275;
			canReload = true;
		}
		EffectsFOVOFF();

		if( m_reloadTimer < g_Engine.time )
		{
			(self.m_iClip == 0) ? Reload( CoFG43::GEWEHR_MAX_CLIP, CoFGEWEHR_RELOAD_EMPTY, 5.86f, 1 ) : Reload( CoFG43::GEWEHR_MAX_CLIP, CoFGEWEHR_RELOAD, 4.96f, 1 );
			canReload = false;
		}

		if( mag_counter <= 0 )
		{
			self.pev.nextthink = WeaponTimeBase() + 1.87f;
			SetThink( ThinkFunction( EjectClipThink ) );
		}

		BaseClass.Reload();
	}

	void EjectClipThink()
	{
		mag_counter = CoFG43::GEWEHR_MAX_CLIP;
		ClipCasting( m_pPlayer.pev.origin, m_pPlayer.pev.view_ofs + g_Engine.v_right * -42 + g_Engine.v_up * 16 + g_Engine.v_forward * 8, m_iG43MagEmpty, false, 0 );
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
			self.SendWeaponAnim( (self.m_iClip > 0) ? CoFGEWEHR_IRON_IDLE : CoFGEWEHR_IRON_IDLE_EMPTY, 0, 1 );
		}
		else if( g_iMode_ironsights == CoF_MODE_NOTAIMED )
		{
			self.SendWeaponAnim( (self.m_iClip > 0) ? CoFGEWEHR_IDLE : CoFGEWEHR_IDLE_EMPTY, 0, 1 );
		}

		self.m_flTimeWeaponIdle = WeaponTimeBase() + g_PlayerFuncs.SharedRandomFloat( m_pPlayer.random_seed,  5, 7 );
	}
}

class Mauser792 : ScriptBasePlayerAmmoEntity, ammo_base
{
	void Spawn()
	{
		Precache();
		g_EntityFuncs.SetModel( self, CoFG43::GEWEHR_A_MODEL );
		BaseClass.Spawn();
	}
	
	void Precache()
	{
		g_Game.PrecacheModel( CoFG43::GEWEHR_A_MODEL );
		g_SoundSystem.PrecacheSound( CoFCOMMON::ITEM_SOUND_PICK );
	}

	bool AddAmmo( CBaseEntity@ pOther )
	{
		return CommonAddAmmo( pOther, CoFG43::GEWEHR_MAX_CLIP, CoFG43::GEWEHR_MAX_CARRY, (p_Customizable) ? "ammo_792mauser" : "bolts" );
	}
}

string CoFGEWEHRAmmoName()
{
	return "ammo_792mauser";
}

string CoFGEWEHRName()
{
	return "weapon_cofg43";
}

void RegisterCoFGEWEHR()
{
	g_CustomEntityFuncs.RegisterCustomEntity( CoFGEWEHRName(), CoFGEWEHRName() );
	g_CustomEntityFuncs.RegisterCustomEntity( "Mauser792", CoFGEWEHRAmmoName() );
	g_ItemRegistry.RegisterWeapon( CoFGEWEHRName(), "cof/rifle", (p_Customizable) ? "ammo_792mauser" : "bolts", "", CoFGEWEHRAmmoName() );
}