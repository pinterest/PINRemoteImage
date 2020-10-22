#!/bin/bash
set -e

if [ -z "$OSS_PROJECT" ]; then
    echo "Must set \$OSS_PROJECT envirnonment variable before running."
fi

PROJECT="$OSS_PROJECT"

if ! git diff-index --quiet HEAD --; then
    echo "Please commit or stash any changes before running."
    exit 1
fi

if [ -z "$GITHUB_CHANGELOG_API_KEY" ]; then
    echo "Must set \$GITHUB_CHANGELOG_API_KEY environment variable"
    exit 1
fi

case $1 in
    "--major")
        UPDATE_TYPE="major"
        ;;

    "--minor")
        UPDATE_TYPE="minor"
        ;;

    "--patch")
        UPDATE_TYPE="patch"
        ;;

    *)
        echo "Usage release.sh --patch / --minor / --major"
        exit 1
        ;;
esac

PODSPEC="$PROJECT.podspec"
CURRENT_VERSION=`grep "version" -m 1 $PODSPEC | sed -E "s/^.*version[ \t]*=[ \t]*'([0-9\.]+)'/\1/"`
DOT_COUNT=`echo "$CURRENT_VERSION" | grep -o '\.' | wc -l`

if [ "$DOT_COUNT" -eq "0" ]; then
    major=$CURRENT_VERSION
    minor="0"
    patch="0"
elif [ "$DOT_COUNT" -eq "1" ]; then
    major=`echo "$CURRENT_VERSION" | sed -E "s/([0-9])+\.([0-9]+)/\1/"`
    minor=`echo "$CURRENT_VERSION" | sed -E "s/([0-9])+\.([0-9]+)/\2/"`
    patch="0"
elif [ "$DOT_COUNT" -eq "2" ]; then
    major=`echo "$CURRENT_VERSION" | sed -E "s/([0-9])+\.([0-9]+)\.([0-9]+)/\1/"`
    minor=`echo "$CURRENT_VERSION" | sed -E "s/([0-9])+\.([0-9]+)\.([0-9]+)/\2/"`
    patch=`echo "$CURRENT_VERSION" | sed -E "s/([0-9])+\.([0-9]+)\.([0-9]+)/\3/"`
fi

echo "Current version: $major.$minor.$patch"

if [ "$UPDATE_TYPE" == "major" ]; then
    major=$((major + 1))
    minor=0
    patch=0
elif [ "$UPDATE_TYPE" == "minor" ]; then
    minor=$((minor + 1))
    patch=0
elif [ "$UPDATE_TYPE" == "patch" ]; then
    patch=$((patch + 1))
fi

NEW_VERSION="$major.$minor.$patch"
echo "NEW_VERSION=$NEW_VERSION" >> $GITHUB_ENV
echo "New version: $NEW_VERSION"

echo "Updating $PODSPEC"
sed -E "s/^(.*version[ \t]*=[ \t]*)'$CURRENT_VERSION'/\1'$NEW_VERSION'/" $PODSPEC > new.podspec
mv new.podspec $PODSPEC

echo "Updating .github_changelog_generator"
cat << EOF > .github_changelog_generator
issues=false
since-tag=$CURRENT_VERSION
future-release=$NEW_VERSION
EOF

github_changelog_generator --token $GITHUB_CHANGELOG_API_KEY --user Pinterest --project $PROJECT --output NEW_CHANGES.md

# Delete # Changelog at the top of the old CHANGELOG
grep -v "# Changelog" CHANGELOG.md > CHANGELOG.tmp && mv CHANGELOG.tmp CHANGELOG.md

# Delete the last line and first line then use a magic sed command the internet told me
# about to delete trailing newlines (except the last one)
# Then prepend to existing changelog
grep -v "\*" NEW_CHANGES.md | sed -e :a -e '/^\n*$/{$d;N;};/\n$/ba' | cat - CHANGELOG.md > CHANGELOG.tmp
mv CHANGELOG.tmp CHANGELOG.md
rm NEW_CHANGES.md

git add .github_changelog_generator CHANGELOG.md $PODSPEC
git commit --message "[AUTO] Update CHANGELOG.md and bump for $UPDATE_TYPE update."
