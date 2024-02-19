package com.bookmanagement.bookmanagement;

import com.bookmanagement.bookmanagement.utils.MemoryHealthIndicator;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.boot.actuate.health.Health;
import org.springframework.jdbc.core.JdbcTemplate;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class MemoryHealthIndicatorTest {

    @Mock
    private JdbcTemplate jdbcTemplate;

    @InjectMocks
    private MemoryHealthIndicator memoryHealthIndicator;

    @Test
    void testDatabaseConnectionHealthy() {
        // Mock successful query
        when(jdbcTemplate.queryForObject("SELECT 1 FROM dual", Integer.class)).thenReturn(1);

        // Check health status
        Health health = memoryHealthIndicator.health();
        assertEquals(Health.up().withDetail("message", "Database connection is healthy").build(), health);

        // Verify that the query was executed
        verify(jdbcTemplate, times(1)).queryForObject("SELECT 1 FROM dual", Integer.class);
    }

    @Test
    void testDatabaseConnectionUnhealthy() {
        // Mock exception during query execution
        when(jdbcTemplate.queryForObject("SELECT 1 FROM dual", Integer.class)).thenThrow(new RuntimeException("Connection error"));

        // Check health status
        Health health = memoryHealthIndicator.health();
        assertEquals(Health.down().withDetail("message", "Database connection is not healthy").build(), health);

        // Verify that the query was executed
        verify(jdbcTemplate, times(1)).queryForObject("SELECT 1 FROM dual", Integer.class);
    }
}
