# Спецификация API и клиентов Ballegram

Данный документ описывает спецификации для реализации клиентских приложений (фронтенд, мобильные клиенты) для работы с бэкендом Ballegram.

## 1. Общие сведения

*   **Базовый URL:** Зависит от окружения развертывания (например, `http://localhost:9090`).
*   **Формат данных:** JSON.
*   **Аутентификация:** JWT (JSON Web Tokens). Токен передается в заголовке `Authorization: Bearer <token>`.

## 2. Модуль Аутентификации (Auth)

### Регистрация

*   **Endpoint:** `POST /auth/register`
*   **Описание:** Создает нового пользователя.
*   **Request Body:**
    ```json
    {
        "username": "user123",
        "email": "user@example.com",
        "password": "securepassword"
    }
    ```
*   **Response (201 Created):**
    ```json
    {
        "id": 1,
        "username": "user123",
        "email": "user@example.com",
        "created_at": "2023-10-27T10:00:00Z"
    }
    ```
*   **Ошибки:** `400 Bad Request` (отсутствуют поля), `500 Internal Server Error` (ошибка базы данных, например, если пользователь уже существует).

### Авторизация (Вход)

*   **Endpoint:** `POST /auth/login`
*   **Описание:** Аутентифицирует пользователя и возвращает JWT.
*   **Request Body:**
    ```json
    {
        "username": "user123",
        "password": "securepassword"
    }
    ```
*   **Response (200 OK):**
    ```json
    {
        "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
    }
    ```
*   **Ошибки:** `400 Bad Request`, `401 Unauthorized`.

## 3. Модуль Социальной сети (Social / Feed)

### Лента (Feed)

*   **Endpoint:** Зависит от реализации (например, `GET /social/feed`). Требует JWT.
*   **Описание:** Возвращает посты для пользователя. Может поддерживать пагинацию.
*   **Response (200 OK):**
    ```json
    [
        {
            "id": "uuid-post-1",
            "user_id": "uuid-user-1",
            "caption": "Мой первый пост!",
            "media_urls": ["url1.jpg", "url2.jpg"],
            "created_at": "2023-10-27T10:05:00Z"
        }
    ]
    ```

### Взаимодействия

*   **Поиск пользователей:** `GET /social/users?q=query`
*   Ожидаются эндпоинты для подписок (`POST /social/follow`), лайков (`POST /social/like`) и комментариев (`POST /social/comment`).

## 4. Модуль Чата (Chat)

### Подключение через WebSocket

*   **Endpoint:** `WS /chat` (или `WSS /chat` для защищенного соединения).
*   **Подключение:** Требуется передача JWT, обычно через строку запроса `?token=<jwt>` или через первое сообщение инициализации, в зависимости от окончательной реализации.

### Формат сообщений WebSocket

Для обмена сообщениями в реальном времени клиенты должны отправлять и принимать данные в формате JSON. Структура сообщений будет определяться типом действия (например, `send_message`, `receive_message`, `typing`, `read_receipt`).

Пример отправки сообщения:
```json
{
    "action": "send_message",
    "payload": {
        "chat_id": "uuid-chat-1",
        "content": "Привет, мир!",
        "media_url": null
    }
}
```

Пример получения сообщения:
```json
{
    "event": "new_message",
    "payload": {
        "id": "message-id",
        "chat_id": "uuid-chat-1",
        "sender_id": "uuid-sender",
        "content": "Привет, мир!",
        "created_at": "2023-10-27T10:10:00Z"
    }
}
```

## 5. Модуль Медиа (Media)

*   Служит для загрузки файлов (фото/видео).
*   Вероятно, включает в себя эндпоинты типа `POST /media/upload` (возвращающий URL загруженного файла) и, возможно, `GET /media/{id}` для скачивания, если не используются прямые ссылки на S3/MinIO.

---

*Примечание: Данная спецификация является предварительной и может дополняться по мере развития бэкенда.*

### Синхронизация сессий (Дельты)

*   **Endpoint:** `GET /chat/{chatId}/sync?lastMessageId=123`
*   **Описание:** Возвращает массив пропущенных сообщений (дельт) начиная с указанного `lastMessageId`. Используется для быстрого восстановления сессии после офлайна.
*   **Response (200 OK):**
    ```json
    [
        {
            "id": "124",
            "chat_id": "uuid-chat-1",
            "content": "Пропущенное сообщение",
            "version": 1,
            "is_encrypted": false
        }
    ]
    ```

## 6. Виджеты (B2B Web Widgets)

*   Изолированные эндпоинты для корпоративных клиентов.
*   **Endpoint:** `GET /widgets/{widgetId}/init`
*   **Описание:** Возвращает конфигурацию виджета для встраивания на сайт.
