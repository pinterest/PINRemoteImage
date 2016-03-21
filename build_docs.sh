#!/usr/bin/env sh

appledoc \
    --company-id com.pinterest \
    --project-name PINRemoteImage \
    --project-company Pinterest \
    --project-version 1.0 \
    --docset-bundle-id %COMPANYID.%PROJECTID \
    --docset-bundle-name "%PROJECT %VERSION" \
    --docset-bundle-filename %COMPANYID.%PROJECTID-%VERSIONID.docset \
    --ignore "*.m" \
    --ignore "Assets" \
    --no-repeat-first-par \
    --explicit-crossref \
    --clean-output \
    --keep-intermediate-files \
    --output ./docs \
    Pod
    
mv docs/docset docs/com.pinterest.PINRemoteImage-1.0.docset
rm docs/docset-installed.txt
