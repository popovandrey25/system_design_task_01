workspace {
    name "Сервис поиска попутчиков"
    !identifiers hierarchical

    model {
        // --- C1: Уровень контекста ---
        
        // Роль пользователя
        user = person "Пользователь" "Ищет попутчиков и поездки"

        // Внешняя система
        mapService = softwareSystem "Map Service" "Внешний сервис для получения геоданных и маршрутов"

        // Основная система
        carpooling = softwareSystem "Carpooling System" "Сервис для поиска попутчиков и организации совместных поездок" {

            // --- C2: Уровень контейнеров ---

            // Контейнер для управления пользователями
            userService = container "User Service" {
                description "Управление пользователями (создание, поиск по логину, поиск по имени и фамилии)"
                technology "Python FastAPI"

                // --- C3: Уровень компонентов ---
                userApiRouter = component "User API Router" {
                    description "Обрабатывает REST-запросы, связанные с пользователями, и передаёт их нужным компонентам"
                    technology "Python FastAPI"
                }

                userRegistration = component "User Registration" {
                    description "Реализует логику создания нового пользователя"
                    technology "Python FastAPI"
                }

                userSearch = component "User Search" {
                    description "Реализует логику поиска пользователя (по логину, по имени и фамилии)"
                    technology "Python FastAPI"
                }

                userApiRouter -> userRegistration "Приходит запрос на создание пользователя"
                userApiRouter -> userSearch "Приходит запрос на поиск пользователя"
            }

            routeService = container "Route Service" {
                description "Создание и получение маршрутов, взаимодействие с картографическим сервисом"
                technology "Python FastAPI"
            }

            tripService = container "Trip Service" {
                description "Создание поездок, подключение пользователей, получение информации о поездках"
                technology "Python FastAPI"
            }

            database = container "Database" {
                description "Хранит данные о пользователях, маршрутах и поездках"
                technology "PostgreSQL"
            }

            userService -> database "Читает и пишет данные пользователей" "JDBC"
            routeService -> mapService "Запрашивает геоданные и оптимальные маршруты" "REST API"
            routeService -> database "Хранит/получает информацию о маршрутах" "SQL"
            tripService -> routeService "Получает информацию о маршруте при создании поездки" "REST API"
            tripService -> database "Хранит/получает информацию о поездках" "SQL"
        }

        user -> carpooling "Использует сервис поиска попутчиков" "REST/HTTPS"
        carpooling -> mapService "Запрашивает детали маршрутов" "REST/HTTPS"

        user -> carpooling.userService "Создаёт или ищет пользователя" "REST/HTTPS"
        carpooling.userService -> carpooling.tripService "Запрашивает создание/подключение к поездке" "REST API"
        mapService -> carpooling.routeService "Возвращает данные о маршруте" "REST API"
        carpooling.tripService -> user "Сообщает результат (пользователь подключён к поездке)" "REST/HTTPS"
    }

    views {
        // --- C1: Диаграмма контекста системы ---
        systemContext carpooling "SystemContext" {
            include *
            autolayout lr
        }

        // --- C2: Диаграмма контейнеров ---
        container carpooling "ContainerView" {
            include *
            autolayout lr
        }

        // --- C3: Диаграмма компонентов для конкретного контейнера (User Service) ---
        component carpooling.userService "UserServiceComponents" {
            include *
            autolayout lr
        }

        dynamic carpooling "JoinTrip" "Сценарий подключения пользователя к поездке" {
            user -> carpooling.userService "Создаёт или ищет пользователя"
            carpooling.userService -> carpooling.tripService "Запрашивает создание/подключение к поездке"
            carpooling.tripService -> carpooling.routeService "Уточняет маршрут для поездки"
            carpooling.routeService -> mapService "Запрашивает данные о маршруте"
            mapService -> carpooling.routeService "Возвращает данные о маршруте"
            carpooling.routeService -> carpooling.tripService "Передаёт информацию о маршруте"
            carpooling.tripService -> user "Сообщает результат (пользователь подключён к поездке)"
        }
    }
}

