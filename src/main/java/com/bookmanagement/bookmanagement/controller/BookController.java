package com.bookmanagement.bookmanagement.controller;

import com.bookmanagement.bookmanagement.entitydto.BookDTO;
import com.bookmanagement.bookmanagement.service.BookService;
import com.bookmanagement.bookmanagement.kafka.KafkaProducer;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Optional;

@RestController
@RequestMapping("/books")
@SecurityRequirement(name="Bearer-key")
@Tag(name = "Book Details", description = "Endpoints for managing book details")
public class BookController {
    private final Logger logger = LoggerFactory.getLogger(BookController.class);

    private final BookService bookService;
    private final KafkaProducer kafkaProducer;

    @Autowired
    public BookController(
            BookService bookService,
            KafkaProducer kafkaProducer
    ) {
        this.bookService = bookService;
        this.kafkaProducer = kafkaProducer;
    }

    @GetMapping
    @PreAuthorize("hasAuthority('user')")
    @Operation(summary = "Get all books", description = "Get a list of all books", tags = {"Book Details"})
    public ResponseEntity<List<BookDTO>> getAllBooks() {
        logger.debug("Listing all the Users");
        List<BookDTO> books = bookService.getAllBooks();
        return new ResponseEntity<>(books, HttpStatus.OK);
    }

    @GetMapping("/{id}")
    @PreAuthorize("hasAuthority('user')")
    @Operation(summary = "Get book by ID", description = "Get a book by its ID", tags = {"Book Details"})
    public ResponseEntity<BookDTO> getBookById(@PathVariable Long id) {
        logger.debug("Getting all the users By id");
        Optional<BookDTO> bookDTO = bookService.getBookById(id);
        return bookDTO.map(dto -> new ResponseEntity<>(dto, HttpStatus.OK))
                .orElseGet(() -> new ResponseEntity<>(HttpStatus.NOT_FOUND));
    }

    @PutMapping("/{id}")
    @PreAuthorize("hasAuthority('user')")
    @Operation(summary = "Update a book", description = "Update a book by its ID", tags = {"Book Details"})
    public ResponseEntity<BookDTO> updateBook(@PathVariable Long id, @RequestBody BookDTO updatedBookDTO) {
        logger.debug("Updating the user by id");
        BookDTO updatedBook = bookService.updateBook(id, updatedBookDTO);
        return new ResponseEntity<>(updatedBook, HttpStatus.OK);
    }

    @PostMapping
    @PreAuthorize("hasAuthority('user')")
    @Operation(summary = "Save a new book", description = "Save a new book", tags = {"Book Details"})
    public ResponseEntity<BookDTO> saveBook(@RequestBody BookDTO bookDTO) {
        logger.debug("Showing all the Users");
        BookDTO savedBook = bookService.saveBook(bookDTO);
        return new ResponseEntity<>(savedBook, HttpStatus.OK);
    }

    @DeleteMapping("/{id}")
    @PreAuthorize("hasAuthority('user')")
    @Operation(summary = "Delete a book", description = "Delete a book by its ID", tags = {"Book Details"})
    public ResponseEntity<Void> deleteUser(@PathVariable Long id) {
        logger.debug("Deleting up the users by id");
        bookService.deleteBook(id);
        return new ResponseEntity<>(HttpStatus.NO_CONTENT);
    }

    @PostMapping("/kafka")
    @PreAuthorize("hasAuthority('user')")
    public ResponseEntity<Void> saveBookViaKafka(@RequestBody BookDTO bookDTO) {
        logger.debug("Sending book data to Kafka queue");
        kafkaProducer.sendBookToQueue(bookDTO);
        return new ResponseEntity<>(HttpStatus.ACCEPTED);
    }
}