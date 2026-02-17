import pandas as pd

# Словарь переводов
translations = {
    "I finally met someone who shares my niche hobbies. The matching algorithm actually feels personal and thoughtful. Truly the best dating experience yet.": 
        "Наконец-то я встретил человека, который разделяет мои нишевые хобби. Алгоритм подбора действительно кажется персональным и продуманным. По-настоящему лучший опыт знакомств.",
    
    "This app is a total scam. Profiles are clearly bots and they just want you to pay for useless premium features. Avoid this.": 
        "Это приложение — полное мошенничество. Профили явно боты, и они просто хотят, чтобы вы платили за бесполезные премиум-функции. Избегайте этого.",
    
    "It is an okay app. Not many people in my rural area, but the interface is clean and it doesn't crash often.": 
        "Приложение неплохое. В моём сельском районе не так много людей, но интерфейс чистый и оно редко вылетает.",
    
    "I love the interface! Could you add a filter for specific interests like \"hiking\" or \"gaming\" to make finding matches easier?": 
        "Мне нравится интерфейс! Не могли бы вы добавить фильтр по конкретным интересам, например «походы» или «игры», чтобы было проще находить пары?",
    
    "Incredible experience so far. I've gone on three great dates this week alone. The verification process makes me feel much safer.": 
        "Пока невероятный опыт. Только за эту неделю у меня было три отличных свидания. Процесс верификации даёт мне чувство большей безопасности.",
    
    "Constant glitches. The app freezes every time I try to send a message. It is impossible to actually talk to anyone here.": 
        "Постоянные сбои. Приложение зависает каждый раз, когда я пытаюсь отправить сообщение. Здесь невозможно нормально ни с кем поговорить.",
    
    "Pretty standard dating app. Some good profiles, some bad ones. It works as advertised but doesn't really stand out from the others.": 
        "Довольно стандартное приложение для знакомств. Есть хорошие профили, есть плохие. Работает как заявлено, но особо не выделяется среди других.",
    
    "Met my current partner here! The prompts really help break the ice and start meaningful conversations. Highly recommend this to everyone.": 
        "Познакомился здесь со своим нынешним партнёром! Подсказки действительно помогают сломать лёд и начать содержательные разговоры. Очень рекомендую всем.",
    
    "The subscription price is way too high for what you get. Most \"likes\" I receive are from people thousands of miles away.": 
        "Цена подписки слишком высока за то, что вы получаете. Большинство «лайков», которые я получаю, от людей за тысячи миль.",
    
    "It would be great if we could see who liked us without paying for the full gold tier. Maybe a daily preview?": 
        "Было бы здорово, если бы мы могли видеть, кто нас лайкнул, без оплаты полного золотого уровня. Может, ежедневный предпросмотр?",
    
    "Best UI of any dating app I have used. Everything is smooth and the dark mode looks fantastic. Very happy with it.": 
        "Лучший интерфейс из всех приложений для знакомств, которыми я пользовался. Всё плавно, и тёмный режим выглядит фантастически. Очень доволен.",
    
    "I got banned for no reason and support won't answer my emails. I paid for a month and now I'm locked out.": 
        "Меня забанили без причины, и поддержка не отвечает на мои письма. Я заплатил за месяц, а теперь меня заблокировали.",
    
    "It's fine, but I wish there were more active users in my city. It feels a bit quiet lately compared to last year.": 
        "Всё нормально, но хотелось бы больше активных пользователей в моём городе. В последнее время здесь как-то тихо по сравнению с прошлым годом.",
    
    "Super easy to set up. I appreciate how quickly I was able to verify my profile and start swiping. Great job!": 
        "Очень легко настроить. Я ценю, как быстро я смог верифицировать свой профиль и начать свайпить. Отличная работа!",
    
    "Too many ads. Every three swipes I have to watch a video. It ruins the flow and makes it frustrating to use.": 
        "Слишком много рекламы. Каждые три свайпа я должен смотреть видео. Это портит процесс и раздражает при использовании.",
    
    "Please add a \"travel mode\" so I can see people in the city I am visiting next week. That would be helpful.": 
        "Пожалуйста, добавьте «режим путешествия», чтобы я мог видеть людей в городе, который посещу на следующей неделе. Это было бы полезно.",
    
    "Finally a dating app that doesn't feel like a chore. The daily picks are actually relevant to my preferences. Great work!": 
        "Наконец-то приложение для знакомств, которое не кажется рутиной. Ежедневные подборки действительно соответствуют моим предпочтениям. Отличная работа!",
    
    "The location tracking is way off. It says people are 5 miles away when they are actually in a different state. Fix this.": 
        "Отслеживание местоположения совершенно неточное. Показывает, что люди в 5 милях, хотя они на самом деле в другом штате. Исправьте это.",
    
    "Just joined yesterday. Seems decent so far, though I haven't had any matches yet. Let's see how the week goes.": 
        "Только вчера зарегистрировался. Пока кажется нормальным, хотя у меня ещё нет совпадений. Посмотрим, как пройдёт неделя.",
    
    "I really enjoy the voice note feature. It makes the profiles feel more human and real. Five stars for sure!": 
        "Мне очень нравится функция голосовых заметок. Она делает профили более человечными и настоящими. Определённо пять звёзд!",
}

# Читаем исходный файл
df = pd.read_excel(r'Docs/Translate/Копия Feedback dump.xlsx')

# Переименовываем колонки на русский
df.columns = ['Дата', 'Отзыв']

# Функция для перевода
def translate_text(text):
    if pd.isna(text):
        return text
    # Очищаем текст от возможных проблем с кодировкой
    text_clean = text.replace("'", "'").replace("'", "'")
    # Ищем перевод в словаре
    for eng, rus in translations.items():
        eng_clean = eng.replace("'", "'").replace("'", "'")
        if eng_clean in text_clean or text_clean in eng_clean:
            return rus
    return text  # Если перевод не найден, возвращаем оригинал

# Применяем перевод
df['Отзыв'] = df['Отзыв'].apply(translate_text)

# Сохраняем переведённый файл
output_path = r'Docs/Translate/Feedback_dump_RU.xlsx'
df.to_excel(output_path, index=False)

print(f"Файл успешно переведён и сохранён: {output_path}")
print(f"Всего строк: {len(df)}")
