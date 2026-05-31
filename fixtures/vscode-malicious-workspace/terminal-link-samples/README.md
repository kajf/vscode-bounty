# Terminal link handling samples

Run the `emit-benign-terminal-links` task manually to print link-shaped strings into the integrated terminal. Use this fixture to observe which strings become terminal links and whether activation opens externally, opens files, or requires an explicit modifier/user action.

Expected safe behavior: merely opening the folder must not execute the task. If the task is run manually, clicking terminal links should require the terminal link activation gesture. `command:`-shaped terminal output should not execute an internal VS Code command through the normal URL-link opener.
