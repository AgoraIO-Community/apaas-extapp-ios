#!/bin/sh

# difference
SDK_Name="AgoraWidgets"
Repo_Name="open-apaas-extapp-ios"

# cd this file path
cd $(dirname $0)
echo pwd: `pwd`

# path
CICD_Root_Path=../../../../apaas-cicd-ios
CICD_Products_Path=${CICD_Root_Path}/Products
CICD_Scripts_Path=${CICD_Products_Path}/Scripts

# publish
${CICD_Scripts_Path}/SDK/Publish/v1/publish_source_cocoapods.sh ${SDK_Name} ${Repo_Name}
