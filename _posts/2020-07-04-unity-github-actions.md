---
layout: post
title: "Building Unity with GitHub Actions"
excerpt_separator: <!--more-->
author: isaacbroyles
image: /assets/images/2020-07-04-unity-github-actions/unity.png
categories:
  - gamedev
tags:
  - unity
  - github
  - github actions
  - gamedev
---

I recently began doing some work on a personal project in [Unity Engine](https://store.unity.com/download-nuo). As with any of my projects, the first thing I set up is a working CI pipeline for it. I find doing this early reinforces best practices. I liked the option of using GitHub Actions, since it is a relatively small project. Here's how I did it!

<!--more-->

## Getting Started

First, familiarize yourself with the community offerings for GitHub Actions - [webbertakken/unity-actions](https://github.com/webbertakken/unity-actions). There's a good overview here in the readme of the supported actions.

The main thing you will need to start off with, as called out in the above README, is setting up your license.

## Setting up License

The instructions in the `unity-actions` README aren't the most verbose, but it's actually quite simple.

I'll just go into a little more detail here to try to make things super clear.

### Step 1 - Request Activation File on GitHub

This is an action that is intended to be a one-time use. Its purpose is to create a "license request file" that will be needed for the next step. This is what will allow unity to run builds on the GitHub Actions servers.

The file should end up looking something like this:

`.github/workflows/activation.yml:`

<!-- prettier-ignore-start -->
{% highlight yaml %}
{% raw %}
name: Acquire activation file
on: [push]
jobs:
  activation:
    name: Request manual activation file 🔑
    runs-on: ubuntu-latest
    steps:
        # Request manual activation file
        - name: Request manual activation file
          id: getManualLicenseFile
          uses: webbertakken/unity-request-manual-activation-file@v1.1
          with:
            unityVersion: 2019.3.14f1
        # Upload artifact (Unity_v20XX.X.XXXX.alf)
        - name: Expose as artifact
          uses: actions/upload-artifact@v1
          with:
            name: ${{ steps.getManualLicenseFile.outputs.filePath }}
            path: ${{ steps.getManualLicenseFile.outputs.filePath }} 
{% endraw %}
{% endhighlight %}
<!-- prettier-ignore-end -->

After you push it up, GitHub will run this action and generate a file as an artifact.

To find this file, go to `GitHub` > `Your Repository` > `Actions`. Click on the commit that last ran. You should find a file named something like `Unity_v2019.3.14f1.alf`. (The exact name depends on the version string that you put in `unityVersion` above.)

You'll need to save this file locally for use in the next step.

### Step 2 - Request License from Unity

Head over to the [Unity Manual Activation](https://license.unity3d.com/manual) link.

Here you simply upload your `.alf` file from the previous step. Fill out the form with your license details.

On the last step you should be able to download a file that ends in `.ulf`.

This is your license you will put in GitHub secrets for use in your build actions.

### Step 3 - Save License in GitHub Secrets

Open `GitHub` > `Your Repository` > `Settings` > `Secrets`.

Create a secret called `UNITY_LICENSE` and add the contents of the obtained license file (`.ulf`).

Now that this step is done, you can delete the `.github/workflows/activation.yml` file.

## Set up workflow

Now's the fun stuff! Now that you have your license ready to go, you can start setting up actions.

A couple of best practice recommendations:

- Cache your `Library` folder. This is where all your cached packages and large files end up during builds.
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
      - uses: actions/cache@v1.1.0
        with:
          path: Library
          key: Library

      # Test
      - name: Run tests
        uses: webbertakken/unity-test-runner@v1.3
        with:
          unityVersion: 2019.3.14f1

{% endraw %}
{% endhighlight %}
<!-- prettier-ignore-end -->

#### Build - Runs on tagged commits

This file uses this `on.push.tags` trigger to only run when tags are pushed.

It then uploads artifacts, zips up the binaries, creates a GitHub release for the tag, and uploads the release assets to it.

Depending on your usage, you might not want to upload the artifacts. You'll quickly run into limits if you use it too much.

`.github/workflows/test.yml:`

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
      - uses: actions/cache@v1.1.0
        with:
          path: Library
          key: Library

      # Test
      - name: Run tests
        uses: webbertakken/unity-test-runner@v1.3
        with:
          unityVersion: 2019.3.14f1

      # Build
      - name: Build project
        uses: webbertakken/unity-builder@v0.10
        with:
          unityVersion: 2019.3.14f1
          targetPlatform: StandaloneWindows64 

      # Output 
      - uses: actions/upload-artifact@v1
        with:
          name: Build
          path: build

      - name: Zip build
        run: |
          pushd build/StandaloneWindows64
          zip -r ../../StandaloneWindows64.zip .
          popd

      - name: Create Release
        id: create_release
        uses: actions/create-release@v1
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
        with:
          tag_name: ${{ github.ref }}
          release_name: Release ${{ github.ref }}
          draft: false
          prerelease: false

      - name: Upload Release Asset
        id: upload-release-asset 
        uses: actions/upload-release-asset@v1
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
        with:
          upload_url: ${{ steps.create_release.outputs.upload_url }} # This pulls from the CREATE RELEASE step above, referencing it's ID to get its outputs object, which include a `upload_url`. See this blog post for more info: https://jasonet.co/posts/new-features-of-github-actions/#passing-data-to-future-steps 
          asset_path: ./StandaloneWindows64.zip
          asset_name: StandaloneWindows64.zip
          asset_content_type: application/zip
{% endraw %}
{% endhighlight %}
<!-- prettier-ignore-end -->

Feel free to customize for your use case, as this workflow only outputs windows binaries. However, as mentioned in [webbertakken/unity-actions](https://github.com/webbertakken/unity-actions), there's a ton more supported actions/options.

## Conclusion

Setting up a CI flow early tends to keep me honest in following best practices. I like to do it even for my hobby projects.

A good side effect, is if I have to let projects idle for a while, I can always come back and expect my builds to work.

## Related Links

- [Unity Engine](https://store.unity.com/download-nuo) - The Unity download site
- [Github - Unity Actions](https://github.com/webbertakken/unity-actions) - Unity Actions for GitHub
