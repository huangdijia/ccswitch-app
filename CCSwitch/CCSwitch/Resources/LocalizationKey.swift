import Foundation

/// Centralized localization keys for the CCSwitch application
/// This file provides type-safe access to all localization strings
enum LocalizationKey {
    // MARK: - General

    static let ok = "ok"
    static let cancel = "cancel"
    static let delete = "delete"
    static let save = "save"
    static let done = "done"
    static let edit = "edit"
    static let add = "add"
    static let remove = "remove"
    static let loading = "loading"
    static let error = "error"
    static let warning = "warning"
    static let info = "info"
    static let success = "success"

    // MARK: - Vendor Management

    static let searchVendors = "search_vendors"
    static let favorites = "favorites"
    static let allVendors = "all_vendors"
    static let noVendorSelected = "no_vendor_selected"
    static let noVendorSelectedDesc = "no_vendor_selected_desc"
    static let addVendor = "add_vendor"
    static let addNewVendor = "add_new_vendor"
    static let editVendor = "edit_vendor"
    static let deleteVendor = "delete_vendor"
    static let deleteVendorConfirmation = "delete_vendor_confirmation"
    static let vendorAddedSuccess = "vendor_added_success"
    static let vendorUpdatedSuccess = "vendor_updated_success"
    static let vendorDeletedSuccess = "vendor_deleted_success"
    static let vendorDuplicatedSuccess = "vendor_duplicated_success"
    static let defaultNewVendorName = "default_new_vendor_name"
    static let connectionAndAuth = "connection_and_auth"
    static let networkSettings = "network_settings"
    static let authTokenHint = "auth_token_hint"
    static let testConnectionBtn = "test_connection_btn"
    static let statusSuccess = "status_success"
    static let statusNetworkError = "status_network_error"
    static let statusAuthFailed = "status_auth_failed"
    static let advancedModelMappingDesc = "advanced_model_mapping_desc"

    // MARK: - Vendor Details

    static let basicInfo = "basic_info"
    static let nameLabel = "name_label"
    static let baseURLLabel = "base_url_label"
    static let authSection = "auth_section"
    static let authTokenLabel = "auth_token_label"
    static let authTokenHelper = "auth_token_helper"
    static let modelsSection = "models_section"
    static let defaultModelLabel = "default_model_label"
    static let opusModelLabel = "opus_model_label"
    static let sonnetModelLabel = "sonnet_model_label"
    static let haikuModelLabel = "haiku_model_label"
    static let smallFastModelLabel = "small_fast_model_label"
    static let modelMapping = "model_mapping"
    static let connectionSection = "connection_section"
    static let timeoutLabel = "timeout_label"
    static let testConnection = "test_connection"
    static let connectionSuccess = "connection_success"
    static let connectionFailedSimple = "connection_failed_simple"
    static let connectionErrorStatus = "connection_error_status"

    // MARK: - Vendor Actions

    static let useThisVendor = "use_this_vendor"
    static let usingCurrent = "using_current"
    static let duplicateVendor = "duplicate_vendor"
    static let addToFavorites = "add_to_favorites"
    static let removeFromFavorites = "remove_from_favorites"
    static let addedToFavoritesMsg = "added_to_favorites_msg"
    static let removedFromFavoritesMsg = "removed_from_favorites_msg"
    static let presetLabel = "preset_label"
    static let presetCustom = "preset_custom"
    static let presetAnthropic = "preset_anthropic"
    static let presetOpenAI = "preset_openai"
    static let copyVendor = "copy_vendor"
    static let vendorList = "vendor_list"
    static let setActive = "set_active"
    static let menuBarTooltip = "menu_bar_tooltip"
    static let menuBarTooltipCurrent = "menu_bar_tooltip_current"

    // MARK: - Unsaved Changes

    static let unsavedChanges = "unsaved_changes"
    static let unsavedChangesMsg = "unsaved_changes_msg"
    static let discardChanges = "discard_changes"
    static let keepEditing = "keep_editing"
    static let revert = "revert"
    static let saveChanges = "save_changes"

    // MARK: - Validation

    static let validationNameRequired = "validation_name_required"
    static let validationURLInvalid = "validation_url_invalid"
    static let validationTimeoutRange = "validation_timeout_range"
    static let validationTimeoutNumber = "validation_timeout_number"

    // MARK: - Settings

    static let general = "general"
    static let vendors = "vendors"
    static let advanced = "advanced"

    // MARK: - General Settings

    static let configManagement = "config_management"
    static let autoReloadConfig = "auto_reload_config"
    static let autoReloadConfigDesc = "auto_reload_config_desc"
    static let autoBackup = "auto_backup"
    static let autoBackupDescRefined = "auto_backup_desc_refined"
    static let showBackupFiles = "show_backup_files"
    static let legacyMigrationTitle = "legacy_migration_title"
    static let legacyMigrationDesc = "legacy_migration_desc"
    static let migrateNow = "migrate_now"
    static let notifications = "notifications"
    static let showNotifications = "show_notifications"
    static let showNotificationsDesc = "show_notifications_desc"
    static let notificationPermissionDisabled = "notification_permission_disabled"
    static let openSystemSettings = "open_system_settings"
    static let allowNotifications = "allow_notifications"
    static let softwareUpdate = "software_update"
    static let autoCheckUpdates = "auto_check_updates"
    static let autoCheckUpdatesDesc = "auto_check_updates_desc"
    static let autoInstallUpdates = "auto_install_updates"
    static let autoInstallUpdatesDesc = "auto_install_updates_desc"
    static let checkForUpdatesNow = "check_for_updates_now"
    static let lastCheckedFormat = "last_checked_format"
    static let versionInfo = "version_info"

    // MARK: - Advanced Settings

    static let icloudSettings = "icloud_settings"
    static let icloudSync = "icloud_sync"
    static let icloudSyncDesc = "icloud_sync_desc"
    static let syncStatus = "sync_status"
    static let syncNow = "sync_now"
    static let systemBehavior = "system_behavior"
    static let showDebugLogs = "show_debug_logs"
    static let debugLogsDesc = "debug_logs_desc"
    static let confirmBackupDeletion = "confirm_backup_deletion"
    static let confirmBackupDeletionDesc = "confirm_backup_deletion_desc"
    static let dataMaintenance = "data_maintenance"
    static let backups = "backups"
    static let noBackups = "no_backups"
    static let manageBackups = "manage_backups"
    static let configFile = "config_file"
    static let configFilePath = "config_file_path"
    static let showInFinder = "show_in_finder"
    static let reloadConfig = "reload_config"
    static let reloadSuccessMsg = "reload_success_msg"
    static let dangerZone = "danger_zone"
    static let resetAppAction = "reset_app_action"
    static let resetAppStateWarning = "reset_app_state_warning"
    static let resetAppStateConfirmTitle = "reset_app_state_confirm_title"
    static let resetAppStateConfirmMsg = "reset_app_state_confirm_msg"
    static let resetButton = "reset_button"
    static let resetSuccessMsg = "reset_success_msg"

    // MARK: - Backup Management

    static let confirmRestoreTitle = "confirm_restore_title"
    static let confirmRestoreMsg = "confirm_restore_msg"
    static let restore = "restore"
    static let restoreButton = "restore_button"
    static let restoreSuccessMsg = "restore_success_msg"
    static let backupDeletedSuccess = "backup_deleted_success"

    // MARK: - Migration

    static let migrationTitle = "migration_title"
    static let migrationFoundVendors = "migration_found_vendors"
    static let migrationNote = "migration_note"
    static let migrating = "migrating"
    static let migrationDontShowAgainCheckbox = "migration_dont_show_again_checkbox"
    static let migrateLater = "migrate_later"
    static let migrateNowButton = "migrate_now"
    static let migrationSuccessMsg = "migration_success_msg"
    static let migrationFailureMsg = "migration_failure_msg"

    // MARK: - Sync

    static let syncIdle = "sync_idle"
    static let syncSyncing = "sync_syncing"
    static let syncSuccess = "sync_success"
    static let syncOffline = "sync_offline"
    static let syncError = "sync_error"
    static let syncConflictTitle = "sync_conflict_title"
    static let allConflictsResolved = "all_conflicts_resolved"
    static let localVersion = "local_version"
    static let remoteVersion = "remote_version"
    static let keepLocal = "keep_local"
    static let keepRemote = "keep_remote"
    static let envVarsCount = "env_vars_count"

    // MARK: - Error Messages

    static let errorCannotRemoveCurrentVendor = "error_cannot_remove_current_vendor"
    static let errorCannotRemoveLastVendor = "error_cannot_remove_last_vendor"
    static let errorInvalidVendorName = "error_invalid_vendor_name"
    static let errorInvalidBaseURL = "error_invalid_base_url"
    static let errorInvalidTimeout = "error_invalid_timeout"
    static let errorVendorNotFound = "error_vendor_not_found"
    static let errorVendorAlreadyExists = "error_vendor_already_exists"
    static let errorInvalidConfiguration = "error_invalid_configuration"

    // MARK: - Untitled Vendor

    static let untitledVendor = "untitled_vendor"
    static let copySuffix = "copy_suffix"

    // MARK: - Helper Method

    /// Get localized string for a key
    static func localized(_ key: String) -> String {
        return NSLocalizedString(key, comment: "")
    }

    /// Get localized string for a key with arguments
    static func localized(_ key: String, _ args: CVarArg...) -> String {
        let format = NSLocalizedString(key, comment: "")
        return String(format: format, args)
    }
}
