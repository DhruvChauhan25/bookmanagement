package com.bookmanagement.bookmanagement;

import com.bookmanagement.bookmanagement.entitydto.BookDTO;
import com.bookmanagement.bookmanagement.kafka.KafkaConsumer;
import com.bookmanagement.bookmanagement.kafka.KafkaProducer;
import com.bookmanagement.bookmanagement.service.BookService;
import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.MockitoAnnotations;
import org.springframework.kafka.core.KafkaTemplate;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

class KafkaMessagingTest {

    @Mock
    private BookService bookService;

    @Mock
    private ObjectMapper objectMapper;

    @Mock
    private KafkaTemplate<String, BookDTO> kafkaTemplate;

    @InjectMocks
    private KafkaConsumer kafkaConsumer;

    @InjectMocks
    private KafkaProducer kafkaProducer;

    @BeforeEach
    void setUp() {
        MockitoAnnotations.openMocks(this);
    }

    @Test
    void testConsume() throws JsonProcessingException {
        String sampleMessage = "{'id': 1, 'bookName': 'Sample Book', 'author': 'John Doe', 'price': 20}";
        BookDTO expectedBookDTO = new BookDTO(1, "Sample Book", "John Doe", 20);

        when(objectMapper.readValue(any(String.class), eq(BookDTO.class)))
                .thenReturn(expectedBookDTO);
        kafkaConsumer.consume(sampleMessage);
        verify(bookService).saveBook(expectedBookDTO);
    }

    @Test
    void testSendBookToQueue() {
        BookDTO bookDTO = new BookDTO(1, "Sample Book", "John Doe", 20);
        kafkaProducer.sendBookToQueue(bookDTO);
        verify(kafkaTemplate).send("book-queue", bookDTO);
    }
}