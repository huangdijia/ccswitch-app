# Specification: iCloud Configuration Sync

## Overview
Implement iCloud synchronization for CCSwitch to allow users to sync their configurations and settings across multiple macOS devices. This includes the ability to enable/disable sync and choose specific items to synchronize.

## Functional Requirements
- **Toggle iCloud Sync:** Provide a global setting in the "Advanced" or "General" settings view to enable or disable iCloud synchronization.
- **Granular Sync Selection:** Allow users to select which specific configuration items (e.g., specific vendors, app preferences) should be included in the sync.
- **Sync Triggers:**
    - **Automatic:** Sync changes automatically in the background whenever a local change is made or a remote update is detected.
    - **Manual:** Provide a "Sync Now" button in the settings for immediate synchronization.
- **Conflict Resolution:** If a conflict is detected between local and cloud data, prompt the user with a UI to choose which version to keep (Local vs. iCloud).
- **Status Indication:** Show the current sync status (e.g., "Synced", "Syncing...", "Error") in the settings view.

## Non-Functional Requirements
- **Security:** Ensure that sensitive data (like API keys) is handled securely using iCloud's encrypted storage (CloudKit or iCloud Key-Value Store with appropriate protections).
- **Performance:** Sync operations should be non-blocking and not impact the responsiveness of the menu bar app.
- **Reliability:** Handle network errors gracefully and retry synchronization when a connection is restored.

## Acceptance Criteria
- [ ] User can enable/disable iCloud sync in Settings.
- [ ] User can select which vendors/settings to sync.
- [ ] Changes made on one device appear on another device automatically.
- [ ] "Sync Now" button successfully triggers an immediate sync.
- [ ] Conflict resolution dialog appears correctly and respects user choice.
- [ ] App remains functional when offline.

## Out of Scope
- Synchronization with non-macOS platforms (iOS, etc.).
- Real-time collaborative editing (multi-user sync).
