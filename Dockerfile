# Base Java image - think of this as the minimum requirement to run your Java application
FROM eclipse-temurin:17-jdk-alpine

# Set the working directory for the final application container
WORKDIR /app

# Metadata about image creator 
LABEL maintainer="aslahea"

# Copy your jar file into the Docker image
COPY target/my-maven-app-1.0-SNAPSHOT.jar /app/my-maven-app.jar

# Command to run your application
ENTRYPOINT ["java", "-jar", "my-maven-app.jar"]

