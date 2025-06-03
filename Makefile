DATA_DIR    = $(HOME)/data
MYSQL_DIR   = $(DATA_DIR)/mysql
WP_DIR      = $(DATA_DIR)/wordpress
REDIS_DIR   = $(DATA_DIR)/redis
DOCKER_COMPOSE = docker compose
DOCKER_COMPOSE_FILE = ./srcs/docker-compose.yml

MAKEFLAGS   = --no-print-directory
RM          = rm -rf
MKDIR       = mkdir -p

all: build

build:
	@echo "Creating data directories...@"
	@$(MKDIR) $(MYSQL_DIR)
	@$(MKDIR) $(WP_DIR)
	@$(MKDIR) $(REDIS_DIR)
	@echo "Building and starting containers..."
	@$(DOCKER_COMPOSE) -f $(DOCKER_COMPOSE_FILE) up --build -d --remove-orphans
	@sleep 15 && make $(MAKEFLAGS) status

kill:
	@echo "Killing all containers..."
	@$(DOCKER_COMPOSE) -f $(DOCKER_COMPOSE_FILE) kill

down:
	@echo "Stopping and removing containers..."
	@$(DOCKER_COMPOSE) -f $(DOCKER_COMPOSE_FILE) down

status:
	@echo "\n"
	@docker ps -a

logs:
	@echo "Following container logs (Ctrl+C to exit)..."
	@$(DOCKER_COMPOSE) -f $(DOCKER_COMPOSE_FILE) logs -f

clean:
	@echo "Cleaning up containers and volumes..."
	@$(DOCKER_COMPOSE) -f $(DOCKER_COMPOSE_FILE) down -v

fclean: clean
	@echo "Removing data directories..."
	@$(RM) $(MYSQL_DIR)
	@$(RM) $(WP_DIR)
	@$(RM) $(REDIS_DIR)
	@echo "Pruning Docker system..."
	@docker system prune -a -f
	@docker volume prune -f
	@sudo rm -rf ${HOME}/data/*

restart: clean build

.PHONY: all build kill down status logs clean fclean restart
