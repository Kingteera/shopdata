# Product Cost Tracker 📱

A mobile application developed with **Flutter** for product price, tracking price history, and calculating unit costs. This app utilizes local storage (SQLite) for offline data persistence and supports database backup/restore.

## 🚀 Features

* **CRUD Operations:** Create, Read, Update, and Delete product information.
* **Automatic Calculation:** Automatically calculates "Unit Cost" based on "Cost Price" and "Contain" amount.
* **Price History:** Tracks and logs changes in product prices and details over time using a dedicated history table.
* **Search Functionality:** Efficient product search with custom `SearchDelegate`.
* **Performance Optimization:** Implements pagination (loads 50 items at a time) to handle large datasets smoothly.
* **Data Management:**
    * Export database to local storage for backup.
    * Import/Merge existing databases.
* **Responsive UI:** Clean Material Design interface with formatters for currency and numbers.

## 🛠 Tech Stack

* **Framework:** Flutter (Dart)
* **Database:** SQLite (via `sqflite` package)
* **State Management:** Native `setState` and `ValueNotifier`
* **Key Packages:**
    * `sqflite`: Local database management.
    * `path_provider` & `file_picker`: File system access for import/export.
    * `permission_handler`: Managing storage permissions.
    * `intl`: Number formatting.

## 📸 Screenshots

* ![Home Screen](ex_pic/Untitled%20design%20(3).png))*

## 📂 Project Structure

* `main.dart`: Entry point and theme configuration.
* `database_helper.dart`: Singleton class for handling SQLite database operations (Tables: `products`, `product_history`).
* `product_list_screen.dart`: Main screen displaying paginated product list with import/export features.
* `product_form_screen.dart`: Form for adding/editing products with validation.
* `product_history_screen.dart`: Screen to view historical changes of a specific product.

## 📦 Installation

To install the application on your Android device:

1.  Download the **`shopdata_v2.apk`** file from this repository.
2.  Open the file on your Android device.
3.  If prompted, go to **Settings** and enable **"Install from unknown sources"**.
4.  Tap **Install** to complete the setup.
