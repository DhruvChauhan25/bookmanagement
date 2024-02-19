//package com.bookmanagement.bookmanagement;
//
//import com.bookmanagement.bookmanagement.Controller.BookController;
//import com.bookmanagement.bookmanagement.EntityDto.BookDTO;
//import com.bookmanagement.bookmanagement.Repository.BookRepository;
//import com.bookmanagement.bookmanagement.Service.BookService;
//import com.fasterxml.jackson.databind.ObjectMapper;
//import org.junit.jupiter.api.Test;
//import org.mockito.InjectMocks;
//import org.mockito.Mock;
//import org.springframework.beans.factory.annotation.Autowired;
//import org.springframework.boot.test.autoconfigure.jdbc.AutoConfigureTestDatabase;
//import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
//import org.springframework.boot.test.context.SpringBootTest;
//import org.springframework.context.annotation.ComponentScan;
//import org.springframework.http.MediaType;
//import org.springframework.security.test.context.support.WithMockUser;
//import org.springframework.test.context.TestPropertySource;
//import org.springframework.test.web.servlet.MockMvc;
//
//import java.util.Arrays;
//import java.util.Optional;
//
//import static org.mockito.ArgumentMatchers.any;
//import static org.mockito.Mockito.when;
//import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
//import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
//import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;
//
//@SpringBootTest
//@AutoConfigureMockMvc
//@AutoConfigureTestDatabase(replace = AutoConfigureTestDatabase.Replace.NONE)
//@TestPropertySource(locations = "classpath:application-test.properties")
//@ComponentScan(basePackages = "com.bookmanagement")
//public class BookmanagementApplicationTests {
//
//    @Autowired
//    private MockMvc mockMvc;
//
//    @Autowired
//    private ObjectMapper objectMapper;
//
//    @Mock
//    private BookService bookService;
//
//    @Mock
//    private BookRepository bookRepository;
//
//    @InjectMocks
//    private BookController bookController;
//
//    @Test
//    @WithMockUser(authorities = "user")
//    public void testGetAllBooks() throws Exception {
//        when(bookService.getAllBooks()).thenReturn(Arrays.asList(new BookDTO()));
//
//        mockMvc.perform(get("/books")
//                        .contentType(MediaType.APPLICATION_JSON))
//                .andExpect(status().isOk())
//                .andExpect(jsonPath("$[0].id").exists()); // Update with actual field in your DTO
//    }
//
//    @Test
//    @WithMockUser(authorities = "user")
//    public void testGetBookById() throws Exception {
//        Long bookId = 1L;
//        when(bookService.getBookById(bookId)).thenReturn(Optional.of(new BookDTO()));
//
//        mockMvc.perform(get("/books/{id}", bookId)
//                        .contentType(MediaType.APPLICATION_JSON))
//                .andExpect(status().isOk())
//                .andExpect(jsonPath("$.id").exists()); // Update with actual field in your DTO
//    }
//
//    @Test
//    @WithMockUser(authorities = "user")
//    public void testUpdateBook() throws Exception {
//        Long bookId = 1L;
//        BookDTO updatedBookDTO = new BookDTO();
//        updatedBookDTO.setBookName("Updated Book");
//
//        when(bookService.updateBook(bookId, updatedBookDTO)).thenReturn(updatedBookDTO);
//
//        mockMvc.perform(put("/books/{id}", bookId)
//                        .contentType(MediaType.APPLICATION_JSON)
//                        .content(asJsonString(updatedBookDTO)))
//                .andExpect(status().isOk())
//                .andExpect(jsonPath("$.bookName").value("Updated Book"));
//    }
//
//    @Test
//    @WithMockUser(authorities = "user")
//    public void testSaveBook() throws Exception {
//        BookDTO bookDTO = new BookDTO();
//        bookDTO.setBookName("New Book");
//
//        when(bookService.saveBook(any(BookDTO.class))).thenReturn(bookDTO);
//
//        mockMvc.perform(post("/books")
//                        .contentType(MediaType.APPLICATION_JSON)
//                        .content(asJsonString(bookDTO)))
//                .andExpect(status().isOk())
//                .andExpect(jsonPath("$.bookName").value("New Book"));
//    }
//
//    @Test
//    @WithMockUser(authorities = "user")
//    public void testDeleteBook() throws Exception {
//        Long bookId = 1L;
//
//        mockMvc.perform(delete("/books/{id}", bookId)
//                        .contentType(MediaType.APPLICATION_JSON))
//                .andExpect(status().isNoContent());
//    }
//
//    private String asJsonString(final Object obj) {
//        try {
//            return new ObjectMapper().writeValueAsString(obj);
//        } catch (Exception e) {
//            throw new RuntimeException(e);
//        }
//    }
//}
//
//
//
//
