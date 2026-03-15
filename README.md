# Ballegram 📱📸

**Ballegram** — это амбициозный проект по созданию гибридной социальной платформы, которая объединяет скорость и приватность мессенджера (как Telegram) с визуальным вовлечением социальной сети (как Instagram). Весь бэкенд разработан на **Ballerina**, что позволяет использовать её возможности для облачной разработки и конкурентной обработки сетевых запросов.

## 🚀 Видение

*   **Основа:** Легковесный мессенджер в реальном времени.
*   **Социальная часть:** Публичная лента для обмена фотографиями и историями.
*   **Цель:** Высокая производительность, безопасность типов и бесшовная сетевая интеграция, предоставляемые Ballerina.

## 🛠 Технологический стек

*   **Язык:** [Ballerina](https://ballerina.io/) (Swan Lake)
*   **База данных:** PostgreSQL (основные реляционные данные)
*   **Кеширование и Pub/Sub:** Redis (управление сессиями, распределение WebSocket)
*   **Объектное хранилище:** S3 / MinIO (изображения, видео)
*   **Контейнеризация:** Docker и Kubernetes

## 📂 Структура проекта

Мы используем архитектуру **модульного монолита**. Это позволяет нам разделять предметные области, развертывая при этом единый бинарный файл (на начальном этапе).

```text
ballegram/
├── Ballerina.toml          # Конфигурация проекта
├── Config.toml             # Переменные окружения
├── modules/                # Логика предметных областей
│   ├── auth/               # Регистрация пользователей, выдача JWT
│   ├── chat/               # Логика обмена сообщениями, обработка WebSocket
│   ├── social/             # Лента, посты, взаимодействия
│   ├── media/              # Обработка загрузки/скачивания в S3
│   └── common/             # Общие типы, ошибки, клиент БД
├── service/                # Точки входа (слушатели HTTP/GraphQL/WebSocket)
│   ├── api_service.bal     # Основной HTTP API
│   └── chat_service.bal    # Слушатель WebSocket
├── tests/                  # Интеграционные тесты
└── docker/                 # Настройка инфраструктуры (Postgres, Redis)
```

## 💾 Схема базы данных (PostgreSQL)

База данных спроектирована для поддержки как высоконагруженного обмена сообщениями, так и реляционных социальных данных.

### Пользователи и Аутентификация
*   **`users`**
    *   `id` (UUID, PK)
    *   `username` (VARCHAR, Уникальный)
    *   `email` (VARCHAR, Уникальный)
    *   `password_hash` (VARCHAR)
    *   `avatar_url` (VARCHAR, Nullable)
    *   `bio` (TEXT, Nullable)
    *   `created_at` (TIMESTAMP)

*   **`follows`**
    *   `follower_id` (UUID, FK -> users.id)
    *   `following_id` (UUID, FK -> users.id)
    *   *PK: (follower_id, following_id)*

### Обмен сообщениями (подобно Telegram)
*   **`chats`**
    *   `id` (UUID, PK)
    *   `type` (ENUM: 'DIRECT', 'GROUP')
    *   `created_at` (TIMESTAMP)
    *   `updated_at` (TIMESTAMP) -- используется для сортировки списка чатов

*   **`chat_participants`**
    *   `chat_id` (UUID, FK -> chats.id)
    *   `user_id` (UUID, FK -> users.id)
    *   `role` (ENUM: 'ADMIN', 'MEMBER')
    *   *PK: (chat_id, user_id)*

*   **`messages`**
    *   `id` (BIGSERIAL или TSID, PK)
    *   `chat_id` (UUID, FK -> chats.id)
    *   `sender_id` (UUID, FK -> users.id)
    *   `content` (TEXT)
    *   `media_url` (VARCHAR, Nullable)
    *   `created_at` (TIMESTAMP)
    *   `is_read` (BOOLEAN)

### Социальная лента (подобно Instagram)
*   **`posts`**
    *   `id` (UUID, PK)
    *   `user_id` (UUID, FK -> users.id)
    *   `caption` (TEXT)
    *   `media_urls` (JSONB) -- Массив URL изображений
    *   `created_at` (TIMESTAMP)

*   **`likes`**
    *   `post_id` (UUID, FK -> posts.id)
    *   `user_id` (UUID, FK -> users.id)
    *   *PK: (post_id, user_id)*

*   **`comments`**
    *   `id` (UUID, PK)
    *   `post_id` (UUID, FK -> posts.id)
    *   `user_id` (UUID, FK -> users.id)
    *   `content` (TEXT)
    *   `created_at` (TIMESTAMP)

## 🧪 Стратегия тестирования (Без клиента)

Поскольку фронтенд еще не разработан, мы проверяем бэкенд с использованием **тестирования на основе контрактов**:

1.  **Модульные тесты:** Внутри каждого модуля Ballerina.
2.  **Интеграционные тесты:** Использование тестового набора Ballerina для запуска сервисов и проверки эндпоинтов.
3.  **Симуляция API:**
    *   **HTTP**: Скрипты `curl` или коллекции Postman/Bruno.
    *   **WebSockets**: Использование `wscat` или простого скрипта WebSocket клиента на Ballerina для симуляции трафика чата.

## 🚀 Быстрый старт

1.  Запустите инфраструктуру: `docker-compose up -d`
2.  Выполните миграцию: `bal run modules/db_migration`
3.  Запустите сервер: `bal run`
