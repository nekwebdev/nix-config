Global policy for all repositories:

- Hermes can run signed `git commit` commands when the user requests them and signing is available.
- Always request escalated execution for `git commit` first so signing can use the user's SSH/GPG agent.
- Keep signing enabled by default. Do not use `--no-gpg-sign`, `-c commit.gpgsign=false`, or similar unless the user explicitly asks for an unsigned commit.
- If escalated commit execution is denied or unavailable, stop and ask the user how to proceed. Do not create an unsigned commit as a fallback.
