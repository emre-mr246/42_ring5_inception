DATA_DIR    = $(HOME)/data
MYSQL_DIR   = $(DATA_DIR)/mysql
WP_DIR      = $(DATA_DIR)/wordpress
REDIS_DIR   = $(DATA_DIR)/redis
STATIC_PAGE_DIR = $(DATA_DIR)/static_page
LOG_DIR     = $(DATA_DIR)/logs

MAKEFLAGS   = --no-print-directory
RM          = rm -rf
MKDIR       = mkdir -p

BUILD_PATHS = \
    DOCKER_BUILDKIT=0 docker build -t mariadb-42 ./srcs/requirements/mariadb && \
    DOCKER_BUILDKIT=0 docker build -t nginx-42 ./srcs/requirements/nginx && \
    DOCKER_BUILDKIT=0 docker build -t wordpress-42 ./srcs/requirements/wordpress && \
    DOCKER_BUILDKIT=0 docker build -t ftp-server-42 ./srcs/requirements/bonus/ftp_server && \
    DOCKER_BUILDKIT=0 docker build -t redis-42 ./srcs/requirements/bonus/redis && \
    DOCKER_BUILDKIT=0 docker build -t adminer-42 ./srcs/requirements/bonus/adminer && \
    DOCKER_BUILDKIT=0 docker build -t log-collector-42 ./srcs/requirements/bonus/log_collector && \
	DOCKER_BUILDKIT=0 docker build -t static-page-42 ./srcs/requirements/bonus/static_page

DOCKER_COMPOSE_FILE = ./srcs/docker-compose.yml
STACK_NAME  = inception
SWARM_ARGS = --advertise-addr 127.0.0.1

all: build

build: init_swarm create_network generate_certs create_secrets build_images create_volumes
	@echo "Deploying stack to Docker Swarm..."
	@docker stack deploy -c $(DOCKER_COMPOSE_FILE) $(STACK_NAME)
	@sleep 10 && make $(MAKEFLAGS) status

init_swarm:
	@if ! docker info --format '{{.Swarm.ControlAvailable}}' | grep -q true; then \
		echo "Initializing Docker Swarm..."; \
		docker swarm init $(SWARM_ARGS); \
	else \
		echo "Docker Swarm is already initialized."; \
	fi

create_directories:
	@echo "Creating data directories..."
	@$(MKDIR) $(MYSQL_DIR)
	@$(MKDIR) $(WP_DIR)
	@$(MKDIR) $(REDIS_DIR)
	@$(MKDIR) $(STATIC_PAGE_DIR)
	@${MKDIR} $(LOG_DIR)
	@echo "Data directories created successfully."

create_network:
	@docker network inspect inception_network >/dev/null 2>&1 || \
	docker network create --driver=overlay inception_network

generate_certs:
	@echo "Generating SSL certificates..."
	@bash ./scripts/generate_ssl.sh
	@echo "SSL certificates generated."

create_secrets:
	@echo "Creating Docker Swarm secrets..."
	@bash ./scripts/create_secrets.sh
	@echo "Secrets created successfully."

build_images:
	@echo "Building Docker images..."
	@$(BUILD_PATHS)
	@echo "Images built successfully."

create_volumes: fix_perms
	@docker volume create --driver local \
		--opt type=none --opt o=bind --opt device=$(MYSQL_DIR) mariadb_data || true
	@docker volume create --driver local \
		--opt type=none --opt o=bind --opt device=$(WP_DIR) wordpress_data || true
	@docker volume create --driver local \
		--opt type=none --opt o=bind --opt device=$(REDIS_DIR) redis_data || true
	@docker volume create --driver local \
		--opt type=none --opt o=bind --opt device=$(LOG_DIR) logs_data || true
	@docker volume create --driver local \
		--opt type=none --opt o=bind --opt device=$(STATIC_PAGE_DIR) static_page_data || true
	@echo "Volumes created successfully."

fix_perms: create_directories
	@sudo chown -R 999:999 $(MYSQL_DIR)
	@sudo chown -R 999:999 $(REDIS_DIR)
	@sudo chown -R 33:33 $(WP_DIR)
	@sudo chown -R 1000:1000 $(DATA_DIR)/logs
	@sudo chown -R 1000:1000 $(DATA_DIR)/static_page
	@echo "Permissions fixed successfully."


down: clean

status:
	@echo "\n"
	@docker stack ps inception

exec:
	@read -p "Container name: " cname; \
	cid=$$(docker ps -q --filter "name=$$cname"); \
	if [ -z "$$cid" ]; then \
		echo "Container not found!"; \
	else \
		docker exec -it $$cid bash; \
	fi

clean:
	@echo "Cleaning up containers and volumes..."
	@docker stack rm $(STACK_NAME)
	@docker network rm inception_network 2>/dev/null || true
	@docker swarm leave --force 2>/dev/null || true

clear_secrets:
	@echo "Removing Docker secrets..."
	@docker secret rm mysql_password mysql_root_password 2>/dev/null || true
	@docker secret rm wordpress_db_password 2>/dev/null || true
	@docker secret rm redis_password ftp_password  2>/dev/null || true

clear_data:
	@echo "Clearing data directories..."
	@sudo $(RM) $(MYSQL_DIR)
	@sudo $(RM) $(WP_DIR)
	@sudo $(RM) $(REDIS_DIR)
	@sudo $(RM) $(STATIC_PAGE_DIR)
	@sudo $(RM) $(LOG_DIR)
	@sudo $(RM) .passwords
	@echo "Data directories cleared successfully."

fclean: clean clear_data clear_secrets
	@echo "Pruning Docker system..."
	@docker system prune -a -f
	@docker volume prune -f
	@sudo rm -rf ${HOME}/data/*

restart: clean build

.PHONY: all build down status logs clean fclean restart exec create_directories create_network generate_certs build_images create_volumes fix_perms create_secrets init_swarm
