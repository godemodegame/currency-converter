#!/usr/bin/env ruby
require 'xcodeproj'

project_path = 'CurrencyConverter.xcodeproj'
project = Xcodeproj::Project.open(project_path)

# Get the main target
main_target = project.targets.find { |t| t.name == 'CurrencyConverter' }

# Find and remove incorrectly added files from build phase
main_target.source_build_phase.files.each do |build_file|
  file_ref = build_file.file_ref
  next unless file_ref && file_ref.path

  # Check if it's a Design System file with wrong path
  if file_ref.path.include?('DesignSystem')
    puts "Removing incorrect file reference: #{file_ref.path}"
    build_file.remove_from_project
  end
end

# Find and remove file references from groups
def remove_design_system_refs(group)
  group.children.each do |child|
    if child.is_a?(Xcodeproj::Project::Object::PBXGroup)
      if child.name == 'DesignSystem' || child.display_name == 'DesignSystem'
        puts "Removing DesignSystem group"
        child.remove_from_project
        return
      else
        remove_design_system_refs(child)
      end
    end
  end
end

main_group = project.main_group['CurrencyConverter']
remove_design_system_refs(main_group) if main_group

# Save
project.save

puts "Cleaned up incorrect file references"

# Now add files correctly with relative paths
design_system_group = main_group['DesignSystem'] || main_group.new_group('DesignSystem', 'DesignSystem')

tokens_group = design_system_group['Tokens'] || design_system_group.new_group('Tokens', 'DesignSystem/Tokens')
extensions_group = design_system_group['Extensions'] || design_system_group.new_group('Extensions', 'DesignSystem/Extensions')
modifiers_group = design_system_group['ViewModifiers'] || design_system_group.new_group('ViewModifiers', 'DesignSystem/ViewModifiers')
components_group = design_system_group['Components'] || design_system_group.new_group('Components', 'DesignSystem/Components')

# Files with correct relative paths
files = {
  tokens_group => [
    {name: 'OceanColors.swift', path: 'DesignSystem/Tokens/OceanColors.swift'},
    {name: 'OceanSpacing.swift', path: 'DesignSystem/Tokens/OceanSpacing.swift'},
    {name: 'OceanRadius.swift', path: 'DesignSystem/Tokens/OceanRadius.swift'},
    {name: 'OceanShadows.swift', path: 'DesignSystem/Tokens/OceanShadows.swift'},
    {name: 'OceanBlur.swift', path: 'DesignSystem/Tokens/OceanBlur.swift'}
  ],
  extensions_group => [
    {name: 'Color+Ocean.swift', path: 'DesignSystem/Extensions/Color+Ocean.swift'}
  ],
  modifiers_group => [
    {name: 'GlassmorphismModifier.swift', path: 'DesignSystem/ViewModifiers/GlassmorphismModifier.swift'},
    {name: 'OceanGradientModifier.swift', path: 'DesignSystem/ViewModifiers/OceanGradientModifier.swift'},
    {name: 'GlassCardModifier.swift', path: 'DesignSystem/ViewModifiers/GlassCardModifier.swift'},
    {name: 'FloatingAnimationModifier.swift', path: 'DesignSystem/ViewModifiers/FloatingAnimationModifier.swift'}
  ],
  components_group => [
    {name: 'OceanButton.swift', path: 'DesignSystem/Components/OceanButton.swift'},
    {name: 'GlassCard.swift', path: 'DesignSystem/Components/GlassCard.swift'}
  ]
}

# Add files with correct paths
files.each do |group, file_list|
  file_list.each do |file_info|
    full_path = File.join('CurrencyConverter', file_info[:path])

    unless File.exist?(full_path)
      puts "⚠️  File not found: #{full_path}"
      next
    end

    # Check if file already exists in group
    if group.files.any? { |f| f.display_name == file_info[:name] }
      puts "⏭️  Already added: #{file_info[:name]}"
      next
    end

    # Add file reference with correct relative path
    file_ref = group.new_reference(file_info[:path])
    file_ref.name = file_info[:name]
    file_ref.source_tree = '<group>'

    # Add to build phase
    main_target.source_build_phase.add_file_reference(file_ref)

    puts "✅ Added: #{file_info[:name]} (#{file_info[:path]})"
  end
end

# Save the project
project.save

puts ""
puts "=" * 60
puts "✅ Files added with correct paths!"
puts "=" * 60
