# HR Onboarding AI Agent

A production-ready HR Onboarding AI Agent powered by **Amazon Bedrock**, with a **FastAPI** backend, **React** frontend, and **Terraform**-managed AWS infrastructure deployed via **GitHub Actions**.

## Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│                          React Frontend                             │
│                    (Vite + TailwindCSS + S3)                        │
└──────────────────────────┬──────────────────────────────────────────┘
                           │ HTTPS
┌──────────────────────────▼──────────────────────────────────────────┐
│                        FastAPI Backend                               │
│                     (App Runner / Docker)                            │
└────────┬─────────────────┬──────────────────────────────────────────┘
         │                 │
    ┌────▼────┐       ┌────▼──────┐
    │ Bedrock │       │ DynamoDB  │
    │  Agent  │       │  Tasks    │
    └────┬────┘       └───────────┘
         │
    ┌────▼────────────────────────────────────────┐
    │            Bedrock Agent Components          │
    │  ┌──────────┐  ┌───────────┐  ┌──────────┐  │
    │  │Knowledge │  │ Guardrail │  │  Action  │  │
    │  │  Base    │  │  (PII,    │  │  Groups  │  │
    │  │  (RAG)   │  │  Topics)  │  │          │  │
    │  └────┬─────┘  └───────────┘  └──┬───┬──┘  │
    └───────┼──────────────────────────┼───┼──────┘
            │                          │   │
    ┌───────▼──────┐  ┌───────────────▼┐ ┌▼──────────┐
    │  OpenSearch  │  │ Lambda:        │ │ Lambda:    │
    │  Serverless  │  │ Send Email     │ │ Log Task   │
    │  (Vectors)   │  │ (SES)          │ │ (DynamoDB) │
    └───────┬──────┘  └────────────────┘ └────────────┘
            │
    ┌───────▼──────┐
    │  S3 Bucket   │
    │ (HR Policies)│
    └──────────────┘
```

## Prerequisites

| Tool      | Version | Install |
|-----------|---------|---------|
| AWS Account | — | https://aws.amazon.com |
| AWS CLI   | v2+     | https://aws.amazon.com/cli |
| Terraform | ≥ 1.5   | https://developer.hashicorp.com/terraform/install |
| Docker    | 20+     | https://docs.docker.com/get-docker |
| Python    | 3.11+   | Only needed to generate sample PDFs |

## Project Structure

```
├── infrastructure/          # Terraform — all AWS resources
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   ├── terraform.tfvars.example
│   └── modules/
│       ├── bedrock/         # Agent, Knowledge Base, Guardrails
│       ├── lambda/          # Action group Lambda functions
│       ├── s3/              # Document + frontend buckets
│       ├── opensearch/      # Vector store
│       ├── dynamodb/        # Task table
│       ├── ses/             # Email identity
│       ├── iam/             # Roles and policies
│       └── cloudwatch/      # Dashboard + log groups
├── backend/                 # FastAPI application
├── frontend/                # React application
├── lambdas/                 # Lambda source (zipped by Terraform)
├── docs/                    # PDF generator + sample policies
├── docker-compose.yml       # Local dev: backend + frontend containers
└── .github/workflows/       # CI/CD pipelines
```

---

## Getting Started

> ⚠️ **You must deploy the AWS infrastructure first.**
> The backend connects to real AWS services (DynamoDB, Bedrock Agent).
> Docker Compose will start without them but API calls will fail.
> Follow **Part 1** completely before running **Part 2**.

---

## Part 1 — Deploy AWS Infrastructure (Terraform)

### Step 1 — Create the Terraform remote state bucket

This only needs to be done once, ever.

```bash
aws s3 mb s3://hr-onboarding-terraform-state --region ap-southeast-1
```

### Step 2 — Set your Terraform variables

```bash
cd infrastructure
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars` with your values:

```hcl
aws_region   = "ap-southeast-1"
project_name = "hr-onboarding"
environment  = "production"
sender_email = "hr@yourcompany.com"   # must be an email you own
```

### Step 3 — Deploy

```bash
terraform init
terraform plan    # review what will be created
terraform apply   # type 'yes' to confirm
```

> ⏱ This takes **10–15 minutes** — OpenSearch Serverless is the slowest resource.

When complete, Terraform prints the outputs you need:

```
bedrock_agent_id       = "ABCD1234EF"
bedrock_agent_alias_id = "TSTALIASID"
knowledge_base_id      = "KBXXXXXXXX"
documents_bucket       = "hr-onboarding-documents-production-123456789012"
frontend_bucket        = "hr-onboarding-frontend-production-123456789012"
frontend_url           = "http://hr-onboarding-frontend-....s3-website.amazonaws.com"
```

**Keep this terminal open** — you need these values in the next steps.

### Step 4 — Verify your SES sender email

AWS sends a verification email to the address you set in `sender_email`.
Open your inbox and click the confirmation link before moving on.

### Step 5 — Upload HR policy documents to S3

These are the documents the Bedrock Agent will answer questions from.

```bash
# Go back to project root
cd ..

# Generate the 3 sample PDF policies
pip install reportlab
python docs/generate_policies.py

# Upload them to the S3 documents bucket
aws s3 sync docs/sample-policies/ s3://<documents_bucket from terraform output>/
```

### Step 6 — Sync the Bedrock Knowledge Base

After uploading the PDFs, trigger ingestion so the agent can search them:

```bash
aws bedrock-agent start-ingestion-job \
  --knowledge-base-id <knowledge_base_id from terraform output> \
  --data-source-id <open AWS Console → Bedrock → Knowledge Bases → your KB → Data source ID>
```

> You can also trigger this from the AWS Console: **Amazon Bedrock → Knowledge Bases → your KB → Sync**.

---

## Part 2 — Run Locally (Docker Compose)

Now that AWS infrastructure is live, run the app locally using Docker.
You only need Docker — no Python or Node installation required.

### Step 1 — Create your environment file

```bash
cp backend/.env.example backend/.env
```

Open `backend/.env` and fill in the values from the Terraform output:

```env
AWS_REGION=ap-southeast-1
BEDROCK_AGENT_ID=ABCD1234EF               # from terraform output
BEDROCK_AGENT_ALIAS_ID=TSTALIASID         # from terraform output
DYNAMODB_TABLE_NAME=OnboardingTasks
AWS_ACCESS_KEY_ID=<your IAM access key>
AWS_SECRET_ACCESS_KEY=<your IAM secret key>
FRONTEND_URL=http://localhost:3000
```

### Step 2 — Build and start the containers

```bash
docker compose up --build
```

This builds images for both services and starts them:

| Service  | URL                    | What it does                     |
|----------|------------------------|----------------------------------|
| Backend  | http://localhost:8000  | FastAPI + Bedrock Agent calls    |
| Frontend | http://localhost:3000  | React chat UI + task tracker     |

### Step 3 — Verify everything is working

```bash
# Backend health check
curl http://localhost:8000/api/health
# Expected: {"status":"healthy","service":"hr-onboarding-agent","version":"1.0.0"}

# List tasks (hits DynamoDB)
curl http://localhost:8000/api/tasks
# Expected: []  (empty list initially)
```

Then open **http://localhost:3000** in your browser and try asking the agent:
> *"What is the leave policy?"*

### Step 4 — Stop the containers

```bash
docker compose down
```

---

## GitHub Actions CI/CD

Pushing to GitHub triggers automated pipelines. Add these secrets under
**GitHub repo → Settings → Secrets and variables → Actions**:

| Secret | Where to get it |
|--------|-----------------|
| `AWS_ACCESS_KEY_ID` | Your IAM user credentials |
| `AWS_SECRET_ACCESS_KEY` | Your IAM user credentials |
| `SENDER_EMAIL` | Same email used in `terraform.tfvars` |
| `FRONTEND_BUCKET` | From `terraform output frontend_bucket` |
| `API_URL` | App Runner service URL (after first deploy) |
| `APPRUNNER_SERVICE_ARN` | App Runner service ARN (after first deploy) |

| Trigger | Workflow | What it does |
|---------|----------|--------------|
| Pull Request to `main` | `terraform-plan.yml` | Runs `terraform plan`, posts output as PR comment |
| Push to `main` | `terraform-apply.yml` | Runs `terraform apply` automatically |
| Push to `main` | `deploy-app.yml` | Builds Docker image → ECR → App Runner; uploads frontend → S3 |

---

## API Reference

| Method  | Endpoint                  | Description                       |
|---------|--------------------------|-----------------------------------|
| `POST`  | `/api/chat`              | Send message to agent (streaming) |
| `GET`   | `/api/chat/{session_id}` | Get chat history for a session    |
| `GET`   | `/api/tasks`             | List all onboarding tasks         |
| `POST`  | `/api/tasks`             | Create a new task                 |
| `PATCH` | `/api/tasks/{task_id}`   | Update task status                |
| `GET`   | `/api/health`            | Health check                      |

### Example curl commands

```bash
# Chat with the agent (streaming response)
curl -N -X POST http://localhost:8000/api/chat \
  -H "Content-Type: application/json" \
  -d '{"message": "What is the leave policy?"}'

# Create a task manually
curl -X POST http://localhost:8000/api/tasks \
  -H "Content-Type: application/json" \
  -d '{
    "title": "Setup laptop",
    "description": "Configure new employee laptop with required software",
    "assigned_to": "IT Department",
    "due_date": "2025-02-01"
  }'

# List all tasks
curl http://localhost:8000/api/tasks

# Mark a task as completed
curl -X PATCH http://localhost:8000/api/tasks/<task_id> \
  -H "Content-Type: application/json" \
  -d '{"status": "completed"}'
```

---

## Environment Variables Reference

| Variable                 | Description                     | Default                 |
|--------------------------|---------------------------------|-------------------------|
| `AWS_REGION`             | AWS region                      | `ap-southeast-1`        |
| `BEDROCK_AGENT_ID`       | Bedrock Agent ID                | —                       |
| `BEDROCK_AGENT_ALIAS_ID` | Bedrock Agent Alias ID          | —                       |
| `DYNAMODB_TABLE_NAME`    | DynamoDB table name             | `OnboardingTasks`       |
| `AWS_ACCESS_KEY_ID`      | AWS access key (local dev only) | —                       |
| `AWS_SECRET_ACCESS_KEY`  | AWS secret key (local dev only) | —                       |
| `FRONTEND_URL`           | Allowed CORS origin             | `http://localhost:3000` |

---

## Troubleshooting

**1. Bedrock Agent returns empty responses**
- Check the agent is in `PREPARED` state: AWS Console → Amazon Bedrock → Agents
- Confirm the Knowledge Base was synced after uploading PDFs
- Verify `BEDROCK_AGENT_ID` and `BEDROCK_AGENT_ALIAS_ID` in `.env` match the Terraform output exactly

**2. Tasks API returns an error**
- The DynamoDB table must exist before the backend starts — run `terraform apply` first
- Verify `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY` in `.env` have permission to access DynamoDB

**3. SES email sending fails**
- The sender email must be verified — check your inbox and click the AWS confirmation link
- In SES sandbox mode, the *recipient* email must also be verified
- To send to anyone: request SES production access in the AWS Console

**4. OpenSearch collection creation times out during `terraform apply`**
- This is normal — collections take 5–10 minutes to become `ACTIVE`
- Just re-run `terraform apply` — it is always safe to re-run

**5. `terraform init` fails with "bucket does not exist"**
- Create the state bucket first: `aws s3 mb s3://hr-onboarding-terraform-state --region ap-southeast-1`
- The bucket name in the `backend` block in `infrastructure/main.tf` must match exactly

**6. `docker compose up` starts but chat doesn't work**
- This means the infrastructure is not deployed yet, or `.env` has wrong/missing values
- Complete Part 1 (Terraform) first, then copy the outputs into `backend/.env`
