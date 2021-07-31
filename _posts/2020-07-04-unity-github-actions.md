---
layout: post
title: "Building Unity with GitHub Actions"
excerpt_separator: <!--more-->
author: isaacbroyles
image: /assets/images/2020-07-04-unity-github-actions/unity.png
last_modified_at: 2021-07-31T21:19:22+00:00
date: 2021-07-31T21:19:22+00:00
categories:
  - gamedev
tags:
  - unity
  - github
  - github actions
  - gamedev
---

I recently began doing some work on a personal project in [Unity Engine](https://prf.hn/click/camref:1100ldaXB/destination:https://store.unity.com/products/unity-plus){:target="\_blank"}. As with any of my projects, the first thing I set up is a working CI pipeline for it. I find doing this early reinforces best practices. I liked the option of using GitHub Actions, since it is a relatively small project. Here's how I did it!

<!--more-->

## Getting Started

First, familiarize yourself with the community offerings for GitHub Actions - [game-ci/unity-actions](https://github.com/game-ci/unity-actions){:target="\_blank"}. There's a good overview here in the readme of the supported actions.

The other thing to check would be the official [game-ci getting starting docs](https://game.ci/docs/github/getting-started).

## Setting up License

The instructions in the official docs aren't the most verbose, but it's actually quite simple.

I'll just go into a little more detail here to try to make things super clear.

### Step 1 - Request Activation File on GitHub

This is an action that is intended to be a one-time use. Its purpose is to create a "license request file" that will be needed for the next step. This is what will allow unity to run builds on the GitHub Actions servers.

The file should end up looking something like this:

`.github/workflows/activation.yml:`

<!-- prettier-ignore-start -->
{% highlight yaml %}
{% raw %}
name: Acquire activation file
on:
  workflow_dispatch: {}
jobs:
  activation:
    name: Request manual activation file 🔑
    runs-on: ubuntu-latest
    steps:
      # Request manual activation file
      - name: Request manual activation file
        id: getManualLicenseFile
        uses: game-ci/unity-request-activation-file@v2
      # Upload artifact (Unity_v20XX.X.XXXX.alf)
      - name: Expose as artifact
        uses: actions/upload-artifact@v2
        with:
          name: ${{ steps.getManualLicenseFile.outputs.filePath }}
          path: ${{ steps.getManualLicenseFile.outputs.filePath }}

{% endraw %}
{% endhighlight %}
<!-- prettier-ignore-end -->

After you push it up, you can [manually run the worfklow](https://docs.github.com/en/actions/managing-workflow-runs/manually-running-a-workflow) to generate your license.

To find this file, go to `GitHub` > `Your Repository` > `Actions`. Click on the commit that last ran. You should find a file named something like `Unity_v2019.3.14f1.alf`. (The exact name depends on the version string that you put in `unityVersion` above.)

You'll need to save this file locally for use in the next step.

### Step 2 - Request License from Unity

Head over to the [Unity Manual Activation](https://license.unity3d.com/manual){:target="\_blank"} link.

Here you simply upload your `.alf` file from the previous step. Fill out the form with your license details.

On the last step you should be able to download a file that ends in `.ulf`.

This is your license you will put in GitHub secrets for use in your build actions.

### Step 3 - Save License in GitHub Secrets

Open `GitHub` > `Your Repository` > `Settings` > `Secrets`.

Create a secret called `UNITY_LICENSE` and add the contents of the obtained license file (`.ulf`). Yes, add the entire XML contents to the GitHub secret.

Now that this step is done, you can delete the `.github/workflows/activation.yml` file.

## Set up workflow

Now's the fun stuff! Now that you have your license ready to go, you can start setting up actions.

A couple of best practice recommendations:

- Cache your `Library` folder. This is where all your cached packages and large files end up during builds.
  - Note caches created on branches are scoped to that branch, regardless of key matches. Same goes for tags.
- Use GitHub Releases to store your file, _not_ actions artifacts. You will quickly run into free limits using artifacts
- Due to the size and time of full builds, I like to generate target builds only on tags.

Here's an example of a couple of workflow files.

#### Test - Runs on every commit

`.github/workflows/test.yml:`

<!-- prettier-ignore-start -->
{% highlight yaml %}
{% raw %}
name: Test

on:
  pull_request: {}
  push: { branches: [master] }

env:
  UNITY_LICENSE: ${{ secrets.UNITY_LICENSE }}

jobs:
  build:
    name: Test project
    runs-on: ubuntu-latest
    steps:

      # Checkout
      - name: Checkout repository
        uses: actions/checkout@v2
        with:
          lfs: true
    
      # Cache
      - uses: actions/cache@v2
        with:
          path: Library
          key: Library

      # Test
      - name: Run tests
        uses: game-ci/unity-test-runner@v2
        with:
          unityVersion: 2020.3.15f2

{% endraw %}
{% endhighlight %}
<!-- prettier-ignore-end -->

#### Build - Runs on tagged commits

This file uses this `on.push.tags` trigger to only run when tags are pushed.

It then uploads artifacts, zips up the binaries, creates a GitHub release for the tag, and uploads the release assets to it.

Depending on your usage, you might not want to upload the artifacts. You'll quickly run into limits if you use it too much.

`.github/workflows/main.yml:`

<!-- prettier-ignore-start -->
{% highlight yaml %}
{% raw %}
name: Build

on:
  push:
    tags:
      - '*'

env:
  UNITY_LICENSE: ${{ secrets.UNITY_LICENSE }}

jobs:
  build:
    name: Build my project
    runs-on: ubuntu-latest
    steps:

      # Checkout
      - name: Checkout repository
        uses: actions/checkout@v2
        with:
          lfs: true
    
      # Cache
      - uses: actions/cache@v2
        with:
          path: Library
          key: Library

      # Test
      - name: Run tests
        uses: game-ci/unity-test-runner@v2
        with:
          unityVersion: 2020.3.15f2

      # Build
      - name: Build project
        uses: game-ci/unity-builder@v2
        with:
          unityVersion: 2020.3.15f2
          targetPlatform: StandaloneWindows64 

      # Output 
      - uses: actions/upload-artifact@v2
        with:
          name: Build
          path: build

      - name: Zip build
        run: |
          pushd build/StandaloneWindows64
          zip -r ../../StandaloneWindows64.zip .
          popd

      - name: Release
        uses: softprops/action-gh-release@v1
        with:
          files: StandaloneWindows64.zip
          name: Release ${{ github.ref }}

{% endraw %}
{% endhighlight %}
<!-- prettier-ignore-end -->

Note: If you're using the above workflow, and experience an error on the build step like this:

<!-- prettier-ignore-start -->
{% highlight yaml %}
{% raw %}
Warning: Changes were made to the following files and folders:

Warning: ?? artifacts/

Error: Branch is dirty. Refusing to base semantic version on uncommitted changes
{% endraw %}
{% endhighlight %}
<!-- prettier-ignore-end -->

You will need to add the artifacts folder to your `.gitignore` file, as referenced in [this GitHub issue](https://github.com/game-ci/unity-builder/issues/241).

Another option would be using the [allowDirtyBuild](https://game.ci/docs/github/builder#allowdirtybuild) flag if you are still running into dirty branch issues.

Feel free to customize for your use case, as this workflow only outputs windows binaries. However, as mentioned in [game-ci/unity-actions](https://github.com/game-ci/unity-actions){:target="\_blank"}, there's a ton more supported actions/options.

## Conclusion

Setting up a CI flow early tends to keep me honest in following best practices. I like to do it even for my hobby projects.

A good side effect, is if I have to let projects idle for a while, I can always come back and expect my builds to work.

## Related Links

- [Unity Plus](https://prf.hn/click/camref:1100ldaXB/destination:https://store.unity.com/products/unity-plus){:target="\_blank"} - [Unity Pro](https://prf.hn/click/camref:1100ldaXB/destination:https://store.unity.com/products/unity-pro){:target="\_blank"}
- [Github - Unity Actions](https://github.com/game-ci/unity-actions){:target="\_blank"} - Unity Actions for GitHub

Note: Unity referral links are used in product links.
