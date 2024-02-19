package com.bookmanagement.bookmanagement;

import com.bookmanagement.bookmanagement.entity.Book;
import org.junit.jupiter.api.Test;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotEquals;

class BookTest {

    @Test
    void testBookEntity() {
        // Arrange
        Book book = new Book();
        book.setId(1);
        book.setBookName("Test Book");
        book.setAuthor("Test Author");
        book.setPrice(20);

        // Act and Assert
        assertEquals(1, book.getId());
        assertEquals("Test Book", book.getBookName());
        assertEquals("Test Author", book.getAuthor());
        assertEquals(20, book.getPrice());
    }

    @Test
    void testEqualsAndHashCode() {
        Book book1 = new Book();
        book1.setId(1);
        book1.setBookName("Test Book");
        book1.setAuthor("Test Author");
        book1.setPrice(20);

        Book book2 = new Book();
        book2.setId(1);
        book2.setBookName("Test Book");
        book2.setAuthor("Test Author");
        book2.setPrice(20);
        assertEquals(book1, book2);
        assertEquals(book1.hashCode(), book2.hashCode());
    }

    @Test
    void testNotEquals() {
        Book book1 = new Book();
        book1.setId(1);
        book1.setBookName("Test Book 1");
        book1.setAuthor("Test Author 1");
        book1.setPrice(20);

        Book book2 = new Book();
        book2.setId(2);
        book2.setBookName("Test Book 2");
        book2.setAuthor("Test Author 2");
        book2.setPrice(30);
        assertNotEquals(book1, book2);
    }
}