# Markdown preview link and HTML samples

Open `sample.md` in Markdown Preview with a clean VS Code profile. Do not lower Markdown preview security settings.

Expected safe behavior: raw HTML may render, but inline script/event-handler payloads must not execute under the default preview CSP; relative links should route through the Markdown extension link resolver; `command:`-shaped links should not execute from preview link handling.
