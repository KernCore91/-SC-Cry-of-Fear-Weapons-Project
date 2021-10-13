//Cry of Fear's Specific BuyMenu
//Author: KernCore, Original script by Solokiller, Improved by Zode
/**

DISCLAIMER:
The original Buy Menu script was built back in 2016 by Solokiller, and released by him for free for everyone on the Sven Co-op Forums.
This script contains code that integrates the Cry of Fear Project ONLY and if you paid money to access it, you have been scammed.

Do not remove or change comments made by contributors in any way, shape, or form.
Do not sell or make money in any way, shape or form from this script, be it old versions or newest releases, or any other assets from this project.
Doing so is against the release license of this project, and proper actions will be taken.

*/

namespace BuyMenu
{

final class BuyableItem
{
	private string m_szDescription;
	private string m_szEntityName;
	private string m_szCategory;
	private string m_szSubCategory;
	private uint m_uiCost = 0;

	string Description
	{
		get const { return m_szDescription; }
		set { m_szDescription = value; }
	}

	string EntityName
	{
		get const { return m_szEntityName; }
		set { m_szEntityName = value; }
	}

	string Category
	{
		get const { return m_szCategory; }
		set { m_szCategory = value; }
	}

	string SubCategory
	{
		get const { return m_szSubCategory; }
		set { m_szSubCategory = value; }
	}

	uint Cost
	{
		get const { return m_uiCost; }
		set { m_uiCost = value; }
	}

	BuyableItem( const string& in szDescription, const string& in szEntityName, const uint uiCost, string sCategory, string sSubCategory )
	{
		m_szDescription = "$" + string(uiCost) + " " + szDescription;
		m_szEntityName = szEntityName;
		m_uiCost = uiCost;
		m_szCategory = sCategory;
		m_szSubCategory = sSubCategory;
	}

	void Buy( CBasePlayer@ pPlayer = null )
	{
		GiveItem( pPlayer );
	}

	private void GiveItem( CBasePlayer@ pPlayer ) const
	{
		const uint uiMoney = uint( pPlayer.pev.frags );

		if( pPlayer.HasNamedPlayerItem( m_szEntityName ) !is null )
		{
			//KernCore start
			if( !(pPlayer.HasNamedPlayerItem( m_szEntityName ).iFlags() < 0) && pPlayer.HasNamedPlayerItem( m_szEntityName ).iFlags() & ITEM_FLAG_EXHAUSTIBLE != 0 )
			{
				if( pPlayer.GiveAmmo( 1, m_szEntityName, pPlayer.GetMaxAmmo( m_szEntityName ) ) != -1 )
				{
					pPlayer.HasNamedPlayerItem( m_szEntityName ).AttachToPlayer( pPlayer );
					g_PlayerFuncs.ClientPrint( pPlayer, HUD_PRINTTALK, "You bought ammo for: " + m_szEntityName + "\n" );
				}
				else
				{
					g_PlayerFuncs.ClientPrint( pPlayer, HUD_PRINTTALK, "You already have max ammo for this item!\n" );
					return;
				}
			}
			else
			{
				g_PlayerFuncs.ClientPrint( pPlayer, HUD_PRINTTALK, "You already have that item!\n" );
				return;
			}
			//KernCore end
		}

		if( pPlayer.pev.frags <= 0 )
		{
			g_PlayerFuncs.ClientPrint( pPlayer, HUD_PRINTTALK, "Not enough money (frags) - Cost: $" + m_uiCost + "\n");
			return;
		}
		else if( uiMoney >= m_uiCost )
		{
			pPlayer.pev.frags -= m_uiCost;

			pPlayer.GiveNamedItem( m_szEntityName );
			pPlayer.SelectItem( m_szEntityName );
		}
		else
		{
			g_PlayerFuncs.ClientPrint( pPlayer, HUD_PRINTTALK, "Not enough money (frags) - Cost: $" + m_uiCost + "\n");
			return;
		}
	}
}

final class BuyMenu
{
	array<BuyableItem@> m_Items;

	private CTextMenu@ m_pMenu = null;
	private CTextMenu@ m_pSecondaryMenu = null;
	private CTextMenu@ m_pPrimaryMenu = null;
	private CTextMenu@ m_pEquipmentMenu = null;
	private CTextMenu@ m_pAmmoMenu = null;
	private CTextMenu@ m_pMeleeMenu = null;
	private CTextMenu@ m_pSmgMenu = null;
	private CTextMenu@ m_pShotgunMenu = null;
	private CTextMenu@ m_pAssaultMenu = null;
	private CTextMenu@ m_pRifleMenu = null;
	private CTextMenu@ m_pSpecialMenu = null;

	void RemoveItems()
	{
		if( m_Items !is null )
		{
			m_Items.removeRange( 0, m_Items.length() );
		}
	}

	void AddItem( BuyableItem@ pItem )
	{
		if( pItem is null )
			return;

		if( m_Items.findByRef( @pItem ) != -1 )
			return;

		m_Items.insertLast( pItem );

		if( m_pMenu !is null )
			@m_pMenu = null;
	}

	void Show( CBasePlayer@ pPlayer = null )
	{
		if( m_pMenu is null )
			CreateMenu();

		if( pPlayer !is null )
			m_pMenu.Open( 0, 0, pPlayer );
	}

	private void CreateMenu()
	{
		@m_pMenu = CTextMenu( TextMenuPlayerSlotCallback( this.MainCallback ) );
		m_pMenu.SetTitle( "Choose action: " );
		m_pMenu.AddItem( "Buy primary weapon", null );
		m_pMenu.AddItem( "Buy secondary weapon", null );
		m_pMenu.AddItem( "Buy equipment", null );
		m_pMenu.AddItem( "Buy ammo" );
		m_pMenu.Register();

		@m_pPrimaryMenu = CTextMenu( TextMenuPlayerSlotCallback( this.PrimaryCallback ) );
		m_pPrimaryMenu.SetTitle( "Choose primary weapon category: " );
		m_pPrimaryMenu.AddItem( "Melee", null );
		m_pPrimaryMenu.AddItem( "SMGs", null );
		m_pPrimaryMenu.AddItem( "Shotguns", null );
		m_pPrimaryMenu.AddItem( "Assault Rifles", null );
		m_pPrimaryMenu.AddItem( "Rifles", null );
		m_pPrimaryMenu.AddItem( "Special", null );
		m_pPrimaryMenu.Register();

		@m_pSecondaryMenu = CTextMenu( TextMenuPlayerSlotCallback( this.WeaponCallback ) );
		m_pSecondaryMenu.SetTitle( "Choose secondary weapon: " );
		@m_pEquipmentMenu = CTextMenu( TextMenuPlayerSlotCallback( this.WeaponCallback ) );
		m_pEquipmentMenu.SetTitle( "Choose equipment: " );
		@m_pAmmoMenu = CTextMenu( TextMenuPlayerSlotCallback( this.AmmoCallBack ) );
		m_pAmmoMenu.SetTitle( "Choose Ammo: " );

		@m_pMeleeMenu = CTextMenu( TextMenuPlayerSlotCallback( this.WeaponCallback ) );
		m_pMeleeMenu.SetTitle( "Choose Melee:" );
		@m_pSmgMenu = CTextMenu( TextMenuPlayerSlotCallback( this.WeaponCallback ) );
		m_pSmgMenu.SetTitle( "Choose SMG:" );
		@m_pShotgunMenu = CTextMenu( TextMenuPlayerSlotCallback( this.WeaponCallback ) );
		m_pShotgunMenu.SetTitle( "Choose Shotgun:" );
		@m_pAssaultMenu = CTextMenu( TextMenuPlayerSlotCallback( this.WeaponCallback ) );
		m_pAssaultMenu.SetTitle( "Choose Assault Rifle:" );
		@m_pRifleMenu = CTextMenu( TextMenuPlayerSlotCallback( this.WeaponCallback ) );
		m_pRifleMenu.SetTitle( "Choose Rifle:" );
		@m_pSpecialMenu = CTextMenu( TextMenuPlayerSlotCallback( this.WeaponCallback ) );
		m_pSpecialMenu.SetTitle( "Choose Special Weapon:" );
		for( uint i = 0; i < m_Items.length(); i++ )
		{
			BuyableItem@ pItem = m_Items[i];
			if( pItem.Category == "secondary" )
				m_pSecondaryMenu.AddItem( pItem.Description, any(@pItem) );
			else if( pItem.Category == "equipment" )
				m_pEquipmentMenu.AddItem( pItem.Description, any(@pItem) );
			else if( pItem.Category == "ammo" )
				m_pAmmoMenu.AddItem( pItem.Description, any(@pItem) );
			else if( pItem.Category == "primary" )
			{
				if( pItem.SubCategory == "melee" )
					m_pMeleeMenu.AddItem( pItem.Description, any(@pItem) );
				else if( pItem.SubCategory == "smg" )
					m_pSmgMenu.AddItem( pItem.Description, any(@pItem) );
				else if( pItem.SubCategory == "shotgun" )
					m_pShotgunMenu.AddItem( pItem.Description, any(@pItem) );
				else if( pItem.SubCategory == "assault" )
					m_pAssaultMenu.AddItem( pItem.Description, any(@pItem) );
				else if( pItem.SubCategory == "rifle" )
					m_pRifleMenu.AddItem( pItem.Description, any(@pItem) );
				else if( pItem.SubCategory == "special" )
					m_pSpecialMenu.AddItem( pItem.Description, any(@pItem) );
			}
		}
		m_pSecondaryMenu.Register();
		m_pEquipmentMenu.Register();
		m_pAmmoMenu.Register();
		m_pMeleeMenu.Register();
		m_pSmgMenu.Register();
		m_pShotgunMenu.Register();
		m_pAssaultMenu.Register();
		m_pRifleMenu.Register();
		m_pSpecialMenu.Register();
	}

	private void MainCallback( CTextMenu@ menu, CBasePlayer@ pPlayer, int iSlot, const CTextMenuItem@ pItem )
	{
		if( pItem !is null )
		{
			string sChoice = pItem.m_szName;
			if( sChoice == "Buy primary weapon" )
				m_pPrimaryMenu.Open( 0, 0, pPlayer );
			else if( sChoice == "Buy secondary weapon" )
				m_pSecondaryMenu.Open( 0, 0, pPlayer );
			else if( sChoice == "Buy equipment" )
				m_pEquipmentMenu.Open( 0, 0, pPlayer );
			else if( sChoice == "Buy ammo" )
				m_pAmmoMenu.Open( 0, 0, pPlayer );
		}
	}

	private void PrimaryCallback( CTextMenu@ menu, CBasePlayer@ pPlayer, int iSlot, const CTextMenuItem@ pItem )
	{
		if( pItem !is null )
		{
			string sChoice = pItem.m_szName;
			if( sChoice == "Melee" )
				m_pMeleeMenu.Open( 0, 0, pPlayer );
			else if( sChoice == "SMGs" )
				m_pSmgMenu.Open( 0, 0, pPlayer );
			else if( sChoice == "Shotguns" )
				m_pShotgunMenu.Open( 0, 0, pPlayer );
			else if( sChoice == "Assault Rifles" )
				m_pAssaultMenu.Open( 0, 0, pPlayer );
			else if( sChoice == "Rifles" )
				m_pRifleMenu.Open( 0, 0, pPlayer );
			else if( sChoice == "Special" )
				m_pSpecialMenu.Open( 0, 0, pPlayer );
		}
	}

	private void AmmoCallBack( CTextMenu@ menu, CBasePlayer@ pPlayer, int iSlot, const CTextMenuItem@ pItem )
	{
		if( pItem !is null )
		{
			BuyableItem@ pBuyItem = null;

			pItem.m_pUserData.retrieve( @pBuyItem );

			if( pBuyItem !is null )
			{
				pBuyItem.Buy( pPlayer );
				m_pAmmoMenu.Open( 0, 0, pPlayer );
			}
		}
	}

	private void WeaponCallback( CTextMenu@ menu, CBasePlayer@ pPlayer, int iSlot, const CTextMenuItem@ pItem )
	{
		if( pItem !is null )
		{
			BuyableItem@ pBuyItem = null;

			pItem.m_pUserData.retrieve( @pBuyItem );

			if( pBuyItem !is null )
			{
				pBuyItem.Buy( pPlayer );
				//m_pMenu.Open( 0, 0, pPlayer);
			}
		}
	}
}
}
