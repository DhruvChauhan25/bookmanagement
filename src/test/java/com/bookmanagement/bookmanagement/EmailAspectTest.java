package com.bookmanagement.bookmanagement;


import com.bookmanagement.bookmanagement.utils.EmailAspect;
import org.aspectj.lang.JoinPoint;
import org.aspectj.lang.Signature;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.mail.MailSender;
import org.springframework.mail.SimpleMailMessage;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class EmailAspectTest {

    @Mock
    private MailSender mailSender;

    @InjectMocks
    private EmailAspect emailAspect;

    @Test
    void testSendEmailBeforeMethodExecution() {
        JoinPoint joinPoint = mock(JoinPoint.class);
        Signature signature = mock(Signature.class);
        when(joinPoint.getSignature()).thenReturn(signature);
        when(signature.getName()).thenReturn("methodName");

        emailAspect.sendEmailBeforeMethodExecution(joinPoint);

        verify(mailSender, times(1)).send(any(SimpleMailMessage.class));
    }

    @Test
    void testSendEmailAfterMethodExecution() {
        JoinPoint joinPoint = mock(JoinPoint.class);
        Signature signature = mock(Signature.class);
        when(joinPoint.getSignature()).thenReturn(signature);
        when(signature.getName()).thenReturn("methodName");

        emailAspect.sendEmailAfterMethodExecution(joinPoint);

        verify(mailSender, times(1)).send(any(SimpleMailMessage.class));
    }
}