from __future__ import annotations

from pathlib import Path
from uuid import uuid4

from fastapi import HTTPException, UploadFile

from app.core.config import settings


def validate_image_upload(upload: UploadFile) -> None:
    extension = Path(upload.filename or "upload").suffix.lower()
    if extension not in settings.allowed_image_extensions:
        raise HTTPException(
            status_code=400,
            detail=f"Unsupported file type. Allowed types: {', '.join(settings.allowed_image_extensions)}",
        )


class FileStorageProvider:
    def save_team_logo(self, upload: UploadFile) -> str:
        raise NotImplementedError


class LocalFileStorageProvider(FileStorageProvider):
    def save_team_logo(self, upload: UploadFile) -> str:
        media_root = Path(settings.media_dir)
        logos_dir = media_root / "team_logos"
        logos_dir.mkdir(parents=True, exist_ok=True)

        extension = Path(upload.filename or "logo.png").suffix or ".png"
        filename = f"{uuid4().hex}{extension.lower()}"
        target = logos_dir / filename

        total_bytes = 0
        chunk_size = 1024 * 1024
        try:
            with target.open("wb") as output:
                while True:
                    chunk = upload.file.read(chunk_size)
                    if not chunk:
                        break
                    total_bytes += len(chunk)
                    if total_bytes > settings.max_upload_size_bytes:
                        raise HTTPException(
                            status_code=413,
                            detail=f"File exceeds max upload size of {settings.max_upload_size_bytes} bytes",
                        )
                    output.write(chunk)
        except HTTPException:
            target.unlink(missing_ok=True)
            raise

        return f"{settings.media_base_url.rstrip('/')}/team_logos/{filename}"


class S3CompatibleFileStorageProvider(FileStorageProvider):
    def save_team_logo(self, upload: UploadFile) -> str:
        if not settings.s3_bucket_name:
            raise HTTPException(status_code=503, detail="S3 storage is not configured")

        try:
            import boto3
        except ModuleNotFoundError as exc:
            raise HTTPException(status_code=503, detail="boto3 is required for S3 storage support") from exc

        extension = Path(upload.filename or "logo.png").suffix or ".png"
        filename = f"{uuid4().hex}{extension.lower()}"
        object_key = f"team_logos/{filename}"

        client_kwargs: dict[str, str] = {}
        if settings.s3_region:
            client_kwargs["region_name"] = settings.s3_region
        if settings.s3_endpoint_url:
            client_kwargs["endpoint_url"] = settings.s3_endpoint_url
        if settings.s3_access_key_id:
            client_kwargs["aws_access_key_id"] = settings.s3_access_key_id
        if settings.s3_secret_access_key:
            client_kwargs["aws_secret_access_key"] = settings.s3_secret_access_key

        client = boto3.client("s3", **client_kwargs)

        upload.file.seek(0)
        client.upload_fileobj(
            upload.file,
            settings.s3_bucket_name,
            object_key,
            ExtraArgs={"ContentType": upload.content_type or "application/octet-stream"},
        )
        return self._public_url(object_key)

    def _public_url(self, object_key: str) -> str:
        if settings.s3_public_base_url:
            return f"{settings.s3_public_base_url.rstrip('/')}/{object_key}"
        if settings.s3_endpoint_url:
            return f"{settings.s3_endpoint_url.rstrip('/')}/{settings.s3_bucket_name}/{object_key}"
        region = settings.s3_region or "us-east-1"
        return f"https://{settings.s3_bucket_name}.s3.{region}.amazonaws.com/{object_key}"


def get_file_storage_provider() -> FileStorageProvider:
    if settings.storage_provider == "s3":
        return S3CompatibleFileStorageProvider()
    return LocalFileStorageProvider()


def save_team_logo(upload: UploadFile) -> str:
    validate_image_upload(upload)
    return get_file_storage_provider().save_team_logo(upload)
