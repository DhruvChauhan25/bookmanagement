package com.bookmanagement.bookmanagement;

import io.swagger.v3.oas.annotations.enums.SecuritySchemeType;
import io.swagger.v3.oas.annotations.security.SecurityScheme;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springdoc.core.customizers.OpenApiCustomizer;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.cache.annotation.EnableCaching;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.ComponentScan;
import org.springframework.context.annotation.Configuration;
import org.springframework.scheduling.annotation.EnableScheduling;

@SpringBootApplication
@ComponentScan("com.bookmanagement.bookmanagement")
@EnableScheduling
@EnableCaching
public class BookmanagementApplication {

	public static void main(String[] args) {
		Logger logger= LoggerFactory.getLogger(BookmanagementApplication.class);
		logger.debug("Main application is Executed");
		SpringApplication.run(BookmanagementApplication.class, args);
	}

	@Configuration
	@SecurityScheme(
			name = "Bearer-key",
			type = SecuritySchemeType.HTTP,
			scheme = "Bearer",
			bearerFormat = "JWT"
	)
	public class SwaggerConfig {

		@Bean
		public OpenApiCustomizer openApiCustomizer() {
			return openApi -> openApi.info(
							new io.swagger.v3.oas.models.info.Info()
									.title("Department API")
									.version("1.0")
									.description("Documentation for Department API"))
					.addSecurityItem(new io.swagger.v3.oas.models.security.SecurityRequirement().addList("Bearer-key"));
		}
	}
}
