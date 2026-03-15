# Implementation Plan 📝

This file tracks the progress of the **Ballegram** project. Tasks are broken down into small, PR-sized increments.

## 🟢 Infrastructure & DevOps (Completed)
- [x] **Project Setup**
    - [x] Initialize Ballerina project structure.
    - [x] Create module structure (`common`, `auth`, `chat`, `media`, `social`).
- [x] **CI/CD**
    - [x] Create `Dockerfile` for multi-stage build.
    - [x] Set up GitHub Actions for testing and Docker verification.

## 🟢 Phase 1: Database & Foundation (Completed)
- [x] **Database Schema**
    - [x] Create `docker/init.sql`.
    - [x] Define tables: `users`, `chats`, `messages`, `posts`.
    - [x] Add `docker-compose.yml` for local development (Postgres + Redis).
- [x] **Common Module**
    - [x] Implement DB client wrapper in `common` (currently exists but verify completeness).
    - [x] Implement error types.

## 🟢 Phase 2: Authentication Module (Completed)
- [x] **User Management**
    - [x] Define `User` record/entity.
    - [x] Implement `register` function (password hashing).
- [x] **Security**
    - [x] Implement `login` function (JWT generation).
    - [x] Implement JWT validation middleware.
- [x] **API**
    - [x] Connect `auth` service endpoints to implementation.

## 🟡 Phase 3: Chat Module (In Progress)
- [x] **Chat Core**
    - [x] Define `Chat` and `Message` records.
    - [x] Implement `createChat` DB logic.
    - [x] Implement `saveMessage` DB logic.
    - [x] Implement `getChatHistory`.
- [x] **Real-time**
    - [x] Implement WebSocket listener.
    - [x] Implement connection management (User -> Connection map).
    - [x] Implement message broadcasting.

## 🟣 Phase 4: Social Module (In Progress)
- [x] **Media**
    - [x] Implement file upload handling (S3/Local).
- [x] **Posts**
    - [x] Define `Post` record.
    - [x] Implement `createPost`.
- [x] **Feed**
    - [x] Implement `getFeed` (query logic).

## ⚪ Phase 5: Interaction & Polish
- [x] **Interactions**
    - [x] Implement Likes.
    - [x] Implement Comments.
    - [x] Implement Follow system.
- [x] **Search**
    - [x] Implement User search.

## ⚪ Phase 6: Доработки после аудита
Основываясь на проведенном аудите архитектуры Ballegram, вот подробный TODO-лист для команды бэкенд-разработки. Задачи разбиты по логическим блокам от базовой инфраструктуры до реализации бизнес-логики и новых фичей.
1. Модернизация инфраструктуры и баз данных
 * [ ] Оптимизация API Gateway и IdP: Перевести взаимодействие между микросервисами на gRPC для снижения накладных расходов при заявленной нагрузке в 40 млн DAU.[1]
 * [ ] Внедрение NoSQL решений: Развернуть горизонтально масштабируемые БД (например, Apache Cassandra) для хранения временных рядов (истории сообщений) и графовые БД для управления социальными связями (подписки, друзья).
 * [ ] Реализация Object Storage и CDN: Настроить распределенное хранилище для медиафайлов. Сервер должен эффективно обрабатывать загрузку до 5 изображений на один пост/сообщение, а также аудиосообщения.[1]
 * [ ] Настройка политик хранения (Data Retention): Внедрить автоматизированные джобы для бессрочного хранения социальных публикаций и архивирования/удаления личных сообщений старше 5 лет.[1]
2. Подсистема реального времени (Real-time Core)
 * [ ] Кластер WebSocket/gRPC-стримов: Разработать и развернуть сервис управления постоянными двунаправленными соединениями для замены синхронного HTTP-пуллинга.
 * [ ] Интеграция брокера сообщений: Внедрить Apache Kafka или Redis Pub/Sub для асинхронной маршрутизации событий (новые сообщения, лайки, статусы набора текста) между микросервисами и подключенными клиентами.
 * [ ] Change Data Capture (CDC): Настроить отслеживание и трансляцию только измененных данных на клиенты, чтобы минимизировать задержки и нагрузку на сеть.[2]
3. Синхронизация множества устройств (Device Management & Sync)
 * [ ] Поддержка параллельных сессий: Реализовать логику, при которой каждое устройство пользователя (браузер, смартфон, ПК) имеет собственное WebSocket-соединение, но все они объединены единым идентификатором пользователя.[3]
 * [ ] Механизм cur_max_message_id: Создать эндпоинты для получения от клиента ID последнего известного сообщения и генерации сжатого пакета "дельт" (всех пропущенных событий) для быстрого восстановления сессии после офлайна.[3]
 * [ ] Разрешение конфликтов (MVCC): Внедрить на сервере многоверсионное управление конкурентным доступом (MultiVersion Concurrency Control) и алгоритм Last-Write-Wins для корректной обработки сообщений или постов, отредактированных пользователем в офлайн-режиме.[2, 4]
 * [ ] Интеграция Push-уведомлений: Настроить взаимодействие с внешними провайдерами (Apple APNs, Firebase Cloud Messaging) для доставки уведомлений на отключенные устройства.
4. Реализация сложной бизнес-логики мессенджера и социальной сети
 * [ ] Алгоритм ленты новостей (Feed): Разработать сервис агрегации постов (от самого пользователя, групп и глобальной ленты) со строгой хронологической сортировкой по убыванию (DESC).[1]
 * [ ] Дифференцированные статусы прочтения: Реализовать логику фиксации просмотров. Для личных чатов — точная фиксация факта прочтения, для крупных каналов — счетчик прочтений до достижения заданного порога, после которого статус меняется на базовый "просмотрено".[1]
 * [ ] Ограничения контента: Внедрить валидацию длины сообщений на уровне сервера (строго до 4000 символов).[1]
5. Безопасность и интеграция дополнительных фичей
 * [ ] Поддержка End-to-End Encryption (E2EE): Разработать транспортную инфраструктуру для приватных чатов, при которой сервер маршрутизирует исключительно зашифрованные пакеты и не имеет доступа к ключам (успешное прохождение "mud puddle test").[5]
 * [ ] Связывание устройств (Linked Devices): Создать криптографически безопасный протокол для авторизации новых устройств (например, десктопного клиента через мобильный телефон) с передачей истории E2EE-сообщений напрямую между клиентами в обход серверного хранилища.[5]
 * [ ] Открытый Bot API: Разработать и задокументировать API-шлюз и систему Webhook-ов для подключения сторонних ботов (для опросов, модерации и CRM-интеграций).
 * [ ] B2B Web Widgets: Подготовить изолированные эндпоинты для работы легковесных скриптов (виджетов), которые корпоративные клиенты смогут встраивать на свои сайты для прямой связи с пользователями через Ballegram.[6]
