#!/bin/bash

# ==============================================================================
# 【最終改善版・SP対応強化】<iframe> を利用したHTML統合ビュースクリプト
#
# 変更点:
# - SP表示切替時の高さ再計算に対応するため、親ウィンドウのリサイズも監視。
# ==============================================================================

OUTPUT_FILE="integrated_view.html"
FOLDER_PATTERN="[0-9]*_*"

# --- ビューワーHTMLの基本部分を生成 ---
cat <<'EOL' > "$OUTPUT_FILE"
<!DOCTYPE html>
<html lang="ja">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>コンポーネント統合ビュー (最終改善版・SP対応)</title>
    <style>
        body { font-family: sans-serif; margin: 0; background-color: #f0f2f5; }
        .component-wrapper {
        margin: 0 auto;
        max-width: 1200px;
        iframe {
            width: 100%;
            border: none;
            display: block;
            vertical-align: bottom;
            background-color: #fff;
            transition: height 0.2s ease-in-out;
        }
    </style>
    <script>
        // 全てのiframe要素を格納する配列
        const allIframes = [];

        // iframeの高さを更新するコアな関数
        function updateIframeHeight(iframe) {
            try {
                const contentHeight = iframe.contentWindow.document.documentElement.scrollHeight;
                if (contentHeight > 0 && iframe.style.height !== contentHeight + 'px') {
                    iframe.style.height = contentHeight + 'px';
                    console.log(`[${iframe.title}] 高さを更新: ${contentHeight}px`);
                }
            } catch (e) {
                console.error(`[${iframe.title}] 高さの更新中にエラーが発生しました。`, e);
            }
        }

        // iframeの初期設定と監視を行う関数
        function setupIframe(iframe) {
            console.log(`[${iframe.title}] onloadイベント発生。監視をセットアップします。`);
            
            // 全てのiframeをリストに追加
            allIframes.push(iframe);
            
            try {
                const targetDocument = iframe.contentWindow.document;
                const targetElement = targetDocument.body;

                // 1. iframe内部のサイズ変更を監視
                const observer = new ResizeObserver(() => {
                    updateIframeHeight(iframe);
                });
                observer.observe(targetElement);

                // 2. 初期読み込み時の高さを設定
                updateIframeHeight(iframe);

            } catch (e) {
                console.error(`[${iframe.title}] 監視のセットアップ中にエラーが発生しました。`, e);
            }
        }

        // 3. 親ウィンドウ（ブラウザ）のサイズ変更を監視
        window.addEventListener('resize', () => {
            console.log('--- ウィンドウリサイズ検知 --- 全てのiframeの高さを再計算します ---');
            // 簡素化のため、少し待ってから全iframeの高さを更新
            setTimeout(() => {
                allIframes.forEach(iframe => {
                    updateIframeHeight(iframe);
                });
            }, 300); // 0.3秒待ってから実行
        });
    </script>
</head>
<body>
EOL

echo "統合ビューの生成を開始します..."

# --- 各コンポーネントフォルダをループ処理 ---
for dir in $(ls -d ${FOLDER_PATTERN}/ 2>/dev/null | sort -V); do
    dir_name=$(basename "$dir")
    echo "■ 処理中: ${dir_name}"

    prefix=$(echo "${dir_name}" | cut -d'_' -f1)
    html_file_path=$(find "${dir}" -maxdepth 1 -type f -iname "${prefix}_*.html" -print -quit)

    if [ -z "$html_file_path" ]; then
        echo "  -> スキップ: ${dir} 内に '${prefix}_*.html' が見つかりません。"
        continue
    fi
    
    echo "  -> 参照ファイルを追加: ${html_file_path}"

    cat <<EOT >> "$OUTPUT_FILE"

<!-- Component: ${dir_name} -->
<div class="component-wrapper">
    <iframe src="${html_file_path}" onload="setupIframe(this)" title="${dir_name}"></iframe>
</div>
EOT
done

echo "</body></html>" >> "$OUTPUT_FILE"

echo "----------------------------------------"
echo "✅ 統合ビューの生成が完了しました！"
echo "次にローカルサーバーを起動して確認してください。"
echo "----------------------------------------"