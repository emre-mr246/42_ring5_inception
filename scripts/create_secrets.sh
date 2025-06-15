#!/bin/bash

echo "Creating Docker Swarm secrets..."

# MariaDB secrets
echo "sibercininsifresi123olur1!" | docker secret create mysql_root_password -
echo "sibercininsifresi123olur1!" | docker secret create mysql_password -

# WordPress secrets
echo "sibercininsifresi123olur1!" | docker secret create wordpress_db_password -

# Redis secrets
echo "sibercininsifresi123olur1!" | docker secret create redis_password -

# FTP secrets
echo "sibercininsifresi123olur1!" | docker secret create ftp_password -

echo "Secrets created successfully!"
