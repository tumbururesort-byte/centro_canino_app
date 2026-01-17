# Odoo Client App

## Overview

This is a Flutter application that connects to an Odoo instance, authenticates a user, and displays a list of customers.

## Development Strategy

To accelerate the development cycle, we will prioritize a **web-first** approach. This allows us to leverage faster hot reloads and rapid iterations. All new features and UI changes will be primarily tested on the web platform during development.

## Features

*   User authentication with Odoo.
*   Display a list of the first 10 customers.

## Current Plan

*   Use the `http` package for direct JSON-RPC calls to Odoo.
*   Create a login screen with pre-filled credentials.
*   Create a home screen to display the customer list.
*   Implement Odoo authentication using `http`.
*   Fetch and display customer data using `http`.
