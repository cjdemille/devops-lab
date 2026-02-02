FROM mcr.microsoft.com/devcontainers/base:ubuntu

RUN apt-get update && apt-get install -y \
    curl unzip git jq ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Terraform
RUN curl -fsSL https://apt.releases.hashicorp.com/gpg | gpg --dearmor -o /usr/share/keyrings/hashicorp.gpg && \
    echo "deb [signed-by=/usr/share/keyrings/hashicorp.gpg] https://apt.releases.hashicorp.com jammy main" \
    > /etc/apt/sources.list.d/hashicorp.list && \
    apt-get update && apt-get install -y terraform

# kubectl
RUN curl -LO "https://dl.k8s.io/release/$(curl -sL https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl" && \
    install kubectl /usr/local/bin/kubectl && rm kubectl

# AWS CLI
RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o awscliv2.zip && \
    unzip awscliv2.zip && ./aws/install && rm -rf aws awscliv2.zip
