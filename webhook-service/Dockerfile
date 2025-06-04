FROM openjdk:17-jdk-slim

WORKDIR /app

# Install Maven and Git
RUN apt-get update && \
    apt-get install -y maven git && \
    rm -rf /var/lib/apt/lists/*

# Configure git to trust the workspace directory
RUN git config --global --add safe.directory /workspace && \
    git config --global --add safe.directory '*'

# Copy pom.xml first for better Docker layer caching
COPY pom.xml .

# Download dependencies
RUN mvn dependency:go-offline -B

# Copy source code
COPY src ./src

# Environment variables with defaults
ENV WEBHOOK_SECRET=""
ENV REPO_PATH="/workspace"
ENV GIT_BRANCH="main"
ENV DEBUG="false"
ENV TOUCH_PATHS="backend/src/main/java/com/example/counter/CounterBackendApplication.java"

# Expose the webhook port
EXPOSE 8081

# Start the webhook service
CMD ["mvn", "spring-boot:run"]
