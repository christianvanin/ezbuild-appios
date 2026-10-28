import os
import hashlib

def gen_uuid(seed: str) -> str:
    h = hashlib.md5(seed.encode('utf-8')).hexdigest().upper()
    return h[:24]

BASE_DIR = os.path.abspath(r"SheriffGame")
PROJ_DIR = os.path.abspath(r"SheriffGame.xcodeproj")
os.makedirs(PROJ_DIR, exist_ok=True)

# Swift source files
SWIFT_FILES = [
    ("AppDelegate.swift", "App/AppDelegate.swift"),
    ("GameViewController.swift", "Game/GameViewController.swift"),
    ("FirstPersonController.swift", "Game/FirstPersonController.swift"),
    ("ForestScene.swift", "Game/ForestScene.swift"),
    ("WeaponSystem.swift", "Game/WeaponSystem.swift"),
    ("InventoryManager.swift", "Game/InventoryManager.swift"),
    ("WaveManager.swift", "Game/WaveManager.swift"),
    ("ZombieAI.swift", "Game/ZombieAI.swift"),
    ("ChestManager.swift", "Game/ChestManager.swift"),
    ("EscapeGameMode.swift", "Game/EscapeGameMode.swift"),
    ("HUDOverlayView.swift", "Overlay/HUDOverlayView.swift")
]

# Resource files (Models)
MODEL_FILES = [
    "cabin.obj", "cabin.mtl",
    "chest_base.obj", "chest_base.mtl",
    "chest_lid.obj", "chest_lid.mtl",
    "fence_segment.obj", "fence_segment.mtl",
    "fps_dynamite.obj", "fps_dynamite.mtl",
    "fps_revolver.obj", "fps_revolver.mtl",
    "fps_rifle.obj", "fps_rifle.mtl",
    "fps_shotgun.obj", "fps_shotgun.mtl",
    "fps_sniper.obj", "fps_sniper.mtl",
    "gate.obj", "gate.mtl",
    "grass_clump.obj", "grass_clump.mtl",
    "graveyard_tomb.obj", "graveyard_tomb.mtl",
    "key.obj", "key.mtl",
    "mine_entrance.obj", "mine_entrance.mtl",
    "pine_tree.obj", "pine_tree.mtl",
    "rock.obj", "rock.mtl",
    "saloon.obj", "saloon.mtl",
    "sheriff_office.obj", "sheriff_office.mtl",
    "zombie.obj", "zombie.mtl",
    "zombie_brute.obj", "zombie_brute.mtl",
    "zombie_runner.obj", "zombie_runner.mtl",
    "zombie_walker.obj", "zombie_walker.mtl"
]

def generate_pbxproj():
    # UUIDs
    proj_uuid = gen_uuid("PBXProject")
    target_uuid = gen_uuid("PBXNativeTarget_SheriffGame")
    app_product_uuid = gen_uuid("Product_SheriffGame_app")
    
    main_group_uuid = gen_uuid("Group_Main")
    sheriff_group_uuid = gen_uuid("Group_SheriffGame")
    app_group_uuid = gen_uuid("Group_App")
    game_group_uuid = gen_uuid("Group_Game")
    overlay_group_uuid = gen_uuid("Group_Overlay")
    models_group_uuid = gen_uuid("Group_Models")
    products_group_uuid = gen_uuid("Group_Products")

    sources_phase_uuid = gen_uuid("Phase_Sources")
    resources_phase_uuid = gen_uuid("Phase_Resources")
    frameworks_phase_uuid = gen_uuid("Phase_Frameworks")

    proj_cfg_list_uuid = gen_uuid("CfgList_Project")
    proj_cfg_debug_uuid = gen_uuid("Cfg_Proj_Debug")
    proj_cfg_release_uuid = gen_uuid("Cfg_Proj_Release")

    target_cfg_list_uuid = gen_uuid("CfgList_Target")
    target_cfg_debug_uuid = gen_uuid("Cfg_Target_Debug")
    target_cfg_release_uuid = gen_uuid("Cfg_Target_Release")

    info_plist_ref_uuid = gen_uuid("Ref_Info_plist")

    # Map files to UUIDs
    file_refs = {}
    build_files = {}

    for name, rel_path in SWIFT_FILES:
        ref_uuid = gen_uuid(f"Ref_{name}")
        bld_uuid = gen_uuid(f"Bld_{name}")
        file_refs[name] = (ref_uuid, rel_path, "sourcecode.swift")
        build_files[name] = (bld_uuid, ref_uuid)

    for m in MODEL_FILES:
        ref_uuid = gen_uuid(f"Ref_{m}")
        bld_uuid = gen_uuid(f"Bld_{m}")
        file_type = "text" if m.endswith(".obj") or m.endswith(".mtl") else "file"
        file_refs[m] = (ref_uuid, f"Models/{m}", file_type)
        build_files[m] = (bld_uuid, ref_uuid)

    # Start PBX Output
    lines = []
    lines.append("// !$*UTF8*$!")
    lines.append("{")
    lines.append("\tarchiveVersion = 1;")
    lines.append("\tclasses = {")
    lines.append("\t};")
    lines.append("\tobjectVersion = 54;")
    lines.append("\tobjects = {")

    # PBXBuildFile Section
    lines.append("\n/* Begin PBXBuildFile section */")
    for name, (bld_uuid, ref_uuid) in build_files.items():
        lines.append(f"\t\t{bld_uuid} /* {name} in Sources/Resources */ = {{isa = PBXBuildFile; fileRef = {ref_uuid} /* {name} */; }};")
    lines.append("/* End PBXBuildFile section */")

    # PBXFileReference Section
    lines.append("\n/* Begin PBXFileReference section */")
    lines.append(f"\t\t{app_product_uuid} /* SheriffGame.app */ = {{isa = PBXFileReference; explicitFileType = wrapper.application; includeInIndex = 0; path = SheriffGame.app; sourceTree = BUILT_PRODUCTS_DIR; }};")
    lines.append(f"\t\t{info_plist_ref_uuid} /* Info.plist */ = {{isa = PBXFileReference; lastKnownFileType = text.plist.xml; path = Info.plist; sourceTree = \"<group>\"; }};")

    for name, (ref_uuid, rel_path, ftype) in file_refs.items():
        basename = os.path.basename(rel_path)
        lines.append(f"\t\t{ref_uuid} /* {basename} */ = {{isa = PBXFileReference; lastKnownFileType = {ftype}; path = {basename}; sourceTree = \"<group>\"; }};")
    lines.append("/* End PBXFileReference section */")

    # PBXFrameworksBuildPhase Section
    lines.append("\n/* Begin PBXFrameworksBuildPhase section */")
    lines.append(f"\t\t{frameworks_phase_uuid} /* Frameworks */ = {{")
    lines.append("\t\t\tisa = PBXFrameworksBuildPhase;")
    lines.append("\t\t\tbuildActionMask = 2147483647;")
    lines.append("\t\t\tfiles = (")
    lines.append("\t\t\t);")
    lines.append("\t\t\trunOnlyForDeploymentPostprocessing = 0;")
    lines.append("\t\t};")
    lines.append("/* End PBXFrameworksBuildPhase section */")

    # PBXGroup Section
    lines.append("\n/* Begin PBXGroup section */")
    
    # App Group
    lines.append(f"\t\t{app_group_uuid} /* App */ = {{")
    lines.append("\t\t\tisa = PBXGroup;")
    lines.append("\t\t\tchildren = (")
    lines.append(f"\t\t\t\t{file_refs['AppDelegate.swift'][0]} /* AppDelegate.swift */,")
    lines.append(f"\t\t\t\t{info_plist_ref_uuid} /* Info.plist */,")
    lines.append("\t\t\t);")
    lines.append("\t\t\tpath = App;")
    lines.append("\t\t\tsourceTree = \"<group>\";")
    lines.append("\t\t};")

    # Game Group
    lines.append(f"\t\t{game_group_uuid} /* Game */ = {{")
    lines.append("\t\t\tisa = PBXGroup;")
    lines.append("\t\t\tchildren = (")
    for name, _ in SWIFT_FILES:
        if name != "AppDelegate.swift" and name != "HUDOverlayView.swift":
            lines.append(f"\t\t\t\t{file_refs[name][0]} /* {name} */,")
    lines.append("\t\t\t);")
    lines.append("\t\t\tpath = Game;")
    lines.append("\t\t\tsourceTree = \"<group>\";")
    lines.append("\t\t};")

    # Overlay Group
    lines.append(f"\t\t{overlay_group_uuid} /* Overlay */ = {{")
    lines.append("\t\t\tisa = PBXGroup;")
    lines.append("\t\t\tchildren = (")
    lines.append(f"\t\t\t\t{file_refs['HUDOverlayView.swift'][0]} /* HUDOverlayView.swift */,")
    lines.append("\t\t\t);")
    lines.append("\t\t\tpath = Overlay;")
    lines.append("\t\t\tsourceTree = \"<group>\";")
    lines.append("\t\t};")

    # Models Group
    lines.append(f"\t\t{models_group_uuid} /* Models */ = {{")
    lines.append("\t\t\tisa = PBXGroup;")
    lines.append("\t\t\tchildren = (")
    for m in MODEL_FILES:
        lines.append(f"\t\t\t\t{file_refs[m][0]} /* {m} */,")
    lines.append("\t\t\t);")
    lines.append("\t\t\tpath = Models;")
    lines.append("\t\t\tsourceTree = \"<group>\";")
    lines.append("\t\t};")

    # Products Group
    lines.append(f"\t\t{products_group_uuid} /* Products */ = {{")
    lines.append("\t\t\tisa = PBXGroup;")
    lines.append("\t\t\tchildren = (")
    lines.append(f"\t\t\t\t{app_product_uuid} /* SheriffGame.app */,")
    lines.append("\t\t\t);")
    lines.append("\t\t\tname = Products;")
    lines.append("\t\t\tsourceTree = \"<group>\";")
    lines.append("\t\t};")

    # SheriffGame Group
    lines.append(f"\t\t{sheriff_group_uuid} /* SheriffGame */ = {{")
    lines.append("\t\t\tisa = PBXGroup;")
    lines.append("\t\t\tchildren = (")
    lines.append(f"\t\t\t\t{app_group_uuid} /* App */,")
    lines.append(f"\t\t\t\t{game_group_uuid} /* Game */,")
    lines.append(f"\t\t\t\t{overlay_group_uuid} /* Overlay */,")
    lines.append(f"\t\t\t\t{models_group_uuid} /* Models */,")
    lines.append("\t\t\t);")
    lines.append("\t\t\tpath = SheriffGame;")
    lines.append("\t\t\tsourceTree = \"<group>\";")
    lines.append("\t\t};")

    # Main Group
    lines.append(f"\t\t{main_group_uuid} = {{")
    lines.append("\t\t\tisa = PBXGroup;")
    lines.append("\t\t\tchildren = (")
    lines.append(f"\t\t\t\t{sheriff_group_uuid} /* SheriffGame */,")
    lines.append(f"\t\t\t\t{products_group_uuid} /* Products */,")
    lines.append("\t\t\t);")
    lines.append("\t\t\tsourceTree = \"<group>\";")
    lines.append("\t\t};")
    lines.append("/* End PBXGroup section */")

    # PBXNativeTarget Section
    lines.append("\n/* Begin PBXNativeTarget section */")
    lines.append(f"\t\t{target_uuid} /* SheriffGame */ = {{")
    lines.append("\t\t\tisa = PBXNativeTarget;")
    lines.append(f"\t\t\tbuildConfigurationList = {target_cfg_list_uuid} /* Build configuration list for PBXNativeTarget \"SheriffGame\" */;")
    lines.append("\t\t\tbuildPhases = (")
    lines.append(f"\t\t\t\t{sources_phase_uuid} /* Sources */,")
    lines.append(f"\t\t\t\t{frameworks_phase_uuid} /* Frameworks */,")
    lines.append(f"\t\t\t\t{resources_phase_uuid} /* Resources */,")
    lines.append("\t\t\t);")
    lines.append("\t\t\tbuildRules = (")
    lines.append("\t\t\t);")
    lines.append("\t\t\tdependencies = (")
    lines.append("\t\t\t);")
    lines.append("\t\t\tname = SheriffGame;")
    lines.append("\t\t\tproductName = SheriffGame;")
    lines.append(f"\t\t\tproductReference = {app_product_uuid} /* SheriffGame.app */;")
    lines.append("\t\t\tproductType = \"com.apple.product-type.application\";")
    lines.append("\t\t};")
    lines.append("/* End PBXNativeTarget section */")

    # PBXProject Section
    lines.append("\n/* Begin PBXProject section */")
    lines.append(f"\t\t{proj_uuid} /* Project object */ = {{")
    lines.append("\t\t\tisa = PBXProject;")
    lines.append("\t\t\tattributes = {")
    lines.append("\t\t\t\tLastSwiftUpdateCheck = 1500;")
    lines.append("\t\t\t\tLastUpgradeCheck = 1500;")
    lines.append("\t\t\t};")
    lines.append(f"\t\t\tbuildConfigurationList = {proj_cfg_list_uuid} /* Build configuration list for PBXProject \"SheriffGame\" */;")
    lines.append("\t\t\tcompatibilityVersion = \"Xcode 14.0\";")
    lines.append("\t\t\tdevelopmentRegion = en;")
    lines.append("\t\t\thasScannedForEncodings = 0;")
    lines.append("\t\t\tknownRegions = (")
    lines.append("\t\t\t\ten,")
    lines.append("\t\t\t\tBase,")
    lines.append("\t\t\t);")
    lines.append(f"\t\t\tmainGroup = {main_group_uuid};")
    lines.append(f"\t\t\tproductRefGroup = {products_group_uuid} /* Products */;")
    lines.append("\t\t\tprojectDirPath = \"\";")
    lines.append("\t\t\tprojectRoot = \"\";")
    lines.append("\t\t\ttargets = (")
    lines.append(f"\t\t\t\t{target_uuid} /* SheriffGame */,")
    lines.append("\t\t\t);")
    lines.append("\t\t};")
    lines.append("/* End PBXProject section */")

    # PBXResourcesBuildPhase Section
    lines.append("\n/* Begin PBXResourcesBuildPhase section */")
    lines.append(f"\t\t{resources_phase_uuid} /* Resources */ = {{")
    lines.append("\t\t\tisa = PBXResourcesBuildPhase;")
    lines.append("\t\t\tbuildActionMask = 2147483647;")
    lines.append("\t\t\tfiles = (")
    for m in MODEL_FILES:
        lines.append(f"\t\t\t\t{build_files[m][0]} /* {m} in Resources */,")
    lines.append("\t\t\t);")
    lines.append("\t\t\trunOnlyForDeploymentPostprocessing = 0;")
    lines.append("\t\t};")
    lines.append("/* End PBXResourcesBuildPhase section */")

    # PBXSourcesBuildPhase Section
    lines.append("\n/* Begin PBXSourcesBuildPhase section */")
    lines.append(f"\t\t{sources_phase_uuid} /* Sources */ = {{")
    lines.append("\t\t\tisa = PBXSourcesBuildPhase;")
    lines.append("\t\t\tbuildActionMask = 2147483647;")
    lines.append("\t\t\tfiles = (")
    for name, _ in SWIFT_FILES:
        lines.append(f"\t\t\t\t{build_files[name][0]} /* {name} in Sources */,")
    lines.append("\t\t\t);")
    lines.append("\t\t\trunOnlyForDeploymentPostprocessing = 0;")
    lines.append("\t\t};")
    lines.append("/* End PBXSourcesBuildPhase section */")

    # XCBuildConfiguration Section
    lines.append("\n/* Begin XCBuildConfiguration section */")
    
    # Project Debug
    lines.append(f"\t\t{proj_cfg_debug_uuid} /* Debug */ = {{")
    lines.append("\t\t\tisa = XCBuildConfiguration;")
    lines.append("\t\t\tbuildSettings = {")
    lines.append("\t\t\t\tALWAYS_SEARCH_USER_PATHS = NO;")
    lines.append("\t\t\t\tCLANG_ANALYZER_NONNULL = YES;")
    lines.append("\t\t\t\tCLANG_CXX_LANGUAGE_STANDARD = \"gnu++20\";")
    lines.append("\t\t\t\tCLANG_ENABLE_MODULES = YES;")
    lines.append("\t\t\t\tCLANG_ENABLE_OBJC_ARC = YES;")
    lines.append("\t\t\t\tCOPY_PHASE_STRIP = NO;")
    lines.append("\t\t\t\tDEBUG_INFORMATION_FORMAT = dwarf;")
    lines.append("\t\t\t\tENABLE_STRICT_OBJC_MSGSEND = YES;")
    lines.append("\t\t\t\tENABLE_TESTABILITY = YES;")
    lines.append("\t\t\t\tGCC_DYNAMIC_NO_PIC = NO;")
    lines.append("\t\t\t\tGCC_NO_COMMON_BLOCKS = YES;")
    lines.append("\t\t\t\tGCC_OPTIMIZATION_LEVEL = 0;")
    lines.append("\t\t\t\tGCC_PREPROCESSOR_DEFINITIONS = (")
    lines.append("\t\t\t\t\t\"DEBUG=1\",")
    lines.append("\t\t\t\t\t\"$(inherited)\",")
    lines.append("\t\t\t\t);")
    lines.append("\t\t\t\tMTL_ENABLE_DEBUG_INFO = INCLUDE_SOURCE;")
    lines.append("\t\t\t\tMTL_FAST_MATH = YES;")
    lines.append("\t\t\t\tONLY_ACTIVE_ARCH = YES;")
    lines.append("\t\t\t\tSDKROOT = iphoneos;")
    lines.append("\t\t\t\tSWIFT_ACTIVE_COMPILATION_CONDITIONS = DEBUG;")
    lines.append("\t\t\t\tSWIFT_OPTIMIZATION_LEVEL = \"-Onone\";")
    lines.append("\t\t\t};")
    lines.append("\t\t\tname = Debug;")
    lines.append("\t\t};")

    # Project Release
    lines.append(f"\t\t{proj_cfg_release_uuid} /* Release */ = {{")
    lines.append("\t\t\tisa = XCBuildConfiguration;")
    lines.append("\t\t\tbuildSettings = {")
    lines.append("\t\t\t\tALWAYS_SEARCH_USER_PATHS = NO;")
    lines.append("\t\t\t\tCLANG_ANALYZER_NONNULL = YES;")
    lines.append("\t\t\t\tCLANG_CXX_LANGUAGE_STANDARD = \"gnu++20\";")
    lines.append("\t\t\t\tCLANG_ENABLE_MODULES = YES;")
    lines.append("\t\t\t\tCLANG_ENABLE_OBJC_ARC = YES;")
    lines.append("\t\t\t\tCOPY_PHASE_STRIP = NO;")
    lines.append("\t\t\t\tDEBUG_INFORMATION_FORMAT = \"dwarf-with-dsym\";")
    lines.append("\t\t\t\tENABLE_NS_ASSERTIONS = NO;")
    lines.append("\t\t\t\tENABLE_STRICT_OBJC_MSGSEND = YES;")
    lines.append("\t\t\t\tGCC_NO_COMMON_BLOCKS = YES;")
    lines.append("\t\t\t\tMTL_ENABLE_DEBUG_INFO = NO;")
    lines.append("\t\t\t\tMTL_FAST_MATH = YES;")
    lines.append("\t\t\t\tSDKROOT = iphoneos;")
    lines.append("\t\t\t\tSWIFT_COMPILATION_MODE = \"wholemodule\";")
    lines.append("\t\t\t\tSWIFT_OPTIMIZATION_LEVEL = \"-O\";")
    lines.append("\t\t\t\tVALIDATE_PRODUCT = YES;")
    lines.append("\t\t\t};")
    lines.append("\t\t\tname = Release;")
    lines.append("\t\t};")

    # Target Debug
    lines.append(f"\t\t{target_cfg_debug_uuid} /* Debug */ = {{")
    lines.append("\t\t\tisa = XCBuildConfiguration;")
    lines.append("\t\t\tbuildSettings = {")
    lines.append("\t\t\t\tASSETCATALOG_COMPILER_APPICON_NAME = AppIcon;")
    lines.append("\t\t\t\tCODE_SIGN_STYLE = Manual;")
    lines.append("\t\t\t\tCODE_SIGNING_ALLOWED = NO;")
    lines.append("\t\t\t\tCODE_SIGNING_REQUIRED = NO;")
    lines.append("\t\t\t\tINFOPLIST_FILE = SheriffGame/App/Info.plist;")
    lines.append("\t\t\t\tIPHONEOS_DEPLOYMENT_TARGET = 15.0;")
    lines.append("\t\t\t\tLD_RUNPATH_SEARCH_PATHS = (")
    lines.append("\t\t\t\t\t\"$(inherited)\",")
    lines.append("\t\t\t\t\t\"@executable_path/Frameworks\",")
    lines.append("\t\t\t\t);")
    lines.append("\t\t\t\tPRODUCT_BUNDLE_IDENTIFIER = com.sheriffgame.undeadforest;")
    lines.append("\t\t\t\tPRODUCT_NAME = \"$(TARGET_NAME)\";")
    lines.append("\t\t\t\tSWIFT_VERSION = 5.0;")
    lines.append("\t\t\t\tTARGETED_DEVICE_FAMILY = \"1,2\";")
    lines.append("\t\t\t};")
    lines.append("\t\t\tname = Debug;")
    lines.append("\t\t};")

    # Target Release
    lines.append(f"\t\t{target_cfg_release_uuid} /* Release */ = {{")
    lines.append("\t\t\tisa = XCBuildConfiguration;")
    lines.append("\t\t\tbuildSettings = {")
    lines.append("\t\t\t\tASSETCATALOG_COMPILER_APPICON_NAME = AppIcon;")
    lines.append("\t\t\t\tCODE_SIGN_STYLE = Manual;")
    lines.append("\t\t\t\tCODE_SIGNING_ALLOWED = NO;")
    lines.append("\t\t\t\tCODE_SIGNING_REQUIRED = NO;")
    lines.append("\t\t\t\tINFOPLIST_FILE = SheriffGame/App/Info.plist;")
    lines.append("\t\t\t\tIPHONEOS_DEPLOYMENT_TARGET = 15.0;")
    lines.append("\t\t\t\tLD_RUNPATH_SEARCH_PATHS = (")
    lines.append("\t\t\t\t\t\"$(inherited)\",")
    lines.append("\t\t\t\t\t\"@executable_path/Frameworks\",")
    lines.append("\t\t\t\t);")
    lines.append("\t\t\t\tPRODUCT_BUNDLE_IDENTIFIER = com.sheriffgame.undeadforest;")
    lines.append("\t\t\t\tPRODUCT_NAME = \"$(TARGET_NAME)\";")
    lines.append("\t\t\t\tSWIFT_VERSION = 5.0;")
    lines.append("\t\t\t\tTARGETED_DEVICE_FAMILY = \"1,2\";")
    lines.append("\t\t\t};")
    lines.append("\t\t\tname = Release;")
    lines.append("\t\t};")
    lines.append("/* End XCBuildConfiguration section */")

    # XCConfigurationList Section
    lines.append("\n/* Begin XCConfigurationList section */")
    lines.append(f"\t\t{proj_cfg_list_uuid} /* Build configuration list for PBXProject \"SheriffGame\" */ = {{")
    lines.append("\t\t\tisa = XCConfigurationList;")
    lines.append("\t\t\tbuildConfigurations = (")
    lines.append(f"\t\t\t\t{proj_cfg_debug_uuid} /* Debug */,")
    lines.append(f"\t\t\t\t{proj_cfg_release_uuid} /* Release */,")
    lines.append("\t\t\t);")
    lines.append("\t\t\tdefaultConfigurationIsVisible = 0;")
    lines.append("\t\t\tdefaultConfigurationName = Release;")
    lines.append("\t\t};")

    lines.append(f"\t\t{target_cfg_list_uuid} /* Build configuration list for PBXNativeTarget \"SheriffGame\" */ = {{")
    lines.append("\t\t\tisa = XCConfigurationList;")
    lines.append("\t\t\tbuildConfigurations = (")
    lines.append(f"\t\t\t\t{target_cfg_debug_uuid} /* Debug */,")
    lines.append(f"\t\t\t\t{target_cfg_release_uuid} /* Release */,")
    lines.append("\t\t\t);")
    lines.append("\t\t\tdefaultConfigurationIsVisible = 0;")
    lines.append("\t\t\tdefaultConfigurationName = Release;")
    lines.append("\t\t};")
    lines.append("/* End XCConfigurationList section */")

    lines.append("\t};")
    lines.append(f"\trootObject = {proj_uuid} /* Project object */;")
    lines.append("}")

    pbx_path = os.path.join(PROJ_DIR, "project.pbxproj")
    with open(pbx_path, "w", encoding="utf-8") as f:
        f.write("\n".join(lines) + "\n")
    print("Generated project.pbxproj successfully at:", pbx_path)

    # Generate shared scheme
    scheme_dir = os.path.join(PROJ_DIR, "xcshareddata", "xcschemes")
    os.makedirs(scheme_dir, exist_ok=True)
    scheme_path = os.path.join(scheme_dir, "SheriffGame.xcscheme")
    scheme_content = f"""<?xml version="1.0" encoding="UTF-8"?>
<Scheme
   LastUpgradeVersion = "1500"
   version = "1.7">
   <BuildAction
      parallelizeBuildables = "YES"
      buildImplicitDependencies = "YES">
      <BuildActionEntries>
         <BuildActionEntry
            buildForTesting = "YES"
            buildForRunning = "YES"
            buildForProfiling = "YES"
            buildForArchiving = "YES"
            buildForAnalyzing = "YES">
            <BuildableReference
               BuildableIdentifier = "primary"
               BlueprintIdentifier = "{target_uuid}"
               BuildableName = "SheriffGame.app"
               BlueprintName = "SheriffGame"
               ReferencedContainer = "container:SheriffGame.xcodeproj">
            </BuildableReference>
         </BuildActionEntry>
      </BuildActionEntries>
   </BuildAction>
   <TestAction
      buildConfiguration = "Debug"
      selectedDebuggerIdentifier = "Xcode.DebuggerFoundation.Debugger.LLDB"
      selectedLauncherIdentifier = "Xcode.DebuggerFoundation.Launcher.LLDB"
      shouldUseLaunchSchemeArgsEnv = "YES">
      <Testables>
      </Testables>
   </TestAction>
   <LaunchAction
      buildConfiguration = "Debug"
      selectedDebuggerIdentifier = "Xcode.DebuggerFoundation.Debugger.LLDB"
      selectedLauncherIdentifier = "Xcode.DebuggerFoundation.Launcher.LLDB"
      launchStyle = "0"
      useCustomWorkingDirectory = "NO"
      ignoresPersistentStateOnLaunch = "NO"
      debugDocumentVersioning = "YES"
      debugServiceExtension = "internal"
      allowLocationSimulation = "YES">
      <BuildableProductRunnable
         runnableDebuggingMode = "0">
         <BuildableReference
            BuildableIdentifier = "primary"
            BlueprintIdentifier = "{target_uuid}"
            BuildableName = "SheriffGame.app"
            BlueprintName = "SheriffGame"
            ReferencedContainer = "container:SheriffGame.xcodeproj">
         </BuildableReference>
      </BuildableProductRunnable>
   </LaunchAction>
   <ProfileAction
      buildConfiguration = "Release"
      shouldUseLaunchSchemeArgsEnv = "YES"
      savedToolIdentifier = ""
      useCustomWorkingDirectory = "NO"
      debugDocumentVersioning = "YES">
      <BuildableProductRunnable
         runnableDebuggingMode = "0">
         <BuildableReference
            BuildableIdentifier = "primary"
            BlueprintIdentifier = "{target_uuid}"
            BuildableName = "SheriffGame.app"
            BlueprintName = "SheriffGame"
            ReferencedContainer = "container:SheriffGame.xcodeproj">
         </BuildableReference>
      </BuildableProductRunnable>
   </ProfileAction>
   <AnalyzeAction
      buildConfiguration = "Debug">
   </AnalyzeAction>
   <ArchiveAction
      buildConfiguration = "Release"
      revealArchiveInOrganizer = "YES">
   </ArchiveAction>
</Scheme>
"""
    with open(scheme_path, "w", encoding="utf-8") as f:
        f.write(scheme_content)
    print("Generated SheriffGame.xcscheme successfully at:", scheme_path)

if __name__ == "__main__":
    generate_pbxproj()

