####################################################################################################
## Builder
####################################################################################################
FROM rust:latest AS builder

RUN rustup target add x86_64-unknown-linux-musl
RUN apt update && apt install -y musl-tools musl-dev
RUN update-ca-certificates

RUN adduser --home /nonexistent --no-create-home --disabled-password libreddit

WORKDIR /usr/src/libreddit

COPY . .

RUN cargo build --target x86_64-unknown-linux-musl --release

####################################################################################################
## Final image
####################################################################################################
FROM scratch

# Import user information from builder.
COPY --from=builder /etc/passwd /etc/passwd
COPY --from=builder /etc/group /etc/group

# Import ca-certificates from builder
COPY --from=builder /usr/share/ca-certificates /usr/share/ca-certificates
COPY --from=builder /etc/ssl/certs /etc/ssl/certs

# Copy our build
COPY --from=builder /usr/src/libreddit/target/x86_64-unknown-linux-musl/release/libreddit /usr/local/bin/libreddit

# Use an unprivileged user.
USER libreddit

# Tell Docker to expose port 8080
EXPOSE 8080

# Run a healthcheck every minute to make sure Libreddit is functional
HEALTHCHECK --interval=1m --timeout=3s CMD curl -f http://localhost:8080/settings || exit 1

CMD ["libreddit"]