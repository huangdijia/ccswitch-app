# Implementation Plan: iCloud Configuration Sync

## Phase 1: Foundation & Data Layer [checkpoint: 0fd041d]
- [x] Task: Define `SyncConfiguration` model to track which items are synced [7cd8b46]
    - [x] Write unit tests for `SyncConfiguration` serialization
    - [x] Implement `SyncConfiguration` model
- [x] Task: Implement `ICloudStorageService` using `NSUbiquitousKeyValueStore` or `CloudKit` [f0ebe31]
    - [x] Write tests for `ICloudStorageService` (mocking iCloud)
    - [x] Implement basic CRUD operations for cloud storage
- [x] Task: Conductor - User Manual Verification 'Phase 1: Foundation & Data Layer' (Protocol in workflow.md)

## Phase 2: Sync Engine Logic [checkpoint: 9e4450c]
- [x] Task: Implement `SyncManager` to handle background and manual triggers [6c227d3]
    - [x] Write tests for `SyncManager` coordination
    - [x] Implement change detection and automatic upload/download
- [x] Task: Implement Conflict Detection and Resolution logic [2b4f86d]
    - [x] Write tests for various conflict scenarios (Local vs Remote)
    - [x] Implement detection mechanism and resolution callback
- [x] Task: Integrate `SyncManager` with `ConfigManager` [8a805be]
    - [x] Write integration tests for configuration syncing
    - [x] Update `ConfigManager` to trigger sync on changes
- [x] Task: Conductor - User Manual Verification 'Phase 2: Sync Engine Logic' (Protocol in workflow.md)

## Phase 3: UI Implementation [checkpoint: e87890b]
- [x] Task: Update `GeneralSettingsView` or `AdvancedSettingsView` with iCloud controls [43c8779]
    - [x] Add iCloud Sync toggle switch
    - [x] Add "Sync Now" button and status indicator
- [x] Task: Implement Granular Sync Selection UI [a551aaa]
    - [x] Create view for selecting which vendors/settings to sync
    - [x] Bind UI to `SyncConfiguration`
- [x] Task: Implement Conflict Resolution Dialog [3246243]
    - [x] Create a modal or sheet to prompt user on conflict
    - [x] Implement "Keep Local" and "Keep iCloud" actions
- [x] Task: Conductor - User Manual Verification 'Phase 3: UI Implementation' (Protocol in workflow.md)

## Phase 4: Error Handling & Polishing [checkpoint: e59496e]
- [x] Task: Implement network reachability and retry logic [214f9a2]
    - [x] Write tests for offline/online transitions
    - [x] Implement exponential backoff for retries
- [x] Task: Final end-to-end verification and performance check
    - [x] Verify sync performance with large configuration sets
    - [x] Ensure non-blocking operations on main thread
- [x] Task: Conductor - User Manual Verification 'Phase 4: Error Handling & Polishing' (Protocol in workflow.md)
