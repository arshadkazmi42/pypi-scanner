#!/bin/bash

package_name=$1

mkdir -p $package_name
cd $package_name

download_package_versions() {
	versions=$(curl -s "https://pypi.org/pypi/${package_name}/json" | jq -r '.releases | keys[]')

	for version in $versions; do
		download_url=$(curl -s "https://pypi.org/pypi/${package_name}/${version}/json" | jq -r '.urls[0].url')
		echo "Downloading version ${version}..."
		wget "${download_url}"
		extract_package
		run_trufflehog
	done
}

run_trufflehog() {
	trufflehog filesystem --directory contents --debug --only-verified | tee -a trufflehog.txt | notify
}

extract_package() {
	ls *.whl | xargs -I {} unzip {} -d contents
}

cleanup() {
	local version="$1"
	echo "Cleaning up version ${version}..."
	rm -rf "${version}.tar.gz"
}

download_package_versions
