ARG GIT_SHA=unknown
ARG BUILD_DATE=unknown
 
FROM python:3.9.19-slim AS builder
 
WORKDIR /build
 
RUN apt-get update && \
    apt-get install -y --no-install-recommends gcc libffi-dev && \
    rm -rf /var/lib/apt/lists/*
 
COPY app/requirements.txt .
 
RUN pip install --no-cache-dir --prefix=/install -r requirements.txt
 
 
FROM python:3.9.19-slim AS runner
 
ARG GIT_SHA
ARG BUILD_DATE
LABEL org.opencontainers.image.source="https://github.com/your-org/your-repo" \
      org.opencontainers.image.revision="${GIT_SHA}" \
      org.opencontainers.image.created="${BUILD_DATE}" \
      org.opencontainers.image.base.name="python:3.9.19-slim"
 
RUN apt-get update && \
    apt-get install -y --no-install-recommends curl && \
    rm -rf /var/lib/apt/lists/*
 
RUN addgroup --system appgroup && \
    adduser  --system --ingroup appgroup --no-create-home appuser
 
WORKDIR /app
 
COPY --from=builder /install /usr/local
 
COPY app/ /app/
 
RUN chown -R appuser:appgroup /app
 
VOLUME ["/tmp", "/app/logs"]
 
USER appuser
 
EXPOSE 80
 
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD curl -f http://localhost:80/health || exit 1
 
CMD ["python", "main.py"]