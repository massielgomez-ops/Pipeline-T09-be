# Stage 1: Build con tu propia imagen de Maven 
FROM massielgomezpinto/maven:3.9-amazoncorretto-25-alpine AS builder

WORKDIR /app

COPY pom.xml .
COPY src ./src

RUN mvn clean package -DskipTests


# Stage 2: Run con tu propia imagen de Java
FROM massielgomezpinto/eclipse-temurin:25-jre-alpine

WORKDIR /app

# Copiamos el .jar generado
COPY --from=builder /app/target/*.jar app.jar

# Exponemos el puerto (ajústalo si usas otro)
EXPOSE 8085

ENTRYPOINT ["java", "-jar", "app.jar"]


# 1. Construir la imagen desde tu Dockerfile
# docker build -t massielgomezpinto/springboot-sqlserver:1.0 -f dockerfile-massiel/Dockerfile .
# docker build -t massielgomezpinto/springboot-sqlserver:1.0 .

# 2. Ejecutar SQL Server en contenedor
# docker run -e "ACCEPT_EULA=Y" -e "SA_PASSWORD=Admin12345!" -p 1433:1433 --name mssql-server -d mcr.microsoft.com/mssql/server:2022-latest

# 3. Ejecutar tu aplicación Spring Boot
# docker run -d --name springboot-app -p 8085:8085 massielgomezpinto/springboot-sqlserver:1.0

# 4. Subir tu imagen a DockerHub
# docker push massielgomezpinto/springboot-sqlserver:1.0