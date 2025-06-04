package com.example.webhook.service;

import com.fasterxml.jackson.databind.ObjectMapper;
import org.apache.commons.codec.digest.HmacAlgorithms;
import org.apache.commons.codec.digest.HmacUtils;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;

import java.util.Map;

@Service
public class SignatureService {

    private static final Logger logger = LoggerFactory.getLogger(SignatureService.class);
    private final ObjectMapper objectMapper = new ObjectMapper();

    public boolean verifySignature(Map<String, Object> payload, String signature, String secret) {
        try {
            // Convert payload to JSON string
            String payloadJson = objectMapper.writeValueAsString(payload);
            
            // Calculate expected signature
            String expectedSignature = "sha256=" + new HmacUtils(HmacAlgorithms.HMAC_SHA_256, secret)
                    .hmacHex(payloadJson);
            
            logger.debug("Expected signature: {}", expectedSignature);
            logger.debug("Received signature: {}", signature);
            
            return expectedSignature.equals(signature);
        } catch (Exception e) {
            logger.error("Error verifying signature: {}", e.getMessage());
            return false;
        }
    }
}
