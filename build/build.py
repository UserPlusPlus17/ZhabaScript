#!/usr/bin/env python3
import os
import subprocess
from pathlib import Path

# Конфигурация проекта
CONFIG = {
    "name": "zhabak",
    "source_files": [
        "src/compiler/*.d",
        "src/lexer/*.d"
    ],
    "output": "zhabakNewSchool",
    "compiler": "dmd",
    "flags": ["-O", "-release"]
}

def build_project():
    sources = []
    for pattern in CONFIG["source_files"]:
        sources.extend(Path().glob(pattern))
    
    if not sources:
        print("Ошибка: исходные файлы не найдены!")
        return False
    
    cmd = [
        CONFIG["compiler"],
        *CONFIG["flags"],
        "-of" + CONFIG["output"],
        *map(str, sources)
    ]
    
    print("Сборка:", " ".join(cmd))
    result = subprocess.run(cmd)
    
    if result.returncode == 0:
        print(f"Успешно собрано: {CONFIG['output']}")
        return True
    return False

if __name__ == "__main__":
    if build_project():
        if os.name == 'posix':
            os.chmod(CONFIG["output"], 0o755)
    else:
        print("Сборка завершилась с ошибками")