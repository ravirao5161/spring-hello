############### Stage 1: Build with Maven ###############
FROM registry.access.redhat.com/ubi8/openjdk-17 AS builder

WORKDIR /opt/app-root

# Copy pom.xml first for caching dependencies
COPY pom.xml .
RUN mvn -q dependency:go-offline

# Copy project sources
COPY src ./src

# Build the JAR (skip tests if you want faster builds)
RUN mvn clean package -DskipTests


############### Stage 2: Runtime (small, OpenShift-safe) ###############
FROM registry.access.redhat.com/ubi8/openjdk-17-runtime

# Create working directory
WORKDIR /app

# Copy built artifact
COPY --from=builder /app/target/*.jar app.jar

# Allow arbitrary user (assigned by OpenShift) to run this
RUN chmod -R g+rwX /app

# Do NOT specify USER, OpenShift injects a random UID automatically

EXPOSE 8080

ENTRYPOINT ["java", "-jar", "/app/app.jar"]