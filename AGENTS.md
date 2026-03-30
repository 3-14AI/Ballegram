# Instructions for AI Agents 🤖

This document outlines the protocols, coding standards, and architectural guidelines for AI agents working on the **Ballegram** repository.

## 1. Core Directives

*   **Language:** All backend code must be written in **Ballerina** (Swan Lake).
*   **Architecture:** Adhere strictly to the **Modular Monolith** structure.
    *   **Logic** goes into `modules/<domain>`.
    *   **Transport** (HTTP/WS) goes into `service/`.
    *   **Shared** code goes into `modules/common`.
*   **Verification:** You **must** verify every change. Since there is no frontend, this means running `bal test` or creating a temporary script to call your new API endpoint.

## 2. Coding Standards (Ballerina)

### Error Handling
*   Prefer the `check` expression over verbose `if/else` checks for errors where possible.
*   Return standard error types defined in `modules/common`.

```ballerina
// ✅ GOOD
User user = check db:getUser(id);

// ❌ BAD
var result = db:getUser(id);
if (result is error) { ... }
```

### Type Safety
*   Avoid `json` type when a record type can be defined.
*   Use `record` types for Database entities and DTOs.

### Service Definitions
*   Keep `service.bal` files thin. They should only handle HTTP concerns (status codes, payload extraction) and delegate business logic to the respective module.

## 3. Database Changes

*   Проект использует **PostgreSQL** (реляционные данные), **OpenSearch** (история сообщений) и **Neo4j** (социальный граф).
*   **Интеграция gRPC**: Межсервисное взаимодействие (например, API Gateway с IdP) использует gRPC. При изменениях обновляйте proto-файлы и используйте сгенерированные стабы (`auth_pb.bal`).
*   **Kafka и CDC**: Маршрутизация событий и Change Data Capture (CDC) должны использовать `EventBroker` из модуля `broker` для широковещательной рассылки событий.
*   **MVCC (Многоверсионное управление конкурентным доступом)**: При редактировании постов или сообщений обязательно инкрементируйте и валидируйте поле `version`.
*   **E2EE (Сквозное шифрование)**: Содержимое приватных чатов должно помечаться флагом `isEncrypted=true` и обрабатываться сервером исключительно как непрозрачные строки/массивы байт без логирования контента.
*   If you need to change the schema:
    1.  Update the `README.md` schema section.
    2.  Create a SQL migration script in `docker/init.sql` (for new setups) or a numbered migration file if a migration system is in place.
    3.  Update the Ballerina record types in `modules/<domain>/types.bal`.

## 4. Testing Strategy

Since there is no client application:

1.  **Unit Tests:** Write tests for internal module functions in `tests/`.
2.  **Service Tests:** Use the `http:Client` to test endpoints in your `test` blocks.
3.  **Mocking:** Use `test:mock` to mock the Database client when testing business logic.

## 5. Implementation Roadmap

Refer to `TODO.md` for the prioritized list of tasks. Always pick the highest priority item from the "Pending" list unless instructed otherwise.
