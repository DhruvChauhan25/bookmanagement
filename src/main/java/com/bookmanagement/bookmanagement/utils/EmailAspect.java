package com.bookmanagement.bookmanagement.utils;

import org.aspectj.lang.JoinPoint;
import org.aspectj.lang.annotation.After;
import org.aspectj.lang.annotation.Aspect;
import org.aspectj.lang.annotation.Before;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.mail.MailSender;
import org.springframework.mail.SimpleMailMessage;
import org.springframework.stereotype.Component;

@Aspect
@Component
public class EmailAspect {

    @Autowired
    private MailSender mailSender;

    @Before("execution(* com.bookmanagement.bookmanagement.Controller.*Controller.*(..)) && !execution(* com.bookmanagement.bookmanagement.Controller.*Controller.authenticateAndGetToken(..))")
    public void sendEmailBeforeMethodExecution(JoinPoint joinPoint) {
        String methodName = joinPoint.getSignature().getName();
        String to = "dhruv@gmail.com";
        String subject = "Method Execution Started: " + methodName;
        String text = "The method " + methodName + " has started its execution.";
        sendEmail(to, subject, text);
    }

    @After("execution(* com.bookmanagement.bookmanagement.Controller.*Controller.*(..)) && !execution(* com.bookmanagement.bookmanagement.Controller.*Controller.authenticateAndGetToken(..))")
    public void sendEmailAfterMethodExecution(JoinPoint joinPoint) {
        String methodName = joinPoint.getSignature().getName();
        String to = "dhruv@gmail.com";
        String subject = "Method Execution Completed: " + methodName;
        String text = "The method " + methodName + " has completed its execution.";
        sendEmail(to, subject, text);
    }



     void sendEmail(String to, String subject, String text) {
        SimpleMailMessage message = new SimpleMailMessage();
        message.setTo(to);
        message.setSubject(subject);
        message.setText(text);
        mailSender.send(message);
    }
}
