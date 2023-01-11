using UnrealBuildTool;

public class DFoundryFX_Example : ModuleRules
{
	public DFoundryFX_Example(ReadOnlyTargetRules Target) : base(Target)
	{
		PCHUsage = PCHUsageMode.UseExplicitOrSharedPCHs;

    PublicDependencyModuleNames.AddRange(new string[] { "Core", "CoreUObject", "Engine" } );
  }
}
