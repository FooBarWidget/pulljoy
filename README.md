# Pulljoy: make external pull requests CI-able again

Pulljoy is a CI bot that helps you run CI sessions on external pull requests, in a safe and easy manner.

## Why Pulljoy?

You use Github Actions for CI. Your CI relies on secrets. When you receive a pull request from a fork, you discover that the CI for that pull request fails, because pull request workflow runs don't have access to your secrets.

You search the Internet and discover that there's a setting to allow pull request workflow runs to access your secrets. But you stop -- _should_ you do this? What if someone submits a malicious pull request which steals your secret? You close the tab.

How to solve this? The answer: manual reviews.

 1. You manually review new pull requests for whether they contain malicious changes.
 2. If the PR is not malicious, you pull the PR's changes into a temporary branch on your own repo.
 3. The CI runs, from the temporary branch on your own repo.
 4. When the CI finishes, you report the results.

This process works, but is a lot of work. If only there's a way to automate this.

**Pulljoy to the rescue!** Pulljoy implements the above process, making external pull requests CI-able again. Pulljoy makes pull request reviews joyful again.
