import pandas as pd

# Читаем файл
df = pd.read_excel(r'Docs/Translate/Копия Feedback dump.xlsx')

# Сохраняем отзывы в текстовый файл
with open(r'Docs/Translate/reviews_list.txt', 'w', encoding='utf-8') as f:
    for i, row in df.iterrows():
        f.write(f"{i}|{row['Date']}|{row['Review']}\n")

print(f"Сохранено {len(df)} отзывов")
