#!/bin/bash
set -e

CERT_DIR="/certs"
DB_HOSTNAME="db"

echo "Generating SSL certificates for MySQL."

# 1. Generate CA private key and certificate
echo "Generating CA certificate..."
openssl genrsa -out "${CERT_DIR}/ca.key" 2048
openssl req -new -x509 -nodes -days 3650 \
    -key "${CERT_DIR}/ca.key" \
    -out "${CERT_DIR}/ca.pem" \
    -subj "/C=US/ST=State/L=City/O=MyCompany/CN=MyLocalCA"

# 2. Generate Server private key and certificate request
echo "Generating Server certificate request..."
openssl genrsa -out "${CERT_DIR}/server.key" 2048
openssl req -new \
    -key "${CERT_DIR}/server.key" \
    -out "${CERT_DIR}/server.csr" \
    -subj "/C=US/ST=State/L=City/O=MyCompany/CN=${DB_HOSTNAME}" \
    -addext "subjectAltName=DNS:${DB_HOSTNAME},IP:127.0.0.1"

# 3. Sign the Server certificate with the CA
echo "Signing Server certificate..."
openssl x509 -req -days 3650 \
    -in "${CERT_DIR}/server.csr" \
    -CA "${CERT_DIR}/ca.pem" \
    -CAkey "${CERT_DIR}/ca.key" \
    -CAcreateserial \
    -out "${CERT_DIR}/server.pem" \
    -extfile <(printf "subjectAltName=DNS:${DB_HOSTNAME},IP:127.0.0.1")

# 4. Generate Client private key and certificate request
echo "Generating Client certificate request..."
openssl genrsa -out "${CERT_DIR}/client.key" 2048
openssl req -new \
    -key "${CERT_DIR}/client.key" \
    -out "${CERT_DIR}/client.csr" \
    -subj "/C=US/ST=State/L=City/O=MyCompany/CN=client"

# 5. Sign the Client certificate with the CA
echo "Signing Client certificate..."
openssl x509 -req -days 3650 \
    -in "${CERT_DIR}/client.csr" \
    -CA "${CERT_DIR}/ca.pem" \
    -CAkey "${CERT_DIR}/ca.key" \
    -CAcreateserial \
    -out "${CERT_DIR}/client.pem"

echo "Certificates generated in: ${CERT_DIR}"
ls -l "${CERT_DIR}"