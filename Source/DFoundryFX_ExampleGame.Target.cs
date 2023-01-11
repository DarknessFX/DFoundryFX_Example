using UnrealBuildTool;
using System.Collections.Generic;

public class DFoundryFX_ExampleGameTarget : TargetRules
{
	public DFoundryFX_ExampleGameTarget(TargetInfo Target) : base(Target)
	{
		Type = TargetType.Game;
		DefaultBuildSettings = BuildSettingsVersion.V2;
		IncludeOrderVersion = EngineIncludeOrderVersion.Unreal5_1;
		ExtraModuleNames.Add("DFoundryFX_Example");
	}
}
