# main-push-robot-test

Scratch repository. It checks that a GitHub Actions workflow can push to a
protected `main` with a deploy key kept in an environment that admits `main`
only, that the workflow token is refused, and that `[skip ci]` keeps such a
push from starting the push workflows.
