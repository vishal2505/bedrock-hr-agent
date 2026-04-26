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

---

## Part 1 — Deploy AWS Infrastructure (Terraform)

### Step 1 — Create the Terraform remote state bucket

This only needs to be done once, ever.

```bash
aws s3 mb s3://hr-onboarding-agent-terraform-state --region us-east-1
```

### Step 2 — Set your Terraform variables

```bash
cd infrastructure
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars` with your values:

```hcl
aws_region   = "us-east-1"
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

Or use the CLI to look up the data source ID and start ingestion:

```bash
cd infrastructure
KB_ID=$(terraform output -raw knowledge_base_id)

# Get the data source ID
DS_ID=$(aws bedrock-agent list-data-sources \
  --knowledge-base-id ${KB_ID} \
  --region us-east-1 \
  --query 'dataSourceSummaries[0].dataSourceId' \
  --output text)

# Start ingestion
aws bedrock-agent start-ingestion-job \
  --knowledge-base-id ${KB_ID} \
  --data-source-id ${DS_ID} \
  --region us-east-1

# To check status
aws bedrock-agent list-ingestion-jobs \
  --knowledge-base-id THCV5FBXEF \
  --data-source-id SHLLEPHHUT \
  --region us-east-1 \
  --query 'ingestionJobSummaries[0]' \
  --output json

# To Check Failed job info =>

aws bedrock-agent get-ingestion-job \
  --knowledge-base-id THCV5FBXEF \
  --data-source-id SHLLEPHHUT \
  --ingestion-job-id DS0SMJIBJL \
  --region us-east-1 \
  --output json
```

#### Sync from the AWS Console (manual)

The Knowledge Base does **not** auto-sync when documents are added/removed in S3 — you must trigger ingestion every time the document set changes. To sync from the console:

1. Open the AWS Console → **Amazon Bedrock** (region: `us-east-1`).
2. In the left sidebar, click **Knowledge Bases**.
3. Click your knowledge base (e.g. `hr-onboarding-agent-kb`).
4. Scroll down to the **Data source** section and select the row (e.g. `hr-onboarding-agent-documents`).
5. Click the **Sync** button in the top-right of the data source panel.
6. Wait for the **Status** to change from `Syncing` → `Available` (typically 1–3 minutes for a few PDFs).
7. If a sync fails, click the job ID to see the failure reason (most common cause: the S3 Vectors 2048-byte filterable-metadata limit — see the Troubleshooting section).

After the sync completes, the agent can answer questions from the new documents immediately. Re-run the sync any time you upload, update, or delete files in the documents bucket.

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
AWS_REGION=us-east-1
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
| `AWS_REGION`             | AWS region                      | `us-east-1`             |
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

**4. Knowledge Base ingestion job fails — `numberOfDocumentsFailed: 3`**

Get the exact failure reason:
```bash
aws bedrock-agent get-ingestion-job \
  --knowledge-base-id <KB_ID> \
  --data-source-id <DS_ID> \
  --ingestion-job-id <JOB_ID> \
  --region us-east-1 \
  --query 'ingestionJob.failureReasons'
```

*S3 Vectors metadata size limit* — if the error is:
```
Filterable metadata must have at most 2048 bytes (Service: S3Vectors, Status Code: 400)
```
Bedrock stores each chunk's text + source metadata as filterable metadata in S3 Vectors, which has a hard 2048-byte cap. Fix: ensure the data source has `vector_ingestion_configuration` with small fixed-size chunks (≤ 200 tokens). This is already configured in `infrastructure/modules/bedrock/main.tf`. If you modified chunking settings and broke this, restore:
```hcl
vector_ingestion_configuration {
  chunking_configuration {
    chunking_strategy = "FIXED_SIZE"
    fixed_size_chunking_configuration {
      max_tokens         = 200
      overlap_percentage = 10
    }
  }
}
```
Then run `terraform apply -target=module.bedrock.aws_bedrockagent_data_source.hr_documents` and re-trigger ingestion.

**5. Bedrock embedding model not available in your region**
- Titan Embeddings V2 (`amazon.titan-embed-text-v2:0`) and Claude Sonnet are not available in all regions
- Use `us-east-1` — all required models are available there
- Update `default` in `infrastructure/variables.tf` and the `backend` block region in `infrastructure/main.tf`
- Update `AWS_REGION=us-east-1` in `backend/.env`

**6. `terraform init` fails with "bucket does not exist"**
- Create the state bucket first: `aws s3 mb s3://hr-onboarding-agent-terraform-state --region us-east-1`
- The bucket name in the `backend` block in `infrastructure/main.tf` must match exactly

**7. `docker compose up` starts but chat doesn't work**
- This means the infrastructure is not deployed yet, or `.env` has wrong/missing values
- Complete Part 1 (Terraform) first, then copy the outputs into `backend/.env`

**8. Agent in `Versioning` state error during `terraform apply`**
```
ValidationException: Prepare operation can't be performed on Agent when it is in Versioning state.
```
This happens if the agent alias is created before action groups and the Knowledge Base association are fully applied. The alias creation triggers a versioning cycle that blocks `PrepareAgent` calls. The `aws_bedrockagent_agent_alias` resource has `depends_on` to prevent this — if you see it, just re-run `terraform apply`. It is always safe to re-run.
