#!/usr/bin/env bash
# Pushes HEAD to main of this repository with the deploy key "main-push robot".
#
# Direct pushes to main are allowed only for Nikita's account and for deploy
# keys. The workflow token cannot push to main. The private key is the secret
# MAIN_PUSH_KEY of the environment "main-push", which admits only the default
# branch, so a workflow running on any other branch never receives it. The
# calling job declares `environment: main-push` and passes the secret to this
# step only, as the variable MAIN_PUSH_KEY.
#
# A push made with a deploy key starts the workflows that listen to pushes,
# unlike a push made with the workflow token. The commit message must contain
# "[skip ci]" so that a robot commit starts nothing by itself; workflows that
# the caller starts with `uses:` still run.
#
# Usage: .github/scripts/push-main.sh
# Exits non-zero when the push is refused; the caller decides whether to retry.
set -euo pipefail

: "${MAIN_PUSH_KEY:?MAIN_PUSH_KEY is empty: the job needs environment: main-push and must run on the default branch}"
: "${GITHUB_REPOSITORY:?}"

if ! git log -1 --format=%B | grep -qF '[skip ci]'; then
  echo "::error::The commit to push has no [skip ci] in its message; it would start the push workflows a second time." >&2
  exit 1
fi

dir="$(mktemp -d)"
trap 'rm -rf "$dir"' EXIT
(umask 077 && printf '%s\n' "$MAIN_PUSH_KEY" >"$dir/key")

# GitHub's SSH host keys, as published at
# https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/githubs-ssh-key-fingerprints
# and by https://api.github.com/meta (ssh_keys).
cat >"$dir/known_hosts" <<'EOF'
github.com ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOMqqnkVzrm0SdG6UOoqKLsabgH5C9okWi0dh2l9GKJl
github.com ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBEmKSENjQEezOmxkZMy7opKgwFB9nkt5YRrYMjNuG5N87uRgg6CLrbo5wAdT/y6v0mKV0U2w0WZ2YB/++Tpockg=
github.com ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCj7ndNxQowgcQnjshcLrqPEiiphnt+VTTvDP6mHBL9j1aNUkY4Ue1gvwnGLVlOhGeYrnZaMgRK6+PKCUXaDbC7qtbW8gIkhL7aGCsOr/C56SJMy/BCZfxd1nWzAOxSDPgVsmerOBYfNqltV9/hWCqBywINIR+5dIg6JTJ72pcEpEjcYgXkE2YEFXV1JHnsKgbLWNlhScqb2UmyRkQyytRLtL+38TGxkxCflmO+5Z8CSSNY7GidjMIZ7Q4zMjA2n1nGrlTDkzwDCsw+wqFPGQA179cnfGWOWRVruj16z6XyvxvjJwbz0wQZ75XK5tKSb7FNyeIEs4TT4jk+S4dhPeAUC5y+bDYirYgM4GC7uEnztnZyaVWQ7B381AK4Qdrwt51ZqExKbQpTUNn+EjqoTwvqNj4kqx5QUCI0ThS/YkOxJCXmPUWZbhjpCg56i+2aB6CmK2JGhn57K5mj0MNdBXA4/WnwH6XoPWJzK5Nyu2zB3nAZp+S5hpQs+p1vN1/wsjk=
EOF

GIT_SSH_COMMAND="ssh -i $dir/key -o IdentitiesOnly=yes -o IdentityAgent=none -o UserKnownHostsFile=$dir/known_hosts -o GlobalKnownHostsFile=/dev/null -o StrictHostKeyChecking=yes" \
  git push -q "git@github.com:$GITHUB_REPOSITORY.git" HEAD:main
