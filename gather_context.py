import os
import re
from datetime import datetime

# ==========================================
# Настройки сборки
# ==========================================

# 1. Корневые файлы, которые обязательно нужны для контекста
IMPORTANT_ROOT_FILES = [
    'pubspec.yaml',
    'CHANGELOG.md',
    'README.md',
    'RULES.md',
    'STATE.md',
    'analysis_options.yaml'
]

# 2. Папки, из которых мы рекурсивно собираем исходный код
TARGET_DIRS = [
    'lib',
    'docs'
]

# 3. Исключения (папки и расширения, которые мы пропускаем)
IGNORE_DIRS = set(['.git', '.dart_tool', 'build', 'android', 'ios', 'web', 'windows', 'macos', 'linux', 'assets'])
IGNORE_EXTENSIONS = {'.png', '.jpg', '.jpeg', '.zip', '.tar', '.gz', '.mp3', '.mp4', '.sqlite', '.gpx', '.kml'}

def get_project_version():
    """Извлекает версию проекта из pubspec.yaml"""
    try:
        with open('pubspec.yaml', 'r', encoding='utf-8') as f:
            for line in f:
                if line.startswith('version:'):
                    # Ищет строку вида 'version: 1.16.15+1' и забирает '1.16.15'
                    match = re.search(r'version:\s*([^\s+]+)', line)
                    if match:
                        # Убираем часть билда (+1), если нужно оставить только саму версию
                        return match.group(1).split('+')[0]
    except FileNotFoundError:
        pass
    return 'unknown_version'

def collect_code():
    version = get_project_version()
    date_str = datetime.now().strftime('%Y%m%d_%H%M')
    # Формируем название с версией и датой
    output_filename = f'ParaFlight_snapshot_v{version}_{date_str}.txt'

    print(f"Начинаю сборку проекта ParaFlight (Версия: {version})...")

    with open(output_filename, 'w', encoding='utf-8') as outfile:
        outfile.write(f"=== Проект: ParaFlight ===\n")
        outfile.write(f"=== Версия: {version} ===\n")
        outfile.write(f"=== Дата генерации: {date_str} ===\n\n")

        # 1. Сбор корневых документов
        for fname in IMPORTANT_ROOT_FILES:
            if os.path.exists(fname):
                _write_file_content(outfile, fname)
            else:
                print(f"⚠️ Файл не найден и пропущен: {fname}")

        # 2. Сбор исходного кода
        for dname in TARGET_DIRS:
            if not os.path.exists(dname):
                continue
            
            for root, dirs, files in os.walk(dname):
                # Исключаем ненужные папки из обхода
                dirs[:] = [d for d in dirs if d not in IGNORE_DIRS]

                for file in files:
                    # Исключаем бинарники и медиафайлы
                    if any(file.lower().endswith(ext) for ext in IGNORE_EXTENSIONS):
                        continue
                    
                    filepath = os.path.join(root, file)
                    _write_file_content(outfile, filepath)

    print(f"✅ Готово! Слепок кода успешно сохранен в файл: {output_filename}")

def _write_file_content(outfile, filepath):
    """Форматированная запись содержимого файла в итоговый текстовик"""
    outfile.write(f"{'='*60}\n")
    outfile.write(f"📄 ФАЙЛ: {filepath}\n")
    outfile.write(f"{'='*60}\n")
    try:
        with open(filepath, 'r', encoding='utf-8') as infile:
            outfile.write(infile.read())
        outfile.write("\n\n")
    except Exception as e:
        outfile.write(f"[Ошибка чтения файла: {e}]\n\n")

if __name__ == '__main__':
    collect_code()