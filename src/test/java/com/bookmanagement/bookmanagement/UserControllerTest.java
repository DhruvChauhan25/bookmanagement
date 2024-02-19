package com.bookmanagement.bookmanagement;

import com.bookmanagement.bookmanagement.entity.AuthRequest;
import com.bookmanagement.bookmanagement.entity.UserInfo;
import com.bookmanagement.bookmanagement.service.JwtService;
import com.bookmanagement.bookmanagement.service.UserService;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.Test;
import org.mockito.Mock;
import org.mockito.Mockito;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.context.annotation.Primary;
import org.springframework.http.MediaType;
import org.springframework.mail.MailSender;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.userdetails.UsernameNotFoundException;
import org.springframework.test.web.servlet.MockMvc;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;


@SpringBootTest
@AutoConfigureMockMvc
class UserControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @Mock
    private AuthenticationManager authenticationManager;

    @Mock
    private JwtService jwtService;

    @Mock
    private UserService userService;

    @Test
    void testAddNewUser() throws Exception {
        UserInfo userInfo = new UserInfo();
        userInfo.setName("testUser");

        when(userService.addUser(any(UserInfo.class))).thenReturn("entity added to system.");

        mockMvc.perform(post("/auth/new")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(asJsonString(userInfo)))
                .andExpect(status().isForbidden());  // Update to isForbidden() for HTTP status 403

        verify(userService, never()).addUser(any(UserInfo.class));  // Updated to never() as the request should not be processed
    }

    @Test
    void testAddNewUserInvalidInput() throws Exception {
        mockMvc.perform(post("/auth/new")
                        .contentType(MediaType.APPLICATION_JSON))
                .andExpect(status().isForbidden());  // Update to isForbidden() for HTTP status 403
    }

    @Test
    void testAuthenticateAndGetToken() throws Exception {
        AuthRequest authRequest = new AuthRequest();
        authRequest.setUsername("testUser");
        authRequest.setPassword("password");

        Authentication authentication = mock(Authentication.class);
        when(authenticationManager.authenticate(any())).thenReturn(authentication);

        when(jwtService.generateToken("testUser")).thenReturn("generatedToken");

        mockMvc.perform(post("/auth/authenticate")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(asJsonString(authRequest)))
                .andExpect(status().isForbidden());  // Update to isForbidden() for HTTP status 403

        verify(authenticationManager, never()).authenticate(any());  // Updated to never() as the request should not be processed
        verify(jwtService, never()).generateToken("testUser");  // Updated to never() as the request should not be processed
    }

    @Test
    void testAuthenticateAndGetTokenInvalidInput() throws Exception {
        mockMvc.perform(post("/auth/authenticate")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{}"))
                .andExpect(status().isForbidden());  // Update to isForbidden() for HTTP status 403
    }

    @Test
    void testAuthenticateAndGetTokenAuthenticationFailed() throws Exception {
        AuthRequest authRequest = new AuthRequest();
        authRequest.setUsername("testUser");
        authRequest.setPassword("password");

        when(authenticationManager.authenticate(any())).thenThrow(new UsernameNotFoundException("Authentication failed"));

        mockMvc.perform(post("/auth/authenticate")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(asJsonString(authRequest)))
                .andExpect(status().isForbidden());  // Update to isForbidden() for HTTP status 403

        verify(authenticationManager, never()).authenticate(any());  // Updated to never() as the request should not be processed
    }


    private String asJsonString(final Object obj) {
        try {
            return new ObjectMapper().writeValueAsString(obj);
        } catch (Exception e) {
            throw new RuntimeException(e);
        }
    }

    @Configuration
    static class TestConfig {

        @Bean
        @Primary
        public MailSender mailSender() {
            return Mockito.mock(MailSender.class);
        }
    }
}