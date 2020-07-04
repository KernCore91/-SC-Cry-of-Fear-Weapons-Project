#include "cofcommon"

void PluginInit()
{
	g_Module.ScriptInfo.SetAuthor( "KernCore && D.N.I.O. 071" );
	g_Module.ScriptInfo.SetContactInfo( "https://discord.gg/0wtJ6aAd7XOGI6vI" );
}

void MapInit()
{
	CoFRegister();
}