# coding: utf-8

# Загружает файлы на сервера Telegram и отправляет сообщение в чат с файлами и текстом.
# Берегись! Много говнокода. Я быренько набросал этот файл, ибо мне было лень разбираться с argparse :D
#
# Пример использования:
# - python main.py 1234567890:tokenabcdefg 1234567890 1.2.3 true /path/to/file1.apk /path/to/file2.apk

import json
import os
import sys

import requests


token = sys.argv[1].strip()
chat_id = int(sys.argv[2])
version = sys.argv[3].strip()
is_beta = sys.argv[4].lower().strip() in ("true", "1", "yes")
files = [i.strip() for i in sys.argv[5:]]

github_url = "https://github.com/Zensonaton/FlutterVK/releases/tag/v" + version
info_text = (
	f" • <b>Версия</b>: v{version}.\n"
	f" • <b>Список изменений</b>: <a href=\"{github_url}\">🔗 Github</a>.\n"
)

text = (
	f"<b>🪲 Flutter VK v{version} (бета)</b>. #Beta\n"
	 "\n"
	f"{info_text}"
	 "\n"
	 "⚠️ В бета-билдах приложения могут быть баги.\n"
	 "Бета-версии предназначены только для продвинутых пользователей.\n"
) if is_beta else (
	f"<b>💫 Flutter VK v{version}</b>. #Release\n"
	 "\n"
	f"{info_text}"
)

def main():
	print(f"Args: {sys.argv}")

	media = []
	files_data = {}
	for i, file_path in enumerate(files):
		base = {
			"parse_mode": "HTML",
			"type": "document",
			"media": f"attach://file{i}",
		}
		if i == len(files) - 1:
			base["caption"] = text

		media.append(base)

		files_data[f"file{i}"] = (os.path.basename(file_path), open(file_path, "rb"))


	response = requests.post(
		f"https://api.telegram.org/bot{token}/sendMediaGroup",
		data={
			"chat_id": chat_id,
			"media": json.dumps(media),
		},
		files=files_data
	)
	assert response.status_code == 200, response.text

	for file in files_data.values():
		file[1].close()


if __name__ == "__main__":
	main()
