# Release Process

This document outlines the process for releasing a new version of the project.

## Pre-release

- [ ] **Create Release Branch:** Make a new branch, `release-vX.X.X`, corresponding to the release version being cut (e.g., `release-v0.1.X` for release version `0.1.0`). All patch releases for that minor version should be added to this branch.
- [ ] **Update Version:** Update the project version in [src/harvester/pyproject.toml](./src/harvester/pyproject.toml). For example, for version `0.1.0`:
  ```toml
  [project]
  name = "feedback-harvester"
  version = "0.1.0"
  description = "A simple data harvester."
  # ...
  ```
- [ ] **Commit Changes:** Commit the version changes to your new branch.

## Release Steps

- [ ] **Build and Push Container Image:**
    Build and push the harvester image with the correct version tag.
    ```sh
    export TAG=v0.1.0
    make build-harvester
    podman push quay.io/redhat-ai-dev/feedback-harvester:$TAG
    ```
- [ ] **Set Default Harvester Image:**
    Update the [default-harvester-values](./env/default-harvester-values) to include the tagged release version of the harvester.
    ```sh
    export HARVESTER_IMAGE=quay.io/redhat-ai-dev/feedback-harvester:v0.1.0
    ```
- [ ] **Create GitHub Release:**
    - Go to the [github.com/redhat-ai-dev/rcs-support/releases](https://github.com/redhat-ai-dev/rcs-support/releases) and draft a new release.
    - Target the release branch (e.g. `release-v0.1.X`).
    - Create a new git tag (e.g., `v0.1.0`).
    - Use the git tag you just created (e.g., `v0.1.0`).
    - Set the release title to the version (e.g., `v0.1.0`).
    - Publish the release.

## Post-release

- [ ] **Announce:** Announce the new release to the team.
