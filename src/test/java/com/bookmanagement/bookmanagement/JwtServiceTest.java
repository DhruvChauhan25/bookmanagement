package com.bookmanagement.bookmanagement;

import com.bookmanagement.bookmanagement.service.JwtService;
import org.junit.jupiter.api.Test;
import org.springframework.security.core.userdetails.User;
import org.springframework.security.core.userdetails.UserDetails;

import java.util.ArrayList;

import static org.junit.jupiter.api.Assertions.*;

public class JwtServiceTest {

    @Test
    void testExtractUsername_ValidToken_ReturnsUsername() {
        JwtService jwtService = new JwtService();
        String token = jwtService.generateToken("testUser");
        String username = jwtService.extractUsername(token);
        assertEquals("testUser", username);
    }

    @Test
    void testExtractExpiration_ValidToken_ReturnsExpirationDate() {
        JwtService jwtService = new JwtService();
        String token = jwtService.generateToken("testUser");
        assertNotNull(jwtService.extractExpiration(token));
    }

    @Test
    void testValidateToken_ValidTokenAndUserDetails_ReturnsTrue() {
        JwtService jwtService = new JwtService();
        String token = jwtService.generateToken("testUser");
        UserDetails userDetails = new User("testUser", "password", new ArrayList<>());
        assertTrue(jwtService.validateToken(token, userDetails));
    }

    // Add more test methods...
}

