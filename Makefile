# DevOps Lab Makefile
# Usage:
#   make up
#   make test
#   make down
#   make clean

SHELL := /bin/bash

CLUSTER   ?= devops-lab
NAMESPACE ?= devops-lab
APP       ?= devops-lab-node
IMAGE     ?= $(APP):0.1
KCTX      ?= kind-$(CLUSTER)
APISERVER_HOST ?= host.docker.internal
TLS_SERVERNAME ?= localhost


.PHONY: help up cluster build load ns apply wait test down clean

help:
	@echo "Targets:"
	@echo "  make up      - create cluster (if needed), build+load image, apply manifests, wait, test"
	@echo "  make test    - run DNS + HTTP test pod"
	@echo "  make down    - delete kind cluster"
	@echo "  make clean   - down + remove any leftover node container/network (best-effort)"

up: cluster build load ns apply wait test

cluster:
	@kind get clusters | grep -qx "$(CLUSTER)" || kind create cluster --name "$(CLUSTER)" --wait 5m
	@kind export kubeconfig --name "$(CLUSTER)" >/dev/null
	@$(MAKE) kcfg
	@echo "Kube context: $(KCTX)"

build:
	@echo "Building image: $(IMAGE)"
	@docker build -t "$(IMAGE)" ./app

load:
	@echo "Loading image into kind: $(IMAGE)"
	@kind load docker-image "$(IMAGE)" --name "$(CLUSTER)"

ns:
	@kubectl --context "$(KCTX)" get ns "$(NAMESPACE)" >/dev/null 2>&1 || \
	  kubectl --context "$(KCTX)" create ns "$(NAMESPACE)"

apply:
	@echo "Applying k8s manifests..."
	@kubectl --context "$(KCTX)" -n "$(NAMESPACE)" apply -f k8s/

wait:
	@echo "Waiting for deployment to become ready..."
	@kubectl --context "$(KCTX)" -n "$(NAMESPACE)" rollout status deploy/$(APP) --timeout=120s

test:
	@echo "Running DNS + HTTP test..."
	@kubectl --context "$(KCTX)" -n "$(NAMESPACE)" run curltest --rm -i --restart=Never \
	  --image=curlimages/curl -- sh -lc '\
	    set -e; \
	    echo "DNS:"; \
	    nslookup $(APP).$(NAMESPACE).svc.cluster.local; \
	    echo; \
	    echo "HTTP:"; \
	    curl -sS --max-time 2 http://$(APP)/ | head -c 300; \
	    echo \
	  '

down:
	@kind delete cluster --name "$(CLUSTER)" || true

clean: down
	@docker rm -f "$(CLUSTER)-control-plane" 2>/dev/null || true
	@docker network rm kind 2>/dev/null || true

kcfg:
	@# In some remote/docker setups, kind's exported kubeconfig points to 127.0.0.1:<port>
	@# but the API server is reachable at host.docker.internal:<port>.
	@PORT=$$(docker port $(CLUSTER)-control-plane 6443/tcp | awk -F: '{print $$2}'); \
	kubectl config set-cluster $(KCTX) \
	  --server="https://$(APISERVER_HOST):$${PORT}" \
	  --tls-server-name="$(TLS_SERVERNAME)" >/dev/null; \
	echo "Patched kubeconfig: $(KCTX) -> https://$(APISERVER_HOST):$${PORT} (tls-server-name=$(TLS_SERVERNAME))"
