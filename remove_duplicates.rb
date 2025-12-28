#!/usr/bin/env ruby
require 'xcodeproj'

project_path = 'CurrencyConverter.xcodeproj'
project = Xcodeproj::Project.open(project_path)

# Get the main target
main_target = project.targets.find { |t| t.name == 'CurrencyConverter' }

# Find duplicates in build phase
file_names = {}
duplicates = []

main_target.source_build_phase.files.each do |build_file|
  file_ref = build_file.file_ref
  next unless file_ref && file_ref.display_name

  name = file_ref.display_name

  if file_names[name]
    puts "Found duplicate: #{name}"
    duplicates << build_file
  else
    file_names[name] = build_file
  end
end

# Remove duplicates
duplicates.each do |build_file|
  puts "Removing duplicate build file: #{build_file.file_ref.display_name}"
  build_file.remove_from_project
end

# Save
project.save

puts ""
puts "=" * 60
puts "✅ Removed #{duplicates.count} duplicate file(s)"
puts "=" * 60
