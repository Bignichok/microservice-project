# 🚀 Quick Start - microservice-project

Instructions for quick deployment of Django application in EKS.

## Prerequisites

```bash
make check-tools
make check-aws
```

## Option 1: Automated deployment

```bash
make full-deploy
```

## Option 2: Step-by-step deployment

```bash

make init
make apply

make configure-kubectl

make push-image

make deploy-helm

make check-deployment
```

## Verification

```bash
make get-service-url
make logs
make watch-hpa
```

## Autoscaling test

```bash
make watch-hpa
make load-test
```

## Cleanup

```bash
make clean-helm
make destroy
```

## Useful commands

```bash
make help
kubectl config current-context
kubectl get nodes
kubectl get all
make get-ecr-url
```