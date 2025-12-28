#!/usr/bin/env ruby
require 'xcodeproj'

project_path = 'CurrencyConverter.xcodeproj'
project = Xcodeproj::Project.open(project_path)

# Get the main target
main_target = project.targets.find { |t| t.name == 'CurrencyConverter' }

# Get the main group
main_group = project.main_group['CurrencyConverter']

# Create DesignSystem group if it doesn't exist
design_system_group = main_group['DesignSystem'] || main_group.new_group('DesignSystem')

# Create subgroups
tokens_group = design_system_group['Tokens'] || design_system_group.new_group('Tokens')
extensions_group = design_system_group['Extensions'] || design_system_group.new_group('Extensions')
modifiers_group = design_system_group['ViewModifiers'] || design_system_group.new_group('ViewModifiers')
components_group = design_system_group['Components'] || design_system_group.new_group('Components')

# Files to add
files = {
  tokens_group => [
    'CurrencyConverter/DesignSystem/Tokens/OceanColors.swift',
    'CurrencyConverter/DesignSystem/Tokens/OceanSpacing.swift',
    'CurrencyConverter/DesignSystem/Tokens/OceanRadius.swift',
    'CurrencyConverter/DesignSystem/Tokens/OceanShadows.swift',
    'CurrencyConverter/DesignSystem/Tokens/OceanBlur.swift'
  ],
  extensions_group => [
    'CurrencyConverter/DesignSystem/Extensions/Color+Ocean.swift'
  ],
  modifiers_group => [
    'CurrencyConverter/DesignSystem/ViewModifiers/GlassmorphismModifier.swift',
    'CurrencyConverter/DesignSystem/ViewModifiers/OceanGradientModifier.swift',
    'CurrencyConverter/DesignSystem/ViewModifiers/GlassCardModifier.swift',
    'CurrencyConverter/DesignSystem/ViewModifiers/FloatingAnimationModifier.swift'
  ],
  components_group => [
    'CurrencyConverter/DesignSystem/Components/OceanButton.swift',
    'CurrencyConverter/DesignSystem/Components/GlassCard.swift'
  ]
}

# Add files to project
files.each do |group, file_paths|
  file_paths.each do |file_path|
    # Check if file exists
    unless File.exist?(file_path)
      puts "⚠️  File not found: #{file_path}"
      next
    end

    # Check if file is already in the project
    if group.files.any? { |f| f.path == File.basename(file_path) }
      puts "⏭️  Already added: #{file_path}"
      next
    end

    # Add file reference
    file_ref = group.new_file(file_path)

    # Add to build phase
    main_target.source_build_phase.add_file_reference(file_ref)

    puts "✅ Added: #{file_path}"
  end
end

# Save the project
project.save

puts ""
puts "=" * 60
puts "✅ All files successfully added to Xcode project!"
puts "=" * 60
puts ""
puts "Next steps:"
puts "1. Close and reopen Xcode (if open)"
puts "2. Clean build folder: Cmd+Shift+K"
puts "3. Build the project: Cmd+B"
