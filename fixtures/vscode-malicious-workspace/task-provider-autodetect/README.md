# task-provider-autodetect fixture

Benign marker fixture for validating built-in npm/gulp task-provider discovery boundaries.
Open with a clean VS Code profile and do not trust the workspace initially; marker files should remain absent before explicit trust/task listing.
If `gulp.autoDetect` is enabled at application scope and tasks are listed after trust, the fake local gulp shim writes `GULP_AUTODETECT_MARKER.txt`.
