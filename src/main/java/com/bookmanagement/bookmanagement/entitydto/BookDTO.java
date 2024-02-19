package com.bookmanagement.bookmanagement.entitydto;

import com.bookmanagement.bookmanagement.entity.Book;
import com.fasterxml.jackson.annotation.JsonProperty;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.ToString;

import java.io.Serializable;  // Import the Serializable interface

@Data
@NoArgsConstructor
@AllArgsConstructor
@ToString
public class BookDTO implements Serializable {

    private static final long serialVersionUID = 1L;  // Include the serialVersionUID

    @JsonProperty("id")
    private Integer id;

    @JsonProperty("bookName")
    private String bookName;

    @JsonProperty("author")
    private String author;

    @JsonProperty("price")
    private Integer price;

    public static BookDTO fromEntity(Book book) {
        return new BookDTO(
                book.getId(),
                book.getBookName(),
                book.getAuthor(),
                book.getPrice()
        );
    }

    public static Book toEntity(BookDTO bookDTO) {
        Book book = new Book();
        book.setId(bookDTO.getId());
        book.setBookName(bookDTO.getBookName());
        book.setAuthor(bookDTO.getAuthor());
        book.setPrice(bookDTO.getPrice());
        return book;
    }
}
