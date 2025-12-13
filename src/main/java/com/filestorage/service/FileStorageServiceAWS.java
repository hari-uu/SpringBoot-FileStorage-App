package com.filestorage.service;

import com.filestorage.model.FileMetadata;
import com.filestorage.model.User;
import com.filestorage.repository.FileMetadataRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Profile;
import org.springframework.stereotype.Service;
import org.springframework.util.StringUtils;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.util.List;

@Service
@Profile("aws")
public class FileStorageServiceAWS {
    
    @Autowired
    private FileMetadataRepository fileMetadataRepository;
    
    @Autowired
    private S3Service s3Service;
    
    @Value("${spring.profiles.active:local}")
    private String activeProfile;
    
    public FileMetadata storeFile(MultipartFile file, User user) {
        try {
            String originalFilename = StringUtils.cleanPath(file.getOriginalFilename());
            
            // Upload to S3
            String s3FileName = s3Service.uploadFile(file);
            String fileUrl = s3Service.getFileUrl(s3FileName);
            
            // Save file metadata to database
            FileMetadata fileMetadata = new FileMetadata();
            fileMetadata.setFileName(s3FileName);
            fileMetadata.setOriginalFileName(originalFilename);
            fileMetadata.setFileType(file.getContentType());
            fileMetadata.setFileSize(file.getSize());
            fileMetadata.setFilePath(fileUrl);
            fileMetadata.setUser(user);
            
            return fileMetadataRepository.save(fileMetadata);
            
        } catch (IOException ex) {
            throw new RuntimeException("Could not store file. Please try again!", ex);
        }
    }
    
    public byte[] loadFileAsBytes(Long fileId, User user) {
        FileMetadata fileMetadata = fileMetadataRepository.findByIdAndUser(fileId, user)
                .orElseThrow(() -> new RuntimeException("File not found"));
        
        return s3Service.downloadFile(fileMetadata.getFileName());
    }
    
    public List<FileMetadata> getUserFiles(User user) {
        return fileMetadataRepository.findByUserOrderByUploadedAtDesc(user);
    }
    
    public void deleteFile(Long fileId, User user) {
        FileMetadata fileMetadata = fileMetadataRepository.findByIdAndUser(fileId, user)
                .orElseThrow(() -> new RuntimeException("File not found"));
        
        // Delete from S3
        s3Service.deleteFile(fileMetadata.getFileName());
        
        // Delete metadata from database
        fileMetadataRepository.delete(fileMetadata);
    }
    
    public FileMetadata getFileMetadata(Long fileId, User user) {
        return fileMetadataRepository.findByIdAndUser(fileId, user)
                .orElseThrow(() -> new RuntimeException("File not found"));
    }
}
