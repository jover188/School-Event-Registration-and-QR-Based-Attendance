# Implementation Plan: Functional Report Export Downloads (CSV, XLSX, PDF)

**Date:** 2026-11-15  
**Feature:** Make Export CSV, Export XLSX, and Export PDF functional with automatic file downloads in Attendify.  
**Branch:** `main` (no commits or pushes without explicit user approval).

---

## 1. Problem Statement & User Requirements

The Attendify reports screen (`mobile/lib/screens/common/reports_screen.dart`) features three export buttons in `_ReportExportButtonsCard`:
- **Export CSV** (`.csv`)
- **Export XLSX** (`.xlsx`)
- **Export PDF** (`.pdf`)

Currently, clicking these buttons calls `ApiClient().downloadBytes(...)` but then shows a static preview `AlertDialog` (`_showExportPreviewDialog`) containing truncated text or file size, rather than actually saving or downloading the file to the user's browser or device.

### User Requirements:
1. **Export CSV:** Generate and download the report as a `.csv` file.
2. **Export XLSX:** Generate and download the report as an `.xlsx` file.
3. **Export PDF:** Generate and download the report as a `.pdf` file.
4. **Actual Report Data:** Use real report data belonging to the selected report and active filters (`date_from`, `date_to`, `event_id`, `student_id`, `department`, `year_level`). Never use dummy, sample, or hardcoded data.
5. **Direct Download:** Trigger automatic browser/device download upon clicking. Do not just display a preview dialog.
6. **Empty Data Guard:** If no report data is available for the current selection, show an appropriate feedback message instead of downloading an empty or misleading file.
7. **UI & Loading States:**
   - Keep the existing UI layout, typography, buttons, and styling exactly as they are.
   - Show a loading indicator on the active button while generating/downloading.
   - Disable export buttons to prevent duplicate requests while processing.
   - Show a success toast when download initiates, or clear error message if it fails.
8. **Minimal & Clean:** Zero unnecessary dependencies, reusable existing endpoints, no regressions in unrelated features.

---

## 2. Architecture & File Structure

```
mobile/lib/
├── core/
│   └── utils/
│       ├── file_downloader.dart         # Cross-platform interface & FileDownloadResult
│       ├── file_downloader_web.dart     # Web implementation using Blob & HTML anchor click
│       └── file_downloader_stub.dart    # IO / Android implementation saving to Downloads / systemTemp
└── screens/
    └── common/
        └── reports_screen.dart          # Hook file_downloader, loading state per button, empty guard
mobile/test/
└── screens/
    ├── reports_layout_test.dart         # Existing tests verifying 7 report types and layout
    └── report_export_download_test.dart # New unit/widget tests verifying export button interactions
```

---

## 3. Subagent Task Breakdown

Following the `subagent-driven-development` and `dispatching-parallel-agents` workflow:

### **Task 1: Cross-Platform File Downloader Utility**
- **Files:**
  - `mobile/lib/core/utils/file_downloader.dart`
  - `mobile/lib/core/utils/file_downloader_web.dart`
  - `mobile/lib/core/utils/file_downloader_stub.dart`
- **Owner:** Subagent `file-downloader-specialist`
- **Implementation:**
  - `file_downloader.dart`:
    - Defines `FileDownloadResult(success, savedPath, errorMessage)`.
    - Conditional import:
      `import 'file_downloader_stub.dart' if (dart.library.html) 'file_downloader_web.dart' as platform;`
    - Exports `Future<FileDownloadResult> downloadFile({required List<int> bytes, required String filename, required String mimeType})`.
  - `file_downloader_web.dart`:
    - Creates `html.Blob([bytes], mimeType)`.
    - Creates `html.Url.createObjectUrlFromBlob(blob)`.
    - Injects hidden `html.AnchorElement` with `download` attribute and triggers `anchor.click()`.
    - Revokes object URL cleanly.
  - `file_downloader_stub.dart`:
    - On Android, checks `/storage/emulated/0/Download` or falls back to `Directory.systemTemp`.
    - Writes `bytes` via `File.writeAsBytes(bytes)`.

---

### **Task 2: ReportsScreen Integration & UI State Handling**
- **Files:**
  - `mobile/lib/screens/common/reports_screen.dart`
- **Owner:** Subagent `reports-ui-integration-specialist`
- **Implementation:**
  - Replace `_isExporting` with `String? _exportingFormat` (e.g. `'csv'`, `'xlsx'`, `'pdf'`).
  - Add helper `bool get _hasAvailableReportData` to inspect `_reportPayload` for non-empty records.
  - In `_exportReportFormat(String format)`:
    - Validate parameters (`needsEvent`, `needsStudent`).
    - Verify `_reportPayload != null && _hasAvailableReportData`. If empty or not generated, show:
      `AppToast.error(context, 'No report data available to export. Please generate a report with valid records first.');`
    - Construct descriptive filename:
      `attendify_${_selectedReportType}_${DateTime.now().toIso8601String().split('T')[0]}.$format`
    - Send API request via `ApiClient().downloadBytes(...)`.
    - On success: invoke `await downloadFile(...)` and show `AppToast.success(...)`. Remove `_showExportPreviewDialog`.
    - On error: show `AppToast.error(...)`.
  - In `_ReportExportButtonsCard`:
    - Pass `exportingFormat: _exportingFormat`.
    - Update `AppButton` widgets with:
      `isLoading: exportingFormat == 'csv'`, `onPressed: exportingFormat != null ? null : onExportCsv`, etc.
    - Preserve exact layout, icons, pill styling, and button labels (`Export CSV`, `Export XLSX`, `Export PDF`).

---

### **Task 3: Automated Verification & Testing**
- **Files:**
  - `mobile/test/screens/report_export_download_test.dart`
  - `backend/tests/Feature/ReportExportTest.php`
- **Owner:** Subagent `test-verification-specialist`
- **Implementation:**
  - Write widget tests in `report_export_download_test.dart`:
    - Test CSV button triggers download when payload exists.
    - Test XLSX button triggers download when payload exists.
    - Test PDF button triggers download when payload exists.
    - Test empty payload triggers error toast and prevents API download call.
    - Test button loading state disables other buttons during export.
  - Run `flutter analyze` and `flutter test`.
  - Run `php artisan test --filter=ReportExportTest`.

---

## 4. Verification Checklist & Gate
- [ ] No external dependencies added to `pubspec.yaml` or `composer.json`.
- [ ] CSV download functional with descriptive filename (`attendify_*_YYYY-MM-DD.csv`).
- [ ] XLSX download functional with descriptive filename (`attendify_*_YYYY-MM-DD.xlsx`).
- [ ] PDF download functional with descriptive filename (`attendify_*_YYYY-MM-DD.pdf`).
- [ ] Active filters (`event_id`, `student_id`, `department`, `year_level`, `date_from`, `date_to`) passed accurately to backend.
- [ ] Button loading spinners display during processing, preventing duplicate clicks.
- [ ] Empty report guard shows informative feedback toast.
- [ ] All Flutter and Backend tests green.
- [ ] Do NOT commit or push without user's explicit approval.
