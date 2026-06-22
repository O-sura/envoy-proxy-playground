# Makefile for running Envoy proxy + mock httpbin backend locally

IMAGE        := envoyproxy/envoy:v1.38.2
CONTAINER    := envoy-local
CONFIG       := envoy.yaml
PROXY_PORT   := 10000
ADMIN_PORT   := 9001
BACKEND_DIR  := mock-backend
BACKEND_PORT := 8080

.PHONY: run down run-envoy stop-envoy envoy-restart \
        run-backend stop-backend backend-logs \
        logs status shell pull clean help

## run: start the mock backend and Envoy
run: run-backend run-envoy

## down: stop Envoy and the mock backend
down: stop-envoy stop-backend

## run-envoy: start Envoy in the background with envoy.yaml applied
run-envoy:
	docker run -d --name $(CONTAINER) \
		--add-host=host.docker.internal:host-gateway \
		-p $(PROXY_PORT):$(PROXY_PORT) \
		-p $(ADMIN_PORT):$(ADMIN_PORT) \
		-v $(CURDIR)/$(CONFIG):/etc/envoy/envoy.yaml:ro \
		$(IMAGE) \
		-c /etc/envoy/envoy.yaml
	@echo "Envoy started -> proxy: http://localhost:$(PROXY_PORT)  admin: http://localhost:$(ADMIN_PORT)"

## stop-envoy: stop and remove the Envoy container
stop-envoy:
	-docker stop $(CONTAINER)
	-docker rm $(CONTAINER)

## envoy-restart: restart Envoy to pick up envoy.yaml changes
envoy-restart: stop-envoy run-envoy

## logs: follow the Envoy container logs
logs:
	docker logs -f $(CONTAINER)

## status: show container status for Envoy and the backend
status:
	docker ps -a --filter "name=$(CONTAINER)" --filter "name=mock-httpbin"

## shell: open a shell inside the running Envoy container
shell:
	docker exec -it $(CONTAINER) /bin/sh

## run-backend: start the mock httpbin backend (docker compose)
run-backend:
	docker compose -f $(BACKEND_DIR)/docker-compose.yml up -d
	@echo "httpbin backend started -> http://localhost:$(BACKEND_PORT)"

## stop-backend: stop and remove the mock backend
stop-backend:
	docker compose -f $(BACKEND_DIR)/docker-compose.yml down

## backend-logs: follow the mock backend logs
backend-logs:
	docker compose -f $(BACKEND_DIR)/docker-compose.yml logs -f

## pull: pull the Envoy image
pull:
	docker pull $(IMAGE)

## clean: alias for down (stop everything)
clean: down

## help: list available targets
help:
	@grep -E '^## ' $(MAKEFILE_LIST) | sed 's/## //'
