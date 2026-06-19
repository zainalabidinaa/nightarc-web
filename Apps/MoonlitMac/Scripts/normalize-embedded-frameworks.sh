#!/bin/sh
set -eu

frameworks_dir="${TARGET_BUILD_DIR}/${FRAMEWORKS_FOLDER_PATH}"

if [ ! -d "$frameworks_dir" ]; then
  exit 0
fi

find "$frameworks_dir" -maxdepth 1 -type d -name "*.framework" | while IFS= read -r framework; do
  framework_name="$(basename "$framework" .framework)"
  binary_path="$framework/$framework_name"
  info_plist="$framework/Info.plist"

  if [ -d "$framework/Versions" ] || [ ! -f "$binary_path" ] || [ ! -f "$info_plist" ]; then
    continue
  fi

  version_dir="$framework/Versions/A"
  resources_dir="$version_dir/Resources"

  mkdir -p "$resources_dir"
  mv "$binary_path" "$version_dir/$framework_name"
  mv "$info_plist" "$resources_dir/Info.plist"

  if [ -d "$framework/_CodeSignature" ]; then
    rm -rf "$framework/_CodeSignature"
  fi

  ln -sfn A "$framework/Versions/Current"
  ln -sfn "Versions/Current/$framework_name" "$framework/$framework_name"
  ln -sfn "Versions/Current/Resources" "$framework/Resources"
done
