package com.example.webhook.service;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import java.io.BufferedReader;
import java.io.File;
import java.io.IOException;
import java.io.InputStreamReader;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.time.Instant;

@Service
public class GitService {

    private static final Logger logger = LoggerFactory.getLogger(GitService.class);

    @Value("${git.repo.path:/workspace}")
    private String repoPath;

    @Value("${git.branch:main}")
    private String gitBranch;

    @Value("${touch.paths:backend/src/main/java/com/example/counter/CounterBackendApplication.java}")
    private String touchPaths;

    public String pullLatestChanges() throws Exception {
        logger.info("Pulling latest changes in {}...", repoPath);
        
        String command = String.format("cd %s && git fetch origin %s && git reset --hard origin/%s", 
                                      repoPath, gitBranch, gitBranch);
        
        ProcessBuilder processBuilder = new ProcessBuilder("sh", "-c", command);
        processBuilder.directory(new File(repoPath));
        
        Process process = processBuilder.start();
        
        StringBuilder output = new StringBuilder();
        try (BufferedReader reader = new BufferedReader(new InputStreamReader(process.getInputStream()))) {
            String line;
            while ((line = reader.readLine()) != null) {
                output.append(line).append("\n");
            }
        }
        
        StringBuilder errorOutput = new StringBuilder();
        try (BufferedReader reader = new BufferedReader(new InputStreamReader(process.getErrorStream()))) {
            String line;
            while ((line = reader.readLine()) != null) {
                errorOutput.append(line).append("\n");
            }
        }
        
        int exitCode = process.waitFor();
        
        if (exitCode != 0) {
            throw new RuntimeException("Git command failed: " + errorOutput.toString());
        }
        
        logger.info("Git pull output: {}", output.toString());
        
        // Always touch files to trigger restart after git operations
        logger.info("Git operations completed, touching files to trigger restart...");
        simulateFileChanges();
        
        return "Changes processed successfully";
    }

    public void simulateFileChanges() {
        String[] paths = touchPaths.split(",");
        
        for (String pathStr : paths) {
            String trimmedPath = pathStr.trim();
            if (!trimmedPath.isEmpty()) {
                touchFile(trimmedPath);
            }
        }
    }

    private void touchFile(String relativePath) {
        try {
            Path fullPath = Paths.get(repoPath, relativePath);
            logger.info("Touching file: {}", fullPath);
            
            if (Files.exists(fullPath)) {
                // Update the file's modification time
                Files.setLastModifiedTime(fullPath, 
                    java.nio.file.attribute.FileTime.from(Instant.now()));
                logger.info("Successfully touched {}", fullPath);
            } else {
                logger.warn("File does not exist: {}", fullPath);
            }
        } catch (IOException e) {
            logger.error("Error touching file {}: {}", relativePath, e.getMessage());
        }
    }
}
