#!/bin/bash

run_trufflehog() {
    ../../docker-hub-scanner/trufflehog filesystem --directory contents --debug --only-verified | tee -a trufflehog.txt
}

extract_package() {
    ls *.whl | xargs -I {} unzip {} -d contents
}

notify() {
    cat trufflehog.txt | xargs -I {} sh ../notify.sh {}
}

fetch_latest_two_versions() {
    curl -s "https://pypi.org/pypi/$1/json" | jq -r '.releases | keys_unsorted | reverse | .[0:2] | .[]'
}


fetch_versions() {
	local response=$(curl -s -o /dev/null -w "%{http_code}" "https://pypi.org/pypi/$1/json")
	if [[ $response == 404 ]]; then
		echo "Error: Package $1 not found."
		return 1
	else
		curl -s "https://pypi.org/pypi/$1/json" | jq -r '.releases | keys_unsorted | .[]'
	fi
}

fetch_package_names() {
	curl --header 'Accept: application/vnd.pypi.simple.v1+json' -s https://pypi.org/simple/ | jq -r '.projects[].name'
#    curl -s https://pypi.org/simple/ | grep '<a href="/simple/' | sed 's/<a href="\/simple\///;s/\/">//;s/<\/a>//'
}

for package_name in $(fetch_package_names); do
    echo "Processing $package_name"
    mkdir -p "$package_name"
    cd "$package_name"

    all_versions=$(fetch_versions "$package_name")
    if [ $? -eq 1 ]; then
	cd ..
	rm -rf "$package_name"
	continue
    fi
    latest_two_versions=$(echo "$all_versions" | tail -n 2)
    

    for version in $all_versions; do
	if echo "$latest_two_versions" | grep -q "$version"; then
	        download_url=$(curl -s "https://pypi.org/pypi/${package_name}/${version}/json" | jq -r '.urls[0].url')
	        echo "Downloading version ${version} of ${package_name}..."
	        wget "${download_url}"
	        extract_package
	        run_trufflehog
		sh notify.sh "Processing $version"
	        notify
	        mv contents "$version"
	fi
    done

    cd ..
    rm -rf "$package_name"
done

