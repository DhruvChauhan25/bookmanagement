package com.bookmanagement.bookmanagement.service;

import com.bookmanagement.bookmanagement.entity.Book;
import com.bookmanagement.bookmanagement.entitydto.BookDTO;
import com.bookmanagement.bookmanagement.kafka.KafkaProducer;
import com.bookmanagement.bookmanagement.repository.BookRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.cache.annotation.CacheEvict;
import org.springframework.cache.annotation.CachePut;
import org.springframework.cache.annotation.Cacheable;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.Optional;
import java.util.stream.Collectors;

import static org.apache.kafka.common.utils.Utils.sleep;


@Service
public class BookService {
    private final Logger logger = LoggerFactory.getLogger(BookService.class);

    private final BookRepository bookRepository;
    private final KafkaProducer kafkaProducer;

    @Autowired
    public BookService(BookRepository bookRepository, KafkaProducer kafkaProducer) {
        this.bookRepository = bookRepository;
        this.kafkaProducer = kafkaProducer;
    }

    @Cacheable("books")
    public List<BookDTO> getAllBooks() {
        logger.debug("Showing all up the users");
        List<Book> books = bookRepository.findAll();
        sleep(100);
        return books.stream()
                .map(BookDTO::fromEntity)
                .collect(Collectors.toList());
    }

    public Optional<BookDTO> getBookById(Long id) {
        logger.debug("Finding all the user");
        return bookRepository.findById(Math.toIntExact(id))
                .map(BookDTO::fromEntity);
    }

    @CacheEvict(value="books",allEntries = true)
    @CachePut(value = "books",key = "#result.id")
    public BookDTO saveBook(BookDTO bookDTO) {
        logger.debug("Saving the book");
        Book book = bookRepository.save(BookDTO.toEntity(bookDTO));
        return BookDTO.fromEntity(book);
    }

    public void deleteBook(Long id) {
        logger.debug("Deleting up the users");
        bookRepository.deleteById(Math.toIntExact(id));
    }

    public BookDTO updateBook(Long id, BookDTO updatedBookDTO) {
        logger.debug("Updating the book by id");
        Optional<Book> optionalBook = bookRepository.findById(Math.toIntExact(id));

        if (optionalBook.isPresent()) {
            Book existingBook = optionalBook.get();
            existingBook.setBookName(updatedBookDTO.getBookName());
            existingBook.setAuthor(updatedBookDTO.getAuthor());
            existingBook.setPrice(updatedBookDTO.getPrice());

            Book updatedBook = bookRepository.save(existingBook);
            return BookDTO.fromEntity(updatedBook);
        } else {
            throw new IllegalArgumentException("Book with id " + id + " not found");
        }
    }

    public BookDTO saveBookAndPublishToKafka(BookDTO bookDTO) {
        logger.debug("Saving the book");
        Book book = bookRepository.save(BookDTO.toEntity(bookDTO));
        kafkaProducer.sendBookToQueue(BookDTO.fromEntity(book));

        return BookDTO.fromEntity(book);
    }
}