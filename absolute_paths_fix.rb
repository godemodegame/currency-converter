#!/usr/bin/env ruby
require 'xcodeproj'

project_path = 'CurrencyConverter.xcodeproj'
project = Xcodeproj::Project.open(project_path)

# Get the main target
main_target = project.targets.find { |t| t.name == 'CurrencyConverter' }
main_group = project.main_group['CurrencyConverter']

# Remove existing DesignSystem references
puts "Cleaning up existing references..."
main_target.source_build_phase.files.to_a.each do |build_file|
  file_ref = build_file.file_ref
  if file_ref && file_ref.path && (file_ref.path.include?('DesignSystem') || file_ref.path.include?('Ocean') || file_ref.path.include?('Glass'))
    build_file.remove_from_project
  end
end

if design_group = main_group['DesignSystem']
  design_group.remove_from_project
end

# Create groups
design_system_group = main_group.new_group('DesignSystem')
tokens_group = design_system_group.new_group('Tokens')
extensions_group = design_system_group.new_group('Extensions')
modifiers_group = design_system_group.new_group('ViewModifiers')
components_group = design_system_group.new_group('Components')

# Get absolute project directory
project_dir = File.dirname(File.expand_path(project_path))

# Files with absolute paths
files_to_add = [
  {group: tokens_group, name: 'OceanColors.swift', abs_path: "#{project_dir}/CurrencyConverter/DesignSystem/Tokens/OceanColors.swift"},
  {group: tokens_group, name: 'OceanSpacing.swift', abs_path: "#{project_dir}/CurrencyConverter/DesignSystem/Tokens/OceanSpacing.swift"},
  {group: tokens_group, name: 'OceanRadius.swift', abs_path: "#{project_dir}/CurrencyConverter/DesignSystem/Tokens/OceanRadius.swift"},
  {group: tokens_group, name: 'OceanShadows.swift', abs_path: "#{project_dir}/CurrencyConverter/DesignSystem/Tokens/OceanShadows.swift"},
  {group: tokens_group, name: 'OceanBlur.swift', abs_path: "#{project_dir}/CurrencyConverter/DesignSystem/Tokens/OceanBlur.swift"},
  {group: extensions_group, name: 'Color+Ocean.swift', abs_path: "#{project_dir}/CurrencyConverter/DesignSystem/Extensions/Color+Ocean.swift"},
  {group: modifiers_group, name: 'GlassmorphismModifier.swift', abs_path: "#{project_dir}/CurrencyConverter/DesignSystem/ViewModifiers/GlassmorphismModifier.swift"},
  {group: modifiers_group, name: 'OceanGradientModifier.swift', abs_path: "#{project_dir}/CurrencyConverter/DesignSystem/ViewModifiers/OceanGradientModifier.swift"},
  {group: modifiers_group, name: 'GlassCardModifier.swift', abs_path: "#{project_dir}/CurrencyConverter/DesignSystem/ViewModifiers/GlassCardModifier.swift"},
  {group: modifiers_group, name: 'FloatingAnimationModifier.swift', abs_path: "#{project_dir}/CurrencyConverter/DesignSystem/ViewModifiers/FloatingAnimationModifier.swift"},
  {group: components_group, name: 'OceanButton.swift', abs_path: "#{project_dir}/CurrencyConverter/DesignSystem/Components/OceanButton.swift"},
  {group: components_group, name: 'GlassCard.swift', abs_path: "#{project_dir}/CurrencyConverter/DesignSystem/Components/GlassCard.swift"}
]

puts "\nAdding files with SOURCE_ROOT relative paths..."
files_to_add.each do |file_info|
  unless File.exist?(file_info[:abs_path])
    puts "  ⚠️  File not found: #{file_info[:abs_path]}"
    next
  end

  # Create file reference manually with SOURCE_ROOT relative path
  file_ref = file_info[:group].new_reference(file_info[:name])
  file_ref.path = "CurrencyConverter/DesignSystem/#{file_info[:group].hierarchy_path.split('/').last}/#{file_info[:name]}"
  file_ref.source_tree = 'SOURCE_ROOT'

  # Add to build phase
  main_target.source_build_phase.add_file_reference(file_ref)

  puts "  ✅ Added: #{file_info[:name]} (SOURCE_ROOT relative)"
end

# Save
project.save

puts ""
puts "=" * 60
puts "✅ Files added with SOURCE_ROOT paths!"
puts "=" * 60
