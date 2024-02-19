package com.bookmanagement.bookmanagement.config;

import com.bookmanagement.bookmanagement.entitydto.BookDTO;
import com.bookmanagement.bookmanagement.kafka.KafkaProducer;
import org.apache.kafka.clients.admin.NewTopic;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.kafka.config.TopicBuilder;
import org.springframework.kafka.core.KafkaTemplate;

@Configuration
public class KafkaConfig {
    @Bean
    public NewTopic bookQueue() {
        return TopicBuilder.name("book-queue")
                .partitions(1)
                .replicas(1)
                .build();
    }

    @Bean
    public KafkaProducer kafkaProducer(KafkaTemplate<String, BookDTO> kafkaTemplate) {
        return new KafkaProducer(kafkaTemplate);
    }
}
