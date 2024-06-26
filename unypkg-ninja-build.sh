#!/usr/bin/env bash
# shellcheck disable=SC2034,SC1091,SC2154

set -vx

######################################################################################################################
### Setup Build System and GitHub

#apt install -y

wget -qO- uny.nu/pkg | bash -s buildsys

### Installing build dependencies
unyp install python re2c

### Getting Variables from files
UNY_AUTO_PAT="$(cat UNY_AUTO_PAT)"
export UNY_AUTO_PAT
GH_TOKEN="$(cat GH_TOKEN)"
export GH_TOKEN

source /uny/git/unypkg/fn
uny_auto_github_conf

######################################################################################################################
### Timestamp & Download

uny_build_date

mkdir -pv /uny/sources
cd /uny/sources || exit

pkgname="ninja"
pkggit="https://github.com/ninja-build/ninja.git refs/tags/*"
gitdepth="--depth=1"

### Get version info from git remote
# shellcheck disable=SC2086
latest_head="$(git ls-remote --refs --tags --sort="v:refname" $pkggit | grep -E "v[0-9.]*$" | tail --lines=1)"
latest_ver="$(echo "$latest_head" | grep -o "v[0-9.].*" | sed "s|v||")"
latest_commit_id="$(echo "$latest_head" | cut --fields=1)"

version_details

# Release package no matter what:
echo "newer" >release-"$pkgname"

git_clone_source_repo

#cd "$pkgname" || exit
#cd /uny/sources || exit

version_details
archiving_source

######################################################################################################################
### Build

# unyc - run commands in uny's chroot environment
# shellcheck disable=SC2154
unyc <<"UNYEOF"
set -vx
source /uny/git/unypkg/fn

pkgname="ninja"

version_verbose_log_clean_unpack_cd
get_env_var_values
get_include_paths

####################################################
### Start of individual build script

unset LD_RUN_PATH

python3 configure.py --bootstrap

#./ninja ninja_test
#./ninja_test --gtest_filter=-SubprocessTest.SetWithLots

mkdir -pv /uny/pkg/"$pkgname"/"$pkgver"/bin
install -vm755 ninja /uny/pkg/"$pkgname"/"$pkgver"/bin/

####################################################
### End of individual build script

add_to_paths_files
dependencies_file_and_unset_vars
cleanup_verbose_off_timing_end
UNYEOF

######################################################################################################################
### Packaging

package_unypkg
