# Specification: Advanced Media Previews & Window Management

## Track ID
`advanced-previews-windowing_20260520`

## Overview
This track enhances the application with advanced content preview capabilities and improved window management. Specifically, it introduces native PDF rendering via PDFKit, robust support for cropped image data detection and labeling across all popular formats (PNG, JPG, TIFF), and enforces strict Z-Order for the Settings window relative to the main history panel.

## Functional Requirements

### 1. Z-Order Enforcement (Settings Window)
- **Relationship**: The Settings window must be established as a **child window** of the main `HistoryPanel`.
- **Behavior**: When the Settings window is open, it must always remain positioned relative to and on top of the history panel. Closing the history panel should ideally hide/close the settings window if it's a child.

### 2. Advanced Image & Cropped Data Support
- **Detection**: Improve the `ContentTypeDetector` to distinguish between a full image file reference and raw image data (e.g., from a crop tool or screenshot).
- **Labeling**: In the `EntryRowView`, cropped image data should be specifically labeled (e.g., "Cropped Image") to distinguish it from file-based images.
- **Formats**: Support must extend to all popular image formats: PNG, JPG, TIFF, etc.

### 3. Native PDF Previews
- **History List**: Display a high-quality thumbnail of the **first page** of the PDF in the `EntryRowView`.
- **Detailed Entry View**:
    - Implement a full-featured `PDFView` (from PDFKit) within the `DetailedEntryView`.
    - **Features**: Enable multi-page scrolling, interactive zooming, text selection/copying, and a thumbnail sidebar for rapid navigation.

## Non-Functional Requirements
- **Performance**: PDF thumbnail generation in the list view must be asynchronous and cached to avoid scrolling stutters.
- **Privacy**: PDF content is subject to the same encryption-at-rest and on-demand decryption rules as all other clipboard data.

## Acceptance Criteria
1. Clicking Settings opens a window that remains pinned on top of the ClipVault history panel.
2. Cropped images are detected, labeled uniquely in the list, and render successfully in both views.
3. PDF entries show a first-page preview in the history list.
4. Double-clicking a PDF opens a detailed view with scroll, zoom, text selection, and thumbnails sidebar.
5. All new features achieve ≥95% test coverage.

## Out of Scope
- PDF editing (annotation, signing).
- Cropping images within ClipVault (only previewing external crops).
