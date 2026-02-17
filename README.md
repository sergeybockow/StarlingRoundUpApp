# Starling Bank Round-Up Service

Приложение для автоматизации накоплений, интегрированное с **Starling Bank API (Sandbox)**. Проект анализирует транзакции пользователя и рассчитывает сумму «сдачи» для последующего перевода в накопительную корзину.

---

## Основные возможности

* **Интеграция с REST API**: Полноценная работа с банковскими эндпоинтами для получения счетов и истории транзакций.
* **Автоматизация накоплений**: Расчет суммы округления (Round-Up) для всех исходящих транзакций за указанный период.
* **Безопасность**: Реализация авторизации через Bearer-токен и кастомные HTTP-заголовки.
* **Надежность**: Строгая фильтрация транзакций по статусу `SETTLED` и направлению `OUT`.

---

## Архитектурные решения

Проект реализован с четким разделением ответственности (Separation of Concerns):

1. **Networking Layer**
Использование `URLComponents` и перечислений `StarlingEndpoint` для безопасного формирования запросов и управления путями API.
2. **Data Layer**
Модели данных используют протокол `Decodable` для автоматического маппинга JSON-ответов.
3. **Business Logic**
Вынос математических расчетов в изолированный сервис `RoundUpService`, что упрощает тестирование и поддержку.
4. **Modern Concurrency**
Применение Swift `async/await` для написания чистого и безопасного асинхронного кода без использования callback-функций.

---

## Логика расчета (Round-Up)

Алгоритм работает по принципу накопления остатка до ближайшего целого фунта:

> **Пример**: Транзакция на сумму £1.20 генерирует «сдачу» в 80p. Транзакция на £10.00 генерирует 0p.

* Программа вычисляет остаток в пенсах от каждой транзакции (`minorUnits % 100`).
* Если остаток больше нуля, вычисляется разница до следующего целого числа (`100 - остаток`).
* Транзакции с нулевым остатком (ровные суммы) игнорируются.

---

## Тестирование

Проект включает в себя **Unit-тесты** на фреймворке `XCTest`, которые покрывают ключевую финансовую логику:

* **Accuracy**: Валидация расчета сдачи для различных сумм.
* **Edge Cases**: Проверка корректной обработки транзакций без остатка (целые фунты).
* **Filtering**: Гарантия того, что логика не учитывает входящие переводы и незавершенные операции.

---

## Системные требования

* **Xcode**: 15.0+
* **Swift**: 5.9+
* **iOS**: 15.0+

---

## Инструкция по запуску

1. Склонируйте репозиторий на локальную машину.
2. Получите персональный токен доступа в консоли разработчика **Starling Bank**.
3. Вставьте полученный токен в файл `CustomerDetails.swift` в поле `accessToken`.
4. Запустите тесты нажатием **Cmd + U**, чтобы убедиться в корректности работы алгоритмов.
5. Нажмите **Cmd + R** для запуска приложения на симуляторе или реальном устройстве.


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////



# Starling Bank Round-Up Service

A savings automation application integrated with the **Starling Bank API (Sandbox)**. The project analyzes user transactions and calculates "spare change" to be transferred into a designated savings goal.

---

## Key Features

* **REST API Integration**: Full communication with banking endpoints to retrieve accounts and transaction history.
* **Savings Automation**: Calculation of the "Round-Up" amount for all outgoing transactions within a specified timeframe.
* **Security**: Implementation of Bearer Token authorization and custom HTTP headers.
* **Reliability**: Strict transaction filtering based on `SETTLED` status and `OUT` direction.

---

## Architectural Decisions

The project is built with a clear **Separation of Concerns**:

1. **Networking Layer**
Uses `URLComponents` and `StarlingEndpoint` enums for secure request construction and API path management.
2. **Data Layer**
Data models conform to the `Decodable` protocol for automatic JSON response mapping.
3. **Business Logic**
Mathematical calculations are isolated within the `RoundUpService`, making the code easier to test and maintain.
4. **Modern Concurrency**
Leverages Swift **async/await** to write clean, safe asynchronous code without the need for complex callback functions.

---

## Round-Up Logic

The algorithm accumulates the difference between the transaction amount and the next whole pound:

> **Example**: A transaction of £1.20 generates 80p in "spare change." A transaction of £10.00 generates 0p.

* The program calculates the remainder in pence for each transaction (`minorUnits % 100`).
* If the remainder is greater than zero, the difference to the next whole number is calculated (`100 - remainder`).
* Transactions with a zero remainder (whole amounts) are ignored.

---

## Testing

The project includes a robust suite of **Unit Tests** using the `XCTest` framework, covering key financial logic:

* **Accuracy**: Validation of spare change calculations for various amounts.
* **Edge Cases**: Verification of correct handling for transactions with zero remainder (whole pounds).
* **Filtering**: Ensuring the logic ignores incoming transfers and pending/unsettled operations.

---

## System Requirements

* **Xcode**: 15.0+
* **Swift**: 5.9+
* **iOS**: 15.0+

---

## Getting Started

1. Clone the repository to your local machine.
2. Obtain a personal access token from the **Starling Bank** developer console.
3. Insert your token into the `accessToken` field within the `CustomerDetails.swift` file.
4. Run tests by pressing **Cmd + U** to verify the algorithm's accuracy.
5. Press **Cmd + R** to run the application on a simulator or physical device.
