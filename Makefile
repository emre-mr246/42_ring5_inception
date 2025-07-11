DATA_DIR		= $(HOME)/data
MYSQL_DIR		= $(DATA_DIR)/mysql
WP_DIR			= $(DATA_DIR)/wordpress
REDIS_DIR		= $(DATA_DIR)/redis
STATIC_PAGE_DIR	= $(DATA_DIR)/static_page
LOG_DIR			= $(DATA_DIR)/logs

all: build

build: set-overcommit create_secrets create_directories
	@echo "Building and starting services..."
	@docker compose --file ./srcs/docker-compose.yml up --detach --build
	@make --no-print-directory status

set-overcommit:
	@echo "Setting vm.overcommit_memory to 1... (for Redis)"
	@sudo sysctl --write vm.overcommit_memory=1

generate_certs:
	@echo "Generating SSL certificates..."
	@bash ./scripts/generate_ssl.sh

create_secrets: generate_certs
	@echo "Creating secrets directory and files..."
	@bash ./scripts/create_secrets.sh

create_directories:
	@echo "Creating data directories..."
	@mkdir -p $(MYSQL_DIR) $(WP_DIR) $(REDIS_DIR) $(STATIC_PAGE_DIR) $(LOG_DIR)

down:
	@echo "Stopping containers..."
	@docker compose --file ./srcs/docker-compose.yml down

status:
	@while true; do \
		clear; \
		echo "=== Container Status ===================="; \
		docker ps -a --format "table {{.Names}}\t{{.Status}}"; \
		echo "========================================="; \
		echo "\nPress Ctrl+C to exit"; \
		sleep 1; \
	done

exec:
	@read -p "Container name: " cname; \
	cid=$$(docker compose --file ./srcs/docker-compose.yml ps -q $$cname); \
	if [ -z "$$cid" ]; then \
		echo "Container not found!"; \
	else \
		docker exec -it $$cid bash; \
	fi

clean:
	@docker compose --file ./srcs/docker-compose.yml down
	@docker network rm inception_network 2>/dev/null || true

clear_data:
	@echo "Clearing data directories..."
	@sudo rm -rf $(HOME)/data

clear_secrets:
	@echo "Removing secrets..."
	@sudo rm -rf srcs/secrets/

fclean: clean clear_data clear_secrets
	@echo "Removing all containers..."
	@docker ps -aq | xargs -r docker rm

	@echo "Removing all images..."
	@docker images -q | xargs -r docker rmi

	@echo "Removing all volumes..."
	@docker volume ls -q | xargs -r docker volume rm

	@echo "Removing user-defined networks..."
	@docker network ls --filter "type=custom" -q | xargs -r docker network rm

	@echo "Pruning Docker system..."
	@docker system prune --all --volumes --force

	@echo "Full cleanup completed!"

re: clean build

.PHONY: all build down status clean fclean re exec \
create_directories generate_certs create_secrets
