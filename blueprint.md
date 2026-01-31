# Blueprint de la Aplicación de Clientes

## Visión General

Esta aplicación de Flutter está diseñada para gestionar una lista de clientes de forma offline-first. La aplicación se sincroniza con un servidor Odoo para obtener y enviar datos, pero permite a los usuarios ver, crear, editar y eliminar clientes incluso sin conexión a internet. La base de datos local (implementada con `drift`) se encarga de almacenar los datos y sincronizarlos cuando la conexión esté disponible.

## Diseño y Características Implementadas

### v2.0 (Refactorización y UI - Estado Actual)

*   **Diseño Visual y Tematización (Material 3):**
    *   La interfaz se ha actualizado a **Material 3** para un look & feel moderno.
    *   Se utiliza `ColorScheme.fromSeed` para generar una paleta de colores cohesiva y atractiva a partir de un color principal (morado).
    *   Se ha integrado `google_fonts` para una tipografía más rica y personalizada (`Oswald`, `Roboto`, `Open Sans`).
    *   **Soporte para Tema Oscuro/Claro:** Se ha implementado un `ThemeProvider` que permite al usuario cambiar entre el modo claro, oscuro o seguir la configuración del sistema. El interruptor se encuentra en el `AppDrawer`.
    *   **Rediseño de Componentes:**
        *   La `LoginPage` ha sido rediseñada para ser más atractiva y centrada.
        *   El `AppDrawer` ha sido actualizado para incluir el interruptor de tema y un botón de cierre de sesión claro.

*   **Arquitectura y Gestión de Estado:**
    *   **Patrón Repositorio:** Se ha introducido `ClientesRepository`, que abstrae y centraliza toda la lógica de gestión de clientes (remota y local).
    *   **Separación de la Lógica de UI:** La lógica de estado de la `ClientesPage` ha sido movida a `ClientesProvider`, desacoplando la interfaz de usuario de las operaciones de datos.
    *   **Flujo de Datos Unidireccional:** El flujo de datos es claro y predecible: `UI (ClientesPage) -> ClientesProvider -> ClientesRepository -> (OdooService | ClientesDao)`.

*   **Base de Datos Local (Drift):**
    *   Se ha implementado una base de datos local robusta utilizando el paquete `drift`.
    *   **Singleton de Base de Datos:** `AppDatabase` se ha implementado como un singleton (`AppDatabase.instance`) para garantizar una única conexión en toda la aplicación, evitando inconsistencias.
    *   **DAO (Data Access Object):** La lógica de las consultas a la base de datos se ha aislado en `ClientesDao`, siguiendo las mejores prácticas de `drift`.
    *   **Generación de Código:** Se utiliza `build_runner` para generar automáticamente el código necesario para `drift`.

### v1.0 (Base Funcional)

*   **Autenticación:**
    *   Pantalla de inicio de sesión para conectar con un servidor Odoo.
    *   `OdooService` gestiona la comunicación (autenticación y llamadas RPC).
    *   `AuthProvider` gestiona el estado de la sesión del usuario.

*   **Navegación:**
    *   `NavigationProvider` gestiona la página visible y el título de la `AppBar`.
    *   `MainScaffold` es el widget principal con `AppBar`, `Drawer` y búsqueda.

## Próximos Pasos

La aplicación se encuentra en un estado estable y refactorizado. Las próximas iteraciones podrían centrarse en:

*   **Optimización de la Sincronización:** Implementar una estrategia de sincronización en segundo plano o más avanzada.
*   **Testing:** Añadir tests unitarios y de widgets para asegurar la fiabilidad del código.
*   **Nuevas Funcionalidades:** Añadir más módulos de Odoo (e.g., Pedidos, Productos).
