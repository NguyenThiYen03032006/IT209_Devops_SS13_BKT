# ============================================================
# Stage 1 – Build
# ============================================================
FROM eclipse-temurin:21-jdk-alpine AS builder

WORKDIR /app

# Copy Gradle wrapper & dependency descriptors first (layer cache)
COPY gradlew settings.gradle build.gradle ./
COPY gradle ./gradle

# Download dependencies (cached unless build files change)
RUN chmod +x gradlew && ./gradlew dependencies --no-daemon -q

# Copy source code and build the fat JAR (skip tests – tests run separately)
COPY src ./src
RUN ./gradlew bootJar --no-daemon -x test

# ============================================================
# Stage 2 – Runtime
# ============================================================
FROM eclipse-temurin:21-jre-alpine

WORKDIR /app

# Create a non-root user for security
RUN addgroup -S appgroup && adduser -S appuser -G appgroup

# Copy only the final JAR from the builder stage
COPY --from=builder /app/build/libs/*.jar app.jar

USER appuser

EXPOSE 8080

ENTRYPOINT ["java", "-jar", "app.jar"]
