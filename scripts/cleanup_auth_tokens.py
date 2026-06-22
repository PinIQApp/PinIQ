from app.db.session import SessionLocal
from app.services.token_cleanup import cleanup_expired_auth_tokens


def main() -> None:
    with SessionLocal() as db:
        summary = cleanup_expired_auth_tokens(db)
    print(summary)


if __name__ == "__main__":
    main()
