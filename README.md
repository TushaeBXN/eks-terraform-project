# Production-Style EKS Cluster on AWS with Terraform

## The Problem
A team needs a Kubernetes cluster that can be torn down and rebuilt
identically across environments — not a snowflake cluster someone
clicked together once and is now afraid to touch. This project
provisions that cluster entirely from code, deploys a real
application onto it, and validates every layer locally before any
real AWS spend.

## Architecture
![Architecture diagram](docs/architecture.jpeg)

Traffic flow: Internet → Internet Gateway → Public Subnet → NAT
Gateway → Private Subnet → EKS Node Group → Service (NodePort) →
Pods.

## What This Demonstrates
- **Infrastructure as Code** — full VPC (`10.0.0.0/16`) with 2 public
  + 2 private subnets across 2 AZs, an EKS cluster, and a managed
  node group, all provisioned via Terraform with zero console clicks
- **Remote state** — S3 (`brian-eks-tfstate`) + DynamoDB
  (`terraform-locks`) so the cluster can be rebuilt by anyone on the
  team, not just the person who built it
- **Real workload** — an nginx deployment running on a real
  Kubernetes cluster, exposed via a NodePort service, verified with
  live HTTP traffic
- **Cost-aware local validation** — every Terraform plan and apply
  was run and verified against MiniStack (a free, local AWS
  emulator) before a single resource touched a billed AWS account.
  The workload itself was deployed and tested on a local `kind`
  cluster for the same reason — proving the full stack end to end
  at $0 in cloud spend

## Key Decisions
1. **Remote state over local state** — local state breaks the
   moment more than one person needs to touch the infrastructure,
   or a laptop dies mid-project. S3 + DynamoDB locking makes the
   cluster team-safe and prevents concurrent-apply corruption.
2. **Managed node group over self-managed EC2** — trades a small
   amount of control for AWS handling node patching and lifecycle,
   the right tradeoff for a project without dedicated platform
   headcount.
3. **Validate against a local emulator before touching real AWS** —
   catching a misconfigured IAM trust policy or a bad subnet
   reference against MiniStack costs nothing and takes seconds;
   catching the same error against real AWS costs time, and
   sometimes money.

## Cluster Details
| Resource | Value |
|---|---|
| Cluster name | `eks-portfolio-cluster` |
| Kubernetes version | `1.29` |
| VPC | `vpc-8ba037ae0b57b591d` (`10.0.0.0/16`) |
| Node type | `t3.small`, desired 2 / min 1 / max 3 |
| State bucket | `brian-eks-tfstate` |
| Lock table | `terraform-locks` |

## Deployment

**1. Stand up the infrastructure:**
```bash
cd terraform/environments/dev
terraform init
terraform plan
terraform apply
```

**2. Deploy the workload** (against a local `kind` cluster, since
MiniStack emulates the EKS control plane but not a live Kubernetes
API to schedule against):
```bash
kind create cluster --name eks-portfolio-demo
kubectl apply -f k8s/deployment.yaml
kubectl apply -f k8s/service.yaml
```

**3. Verify it's serving traffic:**
```bash
kubectl port-forward svc/portfolio-demo-svc 8080:80
curl http://localhost:8080
```
You should see the nginx welcome page returned as raw HTML —
confirmation that the deployment, service, and pod networking are
all wired correctly.

## What I'd Change in Production
I'd move node provisioning to Karpenter instead of a static managed
node group. A fixed-size group pays for capacity around the clock
even when traffic is flat overnight — Karpenter provisions nodes
just-in-time based on actual pending pods, which is the difference
between infrastructure that works and infrastructure that works
efficiently.

## Cleanup
```bash
cd terraform/environments/dev
terraform destroy

kind delete cluster --name eks-portfolio-demo
```
