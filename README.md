# Kali Linux Container image

> Forked from https://github.com/onemarcfifty/kali-linux-docker

An optimized Kali Linux image for cybersecurity courses at FI MUNI.

Configuration of the container includes:

- Exposed ports (rdp, ssh)
- XFCE Desktop environment with RDP for remote access
- Kali packages to install (core, default everything, etc.)
- Container username
- Container user password
- AMD64 and ARM64 multiplatfrom image

## How to develop locally

Clone the repository and run `make` which will print help to all of the commands.

Run `make build` to build the current image and `make run` to build and run the image in a drop in shell in interactive mode.

Default username is `xuser` and password is `password123`. You can also connect locally via RDP using the port 13389 or through SSH on 20022

## Automatic builds using gitlab pipelines

> The image build takes about an hour mostly due to having the multiplatform build.

The pipeline consists of two parts:
  1. [https://gitlab.fi.muni.cz/cybersec/infra/images/kali/-/tree/kalilinux-synchronization?ref_type=heads](kalilinux-synchronization)
  2. All other branches

The `kalilinux-synchronization` branch is responsible for synchronizing the rolling kali linux image from docker hub to our container registry to have an atomic starting point for the kali linux image. Documentation to the synchronization process is in the [https://gitlab.fi.muni.cz/cybersec/infra/images/kali/-/blob/kalilinux-synchronization/README.md?ref_type=heads](kalilinux-synchronization/README.md).

The base Kali Linux image is at `gitlab.fi.muni.cz:5050/cybersec/infra/images/kali/kali-rolling-base:YYYYMMDD` where the end tag is the day of synchronization (when the pipeline ran)

> The synchronization should be done semi-regularly (probably at least one every three months) as the apt packages can stop working between major Kali Linux version upgrades.

Other branches coming from the `main` branch are automatically build and the resulting image is pushed to the container registry `gitlab.fi.muni.cz:5050/cybersec/infra/images/kali/kali:BRANCH` where the end tag is the name of the branch (use only numbers and letters in the names of branches for this to work)

> Do not forget to manually delete the unused images from the container registry, after a branch is deleted.

### How to upgrade to new kali linux base image

Follow the build process described in the [https://gitlab.fi.muni.cz/cybersec/infra/images/kali/-/blob/kalilinux-synchronization/README.md?ref_type=heads](kalilinux-synchronization/README.md). Afterwards, modify the `.gitlab-ci.yml` and `Makefile` to include the new version tag in the `XKALI_IMAGE_BASE_TAG` variable.

### Suggestions for use

I would personally create a two stage process where main is the *"development"* branch where you can test out things directly, or create development branches which are automatically build.

Afterwards, I would have a `production` branch or something like `fall24` branch which would contain the production image environment for the semester. However, having an image per semester would require in future to update all of the course materials to include the new branch.

## Notes

Currently, the `.gitlab-ci.yml` files contains a workaround in the form of argument `--provenance false` to circumvent a [https://gitlab.com/gitlab-org/gitlab/-/issues/388865#workaround](bug in gitlab container registry) which is fixed in the new "Next generation" container registry from Gitlab version 17.3.
