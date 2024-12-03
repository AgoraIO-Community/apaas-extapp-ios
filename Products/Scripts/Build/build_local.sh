#!/bin/sh
# cd this file path
cd $(dirname $0)
echo pwd: `pwd`

# difference
Repo_Name="open-apaas-extapp-ios"
SDK_Array=(AgoraWidgets)

# import
. ../../../../apaas-cicd-ios/Products/Scripts/Other/v1/operation_print.sh

# path
CICD_Scripts_Path="../../../../apaas-cicd-ios/Products/Scripts"
CICD_Build_Path="${CICD_Scripts_Path}/SDK/Build"
CICD_Pack_Path="${CICD_Scripts_Path}/SDK/Pack"
CICD_Upload_Path="${CICD_Scripts_Path}/SDK/Upload"

# build
for SDK in ${SDK_Array[*]} 
do
  ${CICD_Build_Path}/v1/build.sh ${SDK} ${Repo_Name}
  
  errorPrint $? "${SDK} build"
done
