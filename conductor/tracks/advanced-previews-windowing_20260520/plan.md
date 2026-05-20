# Implementation Plan: Advanced Media Previews & Window Management

## Phase 1: Window Management & Infrastructure

- [x] Task: Implement Child Window Relationship for Settings
    - [x] Update `MenuBarController` to set `settingsWindow` as a child of the main `panel`.
    - [x] Handle Z-order logic to ensure Settings remains on top.
    - [x] Write integration test verifying window hierarchy and visibility.
    - [x] Commit: `feat(ui): Enforce Settings window as child of history panel`

- [x] Task: Conductor - User Manual Verification 'Phase 1' (Protocol in workflow.md)

## Phase 2: Advanced Content Detection & Labeling

- [x] Task: Enhanced Image & Cropped Data Detection
    - [x] Update `ClipboardContentType` enum to include a specific case for `.croppedImage` if necessary, or refine `.image` logic.
    - [x] Update `ContentTypeDetector` to distinguish raw image data from file URLs.
    - [x] Update `EntryRowView` to display a "Cropped" badge for raw image data.
    - [x] Write unit tests for various image formats (PNG, JPG, TIFF) and detection scenarios.
    - [x] Commit: `feat(clipboard): Improve cropped image detection and labeling`

- [x] Task: Conductor - User Manual Verification 'Phase 2' (Protocol in workflow.md)

## Phase 3: Native PDF Integration

- [x] Task: PDF Detection and Thumbnail Generation
    - [x] Add `.pdf` content type detection to `ContentTypeDetector`.
    - [x] Implement asynchronous PDF thumbnail generation for the first page.
    - [x] Update `ThumbnailCache` to support caching PDF thumbnails.
    - [x] Write unit tests for PDF detection and rendering logic.
    - [x] Commit: `feat(clipboard): Add PDF detection and list-view thumbnails`

- [x] Task: Implement Advanced PDF Detailed View
    - [x] Create `PDFPreview` SwiftUI view using `PDFView` via `NSViewRepresentable`.
    - [x] Enable zoom, text selection, and thumbnails sidebar in `PDFView`.
    - [x] Integrate `PDFPreview` into `DetailedEntryView`.
    - [x] Write UI tests for PDF interaction (scrolling, zooming).
    - [x] Commit: `feat(ui): Implement full PDFKit viewer in detailed view`

- [x] Task: Conductor - User Manual Verification 'Phase 3' (Protocol in workflow.md)

## Phase 4: Final Polish & Optimization

- [x] Task: Performance and UX Optimization
    - [x] Audit memory usage during PDF/Image-heavy history browsing.
    - [x] Ensure smooth scrolling in the history panel with PDF thumbnails.
    - [x] Commit: `perf(ui): Optimize PDF/Image rendering and memory usage`

- [ ] Task: Conductor - User Manual Verification 'Phase 4' (Protocol in workflow.md)
