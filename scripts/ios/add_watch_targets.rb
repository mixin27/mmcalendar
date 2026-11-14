#!/usr/bin/env ruby
# frozen_string_literal: true

# Adds the Apple Watch app and its complications to Runner.xcodeproj.
#
#   ruby scripts/ios/add_watch_targets.rb
#
# Run once; it stops if the watch targets already exist. Needs the
# `xcodeproj` gem (it comes with CocoaPods).
#
# What it sets up:
# - WidgetShared/: Swift shared by the iPhone widgets, the watch app and the
#   complications (the payload, styles and moon), as a synchronized folder.
# - MyanmarCalendarWatch: the SwiftUI watchOS app
#   (dev.mixin27.mmcalendar.watchkitapp), embedded in Runner.
# - MyanmarCalendarWatchWidgetsExtension: the complications
#   (dev.mixin27.mmcalendar.watchkitapp.widgets), embedded in the watch app.
# - Runner/WatchSync.swift in the Runner target.

require 'xcodeproj'

IOS_DIR = File.expand_path('../../apps/myanmar_calendar/ios', __dir__)
PROJECT_PATH = File.join(IOS_DIR, 'Runner.xcodeproj')
WATCHOS = '10.0'
TEAM = 'J3T5Q8M599'
APP_ID = 'dev.mixin27.mmcalendar'
WATCH_APP_ID = "#{APP_ID}.watchkitapp"
WATCH_WIDGETS_ID = "#{WATCH_APP_ID}.widgets"

project = Xcodeproj::Project.open(PROJECT_PATH)
targets = project.targets.to_h { |t| [t.name, t] }
abort 'The watch targets are already in the project.' if targets.key?('MyanmarCalendarWatch')

runner = targets.fetch('Runner')
phone_widgets = targets.fetch('MyanmarCalendarWidgetsExtension')

# Flutter's xcconfigs, by configuration name, as the iPhone widgets use them.
base_configs = phone_widgets.build_configurations.to_h { |c| [c.name, c.base_configuration_reference] }

def synced_group(project, path, excluded: [], target: nil)
  group = project.new(Xcodeproj::Project::Object::PBXFileSystemSynchronizedRootGroup)
  group.path = path
  group.source_tree = '<group>'
  project.main_group.children << group
  unless excluded.empty?
    exception = project.new(Xcodeproj::Project::Object::PBXFileSystemSynchronizedBuildFileExceptionSet)
    exception.target = target
    exception.membership_exceptions = excluded
    group.exceptions << exception
  end
  group
end

def common_settings(bundle_id, entitlements, profile)
  {
    'PRODUCT_NAME' => '$(TARGET_NAME)',
    'PRODUCT_BUNDLE_IDENTIFIER' => bundle_id,
    'SDKROOT' => 'watchos',
    # Flutter's project-level Release and Profile say iphoneos; without
    # this an archive builds the watch targets for iOS.
    'SUPPORTED_PLATFORMS' => 'watchos watchsimulator',
    'TARGETED_DEVICE_FAMILY' => '4',
    'WATCHOS_DEPLOYMENT_TARGET' => WATCHOS,
    'SWIFT_VERSION' => '5.0',
    'SWIFT_EMIT_LOC_STRINGS' => 'YES',
    'GENERATE_INFOPLIST_FILE' => 'YES',
    'INFOPLIST_KEY_CFBundleDisplayName' => 'Myanmar Calendar',
    'MARKETING_VERSION' => '$(FLUTTER_BUILD_NAME)',
    'CURRENT_PROJECT_VERSION' => '$(FLUTTER_BUILD_NUMBER)',
    'CODE_SIGN_ENTITLEMENTS' => entitlements,
    'CODE_SIGN_STYLE' => 'Manual',
    'DEVELOPMENT_TEAM' => '',
    'DEVELOPMENT_TEAM[sdk=watchos*]' => TEAM,
    'CODE_SIGN_IDENTITY[sdk=watchos*]' => 'iPhone Distribution',
    'PROVISIONING_PROFILE_SPECIFIER' => '',
    'PROVISIONING_PROFILE_SPECIFIER[sdk=watchos*]' => profile,
    'SKIP_INSTALL' => 'YES',
    'ENABLE_USER_SCRIPT_SANDBOXING' => 'YES',
    'LOCALIZATION_PREFERS_STRING_CATALOGS' => 'NO',
  }
end

def new_watch_target(project, name, type, settings, base_configs)
  target = project.new_target(type, name, :watchos, WATCHOS)
  # new_target makes Debug and Release; add the project's others (Profile).
  project.build_configurations.map(&:name).each do |config_name|
    next if target.build_configurations.any? { |c| c.name == config_name }

    release = target.build_configurations.find { |c| c.name == 'Release' }
    copy = target.add_build_configuration(config_name, :release)
    copy.build_settings = release.build_settings.dup
  end
  target.build_configurations.each do |config|
    config.base_configuration_reference = base_configs[config.name]
    config.build_settings.merge!(settings)
    if config.name == 'Debug'
      config.build_settings['SWIFT_OPTIMIZATION_LEVEL'] = '-Onone'
      config.build_settings['SWIFT_ACTIVE_COMPILATION_CONDITIONS'] = 'DEBUG $(inherited)'
    end
  end
  target
end

def embed(host, product, name, subfolder, path = '')
  phase = host.copy_files_build_phases.find { |p| p.name == name } ||
          host.new_copy_files_build_phase(name)
  phase.symbol_dst_subfolder_spec = subfolder
  phase.dst_path = path
  file = phase.add_file_reference(product, true)
  file.settings = { 'ATTRIBUTES' => ['RemoveHeadersOnCopy'] }
  phase
end

# Shared Swift: moved out of MyanmarCalendarWidgets, so the iPhone widgets
# use it from here too.
shared = synced_group(project, 'WidgetShared')
phone_widgets.file_system_synchronized_groups << shared

# The watch app.
watch_app = new_watch_target(
  project, 'MyanmarCalendarWatch', :application,
  common_settings(WATCH_APP_ID, 'MyanmarCalendarWatch/MyanmarCalendarWatch.entitlements',
                  'Myanmar Calendar WatchApp Production Profile').merge(
    'ASSETCATALOG_COMPILER_APPICON_NAME' => 'AppIcon',
    'INFOPLIST_KEY_WKCompanionAppBundleIdentifier' => APP_ID,
    'INFOPLIST_KEY_WKRunsIndependentlyOfCompanionApp' => 'NO',
    'INFOPLIST_KEY_UISupportedInterfaceOrientations' => 'UIInterfaceOrientationPortrait UIInterfaceOrientationPortraitUpsideDown',
    'LD_RUNPATH_SEARCH_PATHS' => ['$(inherited)', '@executable_path/Frameworks'],
  ),
  base_configs,
)
watch_group = synced_group(project, 'MyanmarCalendarWatch')
watch_app.file_system_synchronized_groups << watch_group
watch_app.file_system_synchronized_groups << shared

# The complications.
watch_widgets = new_watch_target(
  project, 'MyanmarCalendarWatchWidgetsExtension', :app_extension,
  common_settings(WATCH_WIDGETS_ID,
                  'MyanmarCalendarWatchWidgets/MyanmarCalendarWatchWidgets.entitlements',
                  'Myanmar Calendar WatchApp Widgets Profile').merge(
    'INFOPLIST_FILE' => 'MyanmarCalendarWatchWidgets/Info.plist',
    'LD_RUNPATH_SEARCH_PATHS' => ['$(inherited)', '@executable_path/Frameworks',
                                  '@executable_path/../../Frameworks'],
  ),
  base_configs,
)
widgets_group = synced_group(project, 'MyanmarCalendarWatchWidgets',
                             excluded: ['Info.plist'], target: watch_widgets)
watch_widgets.file_system_synchronized_groups << widgets_group
watch_widgets.file_system_synchronized_groups << shared

# Complications inside the watch app; the watch app inside the iPhone app.
watch_app.add_dependency(watch_widgets)
embed(watch_app, watch_widgets.product_reference, 'Embed Foundation Extensions', :plug_ins)
runner.add_dependency(watch_app)
watch_phase = embed(runner, watch_app.product_reference, 'Embed Watch Content',
                    :products_directory, '$(CONTENTS_FOLDER_PATH)/Watch')
# Keep Flutter's "Thin Binary" last, as for the iPhone widgets.
runner.build_phases.delete(watch_phase)
thin = runner.build_phases.index { |p| p.display_name == 'Thin Binary' }
runner.build_phases.insert(thin, watch_phase)

# The iPhone side of WatchConnectivity.
runner_group = project.main_group.children.find { |g| g.display_name == 'Runner' }
runner.add_file_references([runner_group.new_file('WatchSync.swift')])

# Unit tests for the watch app, hosted by it.
watch_tests = new_watch_target(
  project, 'MyanmarCalendarWatchTests', :unit_test_bundle,
  {
    'PRODUCT_NAME' => '$(TARGET_NAME)',
    'PRODUCT_BUNDLE_IDENTIFIER' => "#{WATCH_APP_ID}.tests",
    'SDKROOT' => 'watchos',
    # Flutter's project-level Release and Profile say iphoneos; without
    # this an archive builds the watch targets for iOS.
    'SUPPORTED_PLATFORMS' => 'watchos watchsimulator',
    'TARGETED_DEVICE_FAMILY' => '4',
    'WATCHOS_DEPLOYMENT_TARGET' => WATCHOS,
    'SWIFT_VERSION' => '5.0',
    'GENERATE_INFOPLIST_FILE' => 'YES',
    'CODE_SIGN_STYLE' => 'Automatic',
    'TEST_HOST' => '$(BUILT_PRODUCTS_DIR)/MyanmarCalendarWatch.app/MyanmarCalendarWatch',
    'BUNDLE_LOADER' => '$(TEST_HOST)',
  },
  base_configs,
)
tests_group = synced_group(project, 'MyanmarCalendarWatchTests')
watch_tests.file_system_synchronized_groups << tests_group
watch_tests.add_dependency(watch_app)

project.save

# A shared scheme to build, run and test the watch app on its own.
scheme = Xcodeproj::XCScheme.new
scheme.add_build_target(watch_app)
scheme.add_test_target(watch_tests)
scheme.set_launch_target(watch_app)
scheme.save_as(PROJECT_PATH, 'MyanmarCalendarWatch', true)

puts 'Added MyanmarCalendarWatch, its complications, tests and scheme.'
