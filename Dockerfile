FROM openjdk:17

WORKDIR /app

COPY target/bookmanagement.jar /app/bookmanagement.jar

ENV SPRING_PROFILES_ACTIVE=dev

EXPOSE 8080

CMD ["java", "-jar", "bookmanagement.jar"]
