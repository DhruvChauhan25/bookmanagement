package com.bookmanagement.bookmanagement.kafka;

import com.bookmanagement.bookmanagement.entitydto.BookDTO;
import com.bookmanagement.bookmanagement.service.BookService;
import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.kafka.annotation.KafkaListener;
import org.springframework.stereotype.Service;

@Service
public class KafkaConsumer {

    private static final Logger logger = LoggerFactory.getLogger(KafkaConsumer.class);

    private final BookService bookService;
    private final ObjectMapper objectMapper;

    public KafkaConsumer(BookService bookService, ObjectMapper objectMapper) {
        this.bookService = bookService;
        this.objectMapper = objectMapper;
    }

    @KafkaListener(topics = "book-queue", groupId = "book-consumer-group")
    public void consume(String message) {
        try {
            BookDTO bookDTO = objectMapper.readValue(message, BookDTO.class);
            bookService.saveBook(bookDTO);
        } catch (JsonProcessingException e) {
            logger.error("Error processing Kafka message: {}", message, e);
        }
    }
}