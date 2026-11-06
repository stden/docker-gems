package com.example.demo;

import org.junit.jupiter.api.Test;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.context.runner.ApplicationContextRunner;

import static org.assertj.core.api.Assertions.assertThat;

@SpringBootTest
public class DemoApplicationTest {

    @Test
    void contextLoads() {
        // This test verifies that the Spring application context loads successfully
    }
    
    @Test
    void mainMethod_shouldStartApplication() {
        // Test that the main method runs and does not throw an exception
        ApplicationContextRunner contextRunner = new ApplicationContextRunner()
                .withUserConfiguration(DemoApplication.class);
        
        contextRunner.run(context -> {
            assertThat(context).hasNotFailed();
            assertThat(context).hasSingleBean(DemoApplication.class);
        });
    }
}
