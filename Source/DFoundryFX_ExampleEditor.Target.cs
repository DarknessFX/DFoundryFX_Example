using UnrealBuildTool;
using System.Collections.Generic;

public class DFoundryFX_ExampleEditorTarget : TargetRules
{
	public DFoundryFX_ExampleEditorTarget(TargetInfo Target) : base(Target)
	{
		Type = TargetType.Editor;
		DefaultBuildSettings = BuildSettingsVersion.Latest;
		IncludeOrderVersion = EngineIncludeOrderVersion.Latest;
		ExtraModuleNames.Add("DFoundryFX_Example");
	}
}
