with open('ClipVault.xcodeproj/project.pbxproj', 'r') as f:
    content = f.read()

# Remove test file from main target
content = content.replace('P4_PREVIEW_CONTENTPREVIEWTESTS_SWIFT_BUILD /* ContentPreviewTests.swift in Sources */,', '')

# Add test file to test target
target_phase = 'F2A3B4C5D6E7F8A9B0C2D2E1 /* Sources */ = {'
insertion_point = content.find(');', content.find(target_phase))
content = content[:insertion_point] + '                                P4_PREVIEW_CONTENTPREVIEWTESTS_SWIFT_BUILD /* ContentPreviewTests.swift in Sources */,\n' + content[insertion_point:]

with open('ClipVault.xcodeproj/project.pbxproj', 'w') as f:
    f.write(content)
