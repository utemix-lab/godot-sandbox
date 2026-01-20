# utemix-godot-sandbox

Godot 4.2 sandbox для тестирования контрактов workspace в режиме **Visitor**.

## Требования

- [Godot 4.2+](https://godotengine.org/download)
- [utemix-workspace](https://github.com/utemix-lab/utemix-workspace) (соседняя папка)

## Быстрый старт

### 1. Клонируйте оба репозитория рядом

```bash
cd ~/projects
git clone https://github.com/utemix-lab/utemix-workspace.git
git clone https://github.com/utemix-lab/utemix-godot-sandbox.git
```

Структура должна быть:
```
projects/
├── utemix-workspace/
│   └── contracts/public/...
└── utemix-godot-sandbox/
    └── project.godot
```

### 2. Откройте проект в Godot

1. Запустите Godot
2. Import → выберите `utemix-godot-sandbox/project.godot`
3. Нажмите **Play** (F5)

### 3. Что должно работать

При запуске:
1. ✅ Контракты загружаются из workspace
2. ✅ Отображаются 3 панели: Story / System / Service
3. ✅ Начальный шаг route graph показан
4. ✅ Кнопки навигации (← / →) переключают шаги
5. ✅ Клики по refs и actions логируются в консоль

## Структура

```
utemix-godot-sandbox/
├── project.godot
├── scenes/
│   └── Main.tscn           # Главная сцена
├── scripts/
│   ├── app_state.gd        # Глобальное состояние (autoload)
│   ├── contracts_loader.gd # Загрузка JSON контрактов (autoload)
│   ├── interaction_runtime.gd # Обработка событий (autoload)
│   └── main.gd             # Контроллер главной сцены
├── ui/panels/
│   ├── StoryPanel.tscn     # Панель Story
│   ├── SystemPanel.tscn    # Панель System
│   └── ServicePanel.tscn   # Панель Service
└── config/
    ├── local_paths.example.json  # Пример конфига
    └── local_paths.json          # Ваш локальный конфиг (не коммитится)
```

## Autoloads

| Singleton | Описание |
|-----------|----------|
| `AppState` | Хранит текущее состояние (step, panels, route graph) |
| `ContractsLoader` | Загружает JSON из workspace |
| `InteractionRuntime` | Обрабатывает события по правилам из interaction.json |

## Подключение workspace

По умолчанию sandbox ищет workspace по пути:
```
../utemix-workspace/contracts/public/
```

Если workspace в другом месте, создайте `config/local_paths.json`:
```json
{
  "workspace_path": "/absolute/path/to/utemix-workspace/contracts/public"
}
```

## Загружаемые контракты

| Контракт | Описание |
|----------|----------|
| `ui/layout/visitor.layout.json` | Расположение панелей |
| `ui/interaction/visitor.interaction.json` | Правила событий |
| `ui/bindings/visitor.bindings.json` | Связи элемент → ассет |
| `routes/demo/visitor.demo.route.json` | Демо-маршрут |
| `sessions/demo/visitor.demo.session.json` | Состояние сессии |

## Горячие клавиши

| Клавиша | Действие |
|---------|----------|
| `←` | Предыдущий шаг |
| `→` | Следующий шаг |
| `Esc` | Сбросить выделение |

## Разработка

### Добавление нового эффекта

1. Добавьте правило в `visitor.interaction.json`:
```json
{
  "id": "my-rule",
  "trigger": { "event": "click", "target": { "type": "my-element" } },
  "effects": [
    { "type": "my-effect", "param": "value" }
  ]
}
```

2. Реализуйте обработчик в `interaction_runtime.gd`:
```gdscript
func _execute_effect(effect: Dictionary) -> void:
    match effect.get("type"):
        "my-effect":
            _effect_my_effect(effect)

func _effect_my_effect(effect: Dictionary) -> void:
    var param = effect.get("param", "")
    # Ваша логика
```

### Тестирование без workspace

Создайте тестовые JSON файлы в `res://test_contracts/` и измените путь в `contracts_loader.gd`.

## Roadmap

- [ ] Визуализация графа (Cytoscape-like)
- [ ] Highlight эффекты
- [ ] Tooltips
- [ ] Мобильный layout
- [ ] Загрузка ассетов (иконки, фоны)
- [ ] Звуковые эффекты

## Связанные репозитории

- [utemix-contracts](https://github.com/utemix-lab/utemix-contracts) — контракты и ассеты
- [extended-mind](https://github.com/utemix-lab/extended-mind) — редактор Route Graph
- [vovaipetrova-core](https://github.com/utemix-lab/vovaipetrova-core) — целевая витрина
