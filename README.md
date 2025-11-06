# File Storage Application

A Spring Boot web application that allows users to register, login, and store files (images, documents, etc.) securely.

## Features

- **User Authentication**: Register and login with username and password
- **File Upload**: Upload any type of file (images, PDFs, documents, etc.)
- **File Management**: View, download, and delete your uploaded files
- **Secure Storage**: Each user can only access their own files
- **Responsive UI**: Modern and user-friendly interface

## Technology Stack

- **Backend**: Spring Boot 3.2.0, Java 17
- **Security**: Spring Security with BCrypt password encryption
- **Database**: H2 (development), MySQL (production ready)
- **ORM**: Spring Data JPA / Hibernate
- **Template Engine**: Thymeleaf
- **Build Tool**: Maven

## Project Structure

```
SpringBoot_Project/
├── src/
│   ├── main/
│   │   ├── java/com/filestorage/
│   │   │   ├── FileStorageApplication.java
│   │   │   ├── config/
│   │   │   │   └── SecurityConfig.java
│   │   │   ├── controller/
│   │   │   │   ├── AuthController.java
│   │   │   │   └── FileController.java
│   │   │   ├── model/
│   │   │   │   ├── User.java
│   │   │   │   └── FileMetadata.java
│   │   │   ├── repository/
│   │   │   │   ├── UserRepository.java
│   │   │   │   └── FileMetadataRepository.java
│   │   │   └── service/
│   │   │       ├── CustomUserDetailsService.java
│   │   │       ├── UserService.java
│   │   │       └── FileStorageService.java
│   │   └── resources/
│   │       ├── application.properties
│   │       ├── static/css/
│   │       │   └── style.css
│   │       └── templates/
│   │           ├── login.html
│   │           ├── register.html
│   │           └── dashboard.html
└── pom.xml
```

## Setup and Installation

### Prerequisites
- Java 17 or higher
- Maven 3.6 or higher

### Steps to Run

1. **Navigate to the project directory**:
   ```bash
   cd /Users/hari/Desktop/SpringBoot_Project
   ```

2. **Build the project**:
   ```bash
   mvn clean install
   ```

3. **Run the application**:
   ```bash
   mvn spring-boot:run
   ```

4. **Access the application**:
   - Open your browser and go to: `http://localhost:8080/login`
   - H2 Console (development): `http://localhost:8080/h2-console`

## Usage

1. **Register**: Create a new account with username, email, and password
2. **Login**: Sign in with your credentials
3. **Upload Files**: Use the upload form to select and upload files
4. **Manage Files**: View all your uploaded files in a table with options to download or delete
5. **Logout**: Click the logout button when done

## Configuration

### Database Configuration (Production)

To use MySQL instead of H2, uncomment these lines in `application.properties`:

```properties
spring.datasource.url=jdbc:mysql://localhost:3306/filestorage_db
spring.datasource.username=root
spring.datasource.password=yourpassword
spring.datasource.driver-class-name=com.mysql.cj.jdbc.Driver
```

### File Upload Settings

Configure in `application.properties`:
```properties
spring.servlet.multipart.max-file-size=50MB
spring.servlet.multipart.max-request-size=50MB
file.upload-dir=./uploads
```

## Security

- Passwords are encrypted using BCrypt
- Spring Security handles authentication and authorization
- Each user can only access their own files
- CSRF protection enabled for all forms

## Future Enhancements

- File sharing between users
- File preview functionality
- Folder organization
- Search and filter files
- User profile management
- File size quotas per user

## License

This project is created for educational purposes.
