package com.bookmanagement.bookmanagement;


import com.bookmanagement.bookmanagement.entity.AuthRequest;
import org.junit.jupiter.api.Test;
import org.mockito.Mockito;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.when;

class AuthRequestTest {

    @Test
    void testNoArgsConstructor() {
        AuthRequest authRequest = new AuthRequest();
        assertNotNull(authRequest);
    }

    @Test
    void testAllArgsConstructor() {
        String username = "testUser";
        String password = "testPassword";
        AuthRequest authRequest = new AuthRequest(username, password);
        assertEquals(username, authRequest.getUsername());
        assertEquals(password, authRequest.getPassword());
    }

    @Test
    void testEqualsAndHashCode() {
        AuthRequest authRequest1 = new AuthRequest("user1", "pass1");
        AuthRequest authRequest2 = new AuthRequest("user1", "pass1");
        AuthRequest authRequest3 = new AuthRequest("user2", "pass2");
        assertEquals(authRequest1, authRequest2);
        assertEquals(authRequest1.hashCode(), authRequest2.hashCode());
        assertNotEquals(authRequest1, authRequest3);
    }

    @Test
    void testNotEquals() {
        AuthRequest authRequest1 = new AuthRequest("user1", "pass1");
        AuthRequest authRequest2 = new AuthRequest("user2", "pass2");
        assertNotEquals(authRequest1, authRequest2);
    }

    @Test
    void testToString() {
        AuthRequest authRequest = new AuthRequest("testUser", "testPassword");
        String toStringResult = authRequest.toString();
        assertNotNull(toStringResult);
        assertTrue(toStringResult.contains("testUser"));
        assertTrue(toStringResult.contains("testPassword"));
    }

    @Test
    void testMockito() {
        AuthRequest authRequestMock = Mockito.mock(AuthRequest.class);
        when(authRequestMock.getUsername()).thenReturn("mockUser");
        when(authRequestMock.getPassword()).thenReturn("mockPassword");
        String username = authRequestMock.getUsername();
        String password = authRequestMock.getPassword();
        assertEquals("mockUser", username);
        assertEquals("mockPassword", password);
    }
}