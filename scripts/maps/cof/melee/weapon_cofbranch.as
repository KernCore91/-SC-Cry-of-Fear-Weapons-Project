// Author: KernCore

#include "../base"

enum CoFBRANCHAnimations_e
{
	CoFBRANCH_IDLE = 0,
	CoFBRANCH_DRAW,
	CoFBRANCH_HOLSTER,
	CoFBRANCH_ATTACK1,
	CoFBRANCH_ATTACK2,
	CoFBRANCH_SPRINT_TO,
	CoFBRANCH_SPRINT_IDLE,
	CoFBRANCH_SPRINT_FROM,
	CoFBRANCH_SHOVE,
	CoFBRANCH_FIDGET1,
	CoFBRANCH_FIDGET2,
	CoFBRANCH_FIDGET3,
	CoFBRANCH_JUMP_TO,
	CoFBRANCH_JUMP_FROM,
	CoFBRANCH_DRAW_FIRST,
	CoFBRANCH_IDLE_ONEHAND,
	CoFBRANCH_DRAW_ONEHAND,
	CoFBRANCH_ATTACK1_ONEHAND,
	CoFBRANCH_HOLSTER_ONEHAND
};

namespace CoFBRANCH
{
	//models
	string BRANCH_W_MODEL	= "models/cof/branch/wld.mdl";
	string BRANCH_V_MODEL	= "models/cof/branch/vwm.mdl";
	string BRANCH_P_MODEL	= "models/cof/branch/wld.mdl";
	//sounds
	const string BRANCH_HIT_S 	= "cof/guns/branch/hit.ogg";
	const string BRANCH_SWNG_S 	= "cof/guns/branch/swing.ogg";
	//weapon info
	const int BRANCH_WEIGHT 	= 5;
	uint BRANCH_DAMAGE      	= 35;
	//iSlot and iPosition in the Hud
	uint SLOT     	= 0;
	uint POSITION 	= 9;
}

class weapon_cofbranch : ScriptBasePlayerWeaponEntity, weapon_base
{
	private CBasePlayer@ m_pPlayer
	{
		get const 	{ return cast<CBasePlayer@>( self.m_hPlayer.GetEntity() ); }
		set       	{ self.m_hPlayer = EHandle( @value ); }
	}
	bool m_WasDrawn;

	// Other Sounds
	private array<string> branchSounds = {
		CoFBRANCH::BRANCH_HIT_S,
		CoFBRANCH::BRANCH_SWNG_S
	};

	void Spawn()
	{
		self.Precache();
		g_EntityFuncs.SetModel( self, self.GetW_Model( CoFBRANCH::BRANCH_W_MODEL ) );
		self.m_iClip    	= -1;
		self.m_flCustomDmg 	= self.pev.dmg;
		iAnimation      	= CoFBRANCH_SHOVE;
		iAnimation2     	= CoFBRANCH_SHOVE;
		m_WasDrawn = false;
		m_bUseCustomScale = true;
		self.pev.scale = 1.3;

		self.FallInit();
	}

	void Precache()
	{
		self.PrecacheCustomModels();

		g_Game.PrecacheModel( CoFBRANCH::BRANCH_W_MODEL );
		g_Game.PrecacheModel( CoFBRANCH::BRANCH_V_MODEL );
		g_Game.PrecacheModel( CoFBRANCH::BRANCH_P_MODEL );

		CommonPrecache(); //Common sounds to all weapons
		PrecacheSound( branchSounds );

		g_Game.PrecacheModel( "sprites/cof/wpn_sel01.spr" );
		g_Game.PrecacheGeneric( "sprites/" + "cof/wpn_sel01.spr" );
		g_Game.PrecacheGeneric( "sprites/" + "cof/melee/weapon_cofbranch.txt" );
	}

	bool GetItemInfo( ItemInfo& out info )
	{
		info.iMaxAmmo1 	= -1;
		info.iMaxAmmo2 	= -1;
		info.iMaxClip 	= WEAPON_NOCLIP;
		info.iSlot   	= CoFBRANCH::SLOT;
		info.iPosition 	= CoFBRANCH::POSITION;
		info.iId     	= g_ItemRegistry.GetIdForName( self.pev.classname );
		info.iWeight 	= CoFBRANCH::BRANCH_WEIGHT;
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
		float deployTime;
		bool bResult;
		{
			if( m_WasDrawn == false )
			{
				bResult = Deploy( CoFBRANCH::BRANCH_V_MODEL, CoFBRANCH::BRANCH_P_MODEL, CoFBRANCH_DRAW_FIRST, "crowbar", 1 );
				deployTime = 2.5f;
				m_WasDrawn = true;
			}
			else if( m_WasDrawn == true )
			{
				bResult = Deploy( CoFBRANCH::BRANCH_V_MODEL, CoFBRANCH::BRANCH_P_MODEL, CoFBRANCH_DRAW, "crowbar", 1 );
				deployTime = 1.0f;
			}

			DeploySleeve();
			self.m_flTimeWeaponIdle = self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = g_Engine.time + deployTime;
			return bResult;
		}
	}

	void Holster( int skipLocal = 0 )
	{
		self.m_fInReload = false;// cancel any reload in progress.
		SetThink( null );
		m_IsPullingBack = false;

		m_pPlayer.pev.viewmodel = string_t();
		BaseClass.Holster( skipLocal );
	}

	void PrimaryAttack()
	{
		if( !m_IsPullingBack )
		{
			// We don't want the player to break/stop the animation or sequence.
			m_IsPullingBack = true;
			
			// We are pulling back our hammer
			self.SendWeaponAnim( CoFBRANCH_ATTACK1 + Math.RandomLong( 0, 1 ), 0, 0 );

			self.m_flTimeWeaponIdle = g_Engine.time + 1.0f;
			// Lets wait for the 'heavy smack'
			SetThink( ThinkFunction( this.DoHeavyAttack ) );
			self.pev.nextthink = g_Engine.time + 0.21f;
			self.m_flNextSecondaryAttack = WeaponTimeBase() + 1.0f;
		}
	}

	void SecondaryAttack()
	{
		if( !Swing( 1, 37, 1, 0.95f, 24, false ) )
		{
			SetThink( ThinkFunction( this.SwingAgain ) );
			self.pev.nextthink = g_Engine.time + 0.1;
		}
		// player "shoot" animation
		m_pPlayer.SetAnimation( PLAYER_ATTACK1 );

		m_IsPullingBack = false;
	}

	void SwingAgain()
	{
		Swing( 0, 37, 1, 0.95f, 24, false );
	}

	void DoHeavyAttack()
	{
		/* Params in order
		Distance;
		Attack Speed;
		Damage;
		Animation Timing;
		Hit Body sounds;
		Hit Wall sounds;
		Damage Bits.
		*/
		HeavySmack( 47, 0.5f, CoFBRANCH::BRANCH_DAMAGE, 0.95f - 0.21f, CoFBRANCH::BRANCH_HIT_S, CoFBRANCH::BRANCH_HIT_S, DMG_CLUB );
		g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_ITEM, CoFBRANCH::BRANCH_SWNG_S, 1, ATTN_NORM, 0, 94 + Math.RandomLong( 0,0xF ) );

		m_pPlayer.pev.punchangle.x = Math.RandomLong( 2, 4 );
		g_WeaponFuncs.DecalGunshot( m_trHit, BULLET_PLAYER_CROWBAR );
	}

	void WeaponIdle()
	{
		if( self.m_flTimeWeaponIdle > g_Engine.time )
			return;

		int iAnim;
		switch( g_PlayerFuncs.SharedRandomLong( m_pPlayer.random_seed, 0, 3 ) )
		{
			case 0:	iAnim = CoFBRANCH_FIDGET1;
			break;

			case 1: iAnim = CoFBRANCH_FIDGET2;
			break;

			case 2: iAnim = CoFBRANCH_FIDGET3;
			break;

			case 3: iAnim = CoFBRANCH_IDLE;
			break;
		}

		self.SendWeaponAnim( iAnim, 0, 0 );

		self.m_flTimeWeaponIdle = g_Engine.time + g_PlayerFuncs.SharedRandomLong( m_pPlayer.random_seed, 4, 5 );
	}
}

string CoFBRANCHName()
{
	return "weapon_cofbranch";
}

void RegisterCoFBRANCH()
{
	g_CustomEntityFuncs.RegisterCustomEntity( CoFBRANCHName(), CoFBRANCHName() );
	g_ItemRegistry.RegisterWeapon( CoFBRANCHName(), "cof/melee" );
}