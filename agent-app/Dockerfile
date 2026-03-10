FROM --platform=linux/arm64 public.ecr.aws/amazonlinux/amazonlinux:2023

RUN dnf update -y && \
    dnf install -y python3.11 python3.11-pip shadow-utils gcc python3.11-devel && \
    dnf clean all

RUN alternatives --install /usr/bin/python3 python3 /usr/bin/python3.11 1 && \
    alternatives --install /usr/bin/pip3 pip3 /usr/bin/pip3.11 1

WORKDIR /app

COPY requirements.txt .
RUN pip3 install --no-cache-dir -r requirements.txt && \
    pip3 install --no-cache-dir aws-opentelemetry-distro==0.10.1

# Create non-root user for security
RUN useradd -m -u 1000 bedrock_agentcore

EXPOSE 8080

# Copy application code
COPY src/agent.py .

# Switch to non-root user (security best practice)
USER bedrock_agentcore

HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD python3 -c "import urllib.request; urllib.request.urlopen('http://localhost:8080/ping')" || exit 1

CMD ["opentelemetry-instrument", "python3", "agent.py"]
