# godot-sandbox

**Инструмент режиссуры** — Godot 4.2 sandbox для UI-сценографии.

---

## Роль в экосистеме

| | |
|---|---|
| **Слой** | Режиссура (опциональный) |
| **Функция** | Визуальное редактирование маршрутов, поиск UI-паттернов |
| **Входы** | universe.json из contracts |
| **Выходы** | Паттерны поведения UI → применяются в dream-graph |

```
extended-mind (редактор) → universe.json → godot-sandbox → dream-graph
                                              ↑
                                    "Строительные леса"
```

> **Статус:** Строительные леса — убираются когда паттерны UI найдены.
> dream-graph может работать напрямую с universe.json без Godot.

---

## Требования

- [Godot 4.2+](https://godotengine.org/download)
- [contracts](https://github.com/utemix-lab/contracts) (соседняя папка)

---

## Быстрый старт

### 1. Клонируйте оба репозитория рядом

```bash
cd ~/projects
git clone https://github.com/utemix-lab/contracts.git
git clone https://github.com/utemix-lab/godot-sandbox.git
```

Структура:
```
projects/
├── contracts/
│   └── contracts/public/...
└── godot-sandbox/
    └── project.godot
```

### 2. Откройте проект в Godot

1. Запустите Godot
2. Import → выберите `godot-sandbox/project.godot`
3. Нажмите **Play** (F5)

### 3. Что должно работать

- ✅ Universe Graph загружается из contracts
- ✅ Отображаются 3 панели: Story / System / Service
- ✅ Навигация по узлам графа
- ✅ Выбор узла обновляет панели

---

## Структура

```
godot-sandbox/
├── project.godot
├── scenes/
│   └── Main.tscn           # Главная сцена
├── scripts/
│   ├── app_state.gd        # Глобальное состояние
│   ├── contracts_loader.gd # Загрузка JSON
│   ├── graph_editor.gd     # 2D редактор графа
│   └── main.gd             # Контроллер
└── ui/panels/
    ├── StoryPanel.tscn     # Панель Story
    ├── SystemPanel.tscn    # Панель System
    └── ServicePanel.tscn   # Панель Service
```

---

## Горячие клавиши

| Клавиша | Действие |
|---------|----------|
| F5 | Запуск сцены |
| ← | Предыдущий узел |
| → | Следующий узел |
| Esc | Сбросить выделение |

---

## Зачем нужен Godot?

1. **Визуальная навигация** — видеть граф целиком
2. **Поиск паттернов** — какие UI-действия нужны
3. **Быстрое прототипирование** — до внедрения в dream-graph

Когда паттерны найдены и реализованы в dream-graph, Godot можно убрать из цепочки.

---

## Связанные репозитории

| Репозиторий | Роль | Статус |
|-------------|------|--------|
| **extended-mind** | Канон, документация | Активный |
| **contracts** | Данные, ассеты | Активный |
| **dream-graph** | Витрина — финальный рендер | Активный |
| **utemix-lab** | Координация | Активный |

---

## Лицензия

MIT © utemix-lab
