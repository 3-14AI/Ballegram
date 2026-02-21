public function getStorageClient(StorageConfig config) returns Storage|error {
    match config.'type {
        LOCAL => {
            return new LocalStorage(config.path);
        }
        S3 => {
            if config.bucket == "" || config.region == "" {
                return error("Bucket and Region are required for S3 storage configuration.");
            }
            return new S3Storage(config.bucket, config.region, config.accessKey, config.secretKey);
        }
        _ => {
            return error("Unsupported storage type.");
        }
    }
}
