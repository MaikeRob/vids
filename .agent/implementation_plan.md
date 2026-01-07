---
description: Debug and fix video quality selection feature
---

# Debug & Fix Video Quality Selection

The user reports the feature is not visible ("application stays the same"). We need to ensure:
1.  The backend correctly extracts available video qualities.
2.  The frontend receives this list.
3.  The frontend renders the selection UI logic correctly.

## Steps

1.  **Backend Logic Robustness**: 
    - [x] Update `ytdlp_service.py` extraction logic to be more inclusive.
    - [x] Add logging to verify what formats are being seen.
2.  **Frontend Verification**:
    - [ ] Update `QualitySelector` or `HomePage` with a visible label change (e.g., "Selecione a Qualidade") to confirm code update.
    - [ ] Verify `DownloadNotifier` parses the JSON correctly.
3.  **Validation**:
    - [ ] Build and Run to verify fixes.
