# Ingress Setup

## Introduction

This document contains steps for enabling ingress for the Grafana installation.

## Installing NGINX Ingress Controller

```bash
kubectl create namespace ingress
kubens ingress
helm install stable/nginx-ingress
# If you already have a static IP available
helm install stable/nginx-ingress --set controller.service.loadBalancerIP=<IP>
```