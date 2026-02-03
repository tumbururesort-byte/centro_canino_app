# Project Blueprint

## Overview

This document outlines the structure, features, and design of the Tumburú mobile application. The application is built with Flutter and utilizes a provider-based architecture for state management. The primary goal of this project is to provide a clean, organized, and scalable codebase that is easy to maintain and extend.

## Project Structure

The project is organized into the following directories:

*   `lib/`: Contains the main application code.
    *   `api/`: Handles communication with the Tumburú API.
    *   `data/`: Manages the application's data, including the local database.
    *   `models/`: Defines the data models used throughout the application.
    *   `pages/`: Contains the application's pages or screens.
    *   `providers/`: Contains the application's providers for state management.
    *   `theme/`: Defines the application's theme and styles.
    *   `widgets/`: Contains reusable widgets used throughout the application.
*   `test/`: Contains the application's tests.

## Implemented Features

The following features have been implemented in the application:

*   **Authentication:** Users can log in to the application using their Tumburú credentials.
*   **Client Management:** Users can view, create, edit, and delete clients.
*   **Profile Management:** Users can view their profile information and log out of the application.
*   **Theme Management:** Users can switch between light and dark themes.
*   **Search:** Users can search for clients by name, email, or phone number.

## Design and Theming

The application uses a custom theme that is defined in the `lib/theme/app_theme.dart` file. The theme is based on the Material Design guidelines and provides a consistent look and feel throughout the application. The theme is also used to manage the application's colors, fonts, and other styles.

## Refactoring of Hardcoded Styles

All hardcoded styles have been removed from the application and replaced with the appropriate `Theme.of(context)` properties. This ensures that the UI updates correctly when the theme changes and that the codebase is clean and organized.

The following files were refactored:

*   `lib/pages/login_page.dart`
*   `lib/pages/cliente_edit_page.dart`
*   `lib/pages/clientes_page.dart`
*   `lib/pages/profile_page.dart`
*   `lib/widgets/app_drawer.dart`
*   `lib/widgets/cliente_list_item.dart`
*   `lib/widgets/main_scaffold.dart`

This refactoring ensures that the application is scalable and easy to maintain. It also makes it easier to add new features and themes to the application in the future.
