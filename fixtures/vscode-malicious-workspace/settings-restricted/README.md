# Restricted workspace-settings fixture

This benign fixture attempts to set high-risk trust/automation controls from repository-controlled workspace settings.

Expected safe behavior in a clean profile: VS Code should not honor these values from the workspace scope because the corresponding upstream settings are registered as application-scoped and/or restricted. In particular, this fixture must not disable Workspace Trust or globally allow automatic tasks merely by opening the folder.
