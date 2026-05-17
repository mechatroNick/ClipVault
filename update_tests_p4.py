with open('ClipVault.xcodeproj/project.pbxproj', 'r') as f:
    content = f.read()

# 1. Remove MenuBarLifecycleTests.swift from test target Sources
content = content.replace('A1B2C3D4E5F6A7B8C9D0E203 /* MenuBarLifecycleTests.swift in Sources */,', '')

# 2. Add MenuBarControllerTests.swift
# PBXFileReference
ref_entry = '                P4_MENUBARCONTROLLERTESTS_SWIFT_REF /* MenuBarControllerTests.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; name = MenuBarControllerTests.swift; path = Tests/ClipVaultTests/MenuBarControllerTests.swift; sourceTree = SOURCE_ROOT; };'
content = content.replace('/* Begin PBXFileReference section */', f'/* Begin PBXFileReference section */\n{ref_entry}')

# PBXBuildFile
build_entry = '                P4_MENUBARCONTROLLERTESTS_SWIFT_BUILD /* MenuBarControllerTests.swift in Sources */ = {isa = PBXBuildFile; fileRef = P4_MENUBARCONTROLLERTESTS_SWIFT_REF /* MenuBarControllerTests.swift */; };'
content = content.replace('/* Begin PBXBuildFile section */', f'/* Begin PBXBuildFile section */\n{build_entry}')

# Add to Group
group_marker = '/* ClipVaultTests */ = {'
insertion_point = content.find('children = (', content.find(group_marker))
insertion_point = content.find(');', insertion_point)
content = content[:insertion_point] + '                                P4_MENUBARCONTROLLERTESTS_SWIFT_REF /* MenuBarControllerTests.swift */,\n' + content[insertion_point:]

# Add to Sources Build Phase of Test Target
target_phase = 'F2A3B4C5D6E7F8A9B0C2D2E1 /* Sources */ = {'
insertion_point = content.find(');', content.find(target_phase))
content = content[:insertion_point] + '                                P4_MENUBARCONTROLLERTESTS_SWIFT_BUILD /* MenuBarControllerTests.swift in Sources */,\n' + content[insertion_point:]

with open('ClipVault.xcodeproj/project.pbxproj', 'w') as f:
    f.write(content)
