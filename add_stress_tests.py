import os
import sys

def add_file_to_pbxproj(proj_path, file_path, group_name, target_name):
    with open(proj_path, 'r') as f:
        content = f.read()

    file_name = os.path.basename(file_path)
    file_ref_id = f"ST_{file_name.upper().replace('.', '_')}_REF"
    build_file_id = f"ST_{file_name.upper().replace('.', '_')}_BUILD"

    if file_ref_id in content:
        print(f"{file_name} already in project.")
        return

    ref_entry = f'                {file_ref_id} /* {file_name} */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; name = {file_name}; path = {file_path}; sourceTree = SOURCE_ROOT; }};'
    content = content.replace('/* Begin PBXFileReference section */', f'/* Begin PBXFileReference section */\n{ref_entry}')

    build_entry = f'                {build_file_id} /* {file_name} in Sources */ = {{isa = PBXBuildFile; fileRef = {file_ref_id} /* {file_name} */; }};'
    content = content.replace('/* Begin PBXBuildFile section */', f'/* Begin PBXBuildFile section */\n{build_entry}')

    group_marker = f'/* {group_name} */ = {{'
    if group_marker in content:
        group_start = content.find(group_marker)
        children_start = content.find('children = (', group_start)
        children_end = content.find(');', children_start)
        content = content[:children_end] + f'                                {file_ref_id} /* {file_name} */,\n' + content[children_end:]

    # Add to Test target sources
    pid = 'F2A3B4C5D6E7F8A9B0C2D2E1' 
    phase_start = content.find(f'{pid} /* Sources */ = {{')
    files_start = content.find('files = (', phase_start)
    files_end = content.find(');', files_start)
    content = content[:files_end] + f'                                {build_file_id} /* {file_name} in Sources */,\n' + content[files_end:]

    with open(proj_path, 'w') as f:
        f.write(content)

proj = 'ClipVault.xcodeproj/project.pbxproj'
add_file_to_pbxproj(proj, 'Tests/ClipVaultTests/StressTests.swift', 'ClipVaultTests', 'ClipVaultTests')
