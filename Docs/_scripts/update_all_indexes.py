"""
Universal Auto-Index Script for Docs/
Generates hierarchical README.md files for each configured folder.
Each README describes both FILES (from YAML metadata) and SUBFOLDERS at that level.

Usage: python Docs/_scripts/update_all_indexes.py
"""

import os
import re

# --- Configuration ---
DOCS_ROOT = os.path.normpath(os.path.join(os.path.dirname(__file__), ".."))

# Folders to auto-index (relative to DOCS_ROOT).
# Empty string "" = the Docs/ root itself.
AUTO_INDEX_DIRS = [
    "",             # Docs/ root
    "Marketing",
    "Core-check",
    "Process",
    "Product",
    "Strategy",
    "Translate",
    "Olds",
]

# Folders to SKIP when listing subfolders (they exist but are internal/utility)
SKIP_SUBFOLDERS = {"_scripts", ".git", "__pycache__", "node_modules"}

# Files to skip when listing
SKIP_FILES = {"README.md"}

# Subfolder descriptions (manual overrides for the root-level Docs/README.md)
# These are used when a subfolder's README doesn't exist yet or for the root level.
SUBFOLDER_DESCRIPTIONS = {
    "Marketing": "Маркетинговая аналитика: воронки, аватары, конкуренты, редполитика.",
    "Marketing_Roundtable": "AI-система симуляции маркетингового отдела (Агенты, Проекты, Архив).",
    "Product": "Описание продуктов (курсов) Kata Academy: программы, условия, гарантии.",
    "Process": "Бизнес-процессы: регламенты, скрипты продаж, воронки, интеграции.",
    "Strategy": "Стратегические документы: модели ценообразования, позиционирование.",
    "Core-check": "Правила и стандарты качества (Cursor Rules): auto, check, clean.",
    "Translate": "Скрипты и данные для перевода обратной связи (Feedback dump).",
    "Olds": "Архив устаревших файлов. Не использовать как источник данных.",
    "_scripts": "Служебные скрипты автоматизации (авто-индексация).",
    "_System": "Ядро системы: досье агентов и сценарии работы.",
    "_Supplemental": "Архив вспомогательных материалов (опросы, черновики).",
    "Projects": "Активные кампании и проекты.",
    "Archive": "Завершенные кампании.",
    "Agents": "Досье и промпты агентов Круглого Стола.",
    "Workflows": "Сценарии и пайплайны работы.",
    "Email_Examples": "Примеры email-рассылок.",
}


def parse_frontmatter(file_path):
    """Extracts YAML frontmatter from a markdown file."""
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            content = f.read()
    except (UnicodeDecodeError, FileNotFoundError):
        return None

    match = re.search(r'^---\s*\n(.*?)\n---', content, re.DOTALL)
    if not match:
        return None

    yaml_text = match.group(1)
    metadata = {}
    for line in yaml_text.split('\n'):
        if ':' in line:
            key, value = line.split(':', 1)
            metadata[key.strip()] = value.strip()
    return metadata


def get_subfolder_description(folder_name, folder_path):
    """Gets description for a subfolder: from its README or from manual overrides."""
    # Check manual overrides first
    if folder_name in SUBFOLDER_DESCRIPTIONS:
        return SUBFOLDER_DESCRIPTIONS[folder_name]

    # Try to extract from the subfolder's README.md
    readme_path = os.path.join(folder_path, "README.md")
    if os.path.exists(readme_path):
        try:
            with open(readme_path, 'r', encoding='utf-8') as f:
                for line in f:
                    line = line.strip()
                    # Look for lines starting with > **Назначение:**
                    if line.startswith("> **"):
                        # Extract the text after the first :** 
                        match = re.search(r'\*\*.*?\*\*\s*(.*)', line)
                        if match:
                            return match.group(1)
        except (UnicodeDecodeError, FileNotFoundError):
            pass

    return "No description available."


def generate_readme_for_dir(target_dir, dir_display_name):
    """Generates a README.md for a single directory."""
    readme_path = os.path.join(target_dir, "README.md")

    # Collect subfolders
    subfolders = []
    # Collect files
    files_by_category = {}

    for item in sorted(os.listdir(target_dir)):
        item_path = os.path.join(target_dir, item)

        if os.path.isdir(item_path):
            if item in SKIP_SUBFOLDERS:
                continue
            desc = get_subfolder_description(item, item_path)
            subfolders.append({"name": item, "description": desc})

        elif os.path.isfile(item_path) and item not in SKIP_FILES:
            # Only index known file types
            if not (item.endswith('.md') or item.endswith('.mdc')):
                # For non-markdown files, create a basic entry
                ext = os.path.splitext(item)[1]
                category = "Other Files"
                files_by_category.setdefault(category, []).append({
                    "filename": item,
                    "description": f"File ({ext})",
                    "owner": ""
                })
                continue

            metadata = parse_frontmatter(item_path)
            if not metadata:
                metadata = {
                    'description': 'No YAML metadata.',
                    'category': 'Uncategorized',
                    'owner': ''
                }

            category = metadata.get('category', 'Uncategorized')
            files_by_category.setdefault(category, []).append({
                "filename": item,
                "description": metadata.get('description', ''),
                "owner": metadata.get('owner', '')
            })

    # --- Build Markdown ---
    lines = []
    lines.append(f"# {dir_display_name}\n")
    lines.append(f"> **Статус:** Auto-Generated Index")
    lines.append(f"> **Script:** `Docs/_scripts/update_all_indexes.py`\n")
    lines.append("---\n")

    # Subfolders section
    if subfolders:
        lines.append("## Subfolders\n")
        for sf in subfolders:
            has_readme = os.path.exists(os.path.join(target_dir, sf['name'], 'README.md'))
            readme_marker = " *(has README)*" if has_readme else ""
            lines.append(f"### [{sf['name']}/]({sf['name']}/)")
            lines.append(f"*   {sf['description']}{readme_marker}\n")
        lines.append("---\n")

    # Files section
    if files_by_category:
        lines.append("## Files\n")
        # Custom sort order for known categories
        CATEGORY_ORDER = [
            "Strategy & Intelligence",
            "Consumer Insights",
            "Growth Mechanics",
            "Product Marketing",
            "Brand System",
            "Product",
            "Process",
            "Integrations",
            "Core Rules",
            "Strategy",
        ]
        sorted_cats = sorted(
            files_by_category.keys(),
            key=lambda x: (
                CATEGORY_ORDER.index(x) if x in CATEGORY_ORDER else 999,
                x
            )
        )
        for cat in sorted_cats:
            lines.append(f"### {cat}\n")
            for fd in files_by_category[cat]:
                lines.append(f"**[{fd['filename']}]({fd['filename']})**")
                lines.append(f"*   {fd['description']}")
                if fd['owner']:
                    lines.append(f"*   Owner: `{fd['owner']}`")
                lines.append("")

    lines.append("---")
    lines.append("*Auto-generated by `Docs/_scripts/update_all_indexes.py`*\n")

    with open(readme_path, 'w', encoding='utf-8') as f:
        f.write('\n'.join(lines))

    return readme_path


def main():
    results = []
    for rel_dir in AUTO_INDEX_DIRS:
        target = os.path.join(DOCS_ROOT, rel_dir) if rel_dir else DOCS_ROOT
        target = os.path.normpath(target)

        if not os.path.isdir(target):
            print(f"[SKIP] Directory not found: {target}")
            continue

        # Display name
        if rel_dir == "":
            display = "Docs/ — Knowledge Base Index"
        else:
            display = f"{rel_dir}/"

        readme = generate_readme_for_dir(target, display)
        results.append(readme)
        print(f"[OK] {readme}")

    print(f"\n[DONE] Updated {len(results)} README files.")


if __name__ == "__main__":
    main()
