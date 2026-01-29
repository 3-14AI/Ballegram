# Stage 1: Build the JAR
FROM --platform=linux/amd64 ballerina/ballerina:latest AS builder
USER root
WORKDIR /app
COPY . .
# Build the project (skip tests to speed up build in this stage if CI handles tests separately,
# but running them is also fine. CI usually runs tests in a separate job).
RUN bal build --skip-tests

# Stage 2: Create the runtime image
FROM --platform=linux/amd64 eclipse-temurin:17-jre
WORKDIR /app

# Copy the built JAR from the builder stage
# The JAR is located in target/bin/<package_name>.jar
COPY --from=builder /app/target/bin/ballegram.jar /app/ballegram.jar

# Create a non-root user
RUN useradd -m ballegram && \
    chown ballegram:ballegram /app/ballegram.jar

USER ballegram

# Expose the port (API Service uses 9090)
EXPOSE 9090

CMD ["java", "-jar", "ballegram.jar"]
