# Project Blueprint

## Overview

This is an offline-first Flutter application for managing a list of clients. It's designed to synchronize with an Odoo backend, allowing users to create, read, update, and delete client information even when they are not connected to the internet. All changes are stored locally and then pushed to the server when a connection is available.

## Style, Design, and Features

### Architecture

*   **Offline-First:** The application is built around the principle of being fully functional without an internet connection. Data is stored locally in a Drift database, and all CRUD operations are performed on this local database first.
*   **Repository Pattern:** A `ClientesRepository` is used to abstract the data layer from the UI. This repository is responsible for coordinating between the local database and the remote Odoo service.
*   **MVVM-like Pattern:** The UI is separated from the business logic. The `OdooClientesPage` acts as a ViewModel, holding the state and business logic, while the widgets represent the View.

### State Management

*   **`setState`:** For this application, `setState` is used for managing the state of the `OdooClientesPage`.

### Data Persistence

*   **Drift:** Drift is used as the local database to store the client data. It provides a reactive API for watching database queries and automatically updating the UI when the data changes.

### Remote API

*   **Odoo:** The application communicates with an Odoo backend to synchronize the client data. The `OdooService` class encapsulates the logic for making API calls to the Odoo server.

### User Interface

*   **Material Design:** The application uses the Material Design library to create a clean and intuitive user interface.
*   **Connection Status:** The UI clearly indicates whether the application is connected to the Odoo server or not.
*   **Sync Status:** The UI shows the last sync time and indicates when a sync is in progress.
*   **Pending Changes:** Clients that have been modified locally but not yet synced to the server are highlighted in the UI.

## Current Task: Initial Setup and Bug Fixing

### Plan and Steps

1.  **Project Renaming:** The project was renamed from `dog_hote` to `myapp`.
2.  **Dependency Updates:** The `pubspec.yaml` file was updated to reflect the new project name.
3.  **Import Path Correction:** All import paths in the Dart files were updated to use the new project name.
4.  **Database Connection:** The `openConnection` method in `lib/data/local/app_database.dart` was implemented.
5.  **Build Runner:** The `build_runner` was executed to regenerate the Drift database code.
6.  **Static Analysis:** `flutter analyze` was run to identify and fix any remaining analysis errors.
7.  **Linting:** The code was linted to remove unused imports and `print` statements.
