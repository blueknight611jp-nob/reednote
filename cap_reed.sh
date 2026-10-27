#!/bin/bash

# 保存先ディレクトリ
SAVE_DIR="/Volumes/Free/reednote/images"
mkdir -p "$SAVE_DIR"

# タイムスタンプとファイル名設定
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
TEMP_RAW="/tmp/raw_${TIMESTAMP}.jpg"
OUTPUT_FILE="${SAVE_DIR}/reed_${TIMESTAMP}.jpg"

# 書画カメラで撮影（ウォームアップ1秒）
# ※ 書画カメラのデバイス名は `imagesnap -l` で確認した名称を設定
/opt/homebrew/bin/imagesnap -d "USBカメラ" -w 1.0 "$TEMP_RAW"

# ImageMagickでリード中心部を自動切り出し（サイズや切り出し位置は適宜調整）
/opt/homebrew/bin/magick "$TEMP_RAW" -rotate 90 -gravity Center -crop "1200x1800+0+0" +repage "$OUTPUT_FILE"

# 一時ファイルを削除
rm "$TEMP_RAW"

echo "Saved: $OUTPUT_FILE"

