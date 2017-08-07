#!/bin/bash

#set -eo pipefail

versions=( "$@" )
if [ ${#versions[@]} -eq 0 ]; then
    versions=( */ )
fi
versions=( "${versions[@]%/}" )

GLIBC_VERSION="2.25-r0"

alpineVersions[7]='3.5'
alpineVersions[8]='3.5'

info() {
    echo $1
}

die() {
    echo $1 >&2
    exit 1
}

for version in "${versions[@]}"; do # "8-jdk"
    javaVersion="${version%%-*}"    # "8"
    javaType="${version#*-}"       # "jdk"

    alpineVersion="${alpineVersions[$javaVersion]}"
   
    oracleBaseURL="http://www.oracle.com"
    oracleURL="${oracleBaseURL}/technetwork/java/javase/downloads/index.html"

    oracleReleasesURL="https://www.java.com/en/download/faq/release_dates.xml"
    javaVersionMinor=$(curl -s $oracleReleasesURL | grep "Java $javaVersion Update" | sed "s/.*Update \([0-9]*\).*/\1/g" | head -1)

    case "$javaVersion" in
        7)
            # find latest java version from Previous Releases
            archiveURL=$(curl -s $oracleURL | grep -i "java archive" | grep -i "href" | sed "s|.*href=\"\(.*\)\">\(.*\)|\1|")
            archiveURL=$oracleBaseURL$archiveURL
            javaSEURL=$(curl -s $archiveURL | grep "Java SE 7" | sed "s/.*href=\"\(.*\)\">Java SE 7<\/a>.*/\1/")
            ;;
        8)
            javaSEURL=$(curl -s $oracleURL | grep -o 'href=['"'"'"][^"'"'"']*['"'"'"]' | sed -e 's/href=["'"'"']//' -e 's/["'"'"']$//' | grep -i "/${javaType}${javaVersion}-downloads" | head -1)
            ;;
    esac 
    javaSEURL=$oracleBaseURL$javaSEURL
    downloadURL=$(curl -s $javaSEURL | grep "/${javaType}-${javaVersion}u${javaVersionMinor}-linux-x64.tar.gz" | sed "s;.*filepath\":\"\(.*tar\.gz\)\".*;\1;")
    javaVersionBuild=$(echo $downloadURL | sed "s/.*${javaVersion}u${javaVersionMinor}-b\([0-9]*\).*/\1/" )

    oracleFullVersion=${javaVersion}u${javaVersionMinor}-b${javaVersionBuild}
    
    info "$version: $oracleFullVersion (alpine $alpineVersion)"
    
    dockerfileTemplate="Dockerfile.template"
    [ ! -f ${dockerfileTemplate} ] && die "Missing Dockerfile template: $dockerfileTemplate"

    sed \
        -e "s/%ALPINE_VERSION%/${alpineVersion}/g" \
        -e "s/%JVM_MAJOR%/${javaVersion}/g" \
        -e "s/%JVM_MINOR%/${javaVersionMinor}/g" \
        -e "s/%JVM_BUILD%/${javaVersionBuild}/g" \
        -e "s/%JVM_TYPE%/${javaType}/g" \
        -e "s|%JVM_DOWNLOAD_URL%|${downloadURL}|g" \
        -e "s/%GLIBC_VERSION%/${GLIBC_VERSION}/g" \
        ${dockerfileTemplate} > $version/Dockerfile
done
