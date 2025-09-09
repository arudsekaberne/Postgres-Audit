# Postgres-Audit

## 🚀 Overview
Postgres-Audit is a Python-based tool designed to audit PostgreSQL logs and generate comprehensive reports. It automates the process of extracting, processing, and reporting on PostgreSQL audit logs, making it easier to monitor and maintain your database systems. This project is ideal for database administrators, DevOps engineers, and anyone responsible for ensuring the integrity and performance of PostgreSQL databases.

## ✨ Features
- **Automated Log Processing**: Automatically processes PostgreSQL audit logs.
- **Email Notifications**: Sends email notifications for completed batches.
- **SSH and Docker Integration**: Supports SSH connections and Docker container execution.
- **Customizable**: Configurable via environment variables and SQL scripts.
- **Extensible**: Easy to extend with new features and integrations.

## 🛠️ Tech Stack
- **Programming Language**: Python
- **Libraries and Tools**:
  - `pytz`: Timezone handling
  - `paramiko`: SSH connections
  - `pandas`: DataFrame operations
  - `sqlalchemy`: Database interactions
  - `jinja2`: Template rendering
  - `smtplib`: Email sending
  - `tabulate`: Pretty printing DataFrames
- **System Requirements**:
  - Python 3.8+
  - PostgreSQL
  - SSH access to the server

## 📦 Installation

### Prerequisites
- Python 3.8+
- PostgreSQL
- SSH access to the server

### Quick Start
```bash
# Clone the repository
git clone https://github.com/arudsekaberne/Postgres-Audit.git

# Navigate to the project directory and set up environment variables in .env file
cd Postgres-Audit

# Run the audit job automatically
python main.py --auto
```

## 🎯 Usage

### Basic Usage
```python
# Example: Running the audit job manually
python main.py
```

### Advanced Usage
- **Configuration**: Customize the `.env` file with your database and SSH credentials.
- **SQL Scripts**: Modify the SQL scripts in the `dependencies/sql` directory to fit your specific needs.
- **Email Notifications**: Configure the SMTP settings in the `.env` file to send email notifications.

## 📁 Project Structure
```
Postgres-Audit/
├── .env
├── main.py
├── vault.py
├── dependencies/
│   ├── __init__.py
│   ├── assets/
│   │   ├── __init__.py
│   │   └── pgaudit_email_template.html
│   ├── sql/
│   │   ├── 1_stg_postgre_log.sql
│   │   ├── 2_stg_pgaudit_session_log.sql
│   │   ├── 3_lnd_postgre_log.sql
│   │   ├── 4_lnd_pgaudit_session_log.sql
│   │   └── 5_lnd_postgre_log_run.sql
│   ├── utilities/
│   │   ├── __init__.py
│   │   ├── credential.py
│   │   ├── dataframe.py
│   │   ├── environment.py
│   │   ├── outlook.py
│   │   ├── postgre.py
│   │   ├── ssh.py
│   │   └── validation.py
├── requirements.txt
└── README.md
```

## 🔧 Configuration
- **Environment Variables**: Set up your database and SSH credentials in the `.env` file.
- **SQL Scripts**: Customize the SQL scripts in the `dependencies/sql` directory to fit your specific needs.
- **Email Notifications**: Configure the SMTP settings in the `.env` file to send email notifications.
