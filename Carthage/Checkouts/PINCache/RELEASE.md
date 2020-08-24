# Release Process
This document describes the process for a public PINCache release.

### Preparation
- Install [github_changelog_generator](https://github.com/skywinder/Github-Changelog-Generator): `sudo gem install github_changelog_generator`
- Generate a GitHub Personal Access Token to prevent running into public GitHub API rate limits: https://github.com/github-changelog-generator/github-changelog-generator#github-token

### Process
- Run `github_changelog_generator` in PINCache project directory: `github_changelog_generator --token <generated personal token> --user Pinterest --project PINCache`. To avoid hitting rate limit, the generator will replace the entire file with just the changes from this version – revert that giant deletion to get the entire new changelog.
- Update `spec.version` within `PINCache.podspec` and the `since-tag` and `future-release` fields in `.github_changelog_generator`.
- Create a new PR with the updated `PINCache.podspec` and the newly generated changelog, add `#changelog` to the PR message so the CI will not prevent merging it.
- After merging in the PR, [create a new GitHub release](https://github.com/Pinterest/PINCache/releases/new). Use the generated changelog for the new release.
- Push to Cocoapods with `pod trunk push`
