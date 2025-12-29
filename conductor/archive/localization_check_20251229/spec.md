# Specification: Localization Audit and Verification

## 1. Overview
This track focuses on ensuring the quality and completeness of the application's localization. The goal is to verify that all user-facing text is correctly localized for English, Simplified Chinese, and Traditional Chinese using static analysis and code auditing techniques.

## 2. Scope
*   **Target Languages:**
    *   English (en)
    *   Simplified Chinese (zh-Hans)
    *   Traditional Chinese (zh-Hant)
*   **Target Files:** All `.swift` source files within the `CCSwitch` target, specifically focusing on Views and ViewModels.
*   **Exclusions:** Logging messages, internal error identifiers, and non-user-facing constants.

## 3. Objectives
1.  **Identify Hardcoded Strings:** Detect any user-facing strings in UI components that are not using the localization system.
2.  **Verify Key Completeness:** Ensure every key defined in `LocalizationKey.swift` (or used in code) has a corresponding entry in all three `Localizable.strings` files.
3.  **Standardize Usage:** Ensure consistent use of the project's localization pattern (likely `LocalizationKey`).

## 4. Methodology
*   **Code Audit:** Use search tools (grep/ripgrep) to identify string literals in `View` bodies.
*   **Key Verification:** Cross-reference keys between the code and the `.strings` files to identify missing translations.

## 5. Acceptance Criteria
*   [ ] A report is generated or a check is performed listing any potential hardcoded UI strings.
*   [ ] All valid keys in `LocalizationKey.swift` exist in `en`, `zh-Hans`, and `zh-Hant` string files.
*   [ ] Any missing translations identified during the audit are added (or marked for future addition if translation is unavailable).
