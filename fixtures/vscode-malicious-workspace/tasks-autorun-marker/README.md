# Benign automatic-task marker fixture

This fixture models a malicious-repository primitive without destructive behavior. If VS Code runs the `benign-marker-on-folder-open` task, it writes `autorun-task-marker.txt` in this directory.

Expected safe behavior in a clean profile: the marker should not appear unless the user has explicitly trusted/allowed the workspace behavior that permits automatic tasks.
