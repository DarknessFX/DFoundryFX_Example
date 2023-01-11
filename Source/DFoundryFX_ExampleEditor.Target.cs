using UnrealBuildTool;
using System.Collections.Generic;

public class DFoundryFX_ExampleEditorTarget : TargetRules
{
	public DFoundryFX_ExampleEditorTarget(TargetInfo Target) : base(Target)
	{
		Type = TargetType.Editor;
		DefaultBuildSettings = BuildSettingsVersion.V2;
		IncludeOrderVersion = EngineIncludeOrderVersion.Unreal5_1;
		ExtraModuleNames.Add("DFoundryFX_Example");
	}
}
