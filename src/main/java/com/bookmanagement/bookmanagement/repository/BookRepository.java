package com.bookmanagement.bookmanagement.repository;

import com.bookmanagement.bookmanagement.entity.Book;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface BookRepository extends JpaRepository<Book, Integer> {
  List<Book> findByBookName(String bookName);

}