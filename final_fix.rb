#!/usr/bin/env ruby
require 'xcodeproj'

project_path = 'CurrencyConverter.xcodeproj'
project = Xcodeproj::Project.open(project_path)

# Get the main target
main_target = project.targets.find { |t| t.name == 'CurrencyConverter' }
main_group = project.main_group['CurrencyConverter']

# Step 1: Remove ALL existing DesignSystem file references from build phase
puts "Step 1: Removing all Design System file references from build phase..."
files_to_remove = []
main_target.source_build_phase.files.each do |build_file|
  file_ref = build_file.file_ref
  next unless file_ref && file_ref.path

  if file_ref.path.include?('DesignSystem') || file_ref.path.include?('Ocean') || file_ref.path.include?('Glass')
    puts "  Removing: #{file_ref.path}"
    files_to_remove << build_file
  end
end

files_to_remove.each { |f| f.remove_from_project }

# Step 2: Remove DesignSystem group
puts "\nStep 2: Removing DesignSystem group..."
def find_and_remove_design_system(group)
  group.children.to_a.each do |child|
    if child.is_a?(Xcodeproj::Project::Object::PBXGroup)
      if child.name == 'DesignSystem' || child.display_name == 'DesignSystem'
        puts "  Removing group: #{child.display_name}"
        child.remove_from_project
        return true
      else
        return true if find_and_remove_design_system(child)
      end
    end
  end
  false
end

find_and_remove_design_system(main_group)

# Step 3: Add files fresh with correct structure
puts "\nStep 3: Adding Design System files with correct structure..."

# Create groups with correct paths
design_system_group = main_group.new_group('DesignSystem', 'DesignSystem')
tokens_group = design_system_group.new_group('Tokens', 'Tokens')
extensions_group = design_system_group.new_group('Extensions', 'Extensions')
modifiers_group = design_system_group.new_group('ViewModifiers', 'ViewModifiers')
components_group = design_system_group.new_group('Components', 'Components')

# Define files - path relative to the CurrencyConverter folder
files_to_add = [
  {group: tokens_group, name: 'OceanColors.swift', path: '../DesignSystem/Tokens/OceanColors.swift'},
  {group: tokens_group, name: 'OceanSpacing.swift', path: '../DesignSystem/Tokens/OceanSpacing.swift'},
  {group: tokens_group, name: 'OceanRadius.swift', path: '../DesignSystem/Tokens/OceanRadius.swift'},
  {group: tokens_group, name: 'OceanShadows.swift', path: '../DesignSystem/Tokens/OceanShadows.swift'},
  {group: tokens_group, name: 'OceanBlur.swift', path: '../DesignSystem/Tokens/OceanBlur.swift'},
  {group: extensions_group, name: 'Color+Ocean.swift', path: '../DesignSystem/Extensions/Color+Ocean.swift'},
  {group: modifiers_group, name: 'GlassmorphismModifier.swift', path: '../DesignSystem/ViewModifiers/GlassmorphismModifier.swift'},
  {group: modifiers_group, name: 'OceanGradientModifier.swift', path: '../DesignSystem/ViewModifiers/OceanGradientModifier.swift'},
  {group: modifiers_group, name: 'GlassCardModifier.swift', path: '../DesignSystem/ViewModifiers/GlassCardModifier.swift'},
  {group: modifiers_group, name: 'FloatingAnimationModifier.swift', path: '../DesignSystem/ViewModifiers/FloatingAnimationModifier.swift'},
  {group: components_group, name: 'OceanButton.swift', path: '../DesignSystem/Components/OceanButton.swift'},
  {group: components_group, name: 'GlassCard.swift', path: '../DesignSystem/Components/GlassCard.swift'}
]

files_to_add.each do |file_info|
  # Check if file exists
  full_path = File.join('CurrencyConverter', file_info[:path])
  unless File.exist?(full_path)
    puts "  ⚠️  File not found: #{full_path}"
    next
  end

  # Create file reference
  file_ref = file_info[:group].new_reference(file_info[:path])
  file_ref.name = file_info[:name]
  file_ref.source_tree = '<group>'

  # Add to build phase
  main_target.source_build_phase.add_file_reference(file_ref)

  puts "  ✅ Added: #{file_info[:name]}"
end

# Save
project.save

puts ""
puts "=" * 60
puts "✅ Design System files added correctly!"
puts "=" * 60
puts ""
puts "Now try building: xcodebuild -scheme CurrencyConverter -project CurrencyConverter.xcodeproj build"
