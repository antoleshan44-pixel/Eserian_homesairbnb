# Multi-stage build for Spring Boot + React together

# Stage 1: Build React frontend
FROM node:18-alpine AS frontend-build

WORKDIR /frontend

# Copy frontend files
COPY src/main/resources/eserian-frontend/package*.json ./
RUN npm ci --only=production

COPY src/main/resources/eserian-frontend/ ./
RUN npm run build

# Stage 2: Build Spring Boot backend
FROM openjdk:17-jdk-slim AS backend-build

WORKDIR /app

# Copy Maven files
COPY mvnw .
COPY .mvn .mvn
COPY pom.xml .

# Download dependencies
RUN ./mvnw dependency:go-offline -B

# Copy source code
COPY src src/

# Copy built frontend to Spring Boot static directory
COPY --from=frontend-build /frontend/build /app/src/main/resources/static

# Build the application
RUN ./mvnw clean package -DskipTests

# Stage 3: Run the application
FROM openjdk:17-jdk-slim

WORKDIR /app

# Copy the built jar file
COPY --from=backend-build /app/target/*.jar app.jar

# Expose port
EXPOSE 8080

# Run the application
ENTRYPOINT ["java", "-jar", "app.jar"]