package com.bookmanagement.bookmanagement;

import com.bookmanagement.bookmanagement.entity.UserInfo;
import com.bookmanagement.bookmanagement.repository.UserInfoRepository;
import com.bookmanagement.bookmanagement.service.UserInfoUserDetailsService;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.core.userdetails.UsernameNotFoundException;

import java.util.Optional;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class UserInfoUserDetailsTest {

    @Mock
    private UserInfoRepository repository;

    @InjectMocks
    private UserInfoUserDetailsService userDetailsService;

    @Test
    void testLoadUserByUsername_WhenUserExists() {
        UserInfo userInfo = new UserInfo();
        userInfo.setName("testUser");
        userInfo.setRoles("ROLE_USER"); // Set roles to a non-null value
        when(repository.findByName("testUser")).thenReturn(Optional.of(userInfo));
        UserDetails userDetails = userDetailsService.loadUserByUsername("testUser");
        assertEquals(userInfo.getName(), userDetails.getUsername());
    }

    @Test
    void testLoadUserByUsername_WhenUserNotExists() {
        when(repository.findByName(anyString())).thenReturn(Optional.empty());
        assertThrows(UsernameNotFoundException.class, () -> userDetailsService.loadUserByUsername("nonexistentUser"));
    }
}