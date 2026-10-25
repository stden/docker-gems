package com.example.demo.controller;

import com.example.demo.model.Product;
import org.junit.jupiter.api.Test;
import org.springframework.http.HttpStatus;

import java.math.BigDecimal;
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.Executors;
import java.util.concurrent.TimeUnit;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;

class ProductControllerConcurrencyTest {

    @Test
    void categoryQueryAcceptsConcurrentCreate() throws Exception {
        ProductController controller = new ProductController();
        CountDownLatch queryStarted = new CountDownLatch(1);
        CountDownLatch resumeQuery = new CountDownLatch(1);
        Product blockedProduct = new Product() {
            @Override
            public String getCategory() {
                queryStarted.countDown();
                await(resumeQuery);
                return "Audit";
            }
        };
        controller.createProduct(blockedProduct);

        try (var executor = Executors.newSingleThreadExecutor()) {
            var query = executor.submit(() -> controller.getProductsByCategory("Audit"));
            try {
                await(queryStarted);
                controller.createProduct(product("New product"));
            } finally {
                resumeQuery.countDown();
            }
            assertTrue(query.get(5, TimeUnit.SECONDS).contains(blockedProduct));
        }
    }

    @Test
    void updateDoesNotRestoreDeletedProduct() throws Exception {
        ProductController controller = new ProductController();
        Long id = controller.createProduct(product("Original product")).getBody().getId();
        CountDownLatch updateStarted = new CountDownLatch(1);
        CountDownLatch resumeUpdate = new CountDownLatch(1);
        Product replacement = new Product() {
            @Override
            public void setId(Long value) {
                updateStarted.countDown();
                await(resumeUpdate);
                super.setId(value);
            }
        };

        try (var executor = Executors.newSingleThreadExecutor()) {
            var update = executor.submit(() -> controller.updateProduct(id, replacement));
            try {
                await(updateStarted);
                assertEquals(HttpStatus.NO_CONTENT, controller.deleteProduct(id).getStatusCode());
            } finally {
                resumeUpdate.countDown();
            }
            assertEquals(HttpStatus.NOT_FOUND, update.get(5, TimeUnit.SECONDS).getStatusCode());
            assertEquals(HttpStatus.NOT_FOUND, controller.getProductById(id).getStatusCode());
        }
    }

    private static Product product(String name) {
        Product product = new Product();
        product.setName(name);
        product.setCategory("Audit");
        product.setPrice(BigDecimal.ONE);
        return product;
    }

    private static void await(CountDownLatch latch) {
        try {
            assertTrue(latch.await(5, TimeUnit.SECONDS), "The request did not reach the expected state.");
        } catch (InterruptedException error) {
            Thread.currentThread().interrupt();
            throw new AssertionError(error);
        }
    }
}
