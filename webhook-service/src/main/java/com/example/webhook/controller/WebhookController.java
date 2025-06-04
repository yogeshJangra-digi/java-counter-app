package com.example.webhook.controller;

import com.example.webhook.service.GitService;
import com.example.webhook.service.SignatureService;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

@RestController
public class WebhookController {

    private static final Logger logger = LoggerFactory.getLogger(WebhookController.class);

    @Autowired
    private GitService gitService;

    @Autowired
    private SignatureService signatureService;

    @Value("${webhook.secret:}")
    private String webhookSecret;

    @Value("${git.branch:main}")
    private String gitBranch;

    @Value("${webhook.debug:false}")
    private boolean debug;

    @PostMapping("/webhook")
    public ResponseEntity<String> handleWebhook(
            @RequestBody Map<String, Object> payload,
            @RequestHeader(value = "X-Hub-Signature-256", required = false) String signature,
            @RequestHeader(value = "X-GitHub-Event", required = false) String githubEvent,
            @RequestParam(value = "test", required = false) String testMode) {

        if (debug) {
            logger.info("Received webhook request - Event: {}, Test: {}", githubEvent, testMode);
        }

        // Handle test mode
        if ("true".equals(testMode)) {
            logger.info("Test mode: Skipping git pull");
            gitService.simulateFileChanges();
            return ResponseEntity.ok("Simulated file changes to trigger restart");
        }

        // Verify signature if provided
        if (signature != null && !webhookSecret.isEmpty()) {
            if (!signatureService.verifySignature(payload, signature, webhookSecret)) {
                logger.warn("Invalid webhook signature");
                return ResponseEntity.status(403).body("Invalid signature");
            }
            logger.info("Signature verified successfully");
        } else {
            logger.info("No signature provided, skipping verification (useful for testing)");
        }

        // Check if this is a GitHub push event
        if ("push".equals(githubEvent)) {
            String ref = (String) payload.get("ref");
            String expectedRef = "refs/heads/" + gitBranch;
            
            if (ref != null && !ref.equals(expectedRef) && !"*".equals(gitBranch)) {
                logger.info("Ignoring push to {}, watching for {}", ref, gitBranch);
                return ResponseEntity.ok("Ignored push to non-watched branch");
            }
        }

        // Pull the latest changes
        try {
            String result = gitService.pullLatestChanges();
            return ResponseEntity.ok(result);
        } catch (Exception e) {
            logger.error("Error pulling changes: {}", e.getMessage());
            return ResponseEntity.status(500).body("Error pulling changes: " + e.getMessage());
        }
    }
}
