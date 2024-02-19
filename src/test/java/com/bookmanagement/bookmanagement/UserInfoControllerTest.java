//package com.bookmanagement.bookmanagement;
//
//import com.bookmanagement.bookmanagement.controller.UserController;
//import com.bookmanagement.bookmanagement.entity.AuthRequest;
//import com.bookmanagement.bookmanagement.entity.UserInfo;
//import com.bookmanagement.bookmanagement.repository.UserInfoRepository;
//import com.bookmanagement.bookmanagement.service.JwtService;
//import com.bookmanagement.bookmanagement.service.UserService;
//import org.junit.jupiter.api.Test;
//import org.mockito.InjectMocks;
//import org.mockito.Mock;
//import org.springframework.beans.factory.annotation.Autowired;
//import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
//import org.springframework.http.MediaType;
//import org.springframework.security.authentication.AuthenticationManager;
//import org.springframework.security.authentication.BadCredentialsException;
//import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
//import org.springframework.test.web.servlet.MockMvc;
//import org.springframework.test.web.servlet.request.MockMvcRequestBuilders;
//import org.springframework.test.web.servlet.result.MockMvcResultMatchers;
//
//import java.util.Optional;
//
//import static org.mockito.Mockito.*;
//
//@WebMvcTest(UserController.class)
//class UserInfoControllerTest {
//
//    @Mock
//    private AuthenticationManager authenticationManager;
//
//    @Mock
//    private JwtService jwtService;
//
//    @Mock
//    private UserService userService;
//
//    @Mock
//    private UserInfoRepository userInfoRepository;  // Mock the repository
//
//    @InjectMocks
//    private UserController userController;  // Create UserController and inject mocks
//
//    @Autowired
//    private MockMvc mockMvc;
//
//    @Test
//    void testAddNewUser() throws Exception {
//        UserInfo userInfo = new UserInfo();
//
//        // Mock the repository response
//        when(userInfoRepository.save(userInfo)).thenReturn(userInfo);
//
//        // Perform the POST request
//        mockMvc.perform(MockMvcRequestBuilders.post("/auth/new")
//                        .contentType(MediaType.APPLICATION_JSON)
//                        .content("{}"))
//                .andExpect(MockMvcResultMatchers.status().isOk())
//                .andExpect(MockMvcResultMatchers.content().string("entity added to system."));
//
//        // Verify that the repository method was called
//        verify(userInfoRepository, times(1)).save(userInfo);
//    }
//
//    @Test
//    void testAddNewUser_ServiceError() throws Exception {
//        UserInfo userInfo = new UserInfo();
//
//        // Mock the repository response
//        when(userInfoRepository.save(userInfo)).thenReturn(userInfo);
//
//        // Mock the service response
//        when(userService.addUser(userInfo)).thenThrow(new RuntimeException("Error in adding user."));
//
//        // Perform the POST request
//        mockMvc.perform(MockMvcRequestBuilders.post("/auth/new")
//                        .contentType(MediaType.APPLICATION_JSON)
//                        .content("{}"))
//                .andExpect(MockMvcResultMatchers.status().isInternalServerError())
//                .andExpect(MockMvcResultMatchers.content().string("Error in adding user."));
//
//        // Verify that the repository and service methods were called
//        verify(userInfoRepository, times(1)).save(userInfo);
//        verify(userService, times(1)).addUser(userInfo);
//    }
//
//    @Test
//    void testAuthenticateAndGetToken() throws Exception {
//        AuthRequest authRequest = new AuthRequest();
//        authRequest.setUsername("testUser");
//        authRequest.setPassword("testPassword");
//
//        UserInfo userInfo = new UserInfo();
//        userInfo.setName("testUser");
//
//        // Mock the repository response
//        when(userInfoRepository.findByName("testUser")).thenReturn(Optional.of(userInfo));
//
//        // Mock the authentication response
//        when(authenticationManager.authenticate(any(UsernamePasswordAuthenticationToken.class))).thenReturn(null);
//
//        // Mock the service response
//        when(jwtService.generateToken("testUser")).thenReturn("testToken");
//
//        // Perform the POST request
//        mockMvc.perform(MockMvcRequestBuilders.post("/auth/authenticate")
//                        .contentType(MediaType.APPLICATION_JSON)
//                        .content("{\"username\":\"testUser\", \"password\":\"testPassword\"}"))
//                .andExpect(MockMvcResultMatchers.status().isOk())
//                .andExpect(MockMvcResultMatchers.content().string("testToken"));
//
//        // Verify that the repository, authentication, and service methods were called
//        verify(userInfoRepository, times(1)).findByName("testUser");
//        verify(authenticationManager, times(1)).authenticate(any(UsernamePasswordAuthenticationToken.class));
//        verify(jwtService, times(1)).generateToken("testUser");
//    }
//
//    @Test
//    void testAuthenticateAndGetToken_UserNotFound() throws Exception {
//        AuthRequest authRequest = new AuthRequest();
//        authRequest.setUsername("nonExistentUser");
//        authRequest.setPassword("testPassword");
//
//        // Mock the repository response for a non-existent user
//        when(userInfoRepository.findByName("nonExistentUser")).thenReturn(Optional.empty());
//
//        // Perform the POST request
//        mockMvc.perform(MockMvcRequestBuilders.post("/auth/authenticate")
//                        .contentType(MediaType.APPLICATION_JSON)
//                        .content("{\"username\":\"nonExistentUser\", \"password\":\"testPassword\"}"))
//                .andExpect(MockMvcResultMatchers.status().isUnauthorized())
//                .andExpect(MockMvcResultMatchers.content().string("User not found"));
//
//        // Verify that the repository method was called
//        verify(userInfoRepository, times(1)).findByName("nonExistentUser");
//    }
//
//    @Test
//    void testAuthenticateAndGetToken_AuthenticationFailure() throws Exception {
//        AuthRequest authRequest = new AuthRequest();
//        authRequest.setUsername("testUser");
//        authRequest.setPassword("invalidPassword");
//
//        UserInfo userInfo = new UserInfo();
//        userInfo.setName("testUser");
//
//        // Mock the repository response
//        when(userInfoRepository.findByName("testUser")).thenReturn(Optional.of(userInfo));
//
//        // Mock the authentication response for invalid credentials
//        when(authenticationManager.authenticate(any(UsernamePasswordAuthenticationToken.class)))
//                .thenThrow(new BadCredentialsException("Invalid credentials"));
//
//        // Perform the POST request
//        mockMvc.perform(MockMvcRequestBuilders.post("/auth/authenticate")
//                        .contentType(MediaType.APPLICATION_JSON)
//                        .content("{\"username\":\"testUser\", \"password\":\"invalidPassword\"}"))
//                .andExpect(MockMvcResultMatchers.status().isUnauthorized())
//                .andExpect(MockMvcResultMatchers.content().string("Invalid credentials"));
//
//        // Verify that the repository and authentication methods were called
//        verify(userInfoRepository, times(1)).findByName("testUser");
//        verify(authenticationManager, times(1)).authenticate(any(UsernamePasswordAuthenticationToken.class));
//    }
//
//    @Test
//    void testAuthenticateAndGetToken_JwtGenerationFailure() throws Exception {
//        AuthRequest authRequest = new AuthRequest();
//        authRequest.setUsername("testUser");
//        authRequest.setPassword("testPassword");
//
//        UserInfo userInfo = new UserInfo();
//        userInfo.setName("testUser");
//
//        // Mock the repository response
//        when(userInfoRepository.findByName("testUser")).thenReturn(Optional.of(userInfo));
//
//        // Mock the authentication response
//        when(authenticationManager.authenticate(any(UsernamePasswordAuthenticationToken.class))).thenReturn(null);
//
//        // Mock the service response for JWT generation failure
//        when(jwtService.generateToken("testUser")).thenThrow(new RuntimeException("JWT generation failed"));
//
//        // Perform the POST request
//        mockMvc.perform(MockMvcRequestBuilders.post("/auth/authenticate")
//                        .contentType(MediaType.APPLICATION_JSON)
//                        .content("{\"username\":\"testUser\", \"password\":\"testPassword\"}"))
//                .andExpect(MockMvcResultMatchers.status().isInternalServerError())
//                .andExpect(MockMvcResultMatchers.content().string("JWT generation failed"));
//
//        // Verify that the repository, authentication, and service methods were called
//        verify(userInfoRepository, times(1)).findByName("testUser");
//        verify(authenticationManager, times(1)).authenticate(any(UsernamePasswordAuthenticationToken.class));
//        verify(jwtService, times(1)).generateToken("testUser");
//    }
//}
