.PHONY: \
	run icon

# flutterをローカルのサーバーに繋がるように実行
run:
	flutter run --release --dart-define-from-file=lib/config/dev.json

# アプリにアイコンを設定する
# ※生成される画像の大きさが誤っている場合があります
icon:
	flutter pub run flutter_launcher_icons
