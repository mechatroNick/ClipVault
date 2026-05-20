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

- [ ] Task: Conductor - User Manual Verification 'Phase 2' (Protocol in workflow.md)

## Phase 3: Native PDF Integration

- [ ] Task: PDF Detection and Thumbnail Generation
    - [ ] Add `.pdf` content type detection to `ContentTypeDetector`.
    - [ ] Implement asynchronous PDF thumbnail generation for the first page.
    - [ ] Update `ThumbnailCache` to support caching PDF thumbnails.
    - [ ] Write unit tests for PDF detection and rendering logic.
    - [ ] Commit: `feat(clipboard): Add PDF detection and list-view thumbnails`

- [ ] Task: Implement Advanced PDF Detailed View
    - [ ] Create `PDFPreview` SwiftUI view using `PDFView` via `NSViewRepresentable`.
    - [ ] Enable zoom, text selection, and thumbnails sidebar in `PDFView`.
    - [ ] Integrate `PDFPreview` into `DetailedEntryView`.
    - [ ] Write UI tests for PDF interaction (scrolling, zooming).
    - [ ] Commit: `feat(ui): Implement full PDFKit viewer in detailed view`

- [ ] Task: Conductor - User Manual Verification 'Phase 3' (Protocol in workflow.md)

## Phase 4: Final Polish & Optimization

- [ ] Task: Performance and UX Optimization
    - [ ] Audit memory usage during PDF/Image-heavy history browsing.
    - [ ] Ensure smooth scrolling in the history panel with PDF thumbnails.
    - [ ] Commit: `perf(ui): Optimize PDF/Image rendering and memory usage`

- [ ] Task: Conductor - User Manual Verification 'Phase 4' (Protocol in workflow.md)
