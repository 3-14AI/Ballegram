# Runtime Stage
FROM --platform=linux/amd64 eclipse-temurin:21-jre
WORKDIR /app

# Copy the JAR built by the external environment (CI or local `bal build`)
COPY target/bin/ballegram.jar /app/ballegram.jar

# Create a non-root user
RUN useradd -m ballegram && \
    chown ballegram:ballegram /app/ballegram.jar

USER ballegram

# Expose the port (API Service uses 9090)
EXPOSE 9090

CMD ["java", "-jar", "ballegram.jar"]
