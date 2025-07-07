DATA_DIR		= $(HOME)/data
MYSQL_DIR		= $(DATA_DIR)/mysql
WP_DIR			= $(DATA_DIR)/wordpress
REDIS_DIR		= $(DATA_DIR)/redis
STATIC_PAGE_DIR	= $(DATA_DIR)/static_page
LOG_DIR			= $(DATA_DIR)/logs

all: build

build: generate_certs create_secrets fix_perms
	@echo "Setting vm.overcommit_memory to 1..."
	@sudo sysctl --write vm.overcommit_memory=1
	@echo "Building and starting services..."
	@docker compose --file ./srcs/docker-compose.yml up --detach --build
	@make --no-print-directory status

create_directories:
	@echo "Creating data directories..."
	@mkdir -p $(MYSQL_DIR) $(WP_DIR) $(REDIS_DIR) $(STATIC_PAGE_DIR) $(LOG_DIR)

generate_certs:
	@echo "Generating SSL certificates..."
	@bash ./scripts/generate_ssl.sh

create_secrets:
	@echo "Creating secrets directory and files..."
	@bash ./scripts/create_secrets.sh

fix_perms: create_directories
	@echo "Fixing directory permissions..."
	@sudo chown -R 999:999 $(MYSQL_DIR) $(REDIS_DIR)
	@sudo chown -R 33:33 $(WP_DIR)
	@sudo chown -R 1000:1000 $(LOG_DIR) $(STATIC_PAGE_DIR)

down: clean

status:
	@while true; do \
		clear; \
		docker ps -a; \
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
	@echo "Stopping and removing containers..."
	@docker compose --file ./srcs/docker-compose.yml down || true
	@docker network rm inception_network 2>/dev/null || true

clear_data:
	@echo "Clearing data directories..."
	@sudo rm -rf $(HOME)/data .passwords

clear_secrets:
	@echo "Removing secrets directory..."
	@sudo rm -rf srcs/secrets/

fclean: clean clear_data clear_secrets
	@echo "Stopping all containers..."
	@docker stop $$(docker ps -aq) 2>/dev/null || true
	@echo "Removing all containers..."
	@docker rm $$(docker ps -aq) 2>/dev/null || true
	@echo "Removing all images..."
	@docker rmi $$(docker images -q) 2>/dev/null || true
	@echo "Removing all volumes..."
	@docker volume rm $$(docker volume ls -q) 2>/dev/null || true
	@echo "Removing all networks..."
	@docker network rm $$(docker network ls -q) 2>/dev/null || true
	@echo "Pruning Docker system..."
	@docker system prune --all --volumes --force 2>/dev/null || true
	@echo "Full cleanup completed!"

re: clean build

.PHONY: all build down status clean fclean re exec \
create_directories generate_certs fix_perms create_secrets
