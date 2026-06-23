#!/bin/sh
set -e
set -u
set -o pipefail

function on_error {
  echo "$(realpath -mq "${0}"):$1: error: Unexpected failure"
}
trap 'on_error $LINENO' ERR


# This protects against multiple targets copying the same framework dependency at the same time. The solution
# was originally proposed here: https://lists.samba.org/archive/rsync/2008-February/020158.html
RSYNC_PROTECT_TMP_FILES=(--filter "P .*.??????")


variant_for_slice()
{
  case "$1" in
  "FLAnalytics.xcframework/ios-arm64")
    echo ""
    ;;
  "FLAnalytics.xcframework/ios-arm64_x86_64-simulator")
    echo "simulator"
    ;;
  "FLAnalytics.xcframework/tvos-arm64")
    echo ""
    ;;
  "FLAnalytics.xcframework/tvos-arm64_x86_64-simulator")
    echo "simulator"
    ;;
  "FLBookmarks.xcframework/ios-arm64")
    echo ""
    ;;
  "FLBookmarks.xcframework/ios-arm64_x86_64-simulator")
    echo "simulator"
    ;;
  "FLBookmarks.xcframework/tvos-arm64")
    echo ""
    ;;
  "FLBookmarks.xcframework/tvos-arm64_x86_64-simulator")
    echo "simulator"
    ;;
  "FLContentAuthorizer.xcframework/ios-arm64")
    echo ""
    ;;
  "FLContentAuthorizer.xcframework/ios-arm64_x86_64-simulator")
    echo "simulator"
    ;;
  "FLContentAuthorizer.xcframework/tvos-arm64")
    echo ""
    ;;
  "FLContentAuthorizer.xcframework/tvos-arm64_x86_64-simulator")
    echo "simulator"
    ;;
  "FLFoundation.xcframework/ios-arm64")
    echo ""
    ;;
  "FLFoundation.xcframework/ios-arm64_x86_64-simulator")
    echo "simulator"
    ;;
  "FLFoundation.xcframework/tvos-arm64")
    echo ""
    ;;
  "FLFoundation.xcframework/tvos-arm64_x86_64-simulator")
    echo "simulator"
    ;;
  "FLHeartbeat.xcframework/ios-arm64")
    echo ""
    ;;
  "FLHeartbeat.xcframework/ios-arm64_x86_64-simulator")
    echo "simulator"
    ;;
  "FLHeartbeat.xcframework/tvos-arm64")
    echo ""
    ;;
  "FLHeartbeat.xcframework/tvos-arm64_x86_64-simulator")
    echo "simulator"
    ;;
  "FLPlatformCore.xcframework/ios-arm64")
    echo ""
    ;;
  "FLPlatformCore.xcframework/ios-arm64_x86_64-simulator")
    echo "simulator"
    ;;
  "FLPlatformCore.xcframework/tvos-arm64")
    echo ""
    ;;
  "FLPlatformCore.xcframework/tvos-arm64_x86_64-simulator")
    echo "simulator"
    ;;
  "FLPlatformPlayer.xcframework/ios-arm64")
    echo ""
    ;;
  "FLPlatformPlayer.xcframework/ios-arm64_x86_64-simulator")
    echo "simulator"
    ;;
  "FLPlatformPlayer.xcframework/tvos-arm64")
    echo ""
    ;;
  "FLPlatformPlayer.xcframework/tvos-arm64_x86_64-simulator")
    echo "simulator"
    ;;
  "FLPlayer.xcframework/ios-arm64")
    echo ""
    ;;
  "FLPlayer.xcframework/ios-arm64_x86_64-simulator")
    echo "simulator"
    ;;
  "FLPlayer.xcframework/tvos-arm64")
    echo ""
    ;;
  "FLPlayer.xcframework/tvos-arm64_x86_64-simulator")
    echo "simulator"
    ;;
  "FLPlayerInterface.xcframework/ios-arm64")
    echo ""
    ;;
  "FLPlayerInterface.xcframework/ios-arm64_x86_64-simulator")
    echo "simulator"
    ;;
  "FLPlayerInterface.xcframework/tvos-arm64")
    echo ""
    ;;
  "FLPlayerInterface.xcframework/tvos-arm64_x86_64-simulator")
    echo "simulator"
    ;;
  "FLStreamConcurrency.xcframework/ios-arm64")
    echo ""
    ;;
  "FLStreamConcurrency.xcframework/ios-arm64_x86_64-simulator")
    echo "simulator"
    ;;
  "FLStreamConcurrency.xcframework/tvos-arm64")
    echo ""
    ;;
  "FLStreamConcurrency.xcframework/tvos-arm64_x86_64-simulator")
    echo "simulator"
    ;;
  esac
}

archs_for_slice()
{
  case "$1" in
  "FLAnalytics.xcframework/ios-arm64")
    echo "arm64"
    ;;
  "FLAnalytics.xcframework/ios-arm64_x86_64-simulator")
    echo "arm64 x86_64"
    ;;
  "FLAnalytics.xcframework/tvos-arm64")
    echo "arm64"
    ;;
  "FLAnalytics.xcframework/tvos-arm64_x86_64-simulator")
    echo "arm64 x86_64"
    ;;
  "FLBookmarks.xcframework/ios-arm64")
    echo "arm64"
    ;;
  "FLBookmarks.xcframework/ios-arm64_x86_64-simulator")
    echo "arm64 x86_64"
    ;;
  "FLBookmarks.xcframework/tvos-arm64")
    echo "arm64"
    ;;
  "FLBookmarks.xcframework/tvos-arm64_x86_64-simulator")
    echo "arm64 x86_64"
    ;;
  "FLContentAuthorizer.xcframework/ios-arm64")
    echo "arm64"
    ;;
  "FLContentAuthorizer.xcframework/ios-arm64_x86_64-simulator")
    echo "arm64 x86_64"
    ;;
  "FLContentAuthorizer.xcframework/tvos-arm64")
    echo "arm64"
    ;;
  "FLContentAuthorizer.xcframework/tvos-arm64_x86_64-simulator")
    echo "arm64 x86_64"
    ;;
  "FLFoundation.xcframework/ios-arm64")
    echo "arm64"
    ;;
  "FLFoundation.xcframework/ios-arm64_x86_64-simulator")
    echo "arm64 x86_64"
    ;;
  "FLFoundation.xcframework/tvos-arm64")
    echo "arm64"
    ;;
  "FLFoundation.xcframework/tvos-arm64_x86_64-simulator")
    echo "arm64 x86_64"
    ;;
  "FLHeartbeat.xcframework/ios-arm64")
    echo "arm64"
    ;;
  "FLHeartbeat.xcframework/ios-arm64_x86_64-simulator")
    echo "arm64 x86_64"
    ;;
  "FLHeartbeat.xcframework/tvos-arm64")
    echo "arm64"
    ;;
  "FLHeartbeat.xcframework/tvos-arm64_x86_64-simulator")
    echo "arm64 x86_64"
    ;;
  "FLPlatformCore.xcframework/ios-arm64")
    echo "arm64"
    ;;
  "FLPlatformCore.xcframework/ios-arm64_x86_64-simulator")
    echo "arm64 x86_64"
    ;;
  "FLPlatformCore.xcframework/tvos-arm64")
    echo "arm64"
    ;;
  "FLPlatformCore.xcframework/tvos-arm64_x86_64-simulator")
    echo "arm64 x86_64"
    ;;
  "FLPlatformPlayer.xcframework/ios-arm64")
    echo "arm64"
    ;;
  "FLPlatformPlayer.xcframework/ios-arm64_x86_64-simulator")
    echo "arm64 x86_64"
    ;;
  "FLPlatformPlayer.xcframework/tvos-arm64")
    echo "arm64"
    ;;
  "FLPlatformPlayer.xcframework/tvos-arm64_x86_64-simulator")
    echo "arm64 x86_64"
    ;;
  "FLPlayer.xcframework/ios-arm64")
    echo "arm64"
    ;;
  "FLPlayer.xcframework/ios-arm64_x86_64-simulator")
    echo "arm64 x86_64"
    ;;
  "FLPlayer.xcframework/tvos-arm64")
    echo "arm64"
    ;;
  "FLPlayer.xcframework/tvos-arm64_x86_64-simulator")
    echo "arm64 x86_64"
    ;;
  "FLPlayerInterface.xcframework/ios-arm64")
    echo "arm64"
    ;;
  "FLPlayerInterface.xcframework/ios-arm64_x86_64-simulator")
    echo "arm64 x86_64"
    ;;
  "FLPlayerInterface.xcframework/tvos-arm64")
    echo "arm64"
    ;;
  "FLPlayerInterface.xcframework/tvos-arm64_x86_64-simulator")
    echo "arm64 x86_64"
    ;;
  "FLStreamConcurrency.xcframework/ios-arm64")
    echo "arm64"
    ;;
  "FLStreamConcurrency.xcframework/ios-arm64_x86_64-simulator")
    echo "arm64 x86_64"
    ;;
  "FLStreamConcurrency.xcframework/tvos-arm64")
    echo "arm64"
    ;;
  "FLStreamConcurrency.xcframework/tvos-arm64_x86_64-simulator")
    echo "arm64 x86_64"
    ;;
  esac
}

copy_dir()
{
  local source="$1"
  local destination="$2"

  # Use filter instead of exclude so missing patterns don't throw errors.
  echo "rsync --delete -av "${RSYNC_PROTECT_TMP_FILES[@]}" --links --filter \"- CVS/\" --filter \"- .svn/\" --filter \"- .git/\" --filter \"- .hg/\" \"${source}*\" \"${destination}\""
  rsync --delete -av "${RSYNC_PROTECT_TMP_FILES[@]}" --links --filter "- CVS/" --filter "- .svn/" --filter "- .git/" --filter "- .hg/" "${source}"/* "${destination}"
}

SELECT_SLICE_RETVAL=""

select_slice() {
  local xcframework_name="$1"
  xcframework_name="${xcframework_name##*/}"
  local paths=("${@:2}")
  # Locate the correct slice of the .xcframework for the current architectures
  local target_path=""

  # Split archs on space so we can find a slice that has all the needed archs
  local target_archs=$(echo $ARCHS | tr " " "\n")

  local target_variant=""
  if [[ "$PLATFORM_NAME" == *"simulator" ]]; then
    target_variant="simulator"
  fi
  if [[ ! -z ${EFFECTIVE_PLATFORM_NAME+x} && "$EFFECTIVE_PLATFORM_NAME" == *"maccatalyst" ]]; then
    target_variant="maccatalyst"
  fi
  for i in ${!paths[@]}; do
    local matched_all_archs="1"
    local slice_archs="$(archs_for_slice "${xcframework_name}/${paths[$i]}")"
    local slice_variant="$(variant_for_slice "${xcframework_name}/${paths[$i]}")"
    for target_arch in $target_archs; do
      if ! [[ "${slice_variant}" == "$target_variant" ]]; then
        matched_all_archs="0"
        break
      fi

      if ! echo "${slice_archs}" | tr " " "\n" | grep -F -q -x "$target_arch"; then
        matched_all_archs="0"
        break
      fi
    done

    if [[ "$matched_all_archs" == "1" ]]; then
      # Found a matching slice
      echo "Selected xcframework slice ${paths[$i]}"
      SELECT_SLICE_RETVAL=${paths[$i]}
      break
    fi
  done
}

install_xcframework() {
  local basepath="$1"
  local name="$2"
  local package_type="$3"
  local paths=("${@:4}")

  # Locate the correct slice of the .xcframework for the current architectures
  select_slice "${basepath}" "${paths[@]}"
  local target_path="$SELECT_SLICE_RETVAL"
  if [[ -z "$target_path" ]]; then
    echo "warning: [CP] $(basename ${basepath}): Unable to find matching slice in '${paths[@]}' for the current build architectures ($ARCHS) and platform (${EFFECTIVE_PLATFORM_NAME-${PLATFORM_NAME}})."
    return
  fi
  local source="$basepath/$target_path"

  local destination="${PODS_XCFRAMEWORKS_BUILD_DIR}/${name}"

  if [ ! -d "$destination" ]; then
    mkdir -p "$destination"
  fi

  copy_dir "$source/" "$destination"
  echo "Copied $source to $destination"
}

install_xcframework "${PODS_ROOT}/Firstlight/Frameworks/FLAnalytics.xcframework" "Firstlight/FLAnalytics" "framework" "ios-arm64" "ios-arm64_x86_64-simulator"
install_xcframework "${PODS_ROOT}/Firstlight/Frameworks/FLBookmarks.xcframework" "Firstlight/FLBookmarks" "framework" "ios-arm64" "ios-arm64_x86_64-simulator"
install_xcframework "${PODS_ROOT}/Firstlight/Frameworks/FLContentAuthorizer.xcframework" "Firstlight/FLContentAuthorizer" "framework" "ios-arm64" "ios-arm64_x86_64-simulator"
install_xcframework "${PODS_ROOT}/Firstlight/Frameworks/FLFoundation.xcframework" "Firstlight/FLFoundation" "framework" "ios-arm64" "ios-arm64_x86_64-simulator"
install_xcframework "${PODS_ROOT}/Firstlight/Frameworks/FLHeartbeat.xcframework" "Firstlight/FLHeartbeat" "framework" "ios-arm64" "ios-arm64_x86_64-simulator"
install_xcframework "${PODS_ROOT}/Firstlight/Frameworks/FLPlatformCore.xcframework" "Firstlight/FLPlatformCore" "framework" "ios-arm64" "ios-arm64_x86_64-simulator"
install_xcframework "${PODS_ROOT}/Firstlight/Frameworks/FLPlatformPlayer.xcframework" "Firstlight/FLPlatformPlayer" "framework" "ios-arm64" "ios-arm64_x86_64-simulator"
install_xcframework "${PODS_ROOT}/Firstlight/Frameworks/FLPlayer.xcframework" "Firstlight/FLPlayer" "framework" "ios-arm64" "ios-arm64_x86_64-simulator"
install_xcframework "${PODS_ROOT}/Firstlight/Frameworks/FLPlayerInterface.xcframework" "Firstlight/FLPlayerInterface" "framework" "ios-arm64" "ios-arm64_x86_64-simulator"
install_xcframework "${PODS_ROOT}/Firstlight/Frameworks/FLStreamConcurrency.xcframework" "Firstlight/FLStreamConcurrency" "framework" "ios-arm64" "ios-arm64_x86_64-simulator"

