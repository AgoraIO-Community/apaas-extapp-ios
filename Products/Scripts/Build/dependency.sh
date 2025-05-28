#!/bin/sh

# Difference
# Dependency libs
# Widget
# UIBaseViews
Artifactory_iOS_URL="https://artifactory.agoralab.co/artifactory/AD_repo/aPaaS/iOS"

Version="2.8.111"
Branch="release_${Version}"

AgoraWidget_URL="${Artifactory_iOS_URL}/AgoraWidget/${Branch}/dev/AgoraWidget_${Version}.zip"
AgoraUIBaseViews_URL="${Artifactory_iOS_URL}/AgoraUIBaseViews/${Branch}/dev/AgoraUIBaseViews_${Version}.zip"

Dep_Array_URL=("${AgoraWidget_URL}"
               "${AgoraUIBaseViews_URL}")

Dep_Array=(AgoraWidget
           AgoraUIBaseViews)

# cd this file path
cd $(dirname $0)
echo pwd: `pwd`

# parameters
Repo_Name=$1

# path
CICD_Repo_Path=../../../../apaas-cicd-ios
CICD_Products_Path=${CICD_Repo_Path}/Products
CICD_Scripts_Path=${CICD_Products_Path}/Scripts

${CICD_Scripts_Path}/SDK/Build/v1/dependency.sh "${Dep_Array_URL[*]}" "${Dep_Array[*]}" ${Repo_Name}
