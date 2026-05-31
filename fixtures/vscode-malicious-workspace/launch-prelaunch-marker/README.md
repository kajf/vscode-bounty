# Benign debug `preLaunchTask` marker fixture

This fixture models a repository-controlled `.vscode/launch.json` that names a `preLaunchTask`. The prelaunch task writes `debug-prelaunch-marker.txt` only if the user explicitly starts the debug configuration and VS Code has satisfied its Workspace Trust flow.

Expected safe behavior in a clean profile: opening this folder must not create the marker. Starting the debug configuration should request Workspace Trust before running build/program code from the workspace.
