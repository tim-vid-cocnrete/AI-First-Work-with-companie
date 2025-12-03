# Руководство по Интеграции LLM
*[ШАБЛОН ДОКУМЕНТАЦИИ - Руководство по внедрению реальной AI оценки]*

Этот агент в настоящее время использует логику-заглушку для демонстрационных целей. Чтобы сделать его готовым к продакшену, вам нужно интегрировать его с реальной Большой Языковой Моделью (LLM).

## Опции Интеграции

### 1. Интеграция OpenAI GPT
```python
import openai

def evaluate_with_openai(prompt, candidate_data):
    client = openai.OpenAI(api_key="your-api-key")
    
    response = client.chat.completions.create(
        model="gpt-4",
        messages=[
            {"role": "system", "content": prompt},
            {"role": "user", "content": str(candidate_data)}
        ],
        temperature=0.1
    )
    
    return response.choices[0].message.content
```

### 2. Интеграция Anthropic Claude
```python
import anthropic

def evaluate_with_claude(prompt, candidate_data):
    client = anthropic.Anthropic(api_key="your-api-key")
    
    response = client.messages.create(
        model="claude-3-sonnet-20240229",
        max_tokens=2000,
        messages=[
            {"role": "user", "content": f"{prompt}\n\nCandidate Data:\n{candidate_data}"}
        ]
    )
    
    return response.content[0].text
```

### 3. Интеграция Локальной Модели (Ollama)
```python
import requests

def evaluate_with_ollama(prompt, candidate_data):
    response = requests.post('http://localhost:11434/api/generate',
        json={
            'model': 'llama2',
            'prompt': f"{prompt}\n\nCandidate Data:\n{candidate_data}",
            'stream': False
        })
    
    return response.json()['response']
```

## Шаги Внедрения

### Шаг 1: Замена Функций-Заглушек
В `agent.py` замените эти методы на реальные вызовы LLM:
- `_evaluate_critical_competency()`
- `_evaluate_competency()`
- `_generate_notes()`

### Шаг 2: Добавление Переменных Окружения
```bash
# .env file
OPENAI_API_KEY=your_openai_key
ANTHROPIC_API_KEY=your_anthropic_key
LLM_PROVIDER=openai  # или anthropic, ollama
```

### Шаг 3: Обновление Зависимостей
```bash
pip install openai anthropic python-dotenv
```

### Шаг 4: Внедрение Структурированного Вывода
Используйте LLM для возврата структурированного JSON для последовательного скоринга:

```python
evaluation_prompt = f"""
{self.prompt}

Пожалуйста, оцените этого кандидата и верните JSON ответ с:
{{
    "competencyScores": {{
        "SQL Proficiency": 1-5,
        "ETL Experience": 1-5,
        // ... другие компетенции
    }},
    "fitResult": "Strong Fit" | "Potential Fit" | "Weak Fit",
    "notes": "Детальное объяснение опасений или сильных сторон"
}}

Данные Кандидата: {candidate_data}
"""
```

## Соображения по Стоимости

### Оценки Использования Токенов:
- **OpenAI GPT-4:** ~$0.03-0.06 за оценку
- **Claude 3 Sonnet:** ~$0.015-0.03 за оценку
- **Локальные Модели:** Бесплатно после настройки

### Советы по Оптимизации:
1. Кэшируйте контекстные файлы, чтобы избежать повторной отправки
2. Используйте более дешевые модели для начального скрининга
3. Внедрите пакетную обработку для нескольких кандидатов
4. Установите лимиты токенов для контроля затрат

## Тестирование Вашей Интеграции

### Юнит-тесты:
```python
def test_llm_integration():
    agent = CandidateEvaluationAgent()
    test_candidate = {"files": {"CV.md": "Sample CV content"}}
    
    evaluation = agent.evaluate_candidate(test_candidate)
    
    assert "competencyScores" in evaluation
    assert evaluation["fitResult"] in ["Strong Fit", "Potential Fit", "Weak Fit"]
    assert isinstance(evaluation["notes"], str)
```

### Валидация:
1. Протестируйте на известных хороших/плохих кандидатах
2. Сравните результаты LLM с оценками человека
3. Отслеживайте последовательность через несколько запусков
4. Валидируйте структуру JSON и диапазоны оценок

## Соображения для Продакшена

### Обработка Ошибок:
```python
try:
    evaluation = evaluate_with_llm(prompt, candidate_data)
except Exception as e:
    logger.error(f"LLM evaluation failed: {e}")
    # Откат к оценке человеком или дефолтному скорингу
```

### Ограничение Скорости (Rate Limiting):
```python
import time
from functools import wraps

def rate_limit(calls_per_minute=60):
    def decorator(func):
        @wraps(func)
        def wrapper(*args, **kwargs):
            time.sleep(60 / calls_per_minute)
            return func(*args, **kwargs)
        return wrapper
    return decorator
```

### Безопасность:
- Храните API ключи безопасно (переменные окружения, менеджер секретов)
- Очищайте данные кандидатов перед отправкой во внешние API
- Внедрите аудит логгирование для всех вызовов LLM
- Учитывайте правила конфиденциальности данных (GDPR и т.д.)

---

*Это руководство предоставляет основу для внедрения реальной AI оценки. Выберите провайдера LLM, который лучше всего соответствует вашим техническим требованиям, бюджету и потребностям в конфиденциальности данных.*