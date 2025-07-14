#!/bin/bash

# =================================================================
# ClaudeCode向けプロンプト自動生成スクリプト (ピクセルパーフェクト / アイコンフォント)
# =================================================================

# サイトのルートディレクトリを指定
BASE_DIR="/Users/hattaryoga/Desktop/サイト作成/サイトスクショ/スクリーンショット手動"

# ★エラーが出たため、ここのパスを現在作業中のディレクトリに合わせてください
# エラーログから判断すると、おそらく以下のパスが正しいです。
BASE_DIR="/Users/hattaryoga/Downloads/サイトテンプレ/datsumo-osusume-guide.comのコピー/サイト分割"


echo "プロンプト生成を開始します... (モード: ピクセルパーフェクト / アイコンフォント)"
echo "対象ディレクトリ: ${BASE_DIR}"
echo "----------------------------------------"

# [2-8]_ で始まるフォルダをループ処理
for section_dir in "${BASE_DIR}"/[2-8]_*/; do
    # ディレクトリが存在するかチェック
    if [ ! -d "${section_dir}" ]; then
        continue
    fi

    # --- 基本的なパスと名前を定義 ---
    section_name=$(basename "${section_dir}")
    cc_dir="${section_dir}CC作成"
    ref_dir="${section_dir}参考"
    prompt_file="${cc_dir}/prompt.yaml"

    echo "処理中: ${section_name}"

    # --- 必要なフォルダの存在チェック ---
    if [ ! -d "${cc_dir}" ] || [ ! -d "${ref_dir}" ]; then
        # フォルダがない場合は自動作成するよう改良
        mkdir -p "${cc_dir}"
        mkdir -p "${ref_dir}"
        echo "  [情報] 'CC作成' または '参考' フォルダがなかったため自動生成しました。"
    fi

    # --- PNGファイルを検索し、作成日時が古い順にソートして配列に格納 ---
    image_paths=()
    while IFS= read -r file; do
        if [ -n "$file" ]; then
            image_paths+=("$file")
        fi
    done < <(find "${ref_dir}" -maxdepth 1 -type f \( -name "*.png" -o -name "*.PNG" \) -print0 2>/dev/null | xargs -0 stat -f "%m %N" | sort -n | cut -d' ' -f2-)

    if [ ${#image_paths[@]} -eq 0 ]; then
        echo "  [警告] '参考' フォルダ内にスクリーンショット(.png)が見つかりません。スキップします。"
        continue
    fi
    
    # --- YAMLの input_materials セクションを動的に生成 ---
    input_materials_yaml=""
    for path in "${image_paths[@]}"; do
        input_materials_yaml+=$(printf '\n    - type: "Screenshot Image"\n      description: "再現対象のデザインを示すスクリーンショット。時系列順に並んでいます。"\n      file_path: "%s"' "$path")
    done
    
    component_name=$(echo "${section_name}" | sed -E 's/^[0-9]+_//')

    # --- コンポーネントごとの特別指示を生成 ---
    special_instructions=""
    case "${section_name}" in
        "4_Tips"*)
            special_instructions="【UI実装指示】: このコンポーネントは、複数のスクリーンショットを**タブ切り替え**UIとして実装してください。各タブがそれぞれの画像に対応します。"
            ;;
        "5_比較表"*)
            special_instructions="【UI実装指示】: このコンポーネントは、複数のスクリーンショットを**横スライド（カルーセル）**UIとして実装してください。左右の矢印や下部のドットナビゲーションもつけてください。"
            ;;
        "6_詳細コンテンツ"* | "7_コラム"*)
            special_instructions="【UI実装指示】: このコンポーネントは、複数のスクリーンショットを**縦に連続した1つの長いセクション**として実装してください。上の画像がコンテンツの上部、下の画像がその続きです。"
            ;;
    esac
    
    output_filename=$(echo "${section_name}" | sed -E 's/ /_/g' | tr '[:upper:]' '[:lower:]')".html"
    output_filepath="${cc_dir}/${output_filename}"

    # --- プロンプト本体の生成 ---
    cat > "${prompt_file}" <<EOF
# ===============================================================
#  Webサイトコンポーネント生成指示書 (ピクセルパーフェクト / アイコンフォント)
# ===============================================================

# 1. あなたの役割と使命 (Your Role and Mission)
# ---------------------------------------------------------------
# あなたは、与えられたデザインカンプ（スクリーンショット）を1ピクセル単位で忠実に再現することを使命とする、熟練のフロントエンドエンジニアAIです。
# あなたの仕事は、UXデザインを提案することではありません。スクリーンショットという絶対的な指示を、寸分違わずコードに翻訳することです。

# 2. タスク定義 (Task Definition)
# ---------------------------------------------------------------
task_definition:
  title: "【SP版デザインの完全再現】スクリーンショットからのHTML/CSS化"
  objective: "提供された【スマートフォン表示（375px）】のスクリーンショットを**完全に、見たままに**再現するHTML/CSSコードを生成する。"
  component_name: "${component_name}"

# 3. デザイン再現に関する厳格なルール (Strict Rules for Design Reproduction)
# ---------------------------------------------------------------
# このセクションのルールは、他のどの指示よりも優先されます。
design_replication_rules:
  - "【絶対的な正解】: スクリーンショットは、完成形のデザインカンプです。提案ではなく、絶対的な指示と捉えてください。"
  - "【横並びレイアウトの維持】: **最重要ルールです。** スクリーンショット内で要素が横並び（例: 2カラム）の場合、スマートフォン表示（375px）でもその横並びを**絶対に維持**してください。AIの判断で縦積みに変更することは**固く禁止**します。"
  - "【レスポンシブの適用範囲】: レスポンシブ対応とは、主にPC表示（768px以上）でレイアウトを最適化することを指します。**スマートフォン表示（375px）は、スクリーンショットの完全なコピーでなければなりません。**"

# 4. 入力資材 (Input Materials)
# ---------------------------------------------------------------
input_materials:${input_materials_yaml}

# 5. 出力仕様 (Output Specifications)
# ---------------------------------------------------------------
output_specifications:
  file_format: "単一のHTMLファイル"
  structure: "HTMLファイル内に<style>タグでCSSを記述し、<script>タグでJavaScriptを記述する形式。"
  output_filepath: "${output_filepath}"
  technologies:
    - "HTML5"
    - "CSS3 (Flexbox/Grid)"
    - "JavaScript (ES6+)"
    - "Font Awesome 6 (via CDN for web icons)"
  requirements:
    # ▼▼▼▼▼【ここを修正しました】▼▼▼▼▼
    # バッククォート(`)をシングルクォート(')に変更し、Bashに誤解されないようにしました。
    - "【Webアイコンフォントの使用】: スクリーンショット内に絵文字（例: ✅, ➡️, 👑）が見られる場合、それらを直接テキストとして使用するのではなく、**Font Awesome 6**のアイコンに置き換えること。HTMLの'<head>'内に下記のCDNリンクを追加し、適切な'<i>'タグ（例: '<i class=\"fas fa-check-circle\"></i>'）でアイコンを実装すること。\n      <link rel=\"stylesheet\" href=\"https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.2/css/all.min.css\">"
    # ▲▲▲▲▲【ここまで修正しました】▲▲▲▲▲
    - "【その他】: テキスト抽出、画像プレースホルダーの使用など、基本的な要件は遵守すること。"

# 6. 実行指示 (Execution Instructions)
# ---------------------------------------------------------------
instructions: >
  上記の指示書全体を精査し、タスクを実行してください。

  特に、セクション3の**「デザイン再現に関する厳格なルール」を最優先かつ厳格に守ってください。**
  スクリーンショットはスマートフォン（375px）のデザインです。この見た目を、あなたの解釈を一切加えずに、そのままコード化してください。
  また、絵文字は必ず Font Awesome アイコンに置き換えてください。

  ${special_instructions}

  最終的な成果物は、単一のコードブロックで提供し、'output_filepath' に指定されたパスにファイルとして保存してください。
EOF

    echo "  [成功] '${prompt_file}' を動的に生成しました。"
    if [ -n "$special_instructions" ]; then
        echo "    - 特別指示を追加しました。"
    fi
    echo "    - 参照画像数: ${#image_paths[@]}"
    echo "    - 出力先: ${output_filepath}"

done

echo "----------------------------------------"
echo "全てのプロンプト生成が完了しました。"