#!/usr/bin/env ruby
require 'xcodeproj'

project_path = 'CurrencyConverter.xcodeproj'
project = Xcodeproj::Project.open(project_path)

# Get the main target
main_target = project.targets.find { |t| t.name == 'CurrencyConverter' }
main_group = project.main_group['CurrencyConverter']

puts "Adding Design System files..."

# Create groups WITHOUT setting a path (they'll inherit from parent)
design_system_group = main_group.new_group('DesignSystem')
tokens_group = design_system_group.new_group('Tokens')
extensions_group = design_system_group.new_group('Extensions')
modifiers_group = design_system_group.new_group('ViewModifiers')
components_group = design_system_group.new_group('Components')

# Files - use absolute paths from project root
files_to_add = [
  {group: tokens_group, path: 'CurrencyConverter/DesignSystem/Tokens/OceanColors.swift'},
  {group: tokens_group, path: 'CurrencyConverter/DesignSystem/Tokens/OceanSpacing.swift'},
  {group: tokens_group, path: 'CurrencyConverter/DesignSystem/Tokens/OceanRadius.swift'},
  {group: tokens_group, path: 'CurrencyConverter/DesignSystem/Tokens/OceanShadows.swift'},
  {group: tokens_group, path: 'CurrencyConverter/DesignSystem/Tokens/OceanBlur.swift'},
  {group: extensions_group, path: 'CurrencyConverter/DesignSystem/Extensions/Color+Ocean.swift'},
  {group: modifiers_group, path: 'CurrencyConverter/DesignSystem/ViewModifiers/GlassmorphismModifier.swift'},
  {group: modifiers_group, path: 'CurrencyConverter/DesignSystem/ViewModifiers/OceanGradientModifier.swift'},
  {group: modifiers_group, path: 'CurrencyConverter/DesignSystem/ViewModifiers/GlassCardModifier.swift'},
  {group: modifiers_group, path: 'CurrencyConverter/DesignSystem/ViewModifiers/FloatingAnimationModifier.swift'},
  {group: components_group, path: 'CurrencyConverter/DesignSystem/Components/OceanButton.swift'},
  {group: components_group, path: 'CurrencyConverter/DesignSystem/Components/GlassCard.swift'}
]

files_to_add.each do |file_info|
  # Check if file exists
  unless File.exist?(file_info[:path])
    puts "  ⚠️  File not found: #{file_info[:path]}"
    next
  end

  # Add file reference using new_file which handles paths correctly
  file_ref = file_info[:group].new_file(file_info[:path])

  # Add to build phase
  main_target.source_build_phase.add_file_reference(file_ref)

  puts "  ✅ Added: #{File.basename(file_info[:path])}"
end

# Save
project.save

puts ""
puts "=" * 60
puts "✅ All files added successfully!"
puts "=" * 60
